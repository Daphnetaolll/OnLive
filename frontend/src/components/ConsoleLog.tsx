import { ChevronDown, Terminal } from "lucide-react";
import { useState } from "react";

type ConsoleLogProps = {
  logs: string[];
};

export function ConsoleLog({ logs }: ConsoleLogProps) {
  const [expanded, setExpanded] = useState(false);
  const visible = logs.length > 0 ? logs.slice(-80) : ["No Csound output yet."];
  const latest = logs.length > 0 ? logs[logs.length - 1] : "No Csound output yet.";

  return (
    <section className={`console-log${expanded ? " is-expanded" : ""}`}>
      <header className="console-header">
        <span>
          <Terminal size={16} aria-hidden />
          <h2>Csound Console</h2>
        </span>
        <button type="button" onClick={() => setExpanded((current) => !current)} aria-expanded={expanded}>
          <ChevronDown size={16} aria-hidden />
          {expanded ? "Hide" : "Expand"}
        </button>
      </header>
      <p className="console-summary" title={latest}>
        {latest}
      </p>
      {expanded ? (
        <pre>
          {visible.map((line, index) => (
            <span key={`${index}-${line}`}>{line}</span>
          ))}
        </pre>
      ) : null}
    </section>
  );
}
