# ===========================================
# OnLive 音 - DSP Algorithms
# Developed by DAPHNIII
# ===========================================

import numpy as np
import librosa
import soundfile as sf
from pydub import AudioSegment


# Public API
def apply_distortion(input_path, output_path, mode, intensity="medium", fast=False):
    """
    Apply the chosen mode to input_path and write to output_path.

    Args:
        input_path: str - path to WAV/MP3/etc.
        output_path: str - target WAV path (UI converts to MP3 if needed)
        mode: str - "echo" | "memory" | "lofi" | "ghost" | "light" | "medium" | "strong" | "slow"
        intensity: "soft" | "medium" | "strong"
        fast: bool - True = Fast Preview (downsample, mono, faster resampling)

    Returns:
        (ok: bool, err: Optional[str])
    """
    try:
        # Pydub modes
        if mode in ["echo", "memory", "lofi", "ghost"]:
            au = AudioSegment.from_file(input_path)
            if fast:
                # lighten processing load in preview
                au = au.set_frame_rate(22050).set_channels(1)

            if mode == "echo":
                out = musical_echo(au, intensity=intensity)
            elif mode == "memory":
                out = memory_echo_chain(au, intensity=intensity)
            elif mode == "lofi":
                out = lofi_blur(au, intensity=intensity)
            elif mode == "ghost":
                out = ghost_layer(au, intensity=intensity)
            else:
                return False, "Unknown mode"

            out = _normalize_audiosegment(out, target_peak_dbfs=-1.0)
            out.export(output_path, format="wav")
            return True, None

        # Librosa modes 
        elif mode in ["light", "medium", "strong", "slow"]:
            target_sr = 22050 if fast else None  # None = keep native SR
            y, sr = librosa.load(
                input_path,
                sr=target_sr,
                mono=True,
                dtype=np.float32,
                res_type="kaiser_fast" if fast else "kaiser_best"
            )

            if mode == "light":
                y_out = light_distortion(y, sr, intensity=intensity)
            elif mode == "medium":
                y_out = medium_distortion(y, sr, intensity=intensity)
            elif mode == "strong":
                y_out = strong_distortion(y, sr, intensity=intensity)
            elif mode == "slow":
                y_out = slow_fade(y, sr, intensity=intensity)
            else:
                return False, "Unknown mode"

            if not np.all(np.isfinite(y_out)):
                return False, "Non-finite values in audio (NaN/inf)."

            y_out = _normalize_numpy(y_out, target_peak=0.98)
            sf.write(output_path, y_out.astype(np.float32), sr, format="WAV", subtype="PCM_16")
            return True, None

        else:
            return False, f"Unsupported mode: {mode}"

    except Exception as e:
        return False, str(e)


# Intensity helpers
def _pick(intensity, soft_val, med_val, strong_val):
    """Map intensity label to concrete values."""
    return {"soft": soft_val, "medium": med_val, "strong": strong_val}.get(intensity, med_val)


# Pydub modes 
def musical_echo(audio: AudioSegment, intensity="medium"):
    """
    Multi-tap echo with EQ and decay.
    """
    base = (audio - 2).low_pass_filter(16000)

    pre_delay_ms = _pick(intensity, 60, 90, 140)
    delay_times = _pick(
        intensity,
        [pre_delay_ms, pre_delay_ms + 190, pre_delay_ms + 380],
        [pre_delay_ms, pre_delay_ms + 220, pre_delay_ms + 440],
        [pre_delay_ms, pre_delay_ms + 260, pre_delay_ms + 520, pre_delay_ms + 780],
    )
    decays_db = _pick(intensity, [-10, -16, -22], [-8, -14, -20], [-6, -12, -18, -24])

    out = base
    for d_ms, db in zip(delay_times, decays_db):
        tap = base.low_pass_filter(8000) - abs(db)
        out = out.overlay(AudioSegment.silent(duration=d_ms) + tap)

    if out.channels == 1:
        out = out.set_channels(2)

    return out.fade_in(120).fade_out(200)

def add_tape_hiss(audio: AudioSegment, intensity="medium"):
    """tape hiss blended under the mix."""
    level_db = _pick(intensity, -40, -36, -32)
    dur_ms = len(audio)
    samples = np.random.normal(0, 1, int(audio.frame_rate * dur_ms / 1000)).astype(np.int16)
    noise = AudioSegment(
        samples.tobytes(),
        frame_rate=audio.frame_rate,
        sample_width=2,
        channels=1
    ).set_channels(audio.channels)
    noise = noise - abs(level_db)
    return audio.overlay(noise)

def stereo_drift(audio: AudioSegment, intensity="medium"):
    """L/R temporal drift to evoke wobble."""
    drift_ms = _pick(intensity, 10, 18, 28)
    if audio.channels == 1:
        audio = audio.set_channels(2)
    L, R = audio.split_to_mono()
    Ls = AudioSegment.silent(duration=drift_ms) + L
    Rs = R + AudioSegment.silent(duration=drift_ms)
    return AudioSegment.from_mono_audiosegments(Ls, Rs)

def lofi_blur(audio: AudioSegment, intensity="medium"):
    """Lo-fi + LPF + soft fades."""
    new_rate = _pick(intensity, 12000, 10000, 8000)
    cutoff = _pick(intensity, 6000, 5000, 4000)
    out = audio.set_frame_rate(new_rate).low_pass_filter(cutoff)
    return out.fade_in(300).fade_out(400)

