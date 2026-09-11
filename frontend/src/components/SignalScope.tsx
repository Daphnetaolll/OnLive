import { useEffect, useRef } from "react";
import { Activity, BarChart3 } from "lucide-react";

import type { LiveTelemetry } from "../lib/types";

type SignalScopeProps = {
  running: boolean;
  telemetry: LiveTelemetry;
  params: Record<string, number>;
};

type WaveformState = {
  running: boolean;
  samples: number[];
  rms: number;
  peak: number;
  clip: boolean;
};

type EqState = {
  running: boolean;
  spectrum: number[];
  low: number;
  mid: number;
  high: number;
};

// Canvas colors mirror the restrained black, white, purple, and Tiffany-blue palette.
const scopeColors = {
  panel: "#09080e",
  grid: "rgba(243, 239, 247, 0.07)",
  gridStrong: "rgba(243, 239, 247, 0.18)",
  gridSoft: "rgba(243, 239, 247, 0.045)",
  idleFill: "rgba(170, 161, 184, 0.08)",
  idleStroke: "rgba(170, 161, 184, 0.44)",
  violetSoft: "rgba(180, 140, 255, 0.16)",
  violetMid: "rgba(180, 140, 255, 0.6)",
  violetHot: "rgba(180, 140, 255, 0.96)",
  cyanMid: "rgba(77, 225, 211, 0.78)",
  cyanSoft: "rgba(77, 225, 211, 0.44)",
  meter: "rgba(77, 225, 211, 0.74)",
  alert: "rgba(180, 140, 255, 0.88)",
  eqCurve: "rgba(180, 140, 255, 0.98)",
};

export function SignalScope({ running, telemetry, params }: SignalScopeProps) {
  const hasFreshSignal = running && telemetry.running;

  return (
    <section className="signal-visuals" aria-label="Live signal scope">
      <WaveformPanel
        running={hasFreshSignal}
        samples={telemetry.waveform}
        rms={telemetry.rms}
        peak={telemetry.peak}
        clip={telemetry.clip}
      />
      <EqAnalyzerPanel
        running={hasFreshSignal}
        spectrum={telemetry.spectrum}
        low={params["/ol/eq/low"] ?? 0}
        mid={params["/ol/eq/mid"] ?? 0}
        high={params["/ol/eq/high"] ?? 0}
      />
    </section>
  );
}

function WaveformPanel({ running, samples, rms, peak, clip }: WaveformState) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const stateRef = useRef<WaveformState>({ running, samples, rms, peak, clip });
  stateRef.current = { running, samples, rms, peak, clip };

  // Keep the canvas loop alive while fresh telemetry is read from the ref each frame.
  useEffect(() => {
    const canvas = canvasRef.current;
    const context = canvas?.getContext("2d");
    if (!canvas || !context) return;

    let animation = 0;
    const draw = () => {
      const { width, height, ratio } = resizeCanvas(canvas);
      drawScopeBackground(context, width, height, ratio);
      drawWaveform(context, width, height, ratio, stateRef.current);
      animation = requestAnimationFrame(draw);
    };

    draw();
    return () => cancelAnimationFrame(animation);
  }, []);

  return (
    <section className="visual-panel waveform-panel" aria-label="Output waveform">
      <header>
        <span>
          <Activity size={18} aria-hidden />
          Output Waveform
        </span>
        <strong>{running ? "LIVE" : "IDLE"}</strong>
      </header>
      <canvas ref={canvasRef} />
      <div className="visual-readout">
        <span>RMS {formatDb(rms)}</span>
        <span className={clip ? "is-clipping" : undefined}>Peak {formatDb(peak)}</span>
      </div>
    </section>
  );
}

