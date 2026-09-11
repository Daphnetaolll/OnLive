import { Check, Timer, X } from "lucide-react";

export type TempoSuggestion = {
  sampleName: string;
  detectedBpm: number;
  confidence: number | null;
  currentBpm: number;
};

type TempoSuggestionDialogProps = {
  suggestion: TempoSuggestion;
  onUse: () => void;
  onDismiss: () => void;
};

export function TempoSuggestionDialog({ suggestion, onUse, onDismiss }: TempoSuggestionDialogProps) {
  const confidenceText = suggestion.confidence === null ? null : `${Math.round(suggestion.confidence * 100)}%`;

  return (
    <div className="tempo-dialog-backdrop">
      <section className="tempo-dialog" role="dialog" aria-modal="true" aria-labelledby="tempo-dialog-title">
        <header>
          <span>
            <Timer size={18} aria-hidden />
            <h2 id="tempo-dialog-title">Use Sample Tempo?</h2>
          </span>
          <button className="icon-action" type="button" onClick={onDismiss} aria-label="Close tempo suggestion">
            <X size={16} aria-hidden />
          </button>
        </header>
        <p>
          <strong>{suggestion.sampleName}</strong> was detected around <b>{suggestion.detectedBpm} BPM</b>.
        </p>
        <div className="tempo-dialog-readout">
          <span>
            Current
            <b>{Math.round(suggestion.currentBpm)} BPM</b>
          </span>
          <span>
            Sample
            <b>{suggestion.detectedBpm} BPM</b>
          </span>
          {confidenceText ? (
            <span>
              Confidence
              <b>{confidenceText}</b>
            </span>
          ) : null}
        </div>
        <footer>
          <button type="button" onClick={onDismiss}>
            Keep Current
          </button>
          <button className="primary-action" type="button" onClick={onUse}>
            <Check size={16} aria-hidden />
            Use {suggestion.detectedBpm} BPM
          </button>
        </footer>
      </section>
    </div>
  );
}
