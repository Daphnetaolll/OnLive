import { useCallback, useEffect, useState, type CSSProperties } from "react";
import { Cable, Mic2, Speaker } from "lucide-react";

import { ConsoleLog } from "../components/ConsoleLog";
import { DeviceSelect } from "../components/DeviceSelect";
import { EffectCodeDialog } from "../components/EffectCodeDialog";
import { EffectPanel } from "../components/EffectPanel";
import { MasterEqPanel } from "../components/MasterEqPanel";
import { MidiMapBar } from "../components/MidiMapBar";
import { SamplePadSection } from "../components/SamplePadSection";
import { SignalScope } from "../components/SignalScope";
import { SourceModePanel } from "../components/SourceModePanel";
import { StatusStrip } from "../components/StatusStrip";
import { TempoSuggestionDialog, type TempoSuggestion } from "../components/TempoSuggestionDialog";
import { TransportControls } from "../components/TransportControls";
import { api } from "../lib/api";
import { defaultParamValues, effectGroups } from "../lib/liveControls";
import { useMidiLearn, type MidiMessage, type MidiTarget } from "../lib/midiLearn";
import type {
  DeviceList,
  EffectCodeSnippet,
  LiveStatus,
  LiveTelemetry,
  ParamUpdate,
  ActiveSampleEffect,
  SampleEffectId,
  SamplePlayMode,
  SampleSlot,
} from "../lib/types";

const emptyDevices: DeviceList = { inputs: [], outputs: [] };
const emptyTelemetry: LiveTelemetry = {
  running: false,
  waveform: Array.from({ length: 256 }, () => 0),
  spectrum: Array.from({ length: 16 }, () => 0),
  rms: 0,
  peak: 0,
  clip: false,
  timestamp: 0,
};

