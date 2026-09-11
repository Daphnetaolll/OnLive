from __future__ import annotations

from pathlib import Path
import json
import math
import shutil
import tempfile

from fastapi import UploadFile
from pydub import AudioSegment

from app.core.paths import SAMPLE_STORAGE_DIR
from app.schemas.samples import SamplePlayMode, SampleSlot, SampleSlotUpdate
from app.services.tempo_detection import detect_tempo


SAMPLE_SLOT_COUNT = 8
SAMPLE_EFFECT_IDS = ("pitch", "ring", "blur", "flanger", "ats")
DEFAULT_EFFECT_SENDS = {effect_id: 1.0 for effect_id in SAMPLE_EFFECT_IDS}
SUPPORTED_EXTENSIONS = {".wav", ".aif", ".aiff", ".mp3", ".m4a", ".flac", ".ogg"}
MAX_UPLOAD_BYTES = 80 * 1024 * 1024
MAX_SAMPLE_SECONDS = 120
WAVEFORM_POINTS = 96
MIN_SAMPLE_GAIN_DB = -24.0
MAX_SAMPLE_GAIN_DB = 24.0


class SampleBank:
    """Own the fixed 8-slot sample library used by Csound Sample Mode."""

    def __init__(self, root: Path = SAMPLE_STORAGE_DIR) -> None:
        self.root = root
        self.metadata_path = self.root / "samples.json"
        self.root.mkdir(parents=True, exist_ok=True)

    def list_slots(self, active_slots: set[int] | None = None) -> list[SampleSlot]:
        """Return every pad so the UI can render a stable 8-button layout."""

        metadata = self._read_metadata_with_analysis()
        active = active_slots or set()
        return [self._slot_from_metadata(slot, metadata.get(str(slot)), slot in active) for slot in range(SAMPLE_SLOT_COUNT)]

    def get_slot(self, slot: int, active_slots: set[int] | None = None) -> SampleSlot:
        """Read one slot after validating the pad index."""

        self._validate_slot(slot)
        metadata = self._read_metadata_with_analysis()
        return self._slot_from_metadata(slot, metadata.get(str(slot)), slot in (active_slots or set()))

    def store_upload(self, slot: int, upload: UploadFile) -> SampleSlot:
        """Convert an uploaded file to a Csound-friendly 44.1 kHz stereo WAV."""

        self._validate_slot(slot)
        filename = Path(upload.filename or f"pad_{slot + 1}").name
        suffix = Path(filename).suffix.lower()
        if suffix not in SUPPORTED_EXTENSIONS:
            raise ValueError("Upload an audio file: wav, aiff, mp3, m4a, flac, or ogg.")

        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            shutil.copyfileobj(upload.file, tmp)
            temp_path = Path(tmp.name)

        try:
            size_bytes = temp_path.stat().st_size
            if size_bytes > MAX_UPLOAD_BYTES:
                raise ValueError("Sample file is too large.")

            audio = AudioSegment.from_file(temp_path)
            duration = audio.duration_seconds
            if duration <= 0:
                raise ValueError("Sample file is empty.")
            if duration > MAX_SAMPLE_SECONDS:
                raise ValueError(f"Sample must be {MAX_SAMPLE_SECONDS} seconds or shorter.")

            target = self.sample_path(slot)
            normalized = audio.set_frame_rate(44100).set_channels(2).set_sample_width(2)
            normalized.export(target, format="wav")
            tempo = detect_tempo(audio)
            analysis = _analyze_sample_audio(normalized)

            metadata = self._read_metadata()
            existing_name = _metadata_name(metadata.get(str(slot)))
            metadata[str(slot)] = {
                "name": existing_name or filename,
                "duration": round(duration, 3),
                "size_bytes": target.stat().st_size,
                "detected_bpm": tempo.bpm if tempo else None,
                "tempo_confidence": tempo.confidence if tempo else None,
                "gain_db": 0.0,
                "gain": 1.0,
                **analysis,
                "effect_sends": DEFAULT_EFFECT_SENDS.copy(),
                "play_mode": "one_shot",
                "loop_bars": 1,
            }
            self._write_metadata(metadata)
            return self.get_slot(slot)
        finally:
            temp_path.unlink(missing_ok=True)

    def delete_slot(self, slot: int) -> SampleSlot:
        """Clear a pad without changing the other seven slots."""

        self._validate_slot(slot)
        self.sample_path(slot).unlink(missing_ok=True)
        metadata = self._read_metadata()
        metadata.pop(str(slot), None)
        self._write_metadata(metadata)
        return self.get_slot(slot)

    def update_slot(self, slot: int, update: SampleSlotUpdate, active_slots: set[int] | None = None) -> SampleSlot:
        """Persist editable pad metadata and playback behavior."""

        self._validate_slot(slot)
        metadata = self._read_metadata()
        data = metadata.get(str(slot)) if isinstance(metadata.get(str(slot)), dict) else {}
        target_exists = self.sample_path(slot).exists()
        if not target_exists and update.name is None:
            raise ValueError("Load a sample before changing pad settings.")
        if update.name is not None:
            data["name"] = _clean_sample_name(update.name, slot)
        if not target_exists:
            metadata[str(slot)] = data
            self._write_metadata(metadata)
            return self.get_slot(slot, active_slots)
        if update.play_mode is not None:
            data["play_mode"] = update.play_mode
        if update.loop_bars is not None:
            data["loop_bars"] = update.loop_bars
        if update.gain_db is not None:
            gain_db = max(MIN_SAMPLE_GAIN_DB, min(MAX_SAMPLE_GAIN_DB, float(update.gain_db)))
            data["gain_db"] = gain_db
            data["gain"] = _db_to_gain(gain_db)
        if update.effect_sends is not None:
            data["effect_sends"] = _merge_effect_sends(data.get("effect_sends"), update.effect_sends)
        metadata[str(slot)] = data
        self._write_metadata(metadata)
        return self.get_slot(slot, active_slots)

    def sample_path(self, slot: int) -> Path:
        self._validate_slot(slot)
        return self.root / f"pad_{slot:02d}.wav"

    def _slot_from_metadata(self, slot: int, data: dict | None, active: bool = False) -> SampleSlot:
        target = self.sample_path(slot)
        if data is None or not target.exists():
            return SampleSlot(slot=slot, loaded=False, name=_metadata_name(data))
        play_mode: SamplePlayMode = "loop" if data.get("play_mode") == "loop" else "one_shot"
        loop_bars = int(data.get("loop_bars") or 1)
        gain_db = _gain_db_from_metadata(data)
        return SampleSlot(
            slot=slot,
            loaded=True,
            name=str(data.get("name") or f"Pad {slot + 1}"),
            duration=float(data.get("duration") or 0),
            size_bytes=int(data.get("size_bytes") or target.stat().st_size),
            detected_bpm=_optional_clamped_float(data.get("detected_bpm"), 40, 240),
            tempo_confidence=_optional_clamped_float(data.get("tempo_confidence"), 0, 1),
            gain=_db_to_gain(gain_db),
            gain_db=gain_db,
            waveform=_safe_waveform(data.get("waveform")),
            peak_db=_optional_float(data.get("peak_db")),
            clipped=bool(data.get("clipped", False)),
            effect_sends=_merge_effect_sends(data.get("effect_sends"), None),
            play_mode=play_mode,
            loop_bars=max(1, min(8, loop_bars)),
            active=active,
        )

    def _read_metadata_with_analysis(self) -> dict[str, dict]:
        """Backfill waveform and clipping metadata for samples uploaded before this feature."""

        metadata = self._read_metadata()
        changed = False
        for slot_text, data in list(metadata.items()):
            try:
                slot = int(slot_text)
            except ValueError:
                continue
            if slot < 0 or slot >= SAMPLE_SLOT_COUNT or not isinstance(data, dict):
                continue
            target = self.sample_path(slot)
            if not target.exists():
                continue
            if "waveform" not in data or "peak_db" not in data or "clipped" not in data:
                data.update(_analyze_sample_file(target))
                metadata[slot_text] = data
                changed = True
            if "gain_db" not in data:
                data["gain_db"] = _gain_to_db(float(data.get("gain") or 1.0))
                data["gain"] = _db_to_gain(data["gain_db"])
                metadata[slot_text] = data
                changed = True
            if "effect_sends" not in data:
                data["effect_sends"] = DEFAULT_EFFECT_SENDS.copy()
                metadata[slot_text] = data
                changed = True
        if changed:
            self._write_metadata(metadata)
        return metadata

    def _read_metadata(self) -> dict[str, dict]:
        if not self.metadata_path.exists():
            return {}
        with self.metadata_path.open("r", encoding="utf-8") as handle:
            return json.load(handle)

    def _write_metadata(self, metadata: dict[str, dict]) -> None:
        self.root.mkdir(parents=True, exist_ok=True)
        with self.metadata_path.open("w", encoding="utf-8") as handle:
            json.dump(metadata, handle, indent=2, sort_keys=True)

    def _validate_slot(self, slot: int) -> None:
        if slot < 0 or slot >= SAMPLE_SLOT_COUNT:
            raise ValueError(f"Sample slot must be between 0 and {SAMPLE_SLOT_COUNT - 1}.")


