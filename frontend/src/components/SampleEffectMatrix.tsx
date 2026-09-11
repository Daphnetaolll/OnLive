import { SlidersHorizontal } from "lucide-react";

import { midiTargetAttrs } from "../lib/midiLearn";
import type { SampleEffectId, SampleSlot } from "../lib/types";

type SampleEffectMatrixProps = {
  slots: SampleSlot[];
  busy: boolean;
  onSendChange: (slot: number, effectId: SampleEffectId, value: number) => void;
};

const effectColumns: Array<{ id: SampleEffectId; label: string; accent: string }> = [
  { id: "pitch", label: "Pitch", accent: "cyan" },
  { id: "ring", label: "Ring", accent: "amber" },
  { id: "blur", label: "Blur", accent: "rose" },
  { id: "flanger", label: "Flange", accent: "green" },
  { id: "ats", label: "ATS", accent: "violet" },
];

export function SampleEffectMatrix({ slots, busy, onSendChange }: SampleEffectMatrixProps) {
  return (
    <section className="sample-effect-matrix" aria-label="Sample effect send matrix">
      <header>
        <span>
          <SlidersHorizontal size={16} aria-hidden />
          <h3>Sample FX Matrix</h3>
        </span>
      </header>
      <div className="send-matrix-grid">
        <div className="send-matrix-corner">Pad</div>
        {effectColumns.map((effect) => (
          <div key={effect.id} className={`send-matrix-heading accent-${effect.accent}`}>
            {effect.label}
          </div>
        ))}
        {slots.map((slot) => (
          <SampleSendRow key={slot.slot} slot={slot} busy={busy} onSendChange={onSendChange} />
        ))}
      </div>
    </section>
  );
}

function SampleSendRow({
  slot,
  busy,
  onSendChange,
}: {
  slot: SampleSlot;
  busy: boolean;
  onSendChange: (slot: number, effectId: SampleEffectId, value: number) => void;
}) {
  const disabled = busy || !slot.loaded;
  return (
    <>
      <div className={`send-row-label ${slot.loaded ? "" : "is-empty"}`}>
        <strong>{String(slot.slot + 1).padStart(2, "0")}</strong>
        <span>{slot.loaded ? slot.name ?? `Pad ${slot.slot + 1}` : "Empty"}</span>
      </div>
      {effectColumns.map((effect) => {
        const value = clampSend(slot.effect_sends?.[effect.id] ?? 1);
        const active = value > 0.001;
        return (
          <div key={`${slot.slot}-${effect.id}`} className={`send-cell ${active ? "is-active" : ""}`}>
            <button
              type="button"
              disabled={disabled}
              aria-pressed={active}
              aria-label={`Pad ${slot.slot + 1} ${effect.label} send ${active ? "on" : "off"}`}
              onClick={() => onSendChange(slot.slot, effect.id, active ? 0 : 1)}
              {...midiTargetAttrs({
                id: `sample-send-toggle:${slot.slot}:${effect.id}`,
                label: `Pad ${slot.slot + 1} ${effect.label} Send`,
                kind: "sample-send",
                controlType: "toggle",
                slot: slot.slot,
                effectId: effect.id,
                min: 0,
                max: 1,
                step: 1,
              })}
            >
              {active ? "On" : "Off"}
            </button>
            <input
              type="range"
              min={0}
              max={1}
              step={0.01}
              value={value}
              disabled={disabled}
              onChange={(event) => onSendChange(slot.slot, effect.id, Number(event.target.value))}
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
            />
            <output>{formatPercent(value)}</output>
          </div>
        );
      })}
    </>
  );
}

function clampSend(value: number) {
  return Math.min(1, Math.max(0, Number.isFinite(value) ? value : 1));
}

function formatPercent(value: number) {
  return `${Math.round(value * 100)}%`;
}