export function Live() {
  const [devices, setDevices] = useState<DeviceList>(emptyDevices);
  const [status, setStatus] = useState<LiveStatus | null>(null);
  const [values, setValues] = useState<Record<string, number>>(defaultParamValues);
  const [logs, setLogs] = useState<string[]>([]);
  const [sampleSlots, setSampleSlots] = useState<SampleSlot[]>([]);
  const [telemetry, setTelemetry] = useState<LiveTelemetry>(emptyTelemetry);
  const [selectedInput, setSelectedInput] = useState(0);
  const [selectedOutput, setSelectedOutput] = useState(0);
  const [busy, setBusy] = useState(false);
  const [sampleBusy, setSampleBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tempoSuggestion, setTempoSuggestion] = useState<TempoSuggestion | null>(null);
  const [effectCodeSnippets, setEffectCodeSnippets] = useState<Record<string, EffectCodeSnippet>>({});
  const [selectedEffectCode, setSelectedEffectCode] = useState<EffectCodeSnippet | null>(null);

  const running = Boolean(status?.running);
  const sampleMode = Boolean(status?.sample_mode);
  const transportBpm = values["/ol/transport/bpm"] ?? 120;
  const tempoSync = (values["/ol/transport/sync"] ?? 0) >= 0.5;
  const tempoWarp = (values["/ol/transport/warp"] ?? 1) >= 0.5;
  const activeSampleEffects = getActiveSampleEffects(values);
  const loadedSampleCount = sampleSlots.filter((slot) => slot.loaded).length;
  // Sample playback is generated inside Csound, so it only needs an output device.
  const hasDeviceChoices = sampleMode ? devices.outputs.length > 0 : devices.inputs.length > 0 && devices.outputs.length > 0;
  const canStop = running || Boolean(status?.last_message.startsWith("Csound exited"));
  // The rack grid follows the real effect count so wide layouts do not leave empty tracks that compress names.
  const effectRackStyle = { "--effect-count": effectGroups.length } as CSSProperties & Record<"--effect-count", number>;

  const refresh = useCallback(async () => {
    setError(null);
    const [nextDevices, nextStatus, nextLogs, nextSamples] = await Promise.all([api.devices(), api.status(), api.logs(), api.samples()]);
    setDevices(nextDevices);
    setStatus(nextStatus);
    setValues({ ...defaultParamValues, ...nextStatus.params });
    setLogs(nextLogs);
    setSampleSlots(nextSamples);
    setSelectedInput((current) => pickDeviceId(nextDevices.inputs.map((device) => device.id), nextStatus.input_device, current));
    setSelectedOutput((current) => pickDeviceId(nextDevices.outputs.map((device) => device.id), nextStatus.output_device, current));
  }, []);

  useEffect(() => {
    refresh().catch((reason: Error) => setError(reason.message));
  }, [refresh]);

  useEffect(() => {
    // Code snippets are read from the current CSD once and reused by the effect cards.
    api
      .effectCode()
      .then((snippets) =>
        setEffectCodeSnippets(Object.fromEntries(snippets.map((snippet) => [snippet.effect_id, snippet]))),
      )
      .catch((reason: Error) => setError(reason.message));
  }, []);

  useEffect(() => {
    const socket = api.events((payload) => {
      setError(null);
      if (payload.telemetry) {
        setTelemetry(payload.telemetry);
      }
      if (payload.status) {
        setStatus(payload.status);
        setValues({ ...defaultParamValues, ...payload.status.params });
      }
      if (payload.logs) {
        setLogs(payload.logs);
      }
    });
    socket.onerror = () => undefined;
    return () => socket.close();
  }, []);

  const handleStart = async () => {
    setBusy(true);
    setError(null);
    try {
      const nextStatus = await api.start(selectedInput, selectedOutput);
      setStatus(nextStatus);
      setValues({ ...defaultParamValues, ...nextStatus.params });
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    } finally {
      setBusy(false);
    }
  };

  const handleApplySelection = async () => {
    setBusy(true);
    setError(null);
    try {
      const nextStatus = await api.selectDevices(selectedInput, selectedOutput);
      setStatus(nextStatus);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    } finally {
      setBusy(false);
    }
  };

  const handleStop = async () => {
    setBusy(true);
    setError(null);
    try {
      const nextStatus = await api.stop();
      setStatus(nextStatus);
      setTelemetry(emptyTelemetry);
      setSampleSlots(await api.samples());
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    } finally {
      setBusy(false);
    }
  };

  const handleParam = async (path: string, value: number) => {
    setValues((current) => ({ ...current, [path]: value }));
    try {
      const nextStatus = await api.param(path, value);
      setStatus(nextStatus);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    }
  };

  const handleBpm = async (bpm: number) => {
    const nextBpm = Math.min(240, Math.max(40, Number.isFinite(bpm) ? bpm : 120));
    await handleParam("/ol/transport/bpm", nextBpm);
  };

  const handleTempoSync = async (enabled: boolean) => {
    await handleParam("/ol/transport/sync", enabled ? 1 : 0);
  };

  const handleTempoWarp = async (enabled: boolean) => {
    await handleParam("/ol/transport/warp", enabled ? 1 : 0);
  };

  const handleParamBatch = async (updates: ParamUpdate[]) => {
    // Optimistically mirror grouped effect toggles so the UI and Csound move together.
    setValues((current) => ({
      ...current,
      ...Object.fromEntries(updates.map((update) => [update.path, Number(update.value)])),
    }));
    try {
      const nextStatus = await api.paramsBatch(updates);
      setStatus(nextStatus);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    }
  };

  const handleSampleMode = async () => {
    setBusy(true);
    setError(null);
    try {
      const nextStatus = await api.setSampleMode(!sampleMode);
      setStatus(nextStatus);
      setValues({ ...defaultParamValues, ...nextStatus.params });
      setSampleSlots(await api.samples());
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    } finally {
      setBusy(false);
    }
  };

  const handleUploadSample = async (slot: number, file: File) => {
    setSampleBusy(true);
    setError(null);
    try {
      const nextSlot = await api.uploadSample(slot, file);
      setSampleSlots((current) => replaceSampleSlot(current, nextSlot));
      maybeSuggestSampleTempo(nextSlot, transportBpm, setTempoSuggestion);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    } finally {
      setSampleBusy(false);
    }
  };

  const handleUseSampleTempo = async () => {
    const suggestion = tempoSuggestion;
    setTempoSuggestion(null);
    if (suggestion) {
      await handleTempoSync(true);
      await handleBpm(suggestion.detectedBpm);
    }
  };

  const handleSamplePlayMode = async (slot: number, playMode: SamplePlayMode) => {
    setSampleBusy(true);
    setError(null);
    try {
      // Mode buttons are performance actions: they select the mode, then fire the pad immediately.
      const currentSlot = sampleSlots.find((sampleSlot) => sampleSlot.slot === slot);
      let nextSlot = currentSlot;
      if (currentSlot?.play_mode !== playMode) {
        nextSlot = await api.updateSample(slot, { play_mode: playMode });
        setSampleSlots((current) => replaceSampleSlot(current, nextSlot as SampleSlot));
      }

      if (nextSlot?.loaded) {
        const nextStatus = await api.triggerSample(slot, { restart: true });
        setStatus(nextStatus);
        setSampleSlots(await api.samples());
      }
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    } finally {
      setSampleBusy(false);
    }
  };

  const handleSampleLoopBars = async (slot: number, bars: number) => {
    setSampleBusy(true);
    setError(null);
    try {
      // Loop length changes are saved per pad and used on the next quantized loop launch.
      const nextSlot = await api.updateSample(slot, { loop_bars: Math.min(8, Math.max(1, bars)) });
      setSampleSlots((current) => replaceSampleSlot(current, nextSlot));
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    } finally {
      setSampleBusy(false);
    }
  };

  const handleSampleGain = async (slot: number, gainDb: number) => {
    const nextGainDb = clampSampleGainDb(gainDb);
    // Volume rides are performance gestures, so keep the pad responsive while the backend persists the value.
    setSampleSlots((current) =>
      current.map((sampleSlot) =>
        sampleSlot.slot === slot ? { ...sampleSlot, gain_db: nextGainDb, gain: dbToGain(nextGainDb) } : sampleSlot,
      ),
    );
    try {
      const nextSlot = await api.updateSample(slot, { gain_db: nextGainDb });
      setSampleSlots((current) => replaceSampleSlot(current, nextSlot));
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    }
  };

  const handleSampleName = async (slot: number, name: string) => {
    const nextName = cleanSampleName(name, slot);
    // Rename gestures only touch metadata, so the playing Csound voice can continue uninterrupted.
    setSampleSlots((current) => current.map((sampleSlot) => (sampleSlot.slot === slot ? { ...sampleSlot, name: nextName } : sampleSlot)));
    try {
      const nextSlot = await api.updateSample(slot, { name: nextName });
      setSampleSlots((current) => replaceSampleSlot(current, nextSlot));
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    }
  };

  const handleSampleEffectSend = async (slot: number, effectId: SampleEffectId, value: number) => {
    const nextValue = clampSendLevel(value);
    // Matrix moves are live-performance gestures, so the cell updates before the backend round trip finishes.
    setSampleSlots((current) =>
      current.map((sampleSlot) =>
        sampleSlot.slot === slot
          ? {
              ...sampleSlot,
              effect_sends: {
                ...defaultEffectSends(),
                ...sampleSlot.effect_sends,
                [effectId]: nextValue,
              },
            }
          : sampleSlot,
      ),
    );
    try {
      const nextSlot = await api.updateSample(slot, { effect_sends: { [effectId]: nextValue } });
      setSampleSlots((current) => replaceSampleSlot(current, nextSlot));
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    }
  };

  const handleDeleteSample = async (slot: number) => {
    setSampleBusy(true);
    setError(null);
    try {
      const nextSlot = await api.deleteSample(slot);
      setSampleSlots((current) => replaceSampleSlot(current, nextSlot));
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    } finally {
      setSampleBusy(false);
    }
  };

  const handleTriggerSample = async (slot: number) => {
    setError(null);
    try {
      const nextStatus = await api.triggerSample(slot);
      setStatus(nextStatus);
      setSampleSlots(await api.samples());
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    }
  };

  const midiLearn = useMidiLearn((target, message) => {
    const numericValue = midiValueForTarget(target, message, getMidiTargetValue(target, values, sampleSlots));

    if (target.kind === "param" && target.path && numericValue !== null) {
      handleParam(target.path, numericValue);
      return;
    }
    if (target.kind === "sample-gain" && target.slot !== undefined && numericValue !== null) {
      handleSampleGain(target.slot, numericValue);
      return;
    }
    if (target.kind === "sample-send" && target.slot !== undefined && target.effectId && numericValue !== null) {
      handleSampleEffectSend(target.slot, target.effectId, numericValue);
      return;
    }
    if (target.kind === "sample-loop-bars" && target.slot !== undefined && numericValue !== null) {
      handleSampleLoopBars(target.slot, Math.round(numericValue));
      return;
    }
    if (target.kind === "sample-trigger" && target.slot !== undefined && isMidiTrigger(message)) {
      handleTriggerSample(target.slot);
      return;
    }
    if (target.kind === "sample-play-mode" && target.slot !== undefined && target.playMode && isMidiTrigger(message)) {
      handleSamplePlayMode(target.slot, target.playMode);
    }
  });

  return (
    <main className={`live-page ${midiLearn.enabled ? "is-midi-map-mode" : ""}`} onClickCapture={midiLearn.handleCapture}>
      <SourceModePanel
        sampleMode={sampleMode}
        busy={busy || sampleBusy}
        loadedSampleCount={loadedSampleCount}
        onSampleMode={handleSampleMode}
      />

      {/* Live device routing belongs to microphone mode, while Sample Mode keeps the page focused on pads. */}
      {!sampleMode ? (
        <section className="command-panel">
          <div className="command-title">
            <Cable size={20} aria-hidden />
            <h1>OnLive 音 Console</h1>
          </div>
          <div className="device-grid">
            <DeviceSelect
              icon={Mic2}
              label="Input Device (adc)"
              emptyLabel="No adc ports detected"
              devices={devices.inputs}
              value={selectedInput}
              onChange={setSelectedInput}
            />
            <DeviceSelect
              icon={Speaker}
              label="Output Device (dac)"
              emptyLabel="No dac ports detected"
              devices={devices.outputs}
              value={selectedOutput}
              onChange={setSelectedOutput}
            />
          </div>
          <TransportControls
            running={running}
            canStop={canStop}
            busy={busy}
            canStart={hasDeviceChoices}
            onApply={handleApplySelection}
            onStart={handleStart}
            onStop={handleStop}
            onRefresh={refresh}
          />
        </section>
      ) : null}

      <MidiMapBar
        enabled={midiLearn.enabled}
        supported={midiLearn.supported}
        status={midiLearn.status}
        mappingCount={midiLearn.mappingCount}
        inputNames={midiLearn.inputNames}
        onToggle={midiLearn.toggleEnabled}
        onClear={midiLearn.clearMappings}
      />
      <StatusStrip status={status} />
      {error ? <p className="error-banner">{error}</p> : null}
      {tempoSuggestion ? (
        <TempoSuggestionDialog
          suggestion={tempoSuggestion}
          onUse={handleUseSampleTempo}
          onDismiss={() => setTempoSuggestion(null)}
        />
      ) : null}
      {selectedEffectCode ? <EffectCodeDialog snippet={selectedEffectCode} onClose={() => setSelectedEffectCode(null)} /> : null}

      {sampleMode ? (
        <SamplePadSection
          slots={sampleSlots}
          running={running}
          busy={sampleBusy}
          bpm={transportBpm}
          tempoSync={tempoSync}
          tempoWarp={tempoWarp}
          activeEffects={activeSampleEffects}
          onUpload={handleUploadSample}
          onTrigger={handleTriggerSample}
          onDelete={handleDeleteSample}
          onNameChange={handleSampleName}
          onModePlay={handleSamplePlayMode}
          onLoopBarsChange={handleSampleLoopBars}
          onGainChange={handleSampleGain}
          onEffectSendChange={handleSampleEffectSend}
          onBpmChange={handleBpm}
          onTempoSyncChange={handleTempoSync}
          onTempoWarpChange={handleTempoWarp}
        />
      ) : null}

      <section className="live-layout">
        <SignalScope running={running} telemetry={telemetry} params={values} />
        <section className="control-rack" aria-label="Live effects" style={effectRackStyle}>
          <header className="effect-rack-header">
            <span>
              <strong>Live Effects</strong>
              <small>Csound Modules</small>
            </span>
          </header>
          {effectGroups.map((group) => (
            <EffectPanel
              key={group.id}
              group={group}
              values={values}
              onChange={handleParam}
              onChangeMany={handleParamBatch}
              onShowCode={(effectId) => {
                const snippet = effectCodeSnippets[effectId];
                if (snippet) {
                  setSelectedEffectCode(snippet);
                }
              }}
            />
          ))}
        </section>
        <MasterEqPanel values={values} onChange={handleParam} />
        <ConsoleLog logs={logs} />
      </section>
    </main>
  );
}

