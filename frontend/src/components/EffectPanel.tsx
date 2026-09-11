import { defaultParamValues, type EffectGroup, type LiveControl } from "../lib/liveControls";
import { midiTargetAttrs } from "../lib/midiLearn";
import type { ParamUpdate } from "../lib/types";

type EffectPanelProps = {
  group: EffectGroup;
  values: Record<string, number>;
  onChange: (path: string, value: number) => void;
  onChangeMany: (updates: ParamUpdate[]) => void;
  onShowCode: (effectId: string) => void;
};

export function EffectPanel({ group, values, onChange, onChangeMany, onShowCode }: EffectPanelProps) {
  const Icon = group.icon;
  const variantValue = Math.round(values[group.variantPath] ?? defaultParamValues[group.variantPath] ?? 0);
  const activeVariant = group.variants.find((variant) => variant.value === variantValue) ?? group.variants[0];

  const handleControlChange = (control: LiveControl, value: number) => {
    if (control.type === "toggle" && value >= 0.5) {
      // When enabling an effect, push the entire active variant so Csound uses current sliders immediately.
      const updates: ParamUpdate[] = [
        { path: group.variantPath, value: activeVariant.value },
        ...activeVariant.controls.map((variantControl) => ({
          path: variantControl.path,
          value: variantControl.path === control.path ? value : values[variantControl.path] ?? defaultParamValues[variantControl.path] ?? 0,
        })),
      ];
      onChangeMany(updates);
      return;
    }

    onChange(control.path, value);
  };

  return (
    <section className={`effect-panel accent-${group.accent}`}>
      <header>
        <span className="effect-heading">
          <Icon size={19} aria-hidden />
          <h2>{group.title}</h2>
        </span>
        <div className="effect-header-actions">
          <button className="effect-code-button" type="button" onClick={() => onShowCode(group.id)}>
            Code
          </button>
          <select
            className="effect-variant-select"
            aria-label={`${group.title} variant`}
            value={activeVariant.value}
            onChange={(event) => onChange(group.variantPath, Number(event.target.value))}
            {...midiTargetAttrs({
              id: `param:${group.variantPath}`,
              label: `${group.title} Variant`,
              kind: "param",
              controlType: "slider",
              path: group.variantPath,
              min: 0,
              max: Math.max(0, group.variants.length - 1),
              step: 1,
            })}
          >
            {group.variants.map((variant) => (
              <option key={variant.id} value={variant.value}>
                {variant.label}
              </option>
            ))}
          </select>
        </div>
      </header>
      <div className="control-stack">
        {activeVariant.controls.map((control) => (
          <ControlRow
            key={`${activeVariant.id}-${control.path}`}
            control={control}
            midiLabel={`${group.title} ${control.label}`}
            value={values[control.path] ?? defaultParamValues[control.path] ?? 0}
            onChange={(value) => handleControlChange(control, value)}
          />
        ))}
      </div>
    </section>
  );
}

function ControlRow({
  control,
  midiLabel,
  value,
  onChange,
}: {
  control: LiveControl;
  midiLabel: string;
  value: number;
  onChange: (value: number) => void;
}) {
  if (control.type === "toggle") {
    const checked = value >= 0.5;
    return (
      <button
        className={`toggle-row ${checked ? "is-on" : ""}`}
        type="button"
        onClick={() => onChange(checked ? 0 : 1)}
        aria-pressed={checked}
        {...midiTargetAttrs({
          id: `param:${control.path}`,
          label: midiLabel,
          kind: "param",
          controlType: "toggle",
          path: control.path,
          min: 0,
          max: 1,
          step: 1,
        })}
      >
        <span>{control.label}</span>
        <i />
      </button>
    );
  }

  const shown = control.step >= 1 ? value.toFixed(0) : value.toFixed(2);
  return (
    <label
      className="slider-row"
      {...midiTargetAttrs({
        id: `param:${control.path}`,
        label: midiLabel,
        kind: "param",
        controlType: "slider",
        path: control.path,
        min: control.min,
        max: control.max,
        step: control.step,
      })}
    >
      <span>
        {control.label}
        <output>{`${shown}${control.unit ? ` ${control.unit}` : ""}`}</output>
      </span>
      <input
        type="range"
        min={control.min}
        max={control.max}
        step={control.step}
        value={value}
        onChange={(event) => onChange(Number(event.target.value))}
      />
    </label>
  );
}