sample_bank = SampleBank()


def _optional_clamped_float(value: object, minimum: float, maximum: float) -> float | None:
    if value is None:
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return max(minimum, min(maximum, number))


def _optional_float(value: object) -> float | None:
    try:
        return None if value is None else float(value)
    except (TypeError, ValueError):
        return None


def _db_to_gain(db_value: float) -> float:
    safe_db = max(MIN_SAMPLE_GAIN_DB, min(MAX_SAMPLE_GAIN_DB, float(db_value)))
    return round(math.pow(10, safe_db / 20), 6)


def _gain_to_db(gain: float) -> float:
    safe_gain = max(0.0001, float(gain))
    return round(max(MIN_SAMPLE_GAIN_DB, min(MAX_SAMPLE_GAIN_DB, 20 * math.log10(safe_gain))), 2)


def _gain_db_from_metadata(data: dict) -> float:
    if data.get("gain_db") is not None:
        return max(MIN_SAMPLE_GAIN_DB, min(MAX_SAMPLE_GAIN_DB, float(data.get("gain_db"))))
    return _gain_to_db(float(data.get("gain") or 1.0))


def _merge_effect_sends(current: object, updates: dict[str, float] | None) -> dict[str, float]:
    """Keep every sample route complete while allowing partial matrix updates from the UI."""

    merged = DEFAULT_EFFECT_SENDS.copy()
    if isinstance(current, dict):
        for effect_id in SAMPLE_EFFECT_IDS:
            if effect_id in current:
                merged[effect_id] = _clamp_send(current[effect_id])
    if updates:
        for effect_id, value in updates.items():
            if effect_id in SAMPLE_EFFECT_IDS:
                merged[effect_id] = _clamp_send(value)
    return merged