function pickDeviceId(availableIds: number[], backendValue: number, currentValue: number) {
  // Backend status is the source of truth after refreshes, restarts, and mode switches.
  if (availableIds.includes(backendValue)) return backendValue;
  if (availableIds.includes(currentValue)) return currentValue;
  return availableIds[0] ?? 0;
}

function replaceSampleSlot(slots: SampleSlot[], nextSlot: SampleSlot) {
  const nextSlots = slots.filter((slot) => slot.slot !== nextSlot.slot);
  nextSlots.push(nextSlot);
  return nextSlots.sort((left, right) => left.slot - right.slot);
}

function clampSampleGainDb(gainDb: number) {
  return Math.min(24, Math.max(-24, Number.isFinite(gainDb) ? gainDb : 0));
}

function cleanSampleName(value: string, slot: number) {
  const name = value.trim().replace(/\s+/g, " ");
  return name ? name.slice(0, 64) : `Pad ${slot + 1}`;
}

function dbToGain(gainDb: number) {
  return Math.pow(10, gainDb / 20);
}

function clampSendLevel(value: number) {
  return Math.min(1, Math.max(0, Number.isFinite(value) ? value : 1));
}

function defaultEffectSends(): Record<SampleEffectId, number> {
  return { pitch: 1, ring: 1, blur: 1, flanger: 1, ats: 1 };
}

