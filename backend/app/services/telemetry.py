from __future__ import annotations

from collections import deque
import math
import threading
import time

from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import ThreadingOSCUDPServer

from app.core.config import settings
from app.schemas.live import LiveTelemetry


WAVEFORM_POINTS = 256
SPECTRUM_BANDS = 16
TELEMETRY_TIMEOUT_SECONDS = 0.9


class ReusableOSCUDPServer(ThreadingOSCUDPServer):
    """Allow local dev restarts to re-bind the telemetry port quickly."""

    allow_reuse_address = True


class TelemetryReceiver:
    """Receives Csound output probes and exposes the latest UI-ready snapshot."""

    def __init__(self, host: str = settings.osc_host, port: int = settings.telemetry_port) -> None:
        self.host = host
        self.port = port
        self._waveform: deque[float] = deque([0.0] * WAVEFORM_POINTS, maxlen=WAVEFORM_POINTS)
        self._spectrum = [0.0] * SPECTRUM_BANDS
        self._rms = 0.0
        self._peak = 0.0
        self._clip = False
        self._last_update = 0.0
        self._lock = threading.RLock()
        self._server: ReusableOSCUDPServer | None = None
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        """Start the OSC listener once for the FastAPI process."""

        if self._server is not None:
            return

        dispatcher = Dispatcher()
        dispatcher.map("/ol/telemetry/wave", self._handle_wave)
        dispatcher.map("/ol/telemetry/meter", self._handle_meter)
        dispatcher.map("/ol/telemetry/spectrum", self._handle_spectrum)

        self._server = ReusableOSCUDPServer((self.host, self.port), dispatcher)
        self._thread = threading.Thread(target=self._server.serve_forever, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        """Release the UDP port when the API server exits."""

        server = self._server
        if server is None:
            return

        server.shutdown()
        server.server_close()
        self._server = None
        self._thread = None

    def reset(self) -> None:
        """Clear stale signal data when Csound stops or restarts."""

        with self._lock:
            self._waveform = deque([0.0] * WAVEFORM_POINTS, maxlen=WAVEFORM_POINTS)
            self._spectrum = [0.0] * SPECTRUM_BANDS
            self._rms = 0.0
            self._peak = 0.0
            self._clip = False
            self._last_update = 0.0

    def snapshot(self, running: bool) -> LiveTelemetry:
        """Return real data while fresh, otherwise an honest idle baseline."""

        with self._lock:
            fresh = running and self._last_update > 0 and time.monotonic() - self._last_update <= TELEMETRY_TIMEOUT_SECONDS
            if not fresh:
                return LiveTelemetry(
                    running=False,
                    waveform=[0.0] * WAVEFORM_POINTS,
                    spectrum=[0.0] * SPECTRUM_BANDS,
                    rms=0.0,
                    peak=0.0,
                    clip=False,
                    timestamp=time.time(),
                )

            return LiveTelemetry(
                running=True,
                waveform=list(self._waveform),
                spectrum=list(self._spectrum),
                rms=self._rms,
                peak=self._peak,
                clip=self._clip,
                timestamp=time.time(),
            )

    def _handle_wave(self, _: str, *args: object) -> None:
        values = self._coerce_numbers(args)
        if not values:
            return

        with self._lock:
            # Csound sends min/max pairs for each scope window so the browser sees true amplitude bounds.
            if len(values) >= 2:
                self._waveform.append(self._clamp(values[0], -1.0, 1.0))
                self._waveform.append(self._clamp(values[1], -1.0, 1.0))
            else:
                self._waveform.append(self._clamp(values[0], -1.0, 1.0))
            self._last_update = time.monotonic()

    def _handle_meter(self, _: str, *args: object) -> None:
        values = self._coerce_numbers(args)
        if len(values) < 2:
            return

        with self._lock:
            self._rms = self._clamp(values[0], 0.0, 1.5)
            self._peak = self._clamp(values[1], 0.0, 1.5)
            self._clip = bool(values[2] >= 0.5) if len(values) > 2 else self._peak >= 0.98
            self._last_update = time.monotonic()

    def _handle_spectrum(self, _: str, *args: object) -> None:
        values = self._coerce_numbers(args)
        if not values:
            return

        padded = values[:SPECTRUM_BANDS] + [0.0] * max(0, SPECTRUM_BANDS - len(values))
        with self._lock:
            self._spectrum = [self._clamp(value, 0.0, 1.5) for value in padded[:SPECTRUM_BANDS]]
            self._last_update = time.monotonic()

    def _coerce_numbers(self, values: tuple[object, ...]) -> list[float]:
        """Drop malformed OSC values so a bad packet cannot break the stream."""

        numbers: list[float] = []
        for value in values:
            try:
                number = float(value)
            except (TypeError, ValueError):
                continue
            if math.isfinite(number):
                numbers.append(number)
        return numbers

    def _clamp(self, value: float, low: float, high: float) -> float:
        return max(low, min(high, value))


telemetry = TelemetryReceiver()
