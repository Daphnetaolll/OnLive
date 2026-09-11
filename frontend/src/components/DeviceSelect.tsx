import type { LucideIcon } from "lucide-react";

import type { DeviceInfo } from "../lib/types";

type DeviceSelectProps = {
  icon: LucideIcon;
  label: string;
  emptyLabel: string;
  devices: DeviceInfo[];
  value: number;
  disabled?: boolean;
  onChange: (value: number) => void;
};

export function DeviceSelect({ icon: Icon, label, emptyLabel, devices, value, disabled = false, onChange }: DeviceSelectProps) {
  const selectDisabled = disabled || devices.length === 0;

  return (
    <label className={`device-select ${disabled ? "is-disabled" : ""}`}>
      <span>
        <Icon size={16} aria-hidden />
        {label}
      </span>
      <select value={devices.length > 0 ? value : ""} disabled={selectDisabled} onChange={(event) => onChange(Number(event.target.value))}>
        {devices.length === 0 ? (
          <option value="">{emptyLabel}</option>
        ) : (
          devices.map((device) => (
            <option key={`${device.kind}-${device.id}`} value={device.id}>
              {device.label}
            </option>
          ))
        )}
      </select>
    </label>
  );
}
