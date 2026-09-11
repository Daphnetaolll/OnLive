import { Play, RefreshCw, Square } from "lucide-react";

type TransportControlsProps = {
  running: boolean;
  canStop: boolean;
  busy: boolean;
  canStart: boolean;
  onApply: () => void;
  onStart: () => void;
  onStop: () => void;
  onRefresh: () => void;
};

export function TransportControls({
  running,
  canStop,
  busy,
  canStart,
  onApply,
  onStart,
  onStop,
  onRefresh,
}: TransportControlsProps) {
  return (
    <div className="transport">
      <button className="apply-action" type="button" disabled={busy || !canStart} onClick={onApply}>
        Apply selection
      </button>
      <button className="primary-action" type="button" disabled={busy || running || !canStart} onClick={onStart}>
        <Play size={18} aria-hidden />
        Start
      </button>
      <button className="stop-action" type="button" disabled={busy || !canStop} onClick={onStop}>
        <Square size={18} aria-hidden />
        Stop
      </button>
      <button className="icon-action" type="button" disabled={busy} onClick={onRefresh} aria-label="Refresh devices">
        <RefreshCw size={18} aria-hidden />
      </button>
    </div>
  );
}
