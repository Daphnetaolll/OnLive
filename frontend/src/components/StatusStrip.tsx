import { Cpu, RadioTower } from "lucide-react";

import type { LiveStatus } from "../lib/types";

type StatusStripProps = {
  status: LiveStatus | null;
};

export function StatusStrip({ status }: StatusStripProps) {
  return (
    <section className="status-strip">
      <div>
        <RadioTower size={18} aria-hidden />
        <span>{status?.running ? "Running" : "Stopped"}</span>
      </div>
      <div>
        <Cpu size={18} aria-hidden />
        <span>{status?.last_message ?? "Waiting for backend"}</span>
      </div>
    </section>
  );
}