def ghost_layer(audio: AudioSegment, intensity="medium"):
    """slower shadow delayed under the original."""
    if audio.channels == 1:
        audio = audio.set_channels(2)

    ghost = audio.low_pass_filter(_pick(intensity, 4500, 3500, 3000)) - _pick(intensity, 8, 10, 12)
    rate_factor = _pick(intensity, 0.97, 0.94, 0.90)
    ghost = ghost.set_frame_rate(int(ghost.frame_rate * rate_factor))
    ghost = AudioSegment.silent(duration=_pick(intensity, 140, 200, 260)) + ghost

    layered = audio.overlay(ghost)
    return layered.fade_in(120).fade_out(220)

def memory_echo_chain(audio: AudioSegment, intensity="medium"):
    """Echo + tape hiss + stereo drift"""
    step1 = musical_echo(audio, intensity=intensity)
    step2 = add_tape_hiss(step1, intensity=intensity)
    step3 = stereo_drift(step2, intensity=intensity)
    return step3

def _normalize_audiosegment(seg: AudioSegment, target_peak_dbfs=-1.0):
    """ Normalize an AudioSegment."""
    peak = seg.max_dBFS  # e.g., -0.5, -3.2, etc.
    if not np.isfinite(peak):
        return seg
    gain = target_peak_dbfs - peak
    if gain < 0:  # too loud → turn down
        return seg.apply_gain(gain)
    return seg


# Librosa modes (numpy)
def _xfade_join(a, b, sr, ms=40):
    """Crossfade join two numpy arrays to avoid clicks."""
    n = max(1, int(sr * ms / 1000))
    if len(a) < n or len(b) < n:
        return np.concatenate([a, b])
    fade_out = np.linspace(1.0, 0.0, n, dtype=np.float32)
    fade_in  = np.linspace(0.0, 1.0, n, dtype=np.float32)
    mid = a[-n:] * fade_out + b[:n] * fade_in
    return np.concatenate([a[:-n], mid, b[n:]])

def _soft_edges(y, sr, edge_ms=80):
    n = int(sr * edge_ms / 1000)
    if len(y) < 2 * n:
        return y
    fade_in  = np.linspace(0.0, 1.0, n, dtype=np.float32)
    fade_out = np.linspace(1.0, 0.0, n, dtype=np.float32)
    z = y.copy()
    z[:n]  *= fade_in
    z[-n:] *= fade_out
    return z

def _gentle_lpf(y, sr, cutoff=12000):
    """Gentle FIR LPF for subtle smoothing."""
    ny = sr / 2.0
    if cutoff >= ny * 0.95:
        return y
    taps = 65  
    fc = cutoff / ny
    n = np.arange(taps) - (taps - 1) / 2.0
    h = np.sinc(2 * fc * n)
    w = 0.54 - 0.46 * np.cos(2 * np.pi * np.arange(taps) / (taps - 1))
    h *= w
    h /= np.sum(h)
    return np.convolve(y, h, mode="same")

def _normalize_numpy(y, target_peak=0.98):
    peak = float(np.max(np.abs(y))) if y.size else 1.0
    if peak == 0:
        return y.astype(np.float32)
    if peak > target_peak:
        y = y / peak * target_peak
    return y.astype(np.float32)

def light_distortion(y, sr, intensity="medium"):
    rate = _pick(intensity, 0.98, 0.95, 0.92)
    out = librosa.effects.time_stretch(y, rate=rate)
    out = _gentle_lpf(out, sr, cutoff=_pick(intensity, 16000, 12000, 9000))
    out = _soft_edges(out, sr, edge_ms=80)
    return out

def medium_distortion(y, sr, intensity="medium"):
    semis = _pick(intensity, -1.5, -3.0, -4.5)
    rate  = _pick(intensity, 0.95, 0.90, 0.85)
    z1 = librosa.effects.pitch_shift(y, sr=sr, n_steps=semis)
    z2 = librosa.effects.time_stretch(z1, rate=rate)
    z2 = _gentle_lpf(z2, sr, cutoff=_pick(intensity, 14000, 10000, 8000))
    z2 = _soft_edges(z2, sr, edge_ms=100)
    return z2

def strong_distortion(y, sr, intensity="medium"):
    semis = _pick(intensity, -4, -6, -8)
    rate  = _pick(intensity, 0.80, 0.70, 0.60)
    z1 = librosa.effects.pitch_shift(y, sr=sr, n_steps=semis)
    z2 = librosa.effects.time_stretch(z1, rate=rate)
    z2 = _gentle_lpf(z2, sr, cutoff=_pick(intensity, 11000, 9000, 7000))
    z2 = _soft_edges(z2, sr, edge_ms=120)
    return z2

def slow_fade(y, sr, intensity="medium"):
    """
    Gradually slows down over time with crossfades (click-free).
    Segment time stretch with per segment slowdown.
    """
    seg_sec  = _pick(intensity, 7, 6, 5)   # slightly longer segments for speed
    seg_len  = max(1, int(sr * seg_sec))
    rate     = 1.0
    dec      = _pick(intensity, 0.97, 0.95, 0.92)  # per segment slowdown
    xfade_ms = _pick(intensity, 25, 35, 45)       

    pieces = []
    for i in range(0, len(y), seg_len):
        chunk = y[i:i + seg_len]
        if len(chunk) < 1024:
            break
        stretched = librosa.effects.time_stretch(chunk, rate=max(0.35, rate))
        pieces.append(stretched)
        rate *= dec

    if not pieces:
        return y

    out = pieces[0]
    for p in pieces[1:]:
        out = _xfade_join(out, p, sr, ms=xfade_ms)

    out = _gentle_lpf(out, sr, cutoff=_pick(intensity, 15000, 12000, 9000))
    out = _soft_edges(out, sr, edge_ms=140)
    return out