function getActiveSampleEffects(values: Record<string, number>): ActiveSampleEffect[] {
  // Pad drawers mirror the global rack state so hidden sends cannot suggest an inactive effect is still audible.
  return effectGroups.flatMap((group) => {
    if (!isSampleEffectId(group.id)) return [];
    const toggle = group.variants[0]?.controls.find((control) => control.type === "toggle");
    const enabled = toggle ? (values[toggle.path] ?? defaultParamValues[toggle.path] ?? 0) >= 0.5 : false;
    return enabled ? [{ id: group.id, label: compactEffectLabel(group.title), accent: group.accent }] : [];
  });
}

function isSampleEffectId(id: string): id is SampleEffectId {
  return id === "pitch" || id === "ring" || id === "blur" || id === "flanger" || id === "ats";
}

function compactEffectLabel(title: string) {
  return title.replace(" Shifter", "").replace(" Mod", "").replace(" Cross", "");
}

function midiValueForTarget(target: MidiTarget, message: MidiMessage, currentValue: number | null) {
  if (target.controlType === "trigger") {
    return null;
  }

  if (target.controlType === "toggle") {
    if (message.kind === "note") {
      return currentValue !== null && currentValue >= 0.5 ? 0 : 1;
    }
    return message.value >= 64 ? 1 : 0;
  }

  const min = target.min ?? 0;
  const max = target.max ?? 1;
  const rawValue = min + message.normalized * (max - min);
  return roundToStep(rawValue, target.step ?? 0.01);
}

