import asyncio

from fastapi import APIRouter, File, HTTPException, UploadFile, WebSocket, WebSocketDisconnect

from app.schemas.live import DeviceList, EffectCodeSnippet, LiveStatus, ParamBatchUpdate, ParamUpdate, StartLiveRequest
from app.schemas.samples import SampleModeUpdate, SampleSlot, SampleSlotUpdate
from app.services.csound_engine import engine
from app.services.effect_code import list_effect_code_snippets
from app.services.sample_bank import sample_bank
from app.services.telemetry import telemetry


router = APIRouter(prefix="/live", tags=["live"])


@router.get("/devices", response_model=DeviceList)
def devices() -> DeviceList:
    """Return the current Csound adc/dac devices for frontend selectors."""

    try:
        return engine.list_devices()
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@router.post("/start", response_model=LiveStatus)
def start_live(payload: StartLiveRequest) -> LiveStatus:
    """Start the local Csound process with the requested audio routing."""

    try:
        return engine.start(payload.input_device, payload.output_device)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.patch("/devices/selection", response_model=LiveStatus)
def select_devices(payload: StartLiveRequest) -> LiveStatus:
    """Save the selected Csound adc/dac devices before starting live audio."""

    try:
        return engine.select_devices(payload.input_device, payload.output_device)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.post("/stop", response_model=LiveStatus)
def stop_live() -> LiveStatus:
    """Stop the local Csound process and release the audio device."""

    return engine.stop()


@router.get("/status", response_model=LiveStatus)
def status() -> LiveStatus:
    """Return Csound running state and current parameter values."""

    return engine.status()


@router.patch("/params", response_model=LiveStatus)
def update_param(payload: ParamUpdate) -> LiveStatus:
    """Forward a validated Live Mode control change to Csound over OSC."""

    try:
        return engine.update_param(payload.path, payload.value)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.patch("/params/batch", response_model=LiveStatus)
def update_params(payload: ParamBatchUpdate) -> LiveStatus:
    """Forward a complete effect snapshot so toggles apply current slider values immediately."""

    try:
        return engine.update_params(payload.updates)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.get("/logs", response_model=list[str])
def logs() -> list[str]:
    """Return recent Csound process output for the frontend console."""

    return engine.logs()


@router.get("/effects/code", response_model=list[EffectCodeSnippet])
def effect_code() -> list[EffectCodeSnippet]:
    """Return learnable Csound snippets for each visible Live effect."""

    try:
        return list_effect_code_snippets()
    except OSError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.get("/samples", response_model=list[SampleSlot])
def samples() -> list[SampleSlot]:
    """Return the fixed 8-pad sample bank for Sample Mode."""

    return sample_bank.list_slots(engine.active_sample_slots())


@router.post("/samples/mode", response_model=LiveStatus)
def set_sample_mode(payload: SampleModeUpdate) -> LiveStatus:
    """Toggle exclusive Sample Mode without mixing with microphone input."""

    return engine.set_sample_mode(payload.enabled)


@router.put("/samples/{slot}", response_model=SampleSlot)
def upload_sample(slot: int, file: UploadFile = File(...)) -> SampleSlot:
    """Store one uploaded sample in a fixed pad slot."""

    try:
        engine.stop_sample(slot)
        return sample_bank.store_upload(slot, file)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.patch("/samples/{slot}", response_model=SampleSlot)
def update_sample(slot: int, payload: SampleSlotUpdate) -> SampleSlot:
    """Persist pad playback behavior without replacing the uploaded audio."""

    try:
        # Playback replacement is owned by /trigger?restart=true so mode-button clicks
        # cannot accidentally stop the newly started voice with an older stop message.
        next_slot = sample_bank.update_slot(slot, payload, engine.active_sample_slots())
        if payload.gain_db is not None:
            engine.update_sample_gain(slot, next_slot.gain)
        if payload.effect_sends is not None:
            engine.update_sample_sends(slot, next_slot.effect_sends)
        return next_slot
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.delete("/samples/{slot}", response_model=SampleSlot)
def delete_sample(slot: int) -> SampleSlot:
    """Clear a sample pad slot and remove its converted WAV file."""

    try:
        engine.stop_sample(slot)
        return sample_bank.delete_slot(slot)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/samples/{slot}/trigger", response_model=LiveStatus)
def trigger_sample(slot: int, restart: bool = False) -> LiveStatus:
    """Trigger one loaded sample pad through the current Csound effects."""

    try:
        return engine.trigger_sample(sample_bank.get_slot(slot, engine.active_sample_slots()), restart=restart)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc


@router.websocket("/events")
async def live_events(websocket: WebSocket) -> None:
    """Stream status, logs, and real Csound output telemetry while Live is open."""

    await websocket.accept()
    tick = 0
    try:
        while True:
            status_snapshot = engine.status()
            payload = {
                "telemetry": telemetry.snapshot(status_snapshot.running).model_dump(),
            }
            if tick % 15 == 0:
                payload["status"] = status_snapshot.model_dump()
                payload["logs"] = engine.logs()[-80:]

            await websocket.send_json(
                payload
            )
            tick += 1
            await asyncio.sleep(1 / 30)
    except WebSocketDisconnect:
        return