function EqAnalyzerPanel({ running, spectrum, low, mid, high }: EqState) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const stateRef = useRef<EqState>({ running, spectrum, low, mid, high });
  const smoothedSpectrumRef = useRef<number[]>([]);
  stateRef.current = { running, spectrum, low, mid, high };

  // Smooth only the displayed spectrum, while the EQ curve stays locked to slider values.
  useEffect(() => {
    const canvas = canvasRef.current;
    const context = canvas?.getContext("2d");
    if (!canvas || !context) return;

    let animation = 0;
    const draw = () => {
      const { width, height, ratio } = resizeCanvas(canvas);
      drawScopeBackground(context, width, height, ratio);
      drawSpectrum(context, width, height, ratio, stateRef.current, smoothedSpectrumRef.current);
      drawEqCurve(context, width, height, ratio, stateRef.current);
      animation = requestAnimationFrame(draw);
    };

    draw();
    return () => cancelAnimationFrame(animation);
  }, []);

  return (
    <section className="visual-panel eq-panel" aria-label="EQ analyzer">
      <header>
        <span>
          <BarChart3 size={18} aria-hidden />
          EQ Analyzer
        </span>
        <strong>{running ? "SPECTRUM" : "WAITING"}</strong>
      </header>
      <canvas ref={canvasRef} />
      <div className="visual-readout">
        <span>Low {formatGain(low)}</span>
        <span>Mid {formatGain(mid)}</span>
        <span>High {formatGain(high)}</span>
      </div>
    </section>
  );
}

function resizeCanvas(canvas: HTMLCanvasElement) {
  const ratio = window.devicePixelRatio || 1;
  const width = Math.max(1, Math.floor(canvas.clientWidth * ratio));
  const height = Math.max(1, Math.floor(canvas.clientHeight * ratio));
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }
  return { width, height, ratio };
}

function drawScopeBackground(context: CanvasRenderingContext2D, width: number, height: number, ratio: number) {
  context.clearRect(0, 0, width, height);
  context.fillStyle = scopeColors.panel;
  context.fillRect(0, 0, width, height);

  context.lineWidth = ratio;
  for (let row = 0; row <= 6; row += 1) {
    const y = (height / 6) * row;
    context.strokeStyle = row === 3 ? scopeColors.gridStrong : scopeColors.grid;
    context.beginPath();
    context.moveTo(0, y);
    context.lineTo(width, y);
    context.stroke();
  }

  for (let column = 1; column < 8; column += 1) {
    const x = (width / 8) * column;
    context.strokeStyle = scopeColors.gridSoft;
    context.beginPath();
    context.moveTo(x, 0);
    context.lineTo(x, height);
    context.stroke();
  }
}

function drawWaveform(
  context: CanvasRenderingContext2D,
  width: number,
  height: number,
  ratio: number,
  state: WaveformState,
) {
  const samples = state.running ? state.samples : [];
  const envelope = toEnvelopePairs(samples);
  const midY = height * 0.5;
  const amp = height * 0.38;

  context.strokeStyle = scopeColors.gridStrong;
  context.lineWidth = ratio;
  context.beginPath();
  context.moveTo(0, midY);
  context.lineTo(width, midY);
  context.stroke();

  if (envelope.length > 1) {
    const gradient = context.createLinearGradient(0, midY - amp, 0, midY + amp);
    gradient.addColorStop(0, scopeColors.violetMid);
    gradient.addColorStop(0.48, scopeColors.violetHot);
    gradient.addColorStop(0.52, scopeColors.cyanMid);
    gradient.addColorStop(1, scopeColors.cyanSoft);

    // Draw min/max telemetry as an envelope, which preserves real peaks better than aliased point sampling.
    context.fillStyle = state.running ? scopeColors.violetSoft : scopeColors.idleFill;
    context.strokeStyle = state.running ? gradient : scopeColors.idleStroke;
    context.lineWidth = state.running ? 1.6 * ratio : 1.2 * ratio;
    context.beginPath();
    envelope.forEach(([minSample, maxSample], index) => {
      const x = (index / (envelope.length - 1)) * width;
      const y = midY - clamp(maxSample, -1, 1) * amp;
      if (index === 0) context.moveTo(x, y);
      else context.lineTo(x, y);
    });
    for (let index = envelope.length - 1; index >= 0; index -= 1) {
      const [minSample] = envelope[index];
      const x = (index / (envelope.length - 1)) * width;
      const y = midY - clamp(minSample, -1, 1) * amp;
      context.lineTo(x, y);
    }
    context.closePath();
    context.fill();
    context.stroke();
  }

  const peakHeight = Math.min(1, state.peak) * (height - 24 * ratio);
  context.fillStyle = state.clip ? scopeColors.alert : scopeColors.meter;
  context.fillRect(width - 10 * ratio, height - peakHeight - 12 * ratio, 4 * ratio, peakHeight);
}

