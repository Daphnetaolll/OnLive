# ===========================================
# OnLive 音 | Memory Distortion Audio Tool
# Studio Mode + Live Mode 
# Developed by DAPHNIII
# ===========================================

import os, time, html, shutil, subprocess
import gradio as gr
from pydub import AudioSegment
from distortions import apply_distortion
import re

# Audio Device Management
_audio_devices = {"inputs": [], "outputs": []}
_selected_input = 0   # default adc 
_selected_output = 0  # default dac 

def list_audio_devices():
    """
    - input dropdown
    - output dropdown
    """
    global _audio_devices, _selected_input, _selected_output

    try:
        result = subprocess.run(
            ["csound", "--devices"],
            capture_output=True,
            text=True,
        )
        text = result.stderr
    except Exception as e:
        msg = f"[OnLive 音] Failed to run `csound --devices`: {repr(e)}"
        print(msg)
        return (
            gr.update(choices=[], value=None),
            gr.update(choices=[], value=None),
        )

    # print output
    print("----- raw `csound --devices` output -----")
    print(text)
    print("--------------- end ---------------------")

    inputs: list[str] = []
    outputs: list[str] = []

    for line in text.splitlines():
        line = line.strip()
        if ": adc" in line:
            # "4: adc4 (MacBook Pro Microphone [Core Audio, 1 in, 0 out]) [ch:1]"
            parts = line.split(":", 1)
            idx = parts[0].strip()  # "4"
            desc_part = parts[1]
            human = desc_part
            if "(" in desc_part:
                human = desc_part.split("(", 1)[1]
            if "[" in human:
                human = human.split("[", 1)[0]
            human = human.strip(" )")
            label = f"{idx}: {human}"   # "4: MacBook Pro Microphone"
            inputs.append(label)

        if ": dac" in line:
            parts = line.split(":", 1)
            idx = parts[0].strip()  # "2"
            desc_part = parts[1]
            human = desc_part
            if "(" in desc_part:
                human = desc_part.split("(", 1)[1]
            if "[" in human:
                human = human.split("[", 1)[0]
            human = human.strip(" )")
            label = f"{idx}: {human}"
            outputs.append(label)

    _audio_devices = {"inputs": inputs, "outputs": outputs}
    print("[OnLive 音] Parsed inputs:", inputs)
    print("[OnLive 音] Parsed outputs:", outputs)

    # Fallback
    if inputs:
        _selected_input = int(inputs[0].split(":", 1)[0].strip())
    else:
        _selected_input = 0

    if outputs:
        _selected_output = int(outputs[0].split(":", 1)[0].strip())
    else:
        _selected_output = 0

    input_default = inputs[0] if inputs else None
    output_default = outputs[0] if outputs else None

    return (
        gr.update(choices=inputs, value=input_default),
        gr.update(choices=outputs, value=output_default),
    )

def set_audio_devices(input_label, output_label):
    # Store adc and dac
    global _selected_input, _selected_output

    def parse_label(label: str) -> int:
        # "4: MacBook Pro Microphone" -> 4
        if not label:
            return 0
        return int(label.split(":", 1)[0].strip())

    _selected_input = parse_label(input_label)
    _selected_output = parse_label(output_label)

    msg = (
        f"🎧 Audio devices set:\n"
        f"- Input  adc{_selected_input}\n"
        f"- Output dac{_selected_output}"
    )
    print("[OnLive 音] Selected devices:", msg.replace("\n", " | "))
    return msg

# OSC: send UI params to Csound 
try:
    from pythonosc.udp_client import SimpleUDPClient
    _osc = SimpleUDPClient("127.0.0.1", 7777)  # Csound default listening port
except Exception as e:
    _osc = None
    print("[OnLive 音] python-osc not available, OSC disabled:", e)

def send_osc(path, *values):
    if _osc is not None:
        try:
            _osc.send_message(path, list(values) if len(values) > 1 else values[0])
        except Exception as e:
            print("[OnLive 音] OSC send failed:", path, values, e)

# Csound Live engine control _____________________________________________________________________________________ 
CSOUND_CSD_PATH = os.path.join(os.path.dirname(__file__), "on_live.csd")
_csound_proc = None 

