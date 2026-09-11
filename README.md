# OnLive 音 - Browser-Based Live Audio Effects Console
**Developer:** Daphne Tao - *DAPHNIII*

Many digital sound tools are powerful, but the technical barrier to entry in DAWs can make them hard to approach — especially for traditional performers or beginners who just want to hear how live audio effects sound.

OnLive 音 is a browser-based audio effects console for live input and uploaded samples. It treats real-time audio processing like a pedalboard rather than a production suite: choose an audio source, toggle effects, adjust controls, and hear the result immediately — without first learning a full production environment. Every effect can also be opened to reveal the Csound `.csd` file behind it, so users can see exactly how each sound is made.

## Project Goal

OnLive 音 is not meant to replace professional DAWs. Its goal is to offer an open, low-setup way into expressive, interactive sound — for people with or without a production background.

This makes it useful for:

- hearing what common live effects actually sound like
- experimenting with microphone, instrument, or sample-pad processing
- exploring pedal- and rack-style workflows in a simpler environment
- prototyping real-time DSP ideas with a visual interface
- studying how effects are built, through their underlying Csound code

## Current Status

The current OnLive 音 web app is built with React, React Router, FastAPI, OSC, and Csound. It now centers on two parallel performance boards: Live Mode for microphone/instrument input and Sample Mode for an 8-pad sample player. Both modes share realtime Csound process control, output telemetry, five Live effects, master EQ/limiting, tempo-aware controls, MIDI mapping, and a System page for local dependency checks.

Validated locally:

```bash
cd frontend
npm run build

cd ..
python -m compileall backend/app
cd backend
../.venv/bin/python -c "from app.main import app; print(app.title)"
```

## Features

OnLive 音 is organized around two equal performance sources: **Live Mode** and **Sample Mode**. They are separated in the interface because a microphone/instrument input and sample-pad playback should not fight for the same source path. Both modes still feed the same Csound effects chain, master EQ, limiter, output waveform, and EQ analyzer.

Shared foundation:

- Csound is the audio engine; the browser controls Csound and visualizes telemetry
- FastAPI provides REST controls and a real-time WebSocket stream at `/api/live/events`
- Internal OSC/control paths use the OnLive 音 prefix `/ol/...`
- OSC sends validated control changes to Csound on `127.0.0.1:7777`
- Csound telemetry returns final output waveform, spectrum, RMS, peak, and clipping state on `127.0.0.1:7778`
- The Output Waveform panel shows the final processed bus.
- EQ Analyzer shows spectrum telemetry plus the current low/mid/high EQ curve
- System page at `/settings` checks API health, Csound binary, Csound version, CSD path, and runtime dependencies

### Live Mode

Live Mode is for a microphone, an instrument, or an external audio input. It opens a real Csound `adc` input device and sends the processed result to the selected `dac` output device. 

Live Mode features:

- Real input/output device discovery from `csound --devices`
- Device selectors using actual `adc` and `dac` ids
- Channel-aware Csound launch based on selected device channel counts
- Dedicated OnLive 音 Console, shown only while Live Mode is selected
- Apply selection, Start, Stop, and Refresh controls for audio routing
- Live input is muted when Sample Mode is selected, so sample playback does not mix with microphone feedback
- Collapsible Csound console for debugging

Live Mode is best for:

- processing voice, microphone, instrument, or external mixer input
- testing real-time Csound effects with physical audio routing
- performing with live sound while monitoring the final output waveform and spectrum

### Sample Mode

Sample Mode is an exclusive source for sample-based performance. Its main purpose is to let users upload sounds, trigger loops or one-shots, and shape each pad with different effect sends so samples can become playable musical material. The pads are generated inside Csound and enter the shared effects chain before the master bus. A secondary benefit is that users can test the same effects without opening the microphone input, thereby avoiding speaker-to-microphone feedback during experimentation.

Sample Mode features:

- Eight fixed sample-pad slots
- Upload support for WAV and MP3.
- Automatic conversion to 44.1 kHz stereo WAV for Csound playback
- Inline pad renaming directly on the pad title
- Full-file waveform preview for each uploaded sample
- Peak and clipping feedback so loud samples are visible before performance
- Per-pad volume from `-24 dB` to `+24 dB`
- One-shot and loop playback modes
- Loop length selection from 1 to 8 bars
- Tempo controls with Original and Sync modes
- BPM input from `40` to `240`
- Tempo suggestions from uploaded sample detection
- Resample and Warp modes, where Warp keeps pitch more stable when tempo changes
- Per-pad FX Sends drawer that stays available on loaded pads
- FX Sends only show currently active Live effects, so inactive effects do not clutter the pad
- Delete and replace controls for each pad

