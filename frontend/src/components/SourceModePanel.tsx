import { Grid3X3, Mic2 } from "lucide-react";

type SourceModePanelProps = {
  sampleMode: boolean;
  busy: boolean;
  loadedSampleCount: number;
  onSampleMode: () => void;
};

export function SourceModePanel({ sampleMode, busy, loadedSampleCount, onSampleMode }: SourceModePanelProps) {
  const handleLiveMode = () => {
    if (sampleMode && !busy) onSampleMode();
  };

  const handleSampleMode = () => {
    if (!sampleMode && !busy) onSampleMode();
  };

  return (
    <section className="source-mode-panel" aria-label="Performance source modes">
      {/* Source modes stay separate from device selection because live input and sample playback are mutually exclusive. */}
      <button
        className={`source-mode-card is-live ${sampleMode ? "" : "is-active"}`}
        type="button"
        disabled={busy}
        aria-pressed={!sampleMode}
        onClick={handleLiveMode}
      >
        <span className="source-mode-card-top">
          <span className="source-mode-icon">
            <Mic2 size={19} aria-hidden />
          </span>
          <span className="source-mode-status">{sampleMode ? "Ready" : "Active"}</span>
        </span>
        <strong>Live Mode</strong>
        <span className="source-mode-meta">Mic / ADC</span>
      </button>

      <button
        className={`source-mode-card is-sample ${sampleMode ? "is-active" : ""}`}
        type="button"
        disabled={busy}
        aria-pressed={sampleMode}
        onClick={handleSampleMode}
      >
        <span className="source-mode-card-top">
          <span className="source-mode-icon">
            <Grid3X3 size={19} aria-hidden />
          </span>
          <span className="source-mode-status">{sampleMode ? "Active" : "Open Pads"}</span>
        </span>
        <strong>Sample Mode</strong>
        <span className="source-mode-meta">8 Pads / {loadedSampleCount}/8 Loaded</span>
      </button>
    </section>
  );
}