function toEnvelopePairs(samples: number[]) {
  if (samples.length < 2) return [[0, 0]];

  const pairs: Array<[number, number]> = [];
  for (let index = 0; index < samples.length - 1; index += 2) {
    const first = clamp(samples[index], -1, 1);
    const second = clamp(samples[index + 1], -1, 1);
    pairs.push([Math.min(first, second), Math.max(first, second)]);
  }
  return pairs.length > 0 ? pairs : [[0, 0]];
}

function drawSpectrum(
  context: CanvasRenderingContext2D,
  width: number,
  height: number,
  ratio: number,
  state: EqState,
  smoothed: number[],
) {
  const spectrum = state.running ? state.spectrum : [];
  const bands = spectrum.length > 0 ? spectrum : Array.from({ length: 16 }, () => 0);
  if (smoothed.length !== bands.length) {
    smoothed.splice(0, smoothed.length, ...bands.map(() => 0));
  }

  const gap = 3 * ratio;
  const floor = height - 14 * ratio;
  const barWidth = (width - gap * (bands.length + 1)) / bands.length;

  bands.forEach((rawValue, index) => {
    const target = state.running ? normalizeSpectrum(rawValue) : 0;
    smoothed[index] += (target - smoothed[index]) * 0.2;
    const barHeight = smoothed[index] * (height * 0.72);
    const x = gap + index * (barWidth + gap);
    const y = floor - barHeight;

    const hue = index / Math.max(1, bands.length - 1);
    context.fillStyle = pickSpectrumColor(hue, smoothed[index]);
    context.fillRect(x, y, Math.max(1, barWidth), barHeight);
  });
}

function drawEqCurve(context: CanvasRenderingContext2D, width: number, height: number, ratio: number, state: EqState) {
  const points = 96;
  const topPadding = 18 * ratio;
  const bottomPadding = 18 * ratio;
  const centerY = height * 0.5;
  const dbRange = 18;

  context.strokeStyle = scopeColors.eqCurve;
  context.lineWidth = 2.2 * ratio;
  context.beginPath();

  for (let index = 0; index <= points; index += 1) {
    const t = index / points;
    const db = eqDbAt(t, state.low, state.mid, state.high);
    const y = clamp(centerY - (db / dbRange) * (height * 0.36), topPadding, height - bottomPadding);
    const x = t * width;
    if (index === 0) context.moveTo(x, y);
    else context.lineTo(x, y);
  }
  context.stroke();
}

function eqDbAt(position: number, low: number, mid: number, high: number) {
  const lowWeight = 1 - smoothstep(0.08, 0.43, position);
  const midWeight = Math.exp(-Math.pow((position - 0.5) / 0.22, 2));
  const highWeight = smoothstep(0.57, 0.94, position);
  return low * lowWeight + mid * midWeight + high * highWeight;
}

function normalizeSpectrum(value: number) {
  return clamp(Math.log10(1 + Math.max(0, value) * 80), 0, 1);
}

function pickSpectrumColor(position: number, intensity: number) {
  if (position < 0.5) return `rgba(180, 140, 255, ${0.24 + intensity * 0.68})`;
  return `rgba(77, 225, 211, ${0.2 + intensity * 0.66})`;
}

function smoothstep(edge0: number, edge1: number, value: number) {
  const t = clamp((value - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

function clamp(value: number, low: number, high: number) {
  return Math.max(low, Math.min(high, value));
}

function formatDb(value: number) {
  if (value <= 0.00002) return "-inf dB";
  return `${Math.round(20 * Math.log10(value))} dB`;
}

function formatGain(value: number) {
  const rounded = Math.round(value);
  return `${rounded > 0 ? "+" : ""}${rounded} dB`;
}