# Print path info once when app starts 
print("[OnLive 音] Csound live file:", CSOUND_CSD_PATH, "exists:", os.path.exists(CSOUND_CSD_PATH))

#Start Csound
def start_csound_engine():
    import shutil 

    global _csound_proc, _selected_input, _selected_output

    if _csound_proc is not None and _csound_proc.poll() is None:
        return "✅ Csound Live Mode is already running."

    # 1. Check .csd next to app.py
    if not os.path.exists(CSOUND_CSD_PATH):
        return (
            "❌ on_live.csd not found.\n"
            f"Looked here:\n`{CSOUND_CSD_PATH}`"
        )

    # 2. Check `csound` binary is available in environment
    if shutil.which("csound") is None:
        return (
            "❌ Could not find the `csound` command in PATH.\n"
            "Open the same terminal / venv and run: `csound --version`.\n"
            "If that fails, install Csound or add it to PATH."
        )

    try:
        # Build the command using the currently selected input and output
        cmd = [
            "csound",
            f"-iadc{_selected_input}",
            f"-odac{_selected_output}",
            CSOUND_CSD_PATH,
        ]
        print("[OnLive 音] Starting Csound with:", " ".join(cmd))

        _csound_proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        return (
            "▶️ Started Csound Live Mode.\n"
            f"Command: `{' '.join(cmd)}`"
        )
    except Exception as e:
        _csound_proc = None
        return f"❌ Failed to start Csound:\n`{repr(e)}`"

#End Csound
def stop_csound_engine():
    global _csound_proc
    if _csound_proc is None or _csound_proc.poll() is not None:
        _csound_proc = None
        return "⏹️ Csound is not running."
    try:
        _csound_proc.terminate()
        _csound_proc = None
        return "⏹️ Csound Live Mode stopped. Microphone input is now off."
    except Exception as e:
        return f"❌ Failed to stop Csound:\n`{repr(e)}`"
    
# Pitch Shifter
def live_set_PitchOn(enabled: bool):
    send_osc("/ol/pitch/on", 1 if enabled else 0)
    return "Pitch Shifter ON" if enabled else "Pitch Shifter OFF"

def live_set_PitchWet(value: float):
    send_osc("/ol/pitch/wet", float(value))
    return value

def live_set_PitchSemi(value: int):
    send_osc("/ol/pitch/semi", int(value))
    return value

# Ring Modulation
def live_set_RingOn(enabled: bool):
    send_osc("/ol/ring/on", 1 if enabled else 0)
    return "Pitch Modulation ON" if enabled else "Pitch Modulation OFF"

def live_set_RingWet(value: float):
    send_osc("/ol/ring/wet", float(value))
    return value

# Blur Effect
def live_set_BlurOn(enabled: bool):
    send_osc("/ol/blur/on", 1 if enabled else 0)
    return "Blur ON" if enabled else "Blur OFF"

def live_set_BlurLen(value: float):
    send_osc("/ol/blur/len", float(value))
    return value

def live_set_BlurWet(value: float):
    send_osc("/ol/blur/wet", float(value))
    return value

# Flanger Effect
def live_set_FlangerOn(enabled: bool):
    send_osc("/ol/flanger/on", 1 if enabled else 0)
    return "Flanger ON" if enabled else "Flanger OFF"

def live_set_FlangerWet(value: float):
    send_osc("/ol/flanger/wet", float(value))
    return value

def live_set_FlangerRate(value: float):
    send_osc("/ol/flanger/lfo", float(value))
    return value

# EQ
# Low Shelf
def live_set_LowEQ(value: float):
    send_osc("/ol/eq/low", float(value))
    return value

# Mid Peak
def live_set_MidEQ(value: float):
    send_osc("/ol/eq/mid", float(value))
    return value

# High Shelf
def live_set_HighEQ(value: float):
    send_osc("/ol/eq/high", float(value))
    return value

