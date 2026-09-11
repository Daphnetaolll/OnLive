from typing import Literal

from pydantic import BaseModel, Field


class DeviceInfo(BaseModel):
    """Normalized Csound device entry shown by the React device selectors."""

    id: int
    label: str
    name: str
    channels: int
    kind: Literal["input", "output"]
    raw: str


class DeviceList(BaseModel):
    """Input and output device groups returned by the live engine."""

    inputs: list[DeviceInfo]
    outputs: list[DeviceInfo]


class StartLiveRequest(BaseModel):
    """Selected adc/dac ids used when launching the Csound subprocess."""

    input_device: int = Field(0, ge=0)
    output_device: int = Field(0, ge=0)


class ParamUpdate(BaseModel):
    """Single OSC control update sent from a Live Mode UI widget."""

    path: str
    value: float | int | bool


class ParamBatchUpdate(BaseModel):
    """Atomic group of OSC updates used when enabling an effect with stored settings."""

    updates: list[ParamUpdate] = Field(min_length=1)


class LiveStatus(BaseModel):
    """Snapshot of Csound process state and the latest live controls."""

    running: bool
    input_device: int
    output_device: int
    command: list[str]
    params: dict[str, float]
    sample_mode: bool
    last_message: str


class LiveTelemetry(BaseModel):
    """Latest Csound output visualization data streamed to the React canvases."""

    running: bool
    waveform: list[float]
    spectrum: list[float]
    rms: float
    peak: float
    clip: bool
    timestamp: float


class HealthStatus(BaseModel):
    """Preflight result for local dependencies required by Live Mode."""

    api: str
    csound_binary: str | None
    csound_version: str | None
    csd_exists: bool
    csd_path: str


class EffectCodeSnippet(BaseModel):
    """One learnable Csound code region for a Live effect card."""

    effect_id: str
    title: str
    source_path: str
    start_line: int
    end_line: int
    code: str
