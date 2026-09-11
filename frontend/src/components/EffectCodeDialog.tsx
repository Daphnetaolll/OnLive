import { Code2, X } from "lucide-react";

import type { EffectCodeSnippet } from "../lib/types";

type EffectCodeDialogProps = {
  snippet: EffectCodeSnippet;
  onClose: () => void;
};

export function EffectCodeDialog({ snippet, onClose }: EffectCodeDialogProps) {
  return (
    <div className="effect-code-backdrop" onClick={onClose}>
      <section className="effect-code-dialog" role="dialog" aria-modal="true" aria-labelledby="effect-code-title" onClick={(event) => event.stopPropagation()}>
        <header>
          <span>
            <Code2 size={18} aria-hidden />
            <h2 id="effect-code-title">{snippet.title} Csound</h2>
          </span>
          <button className="icon-action" type="button" onClick={onClose} aria-label="Close Csound code">
            <X size={16} aria-hidden />
          </button>
        </header>
        <div className="effect-code-meta">
          <span>{snippet.source_path}</span>
          <strong>{`Lines ${snippet.start_line}-${snippet.end_line}`}</strong>
        </div>
        <pre>
          <code>{snippet.code}</code>
        </pre>
      </section>
    </div>
  );
}
