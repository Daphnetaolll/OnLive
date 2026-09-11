import { ChevronDown, Play, Repeat, SlidersVertical, Square, Trash2, Upload, Volume2 } from "lucide-react";
import { useEffect, useRef, useState, type ChangeEvent, type KeyboardEvent } from "react";

import { midiTargetAttrs } from "../lib/midiLearn";
import type { ActiveSampleEffect, SampleEffectId, SamplePlayMode, SampleSlot } from "../lib/types";

type SamplePadProps = {
  slot: SampleSlot;
  running: boolean;
  busy: boolean;
  tempoSync: boolean;
  activeEffects: ActiveSampleEffect[];
  onUpload: (slot: number, file: File) => void;
  onTrigger: (slot: number) => void;
  onDelete: (slot: number) => void;
  onNameChange: (slot: number, name: string) => void;
  onModePlay: (slot: number, mode: SamplePlayMode) => void;
  onLoopBarsChange: (slot: number, bars: number) => void;
  onGainChange: (slot: number, gainDb: number) => void;
  onEffectSendChange: (slot: number, effectId: SampleEffectId, value: number) => void;
};

export function SamplePad({
  slot,
  running,
  busy,
  tempoSync,
  activeEffects,
  onUpload,
  onTrigger,
  onDelete,
  onNameChange,
  onModePlay,
  onLoopBarsChange,
  onGainChange,
  onEffectSendChange,
}: SamplePadProps) {
  const inputId = `sample-pad-upload-${slot.slot}`;
  const title = slot.name ?? (slot.loaded ? `Pad ${slot.slot + 1}` : "Empty");
  const loopActive = slot.play_mode === "loop" && slot.active;
  const playDisabled = busy || !slot.loaded;
  const gainDb = Number.isFinite(slot.gain_db) ? slot.gain_db : 0;
  const gain = dbToGain(gainDb);
  const postGainPeak = slot.peak_db === null ? null : slot.peak_db + gainDb;
  const willClip = slot.clipped || (postGainPeak !== null && postGainPeak >= 0);
  // Keep the routing drawer present on loaded pads; global FX state only decides its contents.
  const showFxDrawer = slot.loaded;
  const [nameDraft, setNameDraft] = useState(title);

  useEffect(() => {
    setNameDraft(title);
  }, [title]);

  const handleUpload = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      onUpload(slot.slot, file);
    }
    event.target.value = "";
  };

  const saveName = () => {
    const nextName = cleanPadName(nameDraft, slot.slot);
    setNameDraft(nextName);
    if (nextName !== title) {
      onNameChange(slot.slot, nextName);
    }
  };

  // Keep title editing isolated so typing or confirming a name never fires the pad trigger.
  const handleNameKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    event.stopPropagation();
    if (event.key === "Enter") {
      event.currentTarget.blur();
    }
    if (event.key === "Escape") {
      setNameDraft(title);
      event.currentTarget.blur();
    }
  };

  const handleTriggerKeyDown = (event: KeyboardEvent<HTMLElement>) => {
    if (playDisabled) return;
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      onTrigger(slot.slot);
    }
  };

  return (
    <article className={`sample-pad ${slot.loaded ? "is-loaded" : ""} ${loopActive ? "is-active-loop" : ""}`}>
      <div
        className="sample-trigger"
        role="button"
        tabIndex={playDisabled ? -1 : 0}
        aria-disabled={playDisabled}
        onClick={() => {
          if (!playDisabled) {
            onTrigger(slot.slot);
          }
        }}
        onKeyDown={handleTriggerKeyDown}
        title={slot.loaded && !running ? "Start and play" : title}
        {...midiTargetAttrs({
          id: `sample-trigger:${slot.slot}`,
          label: `Pad ${slot.slot + 1} Trigger`,
          kind: "sample-trigger",
          controlType: "trigger",
          slot: slot.slot,
        })}
      >
        <span className="sample-pad-number">{String(slot.slot + 1).padStart(2, "0")}</span>
        <input
          className="sample-title-input"
          type="text"
          maxLength={64}
          aria-label={`Rename sample pad ${slot.slot + 1}`}
          value={nameDraft}
          disabled={busy}
          onBlur={saveName}
          onChange={(event) => setNameDraft(event.target.value)}
          onClick={(event) => event.stopPropagation()}
          onKeyDown={handleNameKeyDown}
          onPointerDown={(event) => event.stopPropagation()}
        />
        <small>{loopActive ? "Looping" : slot.duration ? formatDuration(slot.duration) : "Upload"}</small>
        {loopActive ? <Square size={17} aria-hidden /> : <Play size={18} aria-hidden />}
      </div>
      <div className={`sample-waveform ${willClip ? "is-hot" : ""}`}>
        <SampleWaveform waveform={slot.waveform} gain={gain} clipped={willClip} />
        <span>{slot.loaded ? `Peak ${formatDb(postGainPeak)}` : "No sample"}</span>
      </div>
      <label
        className={`sample-volume-row ${willClip ? "is-hot" : ""}`}
        {...midiTargetAttrs({
          id: `sample-gain:${slot.slot}`,
          label: `Pad ${slot.slot + 1} Volume`,
          kind: "sample-gain",
          controlType: "slider",
          slot: slot.slot,
          min: -24,
          max: 24,
          step: 0.5,
        })}
      >
        <span>
          <Volume2 size={13} aria-hidden />
          Volume
          <output>{formatDb(gainDb)}</output>
        </span>
        <input
          type="range"
          min={-24}
          max={24}
          step={0.5}
          value={gainDb}
          disabled={busy || !slot.loaded}
          onChange={(event) => onGainChange(slot.slot, Number(event.target.value))}
        />
      </label>
      {showFxDrawer ? (
        <details className="sample-fx-drawer">
          <summary>
            <span>
              <SlidersVertical size={13} aria-hidden />
              FX Sends
            </span>
            <strong>{activeEffects.length}</strong>
            <ChevronDown className="sample-fx-chevron" size={14} aria-hidden />
          </summary>
          <div className={`sample-fx-faders ${activeEffects.length === 0 ? "is-empty" : ""}`}>
            {activeEffects.length === 0 ? (
              <p className="sample-fx-empty">No active FX</p>
            ) : (
              activeEffects.map((effect) => {
                const sendValue = clampSend(slot.effect_sends?.[effect.id] ?? 1);
                return (
                  <label
                    key={effect.id}
                    className={`sample-send-fader accent-${effect.accent}`}
                    {...midiTargetAttrs({
                      id: `sample-send:${slot.slot}:${effect.id}`,
                      label: `Pad ${slot.slot + 1} ${effect.label} Send Level`,
                      kind: "sample-send",
                      controlType: "slider",
                      slot: slot.slot,
                      effectId: effect.id,
                      min: 0,
                      max: 1,
                      step: 0.01,
                    })}
                  >
                    <span>{effect.label}</span>
                    <input
                      type="range"
                      min={0}
                      max={1}
                      step={0.01}
                      value={sendValue}
                      disabled={busy}
                      aria-label={`Pad ${slot.slot + 1} ${effect.label} send level`}
                      onChange={(event) => onEffectSendChange(slot.slot, effect.id, Number(event.target.value))}
                    />
                    <output>{formatPercent(sendValue)}</output>
                  </label>
                );
              })
            )}
          </div>
        </details>
      ) : null}
      <div className="sample-mode-toggle" role="group" aria-label={`Pad ${slot.slot + 1} playback mode`}>
        <button
          className={slot.play_mode === "one_shot" ? "is-active" : ""}
          type="button"
          disabled={playDisabled}
          onClick={() => onModePlay(slot.slot, "one_shot")}
          title={slot.loaded && !running ? "Start and play once" : "Play once"}
          {...midiTargetAttrs({
            id: `sample-mode:${slot.slot}:one_shot`,
            label: `Pad ${slot.slot + 1} One Shot`,
            kind: "sample-play-mode",
            controlType: "trigger",
            slot: slot.slot,
            playMode: "one_shot",
          })}
        >
          <Play size={13} aria-hidden />
          One Shot
        </button>
        <button
          className={slot.play_mode === "loop" ? "is-active" : ""}
          type="button"
          disabled={playDisabled}
          onClick={() => onModePlay(slot.slot, "loop")}
          title={loopActive ? "Restart loop" : slot.loaded && !running ? "Start and loop" : "Start loop"}
          {...midiTargetAttrs({
            id: `sample-mode:${slot.slot}:loop`,
            label: `Pad ${slot.slot + 1} Loop`,
            kind: "sample-play-mode",
            controlType: "trigger",
            slot: slot.slot,
            playMode: "loop",
          })}
        >
          <Repeat size={13} aria-hidden />
          Loop
        </button>
      </div>
      <label
        className="loop-bars-select"
        {...midiTargetAttrs({
          id: `sample-loop-bars:${slot.slot}`,
          label: `Pad ${slot.slot + 1} Loop Length`,
          kind: "sample-loop-bars",
          controlType: "slider",
          slot: slot.slot,
          min: 1,
          max: 8,
          step: 1,
        })}
      >
        <span>Loop Length</span>
        <select
          value={slot.loop_bars}
          disabled={busy || !slot.loaded || !tempoSync}
          onChange={(event) => onLoopBarsChange(slot.slot, Number(event.target.value))}
        >
          {Array.from({ length: 8 }, (_, index) => index + 1).map((bars) => (
            <option key={bars} value={bars}>
              {bars} {bars === 1 ? "Bar" : "Bars"}
            </option>
          ))}
        </select>
      </label>
      <div className="sample-pad-actions">
        <label className="sample-file-action" htmlFor={inputId}>
          <Upload size={15} aria-hidden />
          {slot.loaded ? "Replace" : "Upload"}
          <input id={inputId} type="file" accept="audio/*" disabled={busy} onChange={handleUpload} />
        </label>
        {slot.loaded ? (
          <button type="button" disabled={busy} onClick={() => onDelete(slot.slot)} aria-label={`Delete sample pad ${slot.slot + 1}`}>
            <Trash2 size={15} aria-hidden />
          </button>
        ) : null}
      </div>
    </article>
  );
}