Sample Mode is best for:

- building music from loops, stems, drums, spoken clips, or sound design material
- applying different Live effects to different samples through per-pad FX Sends
- turning uploaded audio into a playable performance instrument
- comparing how different samples respond to the same effects chain
- creating a more playful performance workflow inside the web app
- practicing Ableton-style loop behavior with a simpler interface
- testing effects without using the microphone when a live input is not needed

### Shared Effects And Master Bus

Both Live Mode and Sample Mode feed the same Csound processing chain. This means the same effect controls can shape either live microphone audio or uploaded samples.

Live effects rack:

- Pitch Shifter: on/off, dry/wet, semitone shift from `-12` to `+12`
- Ring Mod: on/off, dry/wet
- Blur: on/off, length, dry/wet
- Flanger: on/off, dry/wet, LFO rate
- ATS Cross: on/off, dry/wet, morph, speed

Master section:

- Master EQ with low, mid, and high gain from `-12 dB` to `+12 dB`
- Master Volume for final output level control
- Final limiter with threshold, ceiling, attack, and release controls
- Master processing sits at the end of the audio chain for both source modes

### MIDI Mapping

- Browser Web MIDI-based mapping mode
- Map sliders, toggles, sample triggers, pad volume, loop length, and sample effect sends
- Mappings persist in browser `localStorage`

### Effect Code Viewer

- Each Live effect card has a Code button
- The dialog shows the matching Csound snippet from `backend/app/dsp/on_live.csd`
- Snippets are served by `GET /api/live/effects/code`

## Requirements

Recommended local versions:

- Python 3.11
- Node.js 24
- Csound 6.18+
- FFmpeg for uploaded sample decoding and WAV conversion
- A Chromium-based browser for the most complete Web MIDI support

Check Csound:

```bash
csound --version
csound --devices
```

Install FFmpeg:

```bash
brew install ffmpeg
```

Linux:

```bash
sudo apt-get install ffmpeg
```

Optional virtual audio routing:

- macOS: BlackHole or Loopback
- Linux: ALSA, JACK, PulseAudio, or PipeWire routing depending on your system

## Installation

Clone and enter the project:

```bash
git clone <your-repo-url>
cd LiveSound
```

Create a Python environment:

```bash
python3.11 -m venv .venv
source .venv/bin/activate
```

Install backend dependencies:

```bash
pip install -r backend/requirements.txt
```

Install frontend dependencies:

```bash
cd frontend
npm install
```

## Local Usage

Start the FastAPI backend:

```bash
cd backend
../.venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Start the React frontend in another terminal:

```bash
cd frontend
npm run dev
```

Open:

```text
http://localhost:5173/live
```

If Vite chooses another port, use the URL printed in the terminal.

Live Mode workflow:

1. Open `/live`.
2. Select Live Mode.
3. Use the OnLive 音 Console to choose an Input Device (`adc`) and Output Device (`dac`).
4. Click Refresh if the device list is empty.
5. Click Apply selection.
6. Click Start.
7. Adjust effects, master EQ, master volume, and limiter controls.
8. Watch Output Waveform and EQ Analyzer for final Csound output telemetry.
9. Expand Csound Console only when detailed logs are needed.
10. Click Stop to release the audio device.

Sample Mode workflow:

1. Click Sample Mode.
2. The Live input console is hidden, and no microphone input is opened.
3. Sample playback uses the current/default output device.
4. Upload samples into the eight pads.
5. Rename pads directly from the pad title when needed.
6. Trigger pads as one-shots or loops.
7. Adjust per-pad volume and check the waveform, peak, and clipping indicators.
8. Enable Live effects, then adjust each pad's FX Sends drawer.
9. Use Original/Sync, BPM, Warp/Resample, and loop length controls when working with looped material.
10. Click Stop or leave Sample Mode to release playback.

## Docker Usage

Build and run the packaged frontend/backend stack:

```bash
docker compose up --build
```

Frontend:

```text
http://localhost:8080/live
```

Backend health:

```text
http://localhost:8000/api/health
```

For Linux hosts where Docker should access host audio devices:

```bash
docker compose -f docker-compose.yml -f docker-compose.live-linux.yml up --build
```

Docker audio notes:

- The base Docker setup packages React, FastAPI, Csound, FFmpeg, and Nginx.
- `docker-compose.live-linux.yml` exposes `/dev/snd` and adds the `audio` group for Linux audio experiments.
- macOS Docker Desktop usually cannot access Core Audio devices directly. For real Live Mode audio on macOS, run the backend locally and use Docker mainly for packaging tests.

## API Reference

Health:

- `GET /api/health`

Live engine:

- `GET /api/live/devices`
- `PATCH /api/live/devices/selection`
- `POST /api/live/start`
- `POST /api/live/stop`
- `GET /api/live/status`
- `GET /api/live/logs`
- `PATCH /api/live/params`
- `PATCH /api/live/params/batch`
- `GET /api/live/effects/code`

Sample Mode:

- `GET /api/live/samples`
- `POST /api/live/samples/mode`
- `PUT /api/live/samples/{slot}`
- `PATCH /api/live/samples/{slot}`
- `DELETE /api/live/samples/{slot}`
- `POST /api/live/samples/{slot}/trigger`

Realtime stream:

- `WS /api/live/events`

The WebSocket streams telemetry on every tick and periodically includes status and recent Csound logs.

## System Architecture

```text
React UI + React Router
        |
        | REST + WebSocket
        v
