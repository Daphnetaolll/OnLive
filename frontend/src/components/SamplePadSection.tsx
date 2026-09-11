import { Grid3X3, Timer } from "lucide-react";

import { SamplePad } from "./SamplePad";
import { midiTargetAttrs } from "../lib/midiLearn";
import type { ActiveSampleEffect, SampleEffectId, SamplePlayMode, SampleSlot } from "../lib/types";

type SamplePadSectionProps = {
  slots: SampleSlot[];
  running: boolean;
  busy: boolean;
  bpm: number;
  tempoSync: boolean;
  tempoWarp: boolean;
  activeEffects: ActiveSampleEffect[];
  onUpload: (slot: number, file: File) => void;
  onTrigger: (slot: number) => void;
  onDelete: (slot: number) => void;
  onNameChange: (slot: number, name: string) => void;
  onModePlay: (slot: number, mode: SamplePlayMode) => void;
  onLoopBarsChange: (slot: number, bars: number) => void;
  onGainChange: (slot: number, gainDb: number) => void;
  onEffectSendChange: (slot: number, effectId: SampleEffectId, value: number) => void;
  onBpmChange: (bpm: number) => void;
  onTempoSyncChange: (enabled: boolean) => void;
  onTempoWarpChange: (enabled: boolean) => void;
};

const emptySlots: SampleSlot[] = Array.from({ length: 8 }, (_, slot) => ({
  slot,
  loaded: false,
  name: null,
  duration: null,
  size_bytes: null,
  detected_bpm: null,
  tempo_confidence: null,
  gain: 1,
  gain_db: 0,
  waveform: [],
  peak_db: null,
  clipped: false,
  effect_sends: { pitch: 1, ring: 1, blur: 1, flanger: 1, ats: 1 },
  play_mode: "one_shot",
  loop_bars: 1,
  active: false,
}));

export function SamplePadSection({
  slots,
  running,
  busy,
  bpm,
  tempoSync,
  tempoWarp,
  activeEffects,
  onUpload,
  onTrigger,
  onDelete,
  onNameChange,
  onModePlay,
  onLoopBarsChange,
  onGainChange,
  onEffectSendChange,
  onBpmChange,
  onTempoSyncChange,
  onTempoWarpChange,
}: SamplePadSectionProps) {
  const paddedSlots = emptySlots.map((fallback) => slots.find((slot) => slot.slot === fallback.slot) ?? fallback);

  return (
    <section className="sample-pad-section" aria-label="Sample pads">
      <header>
        <span>
          <Grid3X3 size={18} aria-hidden />
          <h2>Sample Pads</h2>
        </span>
        <div className="tempo-control-cluster">
          <div className="tempo-mode-toggle" role="group" aria-label="Sample tempo mode">
            <button
              className={!tempoSync ? "is-active" : ""}
              type="button"
              onClick={() => onTempoSyncChange(false)}
              {...midiTargetAttrs({
                id: "param:/ol/transport/sync",
                label: "Tempo Sync",
                kind: "param",
                controlType: "toggle",
                path: "/ol/transport/sync",
                min: 0,
                max: 1,
                step: 1,
              })}
            >
              Original
            </button>
            <button
              className={tempoSync ? "is-active" : ""}
              type="button"
              onClick={() => onTempoSyncChange(true)}
              {...midiTargetAttrs({
                id: "param:/ol/transport/sync",
                label: "Tempo Sync",
                kind: "param",
                controlType: "toggle",
                path: "/ol/transport/sync",
                min: 0,
                max: 1,
                step: 1,
              })}
            >
              Sync
            </button>
          </div>
          <div className={`tempo-warp-toggle ${tempoSync ? "" : "is-disabled"}`} role="group" aria-label="Sample warp mode">
            <button
              className={!tempoWarp ? "is-active" : ""}
              type="button"
              disabled={!tempoSync}
              onClick={() => onTempoWarpChange(false)}
              {...midiTargetAttrs({
                id: "param:/ol/transport/warp",
                label: "Tempo Warp",
                kind: "param",
                controlType: "toggle",
                path: "/ol/transport/warp",
                min: 0,
                max: 1,
                step: 1,
              })}
            >
              Resample
            </button>
            <button
              className={tempoWarp ? "is-active" : ""}
              type="button"
              disabled={!tempoSync}
              onClick={() => onTempoWarpChange(true)}
              {...midiTargetAttrs({
                id: "param:/ol/transport/warp",
                label: "Tempo Warp",
                kind: "param",
                controlType: "toggle",
                path: "/ol/transport/warp",
                min: 0,
                max: 1,
                step: 1,
              })}
            >
              Warp
            </button>
          </div>
          <label
            className={`bpm-control ${tempoSync ? "" : "is-disabled"}`}
            {...midiTargetAttrs({
              id: "param:/ol/transport/bpm",
              label: "BPM",
              kind: "param",
              controlType: "slider",
              path: "/ol/transport/bpm",
              min: 40,
              max: 240,
              step: 1,
            })}
          >
            <Timer size={15} aria-hidden />
            <span>BPM</span>
            <input
              type="number"
              min={40}
              max={240}
              step={1}
              disabled={!tempoSync}
              value={Math.round(bpm)}
              onChange={(event) => onBpmChange(Number(event.target.value))}
            />
          </label>
        </div>
      </header>
      <div className="sample-pad-grid">
        {paddedSlots.map((slot) => (
          <SamplePad
            key={slot.slot}
            slot={slot}
            running={running}
            busy={busy}
            tempoSync={tempoSync}
            activeEffects={activeEffects}
            onUpload={onUpload}
            onTrigger={onTrigger}
            onDelete={onDelete}
            onNameChange={onNameChange}
            onModePlay={onModePlay}
            onLoopBarsChange={onLoopBarsChange}
            onGainChange={onGainChange}
            onEffectSendChange={onEffectSendChange}
          />
        ))}
      </div>
    </section>
  );
}
