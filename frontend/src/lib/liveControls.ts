import { AudioLines, Blend, Orbit, Sparkles, Waves } from "lucide-react";
import type { LucideIcon } from "lucide-react";

export type SliderControl = {
  type: "slider";
  label: string;
  path: string;
  min: number;
  max: number;
  step: number;
  unit?: string;
};

export type ToggleControl = {
  type: "toggle";
  label: string;
  path: string;
};

export type LiveControl = SliderControl | ToggleControl;

export type EffectVariant = {
  id: string;
  label: string;
  value: number;
  controls: LiveControl[];
};

export type EffectGroup = {
  id: string;
  title: string;
  variantPath: string;
  accent: "cyan" | "amber" | "rose" | "green" | "violet";
  icon: LucideIcon;
  variants: EffectVariant[];
};

export const defaultParamValues: Record<string, number> = {
  "/ol/transport/bpm": 120,
  "/ol/transport/sync": 0,
  "/ol/transport/warp": 1,
  "/ol/pitch/variant": 0,
  "/ol/pitch/on": 0,
  "/ol/pitch/wet": 0.5,
  "/ol/pitch/semi": 0,
  "/ol/ring/variant": 0,
  "/ol/ring/on": 0,
  "/ol/ring/wet": 0.5,
  "/ol/blur/variant": 0,
  "/ol/blur/on": 0,
  "/ol/blur/len": 50,
  "/ol/blur/wet": 0.5,
  "/ol/flanger/variant": 0,
  "/ol/flanger/on": 0,
  "/ol/flanger/wet": 0.5,
  "/ol/flanger/lfo": 0.5,
  "/ol/ats/variant": 0,
  "/ol/ats/on": 0,
  "/ol/ats/wet": 0.35,
  "/ol/ats/morph": 0.65,
  "/ol/ats/speed": 1,
  "/ol/eq/low": 0,
  "/ol/eq/mid": 0,
  "/ol/eq/high": 0,
  "/ol/master/volume": 1,
  "/ol/limiter/threshold": -3,
  "/ol/limiter/ceiling": -1,
  "/ol/limiter/attack": 2,
  "/ol/limiter/release": 140,
};

// Add same-category Csound variants here first; then mirror any new OSC paths in
// backend/app/services/csound_engine.py and backend/app/dsp/on_live.csd.
export const effectGroups: EffectGroup[] = [
  {
    id: "pitch",
    title: "Pitch Shifter",
    variantPath: "/ol/pitch/variant",
    accent: "cyan",
    icon: AudioLines,
    variants: [
      {
        id: "classic-pvs",
        label: "Classic",
        value: 0,
        controls: [
          { type: "toggle", label: "On", path: "/ol/pitch/on" },
          { type: "slider", label: "Dry/Wet", path: "/ol/pitch/wet", min: 0, max: 1, step: 0.01 },
          { type: "slider", label: "Semitones", path: "/ol/pitch/semi", min: -12, max: 12, step: 1, unit: "st" },
        ],
      },
    ],
  },
  {
    id: "ring",
    title: "Ring Mod",
    variantPath: "/ol/ring/variant",
    accent: "amber",
    icon: Orbit,
    variants: [
      {
        id: "classic-ring",
        label: "Classic",
        value: 0,
        controls: [
          { type: "toggle", label: "On", path: "/ol/ring/on" },
          { type: "slider", label: "Dry/Wet", path: "/ol/ring/wet", min: 0, max: 1, step: 0.01 },
        ],
      },
    ],
  },
  {
    id: "blur",
    title: "Blur",
    variantPath: "/ol/blur/variant",
    accent: "rose",
    icon: Waves,
    variants: [
      {
        id: "memory-blur",
        label: "Classic",
        value: 0,
        controls: [
          { type: "toggle", label: "On", path: "/ol/blur/on" },
          { type: "slider", label: "Length", path: "/ol/blur/len", min: 0, max: 100, step: 0.1 },
          { type: "slider", label: "Dry/Wet", path: "/ol/blur/wet", min: 0, max: 1, step: 0.01 },
        ],
      },
    ],
  },
  {
    id: "flanger",
    title: "Flanger",
    variantPath: "/ol/flanger/variant",
    accent: "green",
    icon: Blend,
    variants: [
      {
        id: "classic-flange",
        label: "Classic",
        value: 0,
        controls: [
          { type: "toggle", label: "On", path: "/ol/flanger/on" },
          { type: "slider", label: "Dry/Wet", path: "/ol/flanger/wet", min: 0, max: 1, step: 0.01 },
          { type: "slider", label: "LFO Rate", path: "/ol/flanger/lfo", min: 0, max: 1, step: 0.01 },
        ],
      },
    ],
  },
  {
    id: "ats",
    title: "ATS Cross",
    variantPath: "/ol/ats/variant",
    accent: "violet",
    icon: Sparkles,
    variants: [
      {
        id: "ats-cross-layer",
        label: "Classic",
        value: 0,
        controls: [
          { type: "toggle", label: "On", path: "/ol/ats/on" },
          { type: "slider", label: "Dry/Wet", path: "/ol/ats/wet", min: 0, max: 1, step: 0.01 },
          { type: "slider", label: "Morph", path: "/ol/ats/morph", min: 0, max: 1, step: 0.01 },
          { type: "slider", label: "Speed", path: "/ol/ats/speed", min: 0.1, max: 2, step: 0.01, unit: "x" },
        ],
      },
    ],
  },
];

// Master EQ is a final-stage tone control, separate from the performance effects row.
export const masterEqControls: SliderControl[] = [
  { type: "slider", label: "Low", path: "/ol/eq/low", min: -12, max: 12, step: 1, unit: "dB" },
  { type: "slider", label: "Mid", path: "/ol/eq/mid", min: -12, max: 12, step: 1, unit: "dB" },
  { type: "slider", label: "High", path: "/ol/eq/high", min: -12, max: 12, step: 1, unit: "dB" },
];

// Master volume feeds the final limiter, which protects the actual output bus.
export const masterVolumeControl: SliderControl = {
  type: "slider",
  label: "Master Volume",
  path: "/ol/master/volume",
  min: 0,
  max: 1,
  step: 0.01,
};

// Limiter parameters live in the master section because they shape the final bus, not one effect slot.
export const masterLimiterControls: SliderControl[] = [
  { type: "slider", label: "Threshold", path: "/ol/limiter/threshold", min: -24, max: 0, step: 0.5, unit: "dB" },
  { type: "slider", label: "Ceiling", path: "/ol/limiter/ceiling", min: -12, max: 0, step: 0.5, unit: "dB" },
  { type: "slider", label: "Attack", path: "/ol/limiter/attack", min: 0.1, max: 30, step: 0.1, unit: "ms" },
  { type: "slider", label: "Release", path: "/ol/limiter/release", min: 20, max: 1000, step: 5, unit: "ms" },
];