function SampleWaveform({ waveform, gain, clipped }: { waveform: number[]; gain: number; clipped: boolean }) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    // Redraw from stored full-file min/max data so the pad always shows the complete sample shape.
    const draw = () => {
      const width = Math.max(180, Math.floor(canvas.clientWidth || 180));
      const height = Math.max(42, Math.floor(canvas.clientHeight || 42));
      const ratio = window.devicePixelRatio || 1;
      canvas.width = Math.floor(width * ratio);
      canvas.height = Math.floor(height * ratio);
      const context = canvas.getContext("2d");
      if (!context) return;
      context.setTransform(ratio, 0, 0, ratio, 0, 0);
      context.clearRect(0, 0, width, height);
      const waveformColor = clipped ? "rgba(180, 140, 255, 0.88)" : "rgba(77, 225, 211, 0.82)";
      context.fillStyle = "#09080e";
      context.fillRect(0, 0, width, height);
      context.strokeStyle = "rgba(243, 239, 247, 0.12)";
      context.beginPath();
      context.moveTo(0, height / 2);
      context.lineTo(width, height / 2);
      context.stroke();

      const pairs = waveform.length >= 2 ? waveform : [0, 0];
      const pairCount = Math.max(1, Math.floor(pairs.length / 2));
      const barWidth = Math.max(1, width / pairCount);
      for (let index = 0; index < pairCount; index += 1) {
        const rawMin = (pairs[index * 2] ?? 0) * gain;
        const rawMax = (pairs[index * 2 + 1] ?? 0) * gain;
        const min = clamp(rawMin, -1, 1);
        const max = clamp(rawMax, -1, 1);
        const x = index * barWidth;
        const top = (1 - max) * 0.5 * height;
        const bottom = (1 - min) * 0.5 * height;
        const hot = clipped || rawMin < -1 || rawMax > 1;
        context.fillStyle = hot ? "rgba(180, 140, 255, 0.88)" : waveformColor;
        context.fillRect(x, top, Math.max(1, barWidth - 0.5), Math.max(1, bottom - top));
      }
    };

    draw();
    window.addEventListener("resize", draw);
    return () => window.removeEventListener("resize", draw);
  }, [waveform, gain, clipped]);

  return <canvas ref={canvasRef} aria-hidden />;
}

function formatDuration(seconds: number) {
  const minutes = Math.floor(seconds / 60);
  const wholeSeconds = Math.max(0, Math.round(seconds % 60));
  return `${minutes}:${String(wholeSeconds).padStart(2, "0")}`;
}

function formatDb(value: number | null) {
  if (value === null || !Number.isFinite(value)) return "-inf dB";
  const rounded = Math.round(value * 10) / 10;
  return `${rounded > 0 ? "+" : ""}${rounded.toFixed(rounded % 1 === 0 ? 0 : 1)} dB`;
}

function formatPercent(value: number) {
  return `${Math.round(clampSend(value) * 100)}%`;
}

function cleanPadName(value: string, slot: number) {
  const name = value.trim().replace(/\s+/g, " ");
  return name ? name.slice(0, 64) : `Pad ${slot + 1}`;
}

function dbToGain(dbValue: number) {
  return Math.pow(10, dbValue / 20);
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

function clampSend(value: number) {
  return clamp(Number.isFinite(value) ? value : 1, 0, 1);
}
