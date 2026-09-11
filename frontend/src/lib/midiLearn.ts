import { useCallback, useEffect, useMemo, useRef, useState, type MouseEvent } from "react";

import type { SampleEffectId, SamplePlayMode } from "./types";

export type MidiControlType = "slider" | "toggle" | "trigger";
export type MidiTargetKind = "param" | "sample-gain" | "sample-send" | "sample-loop-bars" | "sample-trigger" | "sample-play-mode";

export type MidiTarget = {
  id: string;
  label: string;
  kind: MidiTargetKind;
  controlType: MidiControlType;
  min?: number;
  max?: number;
  step?: number;
  path?: string;
  slot?: number;
  effectId?: SampleEffectId;
  playMode?: SamplePlayMode;
};

export type MidiMessage = {
  key: string;
  label: string;
  kind: "cc" | "note";
  channel: number;
  number: number;
  value: number;
  normalized: number;
  isNoteOff: boolean;
};

export type MidiMapping = {
  midiKey: string;
  midiLabel: string;
  target: MidiTarget;
};

type MidiAccessLike = {
  inputs: {
    size: number;
    forEach(callback: (input: MidiInputLike) => void): void;
  };
  onstatechange: (() => void) | null;
};

type MidiInputLike = {
  name?: string | null;
  manufacturer?: string | null;
  state?: string | null;
  onmidimessage: ((event: { data: Uint8Array | number[] | null }) => void) | null;
};

const STORAGE_KEY = "on-live-midi-map-v1";

export function midiTargetAttrs(target: MidiTarget) {
  return {
    "data-midi-id": target.id,
    "data-midi-label": target.label,
    "data-midi-kind": target.kind,
    "data-midi-control": target.controlType,
    "data-midi-min": target.min,
    "data-midi-max": target.max,
    "data-midi-step": target.step,
    "data-midi-path": target.path,
    "data-midi-slot": target.slot,
    "data-midi-effect": target.effectId,
    "data-midi-play-mode": target.playMode,
  };
}

export function useMidiLearn(applyTarget: (target: MidiTarget, message: MidiMessage) => void) {
  const applyTargetRef = useRef(applyTarget);
  const midiAccessRef = useRef<MidiAccessLike | null>(null);
  const enabledRef = useRef(false);
  const pendingTargetRef = useRef<MidiTarget | null>(null);
  const mappingsRef = useRef<MidiMapping[]>([]);
  const [enabled, setEnabled] = useState(false);
  const [pendingTarget, setPendingTarget] = useState<MidiTarget | null>(null);
  const [mappings, setMappings] = useState<MidiMapping[]>(() => readStoredMappings());
  const [status, setStatus] = useState("MIDI Map off");
  const [inputNames, setInputNames] = useState<string[]>([]);
  const [supported] = useState(() => typeof navigator !== "undefined" && "requestMIDIAccess" in navigator);

  applyTargetRef.current = applyTarget;
  enabledRef.current = enabled;
  mappingsRef.current = mappings;
  pendingTargetRef.current = pendingTarget;

  const bindInputs = useCallback((access: MidiAccessLike) => {
    const names: string[] = [];
    access.inputs.forEach((input) => {
      input.onmidimessage = handleMidiMessage;
      if (input.state !== "disconnected") {
        names.push(input.name || input.manufacturer || "MIDI Input");
      }
    });
    setInputNames(names);
  }, []);

  const ensureMidiAccess = useCallback(async () => {
    const requestMidiAccess = (navigator as unknown as { requestMIDIAccess?: (options?: object) => Promise<unknown> }).requestMIDIAccess;
    if (!requestMidiAccess) {
      setStatus("Web MIDI unavailable");
      return false;
    }

    try {
      const access = (await requestMidiAccess.call(window.navigator, { sysex: false })) as MidiAccessLike;
      midiAccessRef.current = access;
      bindInputs(access);
      access.onstatechange = () => bindInputs(access);
      setStatus(access.inputs.size ? "MIDI ready" : "No MIDI input");
      return true;
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "MIDI permission denied");
      return false;
    }
  }, [bindInputs]);

  const toggleEnabled = useCallback(async () => {
    if (enabled) {
      enabledRef.current = false;
      setEnabled(false);
      setPendingTarget(null);
      setStatus("MIDI Map off");
      return;
    }

    const ready = await ensureMidiAccess();
    enabledRef.current = ready;
    setEnabled(ready);
    if (ready) {
      setStatus("Select control");
    }
  }, [enabled, ensureMidiAccess]);

  const clearMappings = useCallback(() => {
    setMappings([]);
    localStorage.removeItem(STORAGE_KEY);
    setStatus("MIDI map cleared");
  }, []);

  const handleCapture = useCallback(
    (event: MouseEvent<HTMLElement>) => {
      if (!enabled) return;
      const element = (event.target as HTMLElement | null)?.closest("[data-midi-id]") as HTMLElement | null;
      if (!element) return;
      event.preventDefault();
      event.stopPropagation();
      const target = targetFromElement(element);
      setPendingTarget(target);
      setStatus(`Map ${target.label}`);
    },
    [enabled],
  );

  const mappingCount = mappings.length;
  const mappedTargetIds = useMemo(() => new Set(mappings.map((mapping) => mapping.target.id)), [mappings]);

  return {
    enabled,
    supported,
    pendingTarget,
    mappings,
    mappingCount,
    mappedTargetIds,
    status,
    inputNames,
    toggleEnabled,
    clearMappings,
    handleCapture,
  };

  function handleMidiMessage(event: { data: Uint8Array | number[] | null }) {
    const message = parseMidiMessage(event.data);
    if (!message || message.isNoteOff) return;

    const target = pendingTargetRef.current;
    if (enabledRef.current && target) {
      const nextMappings = upsertMapping(mappingsRef.current, {
        midiKey: message.key,
        midiLabel: message.label,
        target,
      });
      setMappings(nextMappings);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(nextMappings));
      setPendingTarget(null);
      setStatus(`${target.label} <- ${message.label}`);
      return;
    }

    const mapping = mappingsRef.current.find((candidate) => candidate.midiKey === message.key);
    if (mapping) {
      applyTargetRef.current(mapping.target, message);
    }
  }
}

