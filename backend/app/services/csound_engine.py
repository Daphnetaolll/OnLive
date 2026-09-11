from __future__ import annotations

from collections import deque
from pathlib import Path
import shutil
import subprocess
import threading
import time

from app.core.config import settings
from app.core.paths import ATS_CROSS_DIR, CSOUND_CSD_PATH, SAMPLE_STORAGE_DIR
from app.schemas.live import DeviceList, LiveStatus, ParamUpdate
from app.schemas.samples import SampleSlot
from app.services.device_parser import parse_csound_devices
from app.services.osc_client import OscClient
from app.services.telemetry import telemetry


SAMPLE_EFFECT_INDEXES = {
    "pitch": 0,
    "ring": 1,
    "blur": 2,
    "flanger": 3,
    "ats": 4,
}

# Variant paths are numeric effect-slot selectors. Index 0 is the current Csound
# branch; add new indexes here when adding same-category variants in the .csd file.
ALLOWED_OSC_PATHS = {
    "/ol/mode/sample": (0.0, 1.0),
    "/ol/transport/bpm": (40.0, 240.0),
    "/ol/transport/sync": (0.0, 1.0),
    "/ol/transport/warp": (0.0, 1.0),
    "/ol/pitch/variant": (0.0, 15.0),
    "/ol/pitch/on": (0.0, 1.0),
    "/ol/pitch/wet": (0.0, 1.0),
    "/ol/pitch/semi": (-12.0, 12.0),
    "/ol/ring/variant": (0.0, 15.0),
    "/ol/ring/on": (0.0, 1.0),
    "/ol/ring/wet": (0.0, 1.0),
    "/ol/blur/variant": (0.0, 15.0),
    "/ol/blur/on": (0.0, 1.0),
    "/ol/blur/len": (0.0, 100.0),
    "/ol/blur/wet": (0.0, 1.0),
    "/ol/flanger/variant": (0.0, 15.0),
    "/ol/flanger/on": (0.0, 1.0),
    "/ol/flanger/wet": (0.0, 1.0),
    "/ol/flanger/lfo": (0.0, 1.0),
    "/ol/ats/variant": (0.0, 15.0),
    "/ol/ats/on": (0.0, 1.0),
    "/ol/ats/wet": (0.0, 1.0),
    "/ol/ats/morph": (0.0, 1.0),
    "/ol/ats/speed": (0.1, 2.0),
    "/ol/eq/low": (-12.0, 12.0),
    "/ol/eq/mid": (-12.0, 12.0),
    "/ol/eq/high": (-12.0, 12.0),
    "/ol/master/volume": (0.0, 1.0),
    "/ol/limiter/threshold": (-24.0, 0.0),
    "/ol/limiter/ceiling": (-12.0, 0.0),
    "/ol/limiter/attack": (0.1, 30.0),
    "/ol/limiter/release": (20.0, 1000.0),
}

DEFAULT_PARAMS = {
    "/ol/mode/sample": 0.0,
    "/ol/transport/bpm": 120.0,
    "/ol/transport/sync": 0.0,
    "/ol/transport/warp": 1.0,
    "/ol/pitch/variant": 0.0,
    "/ol/pitch/on": 0.0,
    "/ol/pitch/wet": 0.5,
    "/ol/pitch/semi": 0.0,
    "/ol/ring/variant": 0.0,
    "/ol/ring/on": 0.0,
    "/ol/ring/wet": 0.5,
    "/ol/blur/variant": 0.0,
    "/ol/blur/on": 0.0,
    "/ol/blur/len": 50.0,
    "/ol/blur/wet": 0.5,
    "/ol/flanger/variant": 0.0,
    "/ol/flanger/on": 0.0,
    "/ol/flanger/wet": 0.5,
    "/ol/flanger/lfo": 0.5,
    "/ol/ats/variant": 0.0,
    "/ol/ats/on": 0.0,
    "/ol/ats/wet": 0.35,
    "/ol/ats/morph": 0.65,
    "/ol/ats/speed": 1.0,
    "/ol/eq/low": 0.0,
    "/ol/eq/mid": 0.0,
    "/ol/eq/high": 0.0,
    "/ol/master/volume": 1.0,
    "/ol/limiter/threshold": -3.0,
    "/ol/limiter/ceiling": -1.0,
    "/ol/limiter/attack": 2.0,
    "/ol/limiter/release": 140.0,
}


