import { useEffect, useState } from "react";
import { CheckCircle2, RefreshCw, XCircle } from "lucide-react";

import { api } from "../lib/api";
import type { HealthStatus } from "../lib/types";

export function Settings() {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [error, setError] = useState<string | null>(null);

  const refresh = async () => {
    setError(null);
    try {
      setHealth(await api.health());
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : String(reason));
    }
  };

  useEffect(() => {
    refresh();
  }, []);

  return (
    <main className="settings-page">
      <section className="system-panel">
        <header>
          <h1>System</h1>
          <button className="icon-action" type="button" onClick={refresh} aria-label="Refresh system status">
            <RefreshCw size={18} aria-hidden />
          </button>
        </header>
        {error ? <p className="error-banner">{error}</p> : null}
        <div className="health-grid">
          <HealthItem label="API" ok={health?.api === "ok"} value={health?.api ?? "pending"} />
          <HealthItem label="Csound" ok={Boolean(health?.csound_binary)} value={health?.csound_version ?? "missing"} />
          <HealthItem label="CSD" ok={Boolean(health?.csd_exists)} value={health?.csd_path ?? "pending"} />
        </div>
      </section>
    </main>
  );
}

function HealthItem({ label, ok, value }: { label: string; ok: boolean; value: string }) {
  const Icon = ok ? CheckCircle2 : XCircle;
  return (
    <article className={`health-item ${ok ? "ok" : "bad"}`}>
      <Icon size={20} aria-hidden />
      <div>
        <strong>{label}</strong>
        <span>{value}</span>
      </div>
    </article>
  );
}
