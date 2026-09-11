from typing import Literal

from pydantic import BaseModel, Field


SamplePlayMode = Literal["one_shot", "loop"]
SampleEffectId = Literal["pitch", "ring", "blur", "flanger", "ats"]


class SampleSlot(BaseModel):
    """Frontend-facing metadata for one fixed Live Sample Mode pad."""

    slot: int = Field(ge=0, le=7)
    loaded: bool
    name: str | None = None
    duration: float | None = None
    size_bytes: int | None = None
    detected_bpm: float | None = Field(default=None, ge=40, le=240)
    tempo_confidence: float | None = Field(default=None, ge=0, le=1)
    gain: float = 1.0
    gain_db: float = Field(default=0.0, ge=-24, le=24)
    waveform: list[float] = Field(default_factory=list)
    peak_db: float | None = None
    clipped: bool = False
    effect_sends: dict[SampleEffectId, float] = Field(default_factory=dict)
    play_mode: SamplePlayMode = "one_shot"
    loop_bars: int = Field(default=1, ge=1, le=8)
    active: bool = False


class SampleModeUpdate(BaseModel):
    """Toggle between microphone Live Mode and exclusive Sample Mode."""

    enabled: bool


class SampleSlotUpdate(BaseModel):
    """Editable pad settings that do not replace the underlying audio file."""

    name: str | None = Field(default=None, max_length=64)
    play_mode: SamplePlayMode | None = None
    loop_bars: int | None = Field(default=None, ge=1, le=8)
    gain_db: float | None = Field(default=None, ge=-24, le=24)
    effect_sends: dict[SampleEffectId, float] | None = None
