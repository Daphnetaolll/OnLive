import { SlidersHorizontal, Trash2 } from "lucide-react";

type MidiMapBarProps = {
  enabled: boolean;
  supported: boolean;
  status: string;
  mappingCount: number;
  inputNames: string[];
  onToggle: () => void;
  onClear: () => void;
};

export function MidiMapBar({ enabled, supported, status, mappingCount, inputNames, onToggle, onClear }: MidiMapBarProps) {
  const inputLabel = inputNames.length ? inputNames.join(", ") : supported ? "No input" : "Unavailable";

  return (
    <section className={`midi-map-bar ${enabled ? "is-active" : ""}`} aria-label="MIDI map">
      <button className="midi-map-toggle" type="button" onClick={onToggle} disabled={!supported}>
        <SlidersHorizontal size={16} aria-hidden />
        MIDI Map
      </button>
      <div>
        <strong>{status}</strong>
        <span>{`${mappingCount} mapped · ${inputLabel}`}</span>
      </div>
      <button className="icon-action" type="button" onClick={onClear} disabled={!mappingCount} aria-label="Clear MIDI mappings">
        <Trash2 size={15} aria-hidden />
      </button>
    </section>
  );
}