class CsoundEngine:
    """Owns the single Live Mode Csound subprocess for this backend process."""

    def __init__(self, csd_path: Path = CSOUND_CSD_PATH) -> None:
        self.csd_path = csd_path
        self.input_device = 0
        self.output_device = 0
        self.command: list[str] = []
        self.params = DEFAULT_PARAMS.copy()
        self.sample_mode = False
        self.looping_sample_slots: set[int] = set()
        self.last_message = "Csound is stopped."
        self._logs: deque[str] = deque(maxlen=240)
        self._lock = threading.RLock()
        self._proc: subprocess.Popen[str] | None = None
        self._reader: threading.Thread | None = None
        self._osc = OscClient(settings.osc_host, settings.osc_port)

    def list_devices(self) -> DeviceList:
        """Ask Csound for audio devices and parse both input and output groups."""

        self._require_csound_binary()
        result = subprocess.run(
            ["csound", "--devices"],
            capture_output=True,
            text=True,
            check=False,
        )
        return parse_csound_devices(f"{result.stdout}\n{result.stderr}")

    def start(self, input_device: int, output_device: int) -> LiveStatus:
        """Launch Csound with adc/dac routing that matches the current performance mode."""

        with self._lock:
            if self._is_running_locked():
                self.last_message = "Csound Live Mode is already running."
                return self.status()

            self._require_csound_binary()
            if not self.csd_path.exists():
                raise FileNotFoundError(f"Csound file not found: {self.csd_path}")

            devices = self.list_devices()
            use_audio_input = not self.sample_mode
            input_channels = self._device_channels(devices.inputs, input_device, fallback=2) if use_audio_input else 0
            output_channels = self._device_channels(devices.outputs, output_device, fallback=2)
            self._select_devices_locked(input_device, output_device)
            telemetry.reset()

            # Sample Mode is truly exclusive: do not open an adc device when pads are the source.
            self.command = [
                "csound",
                f"-odac{output_device}",
                f"--nchnls_i={input_channels if use_audio_input else 0}",
                f"--nchnls={max(2, output_channels)}",
                f"--strset1={SAMPLE_STORAGE_DIR}",
                f"--strset2={ATS_CROSS_DIR}",
                "-b128",
                "-B512",
                str(self.csd_path),
            ]
            if use_audio_input:
                self.command.insert(1, f"-iadc{input_device}")

            # Keep the console focused on the current run so stale Csound failures do not look active.
            self._logs.clear()
            self._append_log(f"Starting: {' '.join(self.command)}")
            self._proc = subprocess.Popen(
                self.command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            self._reader = threading.Thread(target=self._read_logs, daemon=True)
            self._reader.start()
            self.last_message = "Csound Live Mode started."

        self._wait_for_osc_listener()
        with self._lock:
            self._refresh_process_state_locked()
        self._send_snapshot()
        return self.status()

    def select_devices(self, input_device: int, output_device: int) -> LiveStatus:
        """Store the active adc/dac selection and restart Csound if needed."""

        with self._lock:
            was_running = self._is_running_locked()

        if was_running:
            self.stop()
            return self.start(input_device, output_device)

        with self._lock:
            self._select_devices_locked(input_device, output_device)
            self.command = []
            self.last_message = f"Audio devices set: input adc{input_device}, output dac{output_device}."
        return self.status()

    def stop(self) -> LiveStatus:
        """Stop Csound gently, then kill it if the process ignores termination."""

        with self._lock:
            if not self._is_running_locked():
                # A failed Csound launch can leave the UI in an error state even after the process exits.
                self._proc = None
                self.last_message = "Csound cleanup complete."
                self._logs.clear()
                self._append_log("Csound cleanup complete.")
                self.looping_sample_slots.clear()
                telemetry.reset()
                return self.status()

            proc = self._proc
            assert proc is not None
            proc.terminate()

        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=2)

        with self._lock:
            self._append_log("Csound stopped.")
            self._proc = None
            self.looping_sample_slots.clear()
            self.last_message = "Csound Live Mode stopped."
        telemetry.reset()
        return self.status()

    def update_param(self, path: str, value: float | int | bool) -> LiveStatus:
        """Validate a UI control and forward it to Csound over OSC."""

        normalized = self._normalize_param(path, value)
        with self._lock:
            self.params[path] = normalized
        self._osc.send(path, normalized)
        return self.status()

    def update_params(self, updates: list[ParamUpdate]) -> LiveStatus:
        """Validate and send a grouped UI state snapshot to Csound in one action."""

        normalized_updates = [(update.path, self._normalize_param(update.path, update.value)) for update in updates]
        with self._lock:
            for path, value in normalized_updates:
                self.params[path] = value
            self.last_message = "Effect parameters synchronized."

        for path, value in normalized_updates:
            self._osc.send(path, value)
        return self.status()

    def status(self) -> LiveStatus:
        """Return a UI-friendly process snapshot without exposing the Popen object."""

        with self._lock:
            self._refresh_process_state_locked()
            return LiveStatus(
                running=self._is_running_locked(),
                input_device=self.input_device,
                output_device=self.output_device,
                command=self.command,
                params=self.params.copy(),
                sample_mode=self.sample_mode,
                last_message=self.last_message,
            )

    def logs(self) -> list[str]:
        """Expose recent process output for the Live Mode console."""

        with self._lock:
            return list(self._logs)

    def set_sample_mode(self, enabled: bool) -> LiveStatus:
        """Switch between exclusive microphone Live Mode and no-input Sample Mode."""

        value = 1.0 if enabled else 0.0
        with self._lock:
            was_running = self._is_running_locked()
            self.sample_mode = enabled
            self.params["/ol/mode/sample"] = value
            self.last_message = "Sample Mode enabled." if enabled else "Live microphone mode enabled."

        # Restart while running so CoreAudio opens or releases the physical input device correctly.
        if was_running:
            self.stop()
            if not enabled:
                self.stop_all_samples("Live microphone mode enabled.")
            return self.start(self.input_device, self.output_device)

        if not enabled:
            self.stop_all_samples("Live microphone mode enabled.")
        self._osc.send("/ol/mode/sample", value)
        return self.status()

    def active_sample_slots(self) -> set[int]:
        """Expose loop-active pads so the frontend can render accurate pad state."""

        with self._lock:
            return set(self.looping_sample_slots)

    def trigger_sample(self, slot: SampleSlot, restart: bool = False) -> LiveStatus:
        """Schedule a loaded sample pad inside Csound so it enters the shared effects chain."""

        if not slot.loaded or slot.duration is None:
            raise ValueError("Load a sample before triggering this pad.")
        with self._lock:
            if not self.sample_mode:
                raise RuntimeError("Enable Sample Mode first.")
            needs_start = not self._is_running_locked()
            input_device = self.input_device
            output_device = self.output_device

        # Pads are performance controls: in Sample Mode, the first hit should wake the engine.
        if needs_start:
            self.start(input_device, output_device)

        with self._lock:
            if not self._is_running_locked():
                raise RuntimeError("Start the engine first.")
            duration = max(0.02, float(slot.duration))
            gain = float(slot.gain)
            loop_bars = max(1, min(8, int(slot.loop_bars)))

            # Mode buttons request restart=True, so they always replace the current pad voice.
            if slot.play_mode == "loop":
                if slot.slot in self.looping_sample_slots and not restart:
                    self.looping_sample_slots.remove(slot.slot)
                    self.last_message = f"Stopped loop pad {slot.slot + 1}: {slot.name or 'Untitled'}."
                    should_start_loop = False
                else:
                    self.looping_sample_slots.add(slot.slot)
                    self.last_message = f"Looping sample pad {slot.slot + 1}: {slot.name or 'Untitled'}."
                    should_start_loop = True
            else:
                self.looping_sample_slots.discard(slot.slot)
                self.last_message = f"Triggered sample pad {slot.slot + 1}: {slot.name or 'Untitled'}."
                should_start_loop = None

        self._sync_sample_sends(slot.slot, slot.effect_sends)
        if should_start_loop is True:
            self._osc.send_many("/ol/sample/loop/start", [slot.slot, gain, duration, loop_bars])
        elif should_start_loop is False:
            self._osc.send_many("/ol/sample/loop/stop", [slot.slot])
        else:
            self._osc.send_many("/ol/sample/trigger", [slot.slot, gain, 1.0, duration])
        return self.status()

    def stop_sample(self, slot: int) -> LiveStatus:
        """Stop one loop pad without touching the rest of Sample Mode."""

        with self._lock:
            self.looping_sample_slots.discard(slot)
            self.last_message = f"Stopped sample pad {slot + 1}."
        self._osc.send_many("/ol/sample/loop/stop", [slot])
        return self.status()

    def update_sample_gain(self, slot: int, gain: float) -> None:
        """Push pad volume changes into any currently playing Csound sample voice."""

        if slot < 0 or slot > 7:
            raise ValueError("Sample slot must be between 0 and 7.")
        with self._lock:
            is_running = self._is_running_locked()
        if is_running:
            self._osc.send_many("/ol/sample/gain", [slot, max(0.0, min(16.0, float(gain)))])

    def update_sample_sends(self, slot: int, effect_sends: dict[str, float]) -> None:
        """Push one sample's effect send row into any active Csound voices."""

        self._sync_sample_sends(slot, effect_sends)

    def stop_all_samples(self, message: str = "All sample pads stopped.") -> LiveStatus:
        """Stop every scheduled sample voice when leaving Sample Mode or stopping audio."""

        with self._lock:
            self.looping_sample_slots.clear()
            self.last_message = message
        self._osc.send("/ol/sample/stop_all", 1.0)
        return self.status()

    def shutdown(self) -> None:
        """Release the audio device when FastAPI exits."""

        try:
            self.stop()
        except Exception as exc:
            self._append_log(f"Shutdown stop failed: {exc}")

    def _send_snapshot(self) -> None:
        """Hydrate a newly started Csound process with the current UI values."""

        for path, value in self.params.items():
            self._osc.send(path, value)

    def _sync_sample_sends(self, slot: int, effect_sends: dict[str, float]) -> None:
        """Mirror a sample row into Csound's sample-send matrix."""

        if slot < 0 or slot > 7:
            raise ValueError("Sample slot must be between 0 and 7.")
        with self._lock:
            is_running = self._is_running_locked()
        if not is_running:
            return
        for effect_id, effect_index in SAMPLE_EFFECT_INDEXES.items():
            value = max(0.0, min(1.0, float(effect_sends.get(effect_id, 1.0))))
            self._osc.send_many("/ol/sample/send", [slot, effect_index, value])

    def _read_logs(self) -> None:
        """Drain Csound stdout so long-running live sessions cannot block."""

        proc = self._proc
        if proc is None or proc.stdout is None:
            return

        for line in proc.stdout:
            self._append_log(line.rstrip())

        with self._lock:
            if proc.poll() not in (None, 0):
                self.last_message = f"Csound exited with code {proc.returncode}."
                self.looping_sample_slots.clear()

    def _wait_for_osc_listener(self, timeout: float = 2.5) -> None:
        """Wait briefly until Csound can receive OSC control messages."""

        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            with self._lock:
                if any("OSC listener" in line for line in self._logs):
                    return
                if self._proc is not None and self._proc.poll() is not None:
                    return
            time.sleep(0.05)

    def _append_log(self, message: str) -> None:
        with self._lock:
            if message:
                self._logs.append(message)

    def _select_devices_locked(self, input_device: int, output_device: int) -> None:
        self.input_device = input_device
        self.output_device = output_device

    def _device_channels(self, devices: list, device_id: int, fallback: int) -> int:
        """Match Csound's process channel count to the selected Core Audio device."""

        for device in devices:
            if device.id == device_id:
                return device.channels
        return fallback

    def _refresh_process_state_locked(self) -> None:
        if self._proc is None:
            return
        returncode = self._proc.poll()
        if returncode is not None and returncode != 0:
            self.last_message = f"Csound exited with code {returncode}. Check the selected adc/dac devices."
            self.looping_sample_slots.clear()

    def _is_running_locked(self) -> bool:
        return self._proc is not None and self._proc.poll() is None

    def _require_csound_binary(self) -> None:
        if shutil.which("csound") is None:
            raise RuntimeError("Could not find the `csound` command in PATH.")

    def _normalize_param(self, path: str, value: float | int | bool) -> float:
        if path not in ALLOWED_OSC_PATHS:
            raise ValueError(f"Unsupported OSC path: {path}")

        low, high = ALLOWED_OSC_PATHS[path]
        numeric = 1.0 if value is True else 0.0 if value is False else float(value)
        if numeric < low or numeric > high:
            raise ValueError(f"{path} must be between {low} and {high}.")
        return numeric


engine = CsoundEngine()