function getMidiTargetValue(target: MidiTarget, values: Record<string, number>, sampleSlots: SampleSlot[]) {
  if (target.kind === "param" && target.path) {
    return values[target.path] ?? defaultParamValues[target.path] ?? null;
  }
  const sample = target.slot === undefined ? undefined : sampleSlots.find((slot) => slot.slot === target.slot);
  if (!sample) return null;
  if (target.kind === "sample-gain") return sample.gain_db;
  if (target.kind === "sample-send" && target.effectId) return sample.effect_sends?.[target.effectId] ?? 1;
  if (target.kind === "sample-loop-bars") return sample.loop_bars;
  return null;
}

function isMidiTrigger(message: MidiMessage) {
  return message.kind === "note" || message.value > 0;
}

function roundToStep(value: number, step: number) {
  if (!Number.isFinite(step) || step <= 0) return value;
  return Math.round(value / step) * step;
}

function maybeSuggestSampleTempo(
  sample: SampleSlot,
  currentBpm: number,
  setTempoSuggestion: (suggestion: TempoSuggestion | null) => void,
) {
  if (sample.detected_bpm === null || !Number.isFinite(sample.detected_bpm)) {
    return;
  }

  const detectedBpm = Math.round(sample.detected_bpm * 10) / 10;
  if (Math.abs(detectedBpm - currentBpm) < 0.5) {
    return;
  }

  setTempoSuggestion({
    sampleName: sample.name ?? `Pad ${sample.slot + 1}`,
    detectedBpm,
    confidence: sample.tempo_confidence,
    currentBpm,
  });
}
