from __future__ import annotations

from dataclasses import dataclass
from math import sqrt

from pydub import AudioSegment


MIN_TEMPO_BPM = 40.0
MAX_TEMPO_BPM = 240.0
ANALYSIS_RATE = 11025
FRAME_SIZE = 1024
HOP_SIZE = 512


@dataclass(frozen=True)
class TempoEstimate:
    """Small confidence-tagged BPM estimate for uploaded sample loops."""

    bpm: float
    confidence: float


def detect_tempo(audio: AudioSegment) -> TempoEstimate | None:
    """Estimate tempo from transient energy without adding heavy audio-analysis dependencies."""

    if audio.duration_seconds < 1.2:
        return None

    analysis_audio = audio.set_channels(1).set_frame_rate(ANALYSIS_RATE).set_sample_width(2)
    samples = analysis_audio.get_array_of_samples()
    if len(samples) < FRAME_SIZE * 4:
        return None

    energies = _frame_energies(samples)
    if len(energies) < 12:
        return None

    onsets = _onset_envelope(energies)
    if sum(onsets) <= 0:
        return None

    min_lag = max(2, round((60 / MAX_TEMPO_BPM) * ANALYSIS_RATE / HOP_SIZE))
    max_lag = min(len(onsets) // 2, round((60 / MIN_TEMPO_BPM) * ANALYSIS_RATE / HOP_SIZE))
    if max_lag <= min_lag:
        return None

    best_bpm = 0.0
    best_score = 0.0
    for lag in range(min_lag, max_lag + 1):
        bpm = (60 * ANALYSIS_RATE) / (HOP_SIZE * lag)
        raw_score = _normalized_autocorrelation(onsets, lag)
        weighted_score = raw_score * _tempo_preference(bpm)
        if weighted_score > best_score:
            best_score = weighted_score
            best_bpm = bpm

    confidence = min(1.0, max(0.0, best_score))
    if best_bpm <= 0 or confidence < 0.08:
        return None

    return TempoEstimate(bpm=round(best_bpm, 1), confidence=round(confidence, 2))


def _frame_energies(samples) -> list[float]:
    energies: list[float] = []
    last_start = len(samples) - FRAME_SIZE
    for start in range(0, max(0, last_start), HOP_SIZE):
        total = 0
        for sample in samples[start : start + FRAME_SIZE]:
            total += abs(sample)
        energies.append(total / FRAME_SIZE)
    return energies


def _onset_envelope(energies: list[float]) -> list[float]:
    deltas = [max(0.0, energies[index] - energies[index - 1]) for index in range(1, len(energies))]
    average = sum(deltas) / len(deltas)
    return [max(0.0, delta - average * 0.5) for delta in deltas]


def _normalized_autocorrelation(values: list[float], lag: int) -> float:
    left_power = 0.0
    right_power = 0.0
    product = 0.0
    for index in range(lag, len(values)):
        left = values[index]
        right = values[index - lag]
        product += left * right
        left_power += left * left
        right_power += right * right
    denominator = sqrt(left_power * right_power)
    if denominator <= 0:
        return 0.0
    return product / denominator


def _tempo_preference(bpm: float) -> float:
    # Close autocorrelation peaks often appear at half or double time; favor playable Live ranges.
    if 80 <= bpm <= 180:
        return 1.0
    if 60 <= bpm < 80 or 180 < bpm <= 220:
        return 0.92
    return 0.82