FastAPI Backend
        |
        | owns one Csound subprocess
        v
CsoundEngine
        |
        | OSC controls on 127.0.0.1:7777
        v
Csound DSP: backend/app/dsp/on_live.csd
        |
        | final processed bus
        v
Audio Output Device (dac)

Csound telemetry on 127.0.0.1:7778
        |
        v
TelemetryReceiver
        |
        | /api/live/events
        v
Output Waveform + EQ Analyzer panels

Sample Mode uploads
        |
        v
backend/storage/live_samples/pad_00.wav ... pad_07.wav
        |
        | /ol/sample/trigger or /ol/sample/loop/start
        v
Csound SampleVoice -> per-pad FX sends -> shared master bus

Web MIDI
        |
        v
Browser localStorage mappings -> React controls -> OSC params
```

## Project Structure

```text
backend/
  app/
    api/             FastAPI health and live routes
    core/            runtime settings and path resolution
    dsp/             current Live Mode Csound file and ATS assets
    schemas/         Pydantic API models
    services/        Csound process, OSC, telemetry, samples, device parsing
  storage/           local sample-pad WAV files and metadata, ignored by git

frontend/
  src/
    components/      Live controls, sample pads, device selectors, visuals, console
    lib/             API client, types, Live control definitions, MIDI mapping
    routes/          Live page, System page, root shell
    styles/          app layout and design tokens

docker/
  Dockerfile.backend
  Dockerfile.frontend
  nginx.conf
```

## Development Notes

Adding a Live effect variant:

1. Add the Csound branch in `backend/app/dsp/on_live.csd`.
2. Reuse the matching variant selector where possible:
   - `/ol/pitch/variant`
   - `/ol/ring/variant`
   - `/ol/blur/variant`
   - `/ol/flanger/variant`
   - `/ol/ats/variant`
3. Add new `chn_k` channels and `OSClisten` paths in the Csound file if the variant needs new controls.
4. Add OSC ranges and defaults in `backend/app/services/csound_engine.py`.
5. Add frontend controls in `frontend/src/lib/liveControls.ts`.
6. If the effect should appear in the code viewer, update `backend/app/services/effect_code.py`.
7. If samples should route into the effect, update `SAMPLE_EFFECT_INDEXES` and sample send UI types.

Sample Mode implementation notes:

- Sample Mode is exclusive. When `/ol/mode/sample` is `1`, microphone input is not opened.
- Uploaded files are normalized to fixed slot filenames: `pad_00.wav` through `pad_07.wav`.
- Sample metadata lives in `backend/storage/live_samples/samples.json`.
- Loop starts use `/ol/sample/loop/start`; one-shots use `/ol/sample/trigger`.
- Pad FX sends are clamped from `0` to `1`.
- Uploads are limited to 80 MB and 120 seconds per sample.

Generated or local-only files:

- `.venv/`
- `frontend/node_modules/`
- `frontend/dist/`
- `backend/storage/`
- `__pycache__/`

These are ignored by `.gitignore`.

## Verification

Frontend:

```bash
cd frontend
npm run build
```

Backend syntax check:

```bash
python -m compileall backend/app
```

Backend import check:

```bash
cd backend
../.venv/bin/python -c "from app.main import app; print(app.title)"
```

Runtime health:

```bash
curl http://127.0.0.1:8000/api/health
```

## Known Limits

- Only one Csound subprocess should run per backend process. The Docker backend uses one Uvicorn worker for this reason.
- The current sample metadata file is a local JSON file; concurrent external API writes can race if multiple clients update samples at the same time.
- Invalid audio files may still surface as generic upload errors, depending on FFmpeg/Pydub decode failures.
- Web MIDI support depends on the browser and user permission.
- `VITE_WS_BASE` should be set explicitly if the frontend is served separately from the FastAPI host.
- Real macOS audio should be run with a local backend rather than Docker Desktop.

## License

MIT License
