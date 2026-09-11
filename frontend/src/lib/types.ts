export type DeviceKind = "input" | "output";

export type DeviceInfo = {
  id: number;
  label: string;
  name: string;
  channels: number;
  kind: DeviceKind;
  raw: string;
};

export type DeviceList = {
  inputs: DeviceInfo[];
  outputs: DeviceInfo[];
};

export type LiveStatus = {
  running: boolean;
  input_device: number;
  output_device: number;
  command: string[];
  params: Record<string, number>;
  sample_mode: boolean;
  last_message: string;
};

export type LiveTelemetry = {
  running: boolean;
  waveform: number[];
  spectrum: number[];
  rms: number;
  peak: number;
  clip: boolean;
  timestamp: number;
};

export type HealthStatus = {
  api: string;
  csound_binary: string | null;
  csound_version: string | null;
  csd_exists: boolean;
  csd_path: string;
};

export type LiveEventPayload = {
  status?: LiveStatus;
  logs?: string[];
  telemetry?: LiveTelemetry;
};

export type EffectCodeSnippet = {
  effect_id: string;
  title: string;
  source_path: string;
  start_line: number;
  end_line: number;
  code: string;
};

export type ParamUpdate = {
  path: string;
  value: number | boolean;
};

export type SamplePlayMode = "one_shot" | "loop";
export type SampleEffectId = "pitch" | "ring" | "blur" | "flanger" | "ats";
export type SampleEffectAccent = "cyan" | "amber" | "rose" | "green" | "violet";

export type ActiveSampleEffect = {
  id: SampleEffectId;
  label: string;
  accent: SampleEffectAccent;
};

export type SampleSlot = {
  slot: number;
  loaded: boolean;
  name: string | null;
  duration: number | null;
  size_bytes: number | null;
  detected_bpm: number | null;
  tempo_confidence: number | null;
  gain: number;
  gain_db: number;
  waveform: number[];
  peak_db: number | null;
  clipped: boolean;
  effect_sends: Record<SampleEffectId, number>;
  play_mode: SamplePlayMode;
  loop_bars: number;
  active: boolean;
};

export type SampleSlotUpdate = {
  name?: string;
  play_mode?: SamplePlayMode;
  loop_bars?: number;
  gain_db?: number;
  effect_sends?: Partial<Record<SampleEffectId, number>>;
};
