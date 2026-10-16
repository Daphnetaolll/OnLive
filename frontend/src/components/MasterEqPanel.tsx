import { useRef, useState, type CSSProperties, type PointerEvent } from "react";
import { ShieldCheck, SlidersHorizontal, Volume2 } from "lucide-react";

import {
  defaultParamValues,
  masterEqControls,
  masterLimiterControls,
  masterVolumeControl,
  type SliderControl,
} from "../lib/liveControls";
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
        {masterEqControls.map((control) => (
          <EqDial key={control.path} control={control} value={values[control.path] ?? 0} onChange={onChange} />
        ))}
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

// Vertical drag turns the dial like a hardware knob; Shift trades speed for fine control.
const DIAL_DRAG_PIXELS = 160;
const DIAL_FINE_DRAG_PIXELS = 640;

type EqDialProps = {
  control: SliderControl;
  value: number;
  onChange: (path: string, value: number) => void;
};

function EqDial({ control, value, onChange }: EqDialProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const dragRef = useRef<{ pointerId: number; lastY: number; value: number } | null>(null);
  const [dragging, setDragging] = useState(false);
  const range = control.max - control.min;
  // Clamp the dial view so API restores never draw outside the 270-degree hardware-style sweep.
  const toAngle = (next: number) => -135 + Math.min(1, Math.max(0, (next - control.min) / range)) * 270;
  // Gain dials grow outward from 0 dB, so cuts and boosts read in opposite directions.
  const dialStyle = { "--dial-angle": `${toAngle(value)}deg`, "--dial-origin": `${toAngle(0)}deg` } as CSSProperties;

  const commit = (next: number) => {
    const stepped = Math.min(control.max, Math.max(control.min, Math.round(next / control.step) * control.step));
    if (stepped !== value) onChange(control.path, stepped);
  };

  // MIDI Map mode uses clicks to pick targets, so the dial must not turn while mapping.
  const isMidiMapping = (element: HTMLElement) => Boolean(element.closest(".is-midi-map-mode"));

  const handlePointerDown = (event: PointerEvent<HTMLElement>) => {
    if (event.button !== 0 || isMidiMapping(event.currentTarget)) return;
    event.preventDefault();
    event.currentTarget.setPointerCapture(event.pointerId);
    // Focus enables arrow-key nudges after a drag without drawing the keyboard focus ring.
    inputRef.current?.focus({ preventScroll: true, focusVisible: false });
    dragRef.current = { pointerId: event.pointerId, lastY: event.clientY, value };
    setDragging(true);
  };

  const handlePointerMove = (event: PointerEvent<HTMLElement>) => {
    const drag = dragRef.current;
    if (!drag || drag.pointerId !== event.pointerId) return;
    // Accumulate unrounded movement so slow drags still cross step boundaries and Shift can toggle mid-drag.
    const pixels = event.shiftKey ? DIAL_FINE_DRAG_PIXELS : DIAL_DRAG_PIXELS;
    drag.value = Math.min(control.max, Math.max(control.min, drag.value + ((drag.lastY - event.clientY) / pixels) * range));
    drag.lastY = event.clientY;
    commit(drag.value);
  };

  const endDrag = (event: PointerEvent<HTMLElement>) => {
    if (dragRef.current?.pointerId !== event.pointerId) return;
    dragRef.current = null;
    setDragging(false);
  };

  return (
    <label
      className="eq-dial"
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
      <i
        className="dial-face"
        style={dialStyle}
        data-dragging={dragging || undefined}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
        onDoubleClick={(event) => {
          if (!isMidiMapping(event.currentTarget)) commit(defaultParamValues[control.path] ?? 0);
        }}
        title="Drag up/down to turn · Shift for fine · Double-click to reset"
      >
        <b />
        {/* The range input stays for keyboard and assistive tech; pointer turning is handled above. */}
        <input
          ref={inputRef}
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