# Studio Mode _____________________________________________________________________________________
# Folders
INPUT_DIR  = os.path.join("audio", "input")
OUTPUT_DIR = os.path.join("audio", "output")
TMP_DIR    = os.path.join("audio", "tmp")
os.makedirs(INPUT_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(TMP_DIR, exist_ok=True)

# Modes
MODES = [
    ("Echo (musical multi-tap)", "echo"),
    ("Memory (echo + hiss + drift)", "memory"),
    ("Lo-fi (downsample + low-pass)", "lofi"),
    ("Ghost (shadow copy)", "ghost"),
    ("Slow Fade (gradual slowdown)", "slow"),
    ("Light (gentle stretch + smoothing)", "light"),
    ("Medium (detune + stretch + smoothing)", "medium"),
    ("Strong (deep detune + slow + soft edges)", "strong"),
]

def knob_to_intensity(v: float) -> str:
    if v <= 33: return "soft"
    if v <= 66: return "medium"
    return "strong"

def _tmp_path(name: str) -> str:
    return os.path.join(TMP_DIR, f"{int(time.time()*1000)}_{name}")

def _export_as_mp3(wav_path: str, mp3_path: str):
    AudioSegment.from_file(wav_path).export(mp3_path, format="mp3")

def _wavesurfer_html(path: str) -> str:
    if not path:
        return "<div></div>"
    src = html.escape(path)
    return f"""
<div id="ws-container" style="width:100%;max-width:1200px;margin:8px auto 0;"></div>
<div style="display:flex;gap:10px;margin:8px 0 2px;">
  <button id="ws-play" style="background:#7c3aed;border:1px solid #5b21b6;color:#fff;padding:8px 14px;border-radius:10px;">Play / Pause</button>
  <span id="ws-time" style="color:#cfcfe6;font-size:12px;">0:00 / 0:00</span>
</div>

<link rel="preconnect" href="https://unpkg.com" />
<script src="https://unpkg.com/wavesurfer.js@7"></script>
<script>
(() => {{
  const url = encodeURI("{src}");
  const ws = WaveSurfer.create({{
    container: '#ws-container',
    waveColor: '#7c3aed',
    progressColor: '#a78bfa',
    cursorColor: '#f1f1ff',
    height: 150,
    normalize: true,
    barWidth: 2,
    interact: true,
  }});
  ws.load(url);

  const fmt = (s) => {{
    const m = Math.floor(s/60); const ss = Math.floor(s%60);
    return m + ":" + (ss<10 ? "0"+ss : ss);
  }};
  const timeEl = document.getElementById('ws-time');
  ws.on('ready', () => {{ timeEl.textContent = "0:00 / " + fmt(ws.getDuration()); }});
  ws.on('audioprocess', () => {{ timeEl.textContent = fmt(ws.getCurrentTime()) + " / " + fmt(ws.getDuration()); }});
  document.getElementById('ws-play').onclick = () => ws.playPause();
}})();
</script>
"""

# PROCESS
def process(src_wav_path, mode_label, knob_val, out_format, fast_preview):

    if not src_wav_path or not os.path.exists(src_wav_path):
        return None, _wavesurfer_html(None), "Please upload a .wav or .mp3 file.", None

    mode = {label: key for (label, key) in MODES}.get(mode_label, "echo")
    intensity = knob_to_intensity(knob_val)
    fast = bool(fast_preview)

    base = os.path.splitext(os.path.basename(src_wav_path))[0]
    flag = "fast" if fast else "hq"

    # Always render preview to TEMP WAV
    temp_wav = _tmp_path(f"{base}_{mode}_{intensity}_{flag}.wav")
    ok, err = apply_distortion(src_wav_path, temp_wav, mode, intensity=intensity, fast=fast)
    if not ok:
        return None, _wavesurfer_html(None), f"❌ Failed: {err or 'Unknown error'}", None

    # Preview always WAV
    status = f"✅ Ready to download ({'MP3' if out_format=='MP3' else 'WAV'}, {flag}). Not saved to disk."
    return temp_wav, _wavesurfer_html(temp_wav), status, temp_wav

# DOWNLOAD 
def on_download(temp_wav, out_format, mode_label, knob_val, fast_preview):

    if not temp_wav or not os.path.exists(temp_wav):
        return None, "No preview to download. Please upload and tweak first."

    # Build output filename 
    base_name_no_ts = os.path.basename(temp_wav).split("_", 1)[-1]
    if out_format == "MP3":
        final_path = os.path.join(OUTPUT_DIR, os.path.splitext(base_name_no_ts)[0] + ".mp3")
        _export_as_mp3(temp_wav, final_path)
    else:
        final_path = os.path.join(OUTPUT_DIR, os.path.splitext(base_name_no_ts)[0] + ".wav")
        shutil.copyfile(temp_wav, final_path)

    return final_path, f"⬇️ Saved & downloading: {final_path}"

# THEME _____________________________________________________________________________________
CUSTOM_CSS = """
:root {
  --ghost-purple: #7c3aed;
  --ghost-p-soft: #a78bfa;
  --ghost-black:  #0b0b10;
  --ghost-gray:   #1d2027;
  --ghost-line:   #2a2f3f;
  --pill-bg:      #212432;
  --pill-on:      #6d28d9;
}
* { font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Inter, "Helvetica Neue", Arial, "Apple Color Emoji", "Segoe UI Emoji"; }
.gradio-container, body, html { background: var(--ghost-black) !important; color: #ececf1 !important; }
#title h1 { color: #efeafe; letter-spacing: .6px; margin: 0 0 4px 0; font-weight: 800; font-size: 26px; }
#subtitle { color: #9aa0b5; font-size: 12px; margin-top: -4px; }

.panel {
  background: linear-gradient(180deg,#12131a,#0e0f14);
  padding: 16px; border-radius: 16px; border: 1px solid var(--ghost-line);
  box-shadow: 0 10px 30px rgba(124,58,237,0.08);
}

button, .btn {
  background: var(--ghost-purple) !important;
  border: 1px solid #5b21b6 !important;
  color: #fff !important;
  border-radius: 12px !important;
}
button:hover { filter: brightness(1.06); }

input, .gr-text-input, .gr-box, .gradio-slider, .gr-dropdown, .gr-checkbox {
  background: var(--ghost-gray) !important; border-color: var(--ghost-line) !important; color: #ececf1 !important; border-radius: 12px !important;
}
.gr-form, .wrap, .block, .group { background: transparent !important; }

/* Rotary knob */
input[type="range"].rotary {
  -webkit-appearance: none; appearance: none;
  width: 120px; height: 120px; border-radius: 50%;
  background: conic-gradient(var(--ghost-purple) calc(var(--val,50)*1%), #3a3a4a 0);
  border: 7px solid #1b1c25; outline: none; cursor: pointer;
  box-shadow: inset 0 0 0 2px #2a2f3f;
}
input[type="range"].rotary::-webkit-slider-thumb { -webkit-appearance: none; appearance: none; width: 0; height: 0; }
input[type="range"].rotary::before {
  content: ""; position: relative; display: block;
  width: 4px; height: 38px; background: #fff;
  top: 38px; left: 58px; border-radius: 2px;
  transform-origin: bottom center;
  transform: rotate(calc((var(--val,50) * 3.6deg) - 180deg));
  box-shadow: 0 0 8px rgba(255,255,255,0.3);
}

/* WAV/MP3 buttons */
#fmt_wav, #fmt_mp3 {
  background: var(--pill-bg) !important;
  border: 1px solid var(--ghost-line) !important;
  color: #e6e6ef !important;
  border-radius: 999px !important;
  padding: 8px 14px !important;
}
#fmt_wav.active, #fmt_mp3.active {
  background: var(--pill-on) !important;
  border-color: #5b21b6 !important;
  color: #fff !important;
  box-shadow: 0 0 0 2px rgba(124,58,237,.25) !important;
}

/* Fast Preview */
.fast-toggle label { display:flex; align-items:center; gap:8px; }
.fast-toggle .wrap-inner { display:flex; align-items:center; gap:8px; }
.fast-badge { background:#2a2139; color:#f8e6ff; border:1px solid #5b21b6; padding:4px 8px; border-radius:999px; font-size:12px; display:inline-flex; align-items:center; gap:6px; }
.fast-badge .bolt { color:#ffd54d; }

/* FX checkbox style______________________________________________________________*/
.fx-toggle label {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 4px 10px;
  border-radius: 999px;
  border: 1px solid transparent;
  cursor: pointer;
  transition: background 0.15s ease, border-color 0.15s ease,
              box-shadow 0.15s ease, color 0.15s ease;
}

/* Disable the default style and draw circle */
.fx-toggle input[type="checkbox"] {
  -webkit-appearance: none;
  appearance: none;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 2px solid #4b5563;
  background: #111827;
  cursor: pointer;
  position: relative;
}

/* add purple border */
.fx-toggle input[type="checkbox"]:checked {
  border-color: var(--ghost-purple);
  box-shadow: 0 0 0 2px rgba(124, 58, 237, 0.6);
}

/* draw a purple circle inside */
.fx-toggle input[type="checkbox"]:checked::after {
  content: "";
  position: absolute;
  inset: 3px;
  border-radius: 50%;
  background: var(--ghost-purple);
}

/* text lights up */
.fx-toggle input[type="checkbox"]:checked + span {
  background: #2a2139;
  border-radius: 999px;
  padding: 2px 8px;
  color: #ffffff;
  box-shadow: 0 0 0 2px rgba(124, 58, 237, 0.35);
}


"""



INTRO_MD = """
### 👻 OnLive 音 — Memory Distortion Audio Tool  
**Developed by DAPHNIII**

Turn tracks into dreamy, memory-like reflections.  
- **Modes**: Echo / Memory / Lo-fi / Ghost / Slow Fade 
- **Intensity**: single rotary knob (0–100), mapped to musical parameters  
- **Preview**: full waveform, click to seek, instant updates  
- **Quality**: *Fast Preview* (quick prelisten) or *High Quality* (final export)  
- **Export**: WAV or MP3; **no autosave** — saved only when you press **Save & Download**
"""

# UI 
with gr.Blocks(css=CUSTOM_CSS, title="OnLive 音 | Memory Distortion Audio Tool") as demo:
    # Top title and description 
    gr.Markdown(
        '<div id="title">'
        '<h1>OnLive 音 | Memory Distortion Audio Tool</h1>'
        '<div id="subtitle">Developed by DAPHNIII</div>'
        '</div>'
    )

    with gr.Tabs():
        
        # TAB 1____________________________________________________________________________________
        
        with gr.Tab("OnLive 音 Studio Mode"):
            gr.Markdown(INTRO_MD)

            # States for the offline processing workflow
            tmp_state     = gr.State(value=None)   # PREVIEW WAV
            fmt_state     = gr.State(value="WAV")  # WAV or MP3
            src_wav_state = gr.State(value=None)   

            # Controls 
            with gr.Row():
                with gr.Column(elem_classes=["panel"]):
                    file_in = gr.File(
                        label="Upload .wav or .mp3",
                        file_types=[".wav", ".mp3"],
                    )
                    mode_dd = gr.Dropdown(
                        choices=[m[0] for m in MODES],
                        value=MODES[0][0],
                        label="Mode",
                    )

                    knob = gr.Slider(
                        0,
                        100,
                        value=50,
                        step=1,
                        label="Intensity",
                        elem_classes=["rotary"],
                    )
                
                    knob.change(
                        None,
                        inputs=knob,
                        outputs=None,
                        js="""
                            (v) => { const els = document.getElementsByClassName('rotary');
                                     for (const el of els) el.style.setProperty('--val', v.toString()); }
                        """,
                    )

                    # WAV / MP3 pill buttons
                    with gr.Row():
                        btn_wav = gr.Button("WAV", elem_id="fmt_wav")
                        btn_mp3 = gr.Button("MP3", elem_id="fmt_mp3", variant="secondary")

                    # Fast Preview toggle
                    fast = gr.Checkbox(value=True, label=" ", elem_classes=["fast-toggle"])
                    gr.Markdown('<span class="fast-badge"><span class="bolt">⚡</span> Fast Preview</span>')

            # Output / preview / download 
            with gr.Row():
                with gr.Column():
                    audio_out = gr.Audio(label="Preview (not saved)", interactive=False)
                    wave_html = gr.HTML()
                    status    = gr.Markdown()
                with gr.Column():
                    download_btn = gr.DownloadButton("Save & Download", visible=True)
                    saved_msg    = gr.Markdown()

            # Helper: decode upload to WAV
            def _prepare_src_wav(f):
                if f is None:
                    return None
                src = f.name
                if os.path.splitext(src)[1].lower() == ".wav":
                    return src
                tmp = _tmp_path("source.wav")
                AudioSegment.from_file(src).export(tmp, format="wav")
                return tmp

            # Helper: run offline processing 
            def _run_auto(src_wav, m, k, ofmt, fast_preview):
                a, h, s, t = process(src_wav, m, k, ofmt, fast_preview)
                return a, h, s, t

            # Wiring: upload to cache WAV to process
            file_in.change(_prepare_src_wav, inputs=file_in, outputs=src_wav_state).then(
                _run_auto,
                inputs=[src_wav_state, mode_dd, knob, fmt_state, fast],
                outputs=[audio_out, wave_html, status, tmp_state],
            )

            # Auto process on mode / intensity / quality change
            for comp in [mode_dd, knob, fast]:
                comp.change(
                    _run_auto,
                    inputs=[src_wav_state, mode_dd, knob, fmt_state, fast],
                    outputs=[audio_out, wave_html, status, tmp_state],
                )

            # WAV click 
            btn_wav.click(
                lambda: "WAV",
                outputs=fmt_state,
                js="""
                    () => {
                        const w = document.getElementById('fmt_wav');
                        const m = document.getElementById('fmt_mp3');
                        w?.classList.add('active');
                        m?.classList.remove('active');
                    }
                """,
            ).then(
                _run_auto,
                inputs=[src_wav_state, mode_dd, knob, fmt_state, fast],
                outputs=[audio_out, wave_html, status, tmp_state],
            )

            # MP3 click 
            btn_mp3.click(
                lambda: "MP3",
                outputs=fmt_state,
                js="""
                    () => {
                        const w = document.getElementById('fmt_wav');
                        const m = document.getElementById('fmt_mp3');
                        m?.classList.add('active');
                        w?.classList.remove('active');
                    }
                """,
            ).then(
                _run_auto,
                inputs=[src_wav_state, mode_dd, knob, fmt_state, fast],
                outputs=[audio_out, wave_html, status, tmp_state],
            )

            # On load: mark WAV as active
            demo.load(
                None,
                inputs=None,
                outputs=None,
                js="""
                    () => { document.getElementById('fmt_wav')?.classList.add('active'); }
                """,
            )

            # Download click
            def _download(t, ofmt, m, k, fast_preview):
                path, msg = on_download(t, ofmt, m, k, fast_preview)
                return path, msg

            download_btn.click(
                _download,
                inputs=[tmp_state, fmt_state, mode_dd, knob, fast],
                outputs=[download_btn, saved_msg],
            )

 
        # TAB 2_____________________________________________________________________________________    
        
        with gr.Tab("OnLive 音 Live Mode"):
            gr.Markdown(
                """
                ### 🎧 Csound Live Mode
                Use your microphone in **real time** and let OnLive 音 blur the edges of the present moment.
                """
            )

            live_status = gr.Markdown("Microphone is **off**. Press **Start Live Csound** to begin.")
            
            # Audio settings device selection
            
            input_dd = gr.Dropdown(
                    label="Input Device (adc)",
                    choices=["adc0", "adc1", "adc2", "adc3","adc14"], 
                    value="adc0",
                    interactive=True,  # ensure it is clickable
            )
            output_dd = gr.Dropdown(
                    label="Output Device (dac)",
                    choices=["dac0", "dac1", "dac2", "dac3","dac14"],
                    value="dac0",
                    interactive=True,
            )
            apply_btn = gr.Button("Apply selection")

    # populate device list when the app loads
            demo.load(
                    list_audio_devices,
                    inputs=[],
                    outputs=[input_dd, output_dd],
            )

    # Save selected and "Apply"
            apply_btn.click(
                    set_audio_devices,
                    inputs=[input_dd, output_dd],
                    outputs=live_status,
            )

            # Live Mode Controls 
            with gr.Row():
                start_btn = gr.Button("▶️ Start Live Csound", variant="primary")
                stop_btn  = gr.Button("⏹️ Stop Live Csound")

            with gr.Row():
                #Pitch Shifter Controls
                with gr.Column():
                    live_PitchOn = gr.Checkbox(
                        value=False,
                        label="Pitch Shifter",
                        elem_classes=["fx-toggle"],
                    )

                    live_PitchWet = gr.Slider(
                        0,
                        1,
                        value=0.5,
                        step=0.01,
                        label="Pitch Shifter Dry/Wet",
                    )

                    live_PitchSemi = gr.Slider(
                        -12,
                        12,
                        value=0,
                        step=1,
                        label="Pitch Shifter Semitones",
                    )

                #Pitch Ring Modulation Controls
                with gr.Column():
                    live_RingOn = gr.Checkbox(
                        value=False,
                        label="Pitch Ring Modulation",
                        elem_classes=["fx-toggle"], 
                    )

                    live_RingWet = gr.Slider(
                        0,
                        1,
                        value=0.5,
                        step=0.01,
                        label="Ring Modulation Dry/Wet",
                    )

                #Blur Controls
                with gr.Column():
                    live_BlurOn = gr.Checkbox(
                        value=False,
                        label="Blur Effect",
                        elem_classes=["fx-toggle"], 
                    )
                    
                    live_BlurLen = gr.Slider(
                        0,
                        100,
                        value=50,
                        step=0.1,
                        label="Blur Length",
                    )

                    live_BlurWet = gr.Slider(
                        0,
                        1,
                        value=0.5,
                        step=0.01,
                        label="Blur Effect Dry/Wet",
                    )

                #Flanger Controls
                with gr.Column():
                    live_FlangerOn = gr.Checkbox(
                        value=False,
                        label="Flanger Effect",
                        elem_classes=["fx-toggle"], 
                    )
                    
                    live_FlangerWet = gr.Slider(
                        0,
                        1,
                        value=0.5,
                        step=0.01,
                        label="Flanger Effect Dry/Wet",
                    )

                    live_FlangerRate = gr.Slider(
                        0,
                        1,
                        value=0.5,
                        step=0.01,
                        label="Flanger LFO Rate",
                    )
            
            with gr.Row():
                #EQ Controls
                with gr.Column():
                    live_highEQ = gr.Slider(
                        -12,
                        12,
                        value=0,
                        step=1,
                        label="High Shelf EQ (dB)",
                    )

                    live_midEQ = gr.Slider(
                        -12,
                        12,
                        value=0,
                        step=1,
                        label="Mid Peak EQ (dB)",
                    )
                    
                    live_lowEQ = gr.Slider(
                        -12,
                        12,
                        value=0,
                        step=1,
                        label="Low Shelf EQ (dB)",
                    )

            # Wiring for Csound Live Mode
            # Start / stop the Csound engine
            start_btn.click(start_csound_engine, outputs=live_status)
            stop_btn.click(stop_csound_engine, outputs=live_status)

        #Pitch Shifter
            live_PitchOn.change(
                live_set_PitchOn,
                inputs=live_PitchOn,
                outputs=live_status,
            )

            live_PitchSemi.change(
                live_set_PitchSemi,
                inputs=live_PitchSemi,
                outputs=None,
            )

            live_PitchWet.change(
                live_set_PitchWet,
                inputs=live_PitchWet,
                outputs=None,
            )

        #Pitch Ring Modulation
            live_RingOn.change(
                live_set_RingOn,
                inputs=live_RingOn,
                outputs=live_status,
            )

            live_RingWet.change(
                live_set_RingWet,
                inputs=live_RingWet,
                outputs=None,
            )

        #Blur Effect
            live_BlurOn.change(
                live_set_BlurOn,
                inputs=live_BlurOn,
                outputs=live_status,
            )

            live_BlurLen.change(
                live_set_BlurLen,
                inputs=live_BlurLen,
                outputs=None,
            )

            live_BlurWet.change(
                live_set_BlurWet,
                inputs=live_BlurWet,
                outputs=None,
            )

        #Flanger Effect
            live_FlangerOn.change(
                live_set_FlangerOn,
                inputs=live_FlangerOn,
                outputs=live_status,
            )

            live_FlangerRate.change(
                live_set_FlangerRate,
                inputs=live_FlangerRate,
                outputs=None,
            )

            live_FlangerWet.change(
                live_set_FlangerWet,
                inputs=live_FlangerWet,
                outputs=None,
            )

        #EQ
            live_lowEQ.change(
                live_set_LowEQ,
                inputs=live_lowEQ,
                outputs=None,
            )

            live_midEQ.change(
                live_set_MidEQ,
                inputs=live_midEQ,
                outputs=None,
            )

            live_highEQ.change(
                live_set_HighEQ,
                inputs=live_highEQ,
                outputs=None,
            )
 

if __name__ == "__main__":
    demo.launch(share=True)