function targetFromElement(element: HTMLElement): MidiTarget {
  const dataset = element.dataset;
  return {
    id: dataset.midiId || "unknown",
    label: dataset.midiLabel || "Control",
    kind: (dataset.midiKind || "param") as MidiTargetKind,
    controlType: (dataset.midiControl || "slider") as MidiControlType,
    min: optionalNumber(dataset.midiMin),
    max: optionalNumber(dataset.midiMax),
    step: optionalNumber(dataset.midiStep),
    path: dataset.midiPath,
    slot: optionalNumber(dataset.midiSlot),
    effectId: dataset.midiEffect as SampleEffectId | undefined,
    playMode: dataset.midiPlayMode as SamplePlayMode | undefined,
  };
}

function parseMidiMessage(data: Uint8Array | number[] | null): MidiMessage | null {
  if (!data) return null;
  const status = data[0] ?? 0;
  const command = status & 0xf0;
  const channel = (status & 0x0f) + 1;
  const number = data[1] ?? 0;
  const value = data[2] ?? 0;
  if (command === 0xb0) {
    return {
      key: `cc:${channel}:${number}`,
      label: `CC ${number} ch ${channel}`,
      kind: "cc",
      channel,
      number,
      value,
      normalized: value / 127,
      isNoteOff: false,
    };
  }
  if (command === 0x90 || command === 0x80) {
    const isNoteOff = command === 0x80 || value === 0;
    return {
      key: `note:${channel}:${number}`,
      label: `Note ${number} ch ${channel}`,
      kind: "note",
      channel,
      number,
      value,
      normalized: value / 127,
      isNoteOff,
    };
  }
  return null;
}

function upsertMapping(mappings: MidiMapping[], nextMapping: MidiMapping) {
  return [nextMapping, ...mappings.filter((mapping) => mapping.midiKey !== nextMapping.midiKey && mapping.target.id !== nextMapping.target.id)];
}

function readStoredMappings(): MidiMapping[] {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return [];
    const parsed = JSON.parse(stored);
    return Array.isArray(parsed) ? parsed.filter(isStoredMapping) : [];
  } catch {
    return [];
  }
}

function isStoredMapping(value: unknown): value is MidiMapping {
  if (!value || typeof value !== "object") return false;
  const mapping = value as MidiMapping;
  return Boolean(mapping.midiKey && mapping.target?.id && mapping.target?.kind);
}

function optionalNumber(value: string | undefined) {
  if (value === undefined || value === "") return undefined;
  const number = Number(value);
  return Number.isFinite(number) ? number : undefined;
}
