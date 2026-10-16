import { Gauge } from "lucide-react";

import { defaultParamValues, inputGainControl } from "../lib/liveControls";
import { midiTargetAttrs } from "../lib/midiLearn";

type InputGainControlProps = {
  values: Record<string, number>;
  onChange: (path: string, value: number) => void;
};

export function InputGainControl({ values, onChange }: InputGainControlProps) {
  const value = values[inputGainControl.path] ?? defaultParamValues[inputGainControl.path];

  return (
    <label
      className="input-gain-control"
      {...midiTargetAttrs({
        id: `param:${inputGainControl.path}`,
        label: inputGainControl.label,
        kind: "param",
        controlType: "slider",
        path: inputGainControl.path,
        min: inputGainControl.min,
        max: inputGainControl.max,
        step: inputGainControl.step,
      })}
    >
      <span>
        <Gauge size={16} aria-hidden />
        {inputGainControl.label}
      </span>
      <input
        type="range"
        min={inputGainControl.min}
        max={inputGainControl.max}
        step={inputGainControl.step}
        value={value}
        onChange={(event) => onChange(inputGainControl.path, Number(event.target.value))}
      />
      <output>{`${value > 0 ? "+" : ""}${Math.round(value)} dB`}</output>
    </label>
  );
}
