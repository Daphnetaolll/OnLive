import type {
  DeviceList,
  EffectCodeSnippet,
  HealthStatus,
  LiveEventPayload,
  LiveStatus,
  ParamUpdate,
  SampleSlot,
  SampleSlotUpdate,
} from "./types";

const API_BASE = import.meta.env.VITE_API_BASE ?? "/api";

// Vite's dev server proxies HTTP cleanly; WebSocket calls go straight to FastAPI.
const WS_BASE =
  import.meta.env.VITE_WS_BASE ??
  (import.meta.env.DEV ? "ws://127.0.0.1:8000" : window.location.origin.replace(/^http/, "ws"));

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const isFormData = init?.body instanceof FormData;
  const response = await fetch(`${API_BASE}${path}`, {
    headers: isFormData ? init?.headers : { "Content-Type": "application/json", ...(init?.headers ?? {}) },
    ...init,
  });

  if (!response.ok) {
    const body = await response.json().catch(() => ({ detail: response.statusText }));
    throw new Error(body.detail ?? response.statusText);
  }

  return response.json() as Promise<T>;
}

// API helpers keep the route components focused on Live Mode state.
export const api = {
  health: () => request<HealthStatus>("/health"),
  devices: () => request<DeviceList>("/live/devices"),
  status: () => request<LiveStatus>("/live/status"),
  logs: () => request<string[]>("/live/logs"),
  effectCode: () => request<EffectCodeSnippet[]>("/live/effects/code"),
  samples: () => request<SampleSlot[]>("/live/samples"),
  start: (inputDevice: number, outputDevice: number) =>
    request<LiveStatus>("/live/start", {
      method: "POST",
      body: JSON.stringify({ input_device: inputDevice, output_device: outputDevice }),
    }),
  selectDevices: (inputDevice: number, outputDevice: number) =>
    request<LiveStatus>("/live/devices/selection", {
      method: "PATCH",
      body: JSON.stringify({ input_device: inputDevice, output_device: outputDevice }),
    }),
  stop: () => request<LiveStatus>("/live/stop", { method: "POST" }),
  setSampleMode: (enabled: boolean) =>
    request<LiveStatus>("/live/samples/mode", {
      method: "POST",
      body: JSON.stringify({ enabled }),
    }),
  uploadSample: (slot: number, file: File) => {
    const form = new FormData();
    form.append("file", file);
    return request<SampleSlot>(`/live/samples/${slot}`, {
      method: "PUT",
      body: form,
    });
  },
  deleteSample: (slot: number) => request<SampleSlot>(`/live/samples/${slot}`, { method: "DELETE" }),
  updateSample: (slot: number, update: SampleSlotUpdate) =>
    request<SampleSlot>(`/live/samples/${slot}`, {
      method: "PATCH",
      body: JSON.stringify(update),
    }),
  triggerSample: (slot: number, options?: { restart?: boolean }) =>
    request<LiveStatus>(`/live/samples/${slot}/trigger${options?.restart ? "?restart=true" : ""}`, { method: "POST" }),
  param: (path: string, value: number | boolean) =>
    request<LiveStatus>("/live/params", {
      method: "PATCH",
      body: JSON.stringify({ path, value }),
    }),
  paramsBatch: (updates: ParamUpdate[]) =>
    request<LiveStatus>("/live/params/batch", {
      method: "PATCH",
      body: JSON.stringify({ updates }),
    }),
  events: (onMessage: (payload: LiveEventPayload) => void) => {
    const socket = new WebSocket(`${WS_BASE}/api/live/events`);
    socket.onmessage = (event) => onMessage(JSON.parse(event.data));
    return socket;
  },
};