def _clean_sample_name(value: str, slot: int) -> str:
    """Store concise pad names so the performance grid stays readable."""

    name = " ".join(str(value).strip().split())
    if not name:
        return f"Pad {slot + 1}"
    return name[:64]


def _metadata_name(data: object) -> str | None:
    """Read optional labels from empty or loaded pad metadata."""

    if not isinstance(data, dict):
        return None
    value = data.get("name")
    if not isinstance(value, str):
        return None
    name = " ".join(value.strip().split())
    if name.lower() == "empty":
        return None
    return name[:64] or None


def _clamp_send(value: object) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return 0.0
    return round(max(0.0, min(1.0, number)), 3)


def _analyze_sample_file(path: Path) -> dict[str, object]:
    audio = AudioSegment.from_file(path)
    return _analyze_sample_audio(audio)


def _analyze_sample_audio(audio: AudioSegment) -> dict[str, object]:
    """Build a compact full-file envelope and peak readout for each sample pad."""

    mono = audio.set_channels(1)
    samples = mono.get_array_of_samples()
    max_amplitude = float(mono.max_possible_amplitude) or 1.0
    waveform: list[float] = []
    window_size = max(1, math.ceil(len(samples) / WAVEFORM_POINTS))
    for index in range(WAVEFORM_POINTS):
        start = index * window_size
        end = min(len(samples), start + window_size)
        chunk = samples[start:end]
        if not chunk:
            waveform.extend([0.0, 0.0])
            continue
        waveform.extend([
            _clamp_sample(min(chunk) / max_amplitude),
            _clamp_sample(max(chunk) / max_amplitude),
        ])

    peak = float(audio.max) / max(float(audio.max_possible_amplitude), 1.0)
    peak_db = None if peak <= 0 else round(20 * math.log10(peak), 1)
    return {
        "waveform": waveform,
        "peak_db": peak_db,
        "clipped": peak >= 0.999,
    }


def _safe_waveform(value: object) -> list[float]:
    if not isinstance(value, list):
        return []
    waveform: list[float] = []
    for sample in value[: WAVEFORM_POINTS * 2]:
        try:
            waveform.append(_clamp_sample(float(sample)))
        except (TypeError, ValueError):
            waveform.append(0.0)
    return waveform


def _clamp_sample(value: float) -> float:
    return round(max(-1.0, min(1.0, value)), 4)
