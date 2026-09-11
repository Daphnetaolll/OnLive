import type { CSSProperties } from "react";
import { ShieldCheck, SlidersHorizontal, Volume2 } from "lucide-react";

import { defaultParamValues, masterEqControls, masterLimiterControls, masterVolumeControl } from "../lib/liveControls";
import { midiTargetAttrs } from "../lib/midiLearn";

type MasterEqPanelProps = {
  values: Record<string, number>;
  onChange: (path: string, value: number) => void;
};

export function MasterEqPanel({ values, onChange }: MasterEqPanelProps) {
  return (
    <section className="master-eq-panel" aria-label="Master EQ">
      <header>
        <span>
          <SlidersHorizontal size={18} aria-hidden />
          <h2>Master EQ</h2>
        </span>
        <strong>Total Control</strong>
      </header>
      <div className="master-eq-controls">
        {masterEqControls.map((control) => {
          const value = values[control.path] ?? 0;
          // Clamp the dial view so API restores or fast drags never draw outside the hardware-style arc.
          const normalized = Math.min(1, Math.max(0, (value - control.min) / (control.max - control.min)));
          const angle = -135 + normalized * 270;

          return (
            <label
              className="eq-dial"
              key={control.path}
              {...midiTargetAttrs({
                id: `param:${control.path}`,
                label: `Master EQ ${control.label}`,
                kind: "param",
                controlType: "slider",
                path: control.path,
                min: control.min,
                max: control.max,
                step: control.step,
              })}
            >
              <span>{control.label}</span>
              <i className="dial-face" style={{ "--dial-value": `${normalized * 100}%`, "--dial-angle": `${angle}deg` } as CSSProperties}>
                <b />
                <input
                  type="range"
                  min={control.min}
                  max={control.max}
                  step={control.step}
                  value={value}
                  onChange={(event) => onChange(control.path, Number(event.target.value))}
                />
              </i>
              <output>{formatGain(value)}</output>
            </label>
          );
        })}
      </div>
      <label
        className="master-volume-control"
        {...midiTargetAttrs({
          id: `param:${masterVolumeControl.path}`,
          label: masterVolumeControl.label,
          kind: "param",
          controlType: "slider",
          path: masterVolumeControl.path,
          min: masterVolumeControl.min,
          max: masterVolumeControl.max,
          step: masterVolumeControl.step,
        })}
      >
        <span>
          <Volume2 size={16} aria-hidden />
          {masterVolumeControl.label}
        </span>
        <input
          type="range"
          min={masterVolumeControl.min}
          max={masterVolumeControl.max}
          step={masterVolumeControl.step}
          value={values[masterVolumeControl.path] ?? 1}
          onChange={(event) => onChange(masterVolumeControl.path, Number(event.target.value))}
        />
        <output>{formatVolume(values[masterVolumeControl.path] ?? 1)}</output>
      </label>
      <div className="master-limiter-section">
        <div className="master-limiter-header">
          <span>
            <ShieldCheck size={16} aria-hidden />
            Limiter
          </span>
          <strong>Final Bus</strong>
        </div>
        <div className="master-limiter-controls">
          {masterLimiterControls.map((control) => {
            const value = values[control.path] ?? defaultParamValues[control.path] ?? control.min;

            return (
              <label
                className="limiter-slider"
                key={control.path}
                {...midiTargetAttrs({
                  id: `param:${control.path}`,
                  label: `Limiter ${control.label}`,
                  kind: "param",
                  controlType: "slider",
                  path: control.path,
                  min: control.min,
                  max: control.max,
                  step: control.step,
                })}
              >
                <span>{control.label}</span>
                <input
                  type="range"
                  min={control.min}
                  max={control.max}
                  step={control.step}
                  value={value}
                  onChange={(event) => onChange(control.path, Number(event.target.value))}
                />
                <output>{formatLimiterValue(control.path, value)}</output>
              </label>
            );
          })}
        </div>
      </div>
    </section>
  );
}

function formatGain(value: number) {
  const rounded = Math.round(value);
  return `${rounded > 0 ? "+" : ""}${rounded} dB`;
}

function formatVolume(value: number) {
  return `${Math.round(value * 100)}%`;
}

function formatLimiterValue(path: string, value: number) {
  if (path.includes("attack") || path.includes("release")) {
    return `${value.toFixed(value < 10 ? 1 : 0)} ms`;
  }

  return `${value > 0 ? "+" : ""}${value.toFixed(value % 1 === 0 ? 0 : 1)} dB`;
}
