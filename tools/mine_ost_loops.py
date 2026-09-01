#!/usr/bin/env python3
"""Mine bar-aligned loop candidates across every complete bar of every OST WAV.

BeatNet downbeats are the timing grid. The miner does not assign narrative
roles, divide tracks into mandatory sections, or declare source material to be
a transition. Every plausible phrase window is retained for listening QA.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import wave
from pathlib import Path
from typing import Any, Dict, Iterable, List, Sequence, Tuple

import numpy as np


SCHEMA = "tradatala.ost_loops.v1"
FRAME_SIZE = 4096
HOP_SIZE = 2048
EPSILON = 1.0e-9
PHRASE_LENGTHS = (2, 4, 8, 12, 16, 24, 32)
BAND_EDGES_HZ = np.asarray(
    [0.0, 60.0, 120.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0, 22050.0],
    dtype=np.float64,
)
BOUNDARY_WINDOW_SAMPLES = 8192
MAX_DISTINCT_CANDIDATES = 64
MAX_DISTINCT_PER_LENGTH = 8


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timing-catalog", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--output-json", type=Path, required=True)
    parser.add_argument("--output-report", type=Path, required=True)
    return parser.parse_args()


def read_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"Expected JSON object: {path}")
    return value


def finite(value: float, digits: int = 6) -> float:
    return round(float(value), digits) if math.isfinite(float(value)) else 0.0


def sample_index(seconds: float, sample_rate: int, frame_count: int) -> int:
    return max(0, min(frame_count, int(round(seconds * sample_rate))))


def read_wav(path: Path) -> Tuple[np.ndarray, int, int, int, int]:
    with wave.open(str(path), "rb") as wav_file:
        channels = wav_file.getnchannels()
        width = wav_file.getsampwidth()
        sample_rate = wav_file.getframerate()
        frame_count = wav_file.getnframes()
        payload = wav_file.readframes(frame_count)

    if width == 1:
        samples = (np.frombuffer(payload, dtype=np.uint8).astype(np.float32) - 128.0) / 128.0
    elif width == 2:
        samples = np.frombuffer(payload, dtype="<i2").astype(np.float32) / 32768.0
    elif width == 3:
        raw = np.frombuffer(payload, dtype=np.uint8)
        packed = raw.reshape(-1, 3).astype(np.int32)
        samples = packed[:, 0] | (packed[:, 1] << 8) | (packed[:, 2] << 16)
        samples = np.where((samples & (1 << 23)) != 0, samples - (1 << 24), samples)
        samples = samples.astype(np.float32) / float(1 << 23)
    elif width == 4:
        samples = np.frombuffer(payload, dtype="<i4").astype(np.float32) / float(1 << 31)
    else:
        raise ValueError(f"Unsupported {width * 8}-bit WAV: {path}")

    if samples.size != frame_count * channels:
        raise ValueError(f"Truncated WAV payload: {path}")
    if channels > 1:
        samples = samples.reshape(frame_count, channels).mean(axis=1)
    return np.asarray(samples, dtype=np.float32).reshape(frame_count), channels, width, sample_rate, frame_count


def make_bars(timing: Dict[str, Any], sample_rate: int, frame_count: int, duration: float) -> List[Dict[str, Any]]:
    downbeats = [
        float(row["time_seconds"])
        for row in timing.get("downbeats", [])
        if isinstance(row, dict) and "time_seconds" in row
    ]
    if len(downbeats) < 2:
        downbeats = [
            float(row["time_seconds"])
            for row in timing.get("beats", [])
            if isinstance(row, dict) and int(row.get("beat_number", 0)) == 1
        ]
    downbeats = sorted(max(0.0, min(duration, value)) for value in downbeats)
    beats_per_bar = max(1, int(timing.get("beats_per_bar", 4)))
    bars: List[Dict[str, Any]] = []
    for index, (start, end) in enumerate(zip(downbeats[:-1], downbeats[1:])):
        if end <= start + 1.0e-4:
            continue
        start_sample = sample_index(start, sample_rate, frame_count)
        end_sample = sample_index(end, sample_rate, frame_count)
        if end_sample <= start_sample:
            continue
        bars.append(
            {
                "bar_index": index,
                "beat_start_index": index * beats_per_bar,
                "beat_end_index": (index + 1) * beats_per_bar,
                "start_seconds": finite(start),
                "end_seconds": finite(end),
                "start_sample": start_sample,
                "end_sample": end_sample,
            }
        )
    return bars


def frame_feature(frame: np.ndarray, sample_rate: int, window: np.ndarray, frequencies: np.ndarray) -> np.ndarray:
    if frame.size < FRAME_SIZE:
        frame = np.pad(frame, (0, FRAME_SIZE - frame.size))
    else:
        frame = frame[:FRAME_SIZE]
    spectrum = np.fft.rfft(frame * window)
    power = np.square(np.abs(spectrum)).astype(np.float64)
    total_power = float(np.sum(power)) + EPSILON
    rms = math.sqrt(float(np.mean(np.square(frame))) + EPSILON)
    bands: List[float] = []
    for lower, upper in zip(BAND_EDGES_HZ[:-1], BAND_EDGES_HZ[1:]):
        mask = (frequencies >= lower) & (frequencies < upper)
        bands.append(math.log10(float(np.mean(power[mask])) + EPSILON) if np.any(mask) else math.log10(EPSILON))
    centroid = float(np.sum(power * frequencies) / total_power) / max(sample_rate / 2.0, 1.0)
    spread = math.sqrt(
        float(np.sum(power * np.square(frequencies / max(sample_rate / 2.0, 1.0) - centroid)) / total_power)
    )
    return np.asarray([math.log10(rms), *bands, centroid, spread], dtype=np.float64)


def extract_bar_features(samples: np.ndarray, bars: Sequence[Dict[str, Any]], sample_rate: int) -> np.ndarray:
    window = np.hanning(FRAME_SIZE).astype(np.float64)
    frequencies = np.fft.rfftfreq(FRAME_SIZE, d=1.0 / sample_rate)
    rows: List[np.ndarray] = []
    for bar in bars:
        region = samples[int(bar["start_sample"]) : int(bar["end_sample"])]
        starts = list(range(0, max(1, region.size - FRAME_SIZE + 1), HOP_SIZE))[:48]
        frames = [frame_feature(region[offset : offset + FRAME_SIZE], sample_rate, window, frequencies) for offset in starts]
        rows.append(np.mean(np.asarray(frames), axis=0))
    return np.asarray(rows, dtype=np.float64)


def robust_standardize(features: np.ndarray) -> np.ndarray:
    median = np.median(features, axis=0)
    mad = np.median(np.abs(features - median), axis=0)
    scale = np.where(1.4826 * mad > EPSILON, 1.4826 * mad, np.std(features, axis=0))
    scale = np.where(scale > EPSILON, scale, 1.0)
    return (features - median) / scale


def similarity(left: np.ndarray, right: np.ndarray) -> float:
    left_norm = float(np.linalg.norm(left))
    right_norm = float(np.linalg.norm(right))
    if left_norm <= EPSILON or right_norm <= EPSILON:
        return 0.5
    cosine = float(np.dot(left, right) / (left_norm * right_norm))
    return max(0.0, min(1.0, (cosine + 1.0) * 0.5))


def boundary_metrics(samples: np.ndarray, start_sample: int, end_sample: int) -> Dict[str, float]:
    size = min(BOUNDARY_WINDOW_SAMPLES, start_sample, len(samples) - end_sample, end_sample - start_sample)
    if size < 32:
        return {"waveform_correlation": 0.0, "boundary_jump": 1.0, "boundary_rms_delta_db": 99.0}
    head = np.asarray(samples[start_sample : start_sample + size], dtype=np.float64)
    tail = np.asarray(samples[end_sample - size : end_sample], dtype=np.float64)
    correlation = float(np.corrcoef(tail, head)[0, 1]) if np.std(tail) > EPSILON and np.std(head) > EPSILON else 0.0
    head_rms = math.sqrt(float(np.mean(np.square(head))) + EPSILON)
    tail_rms = math.sqrt(float(np.mean(np.square(tail))) + EPSILON)
    return {
        "waveform_correlation": finite(correlation),
        "boundary_jump": finite(abs(float(samples[end_sample - 1]) - float(samples[start_sample]))),
        "boundary_rms_delta_db": finite(abs(20.0 * math.log10(head_rms / tail_rms))),
    }


def candidate_for(
    track_id: str,
    start_bar: int,
    bar_count: int,
    bars: Sequence[Dict[str, Any]],
    raw: np.ndarray,
    normalized: np.ndarray,
    samples: np.ndarray,
) -> Dict[str, Any]:
    end_bar = start_bar + bar_count
    half = bar_count // 2
    repetition = float(np.mean([similarity(normalized[start_bar + offset], normalized[start_bar + half + offset]) for offset in range(half)]))
    edge_width = min(2, half)
    seam = 0.5 * similarity(normalized[start_bar], normalized[end_bar - 1])
    seam += 0.5 * similarity(
        np.mean(normalized[start_bar : start_bar + edge_width], axis=0),
        np.mean(normalized[end_bar - edge_width : end_bar], axis=0),
    )
    adjacent = [similarity(normalized[index - 1], normalized[index]) for index in range(start_bar + 1, end_bar)]
    internal = float(np.mean(adjacent)) if adjacent else 0.5
    energy_delta = abs(float(raw[start_bar, 0]) - float(raw[end_bar - 1, 0]))
    energy_balance = math.exp(-energy_delta / 1.5)
    start_seconds = float(bars[start_bar]["start_seconds"])
    end_seconds = float(bars[end_bar - 1]["end_seconds"])
    start_sample = int(bars[start_bar]["start_sample"])
    end_sample = int(bars[end_bar - 1]["end_sample"])
    waveform = boundary_metrics(samples, start_sample, end_sample)
    waveform_score = max(0.0, min(1.0, (float(waveform["waveform_correlation"]) + 1.0) * 0.5))
    length_score = 0.65 if bar_count == 2 else 1.0 if bar_count in (8, 16, 32) else 0.88
    score = 0.32 * repetition + 0.25 * seam + 0.18 * internal + 0.10 * energy_balance + 0.08 * waveform_score + 0.07 * length_score
    if score >= 0.72 and repetition >= 0.68 and seam >= 0.62:
        hint = "strong"
    elif score >= 0.58:
        hint = "promising"
    else:
        hint = "exploratory"
    candidate_id = f"{track_id}_bars_{start_bar + 1:03d}_{end_bar:03d}"
    return {
        "candidate_id": candidate_id,
        "display_name": f"Bars {start_bar + 1}-{end_bar} ({bar_count} bars)",
        "manual_status": "unreviewed",
        "machine_hint": hint,
        "bar_start": start_bar,
        "bar_end": end_bar,
        "bar_count": bar_count,
        "start_seconds": finite(start_seconds),
        "end_seconds": finite(end_seconds),
        "duration_seconds": finite(end_seconds - start_seconds),
        "start_sample": start_sample,
        "end_sample": end_sample,
        "score": finite(score),
        "repetition_similarity": finite(repetition),
        "seam_similarity": finite(seam),
        "internal_consistency": finite(internal),
        "energy_balance": finite(energy_balance),
        **waveform,
        "loop_mode": "forward",
        "whole_track": False,
        "manual_listening_required": True,
    }


def overlap_ratio(left: Dict[str, Any], right: Dict[str, Any]) -> float:
    overlap = max(0, min(int(left["bar_end"]), int(right["bar_end"])) - max(int(left["bar_start"]), int(right["bar_start"])))
    return overlap / float(max(1, min(int(left["bar_count"]), int(right["bar_count"]))))


def choose_distinct(candidates: Sequence[Dict[str, Any]]) -> List[str]:
    selected: List[Dict[str, Any]] = []
    counts_by_length: Dict[int, int] = {}
    for candidate in candidates:
        bar_count = int(candidate["bar_count"])
        same_length = [other for other in selected if int(other["bar_count"]) == bar_count]
        if counts_by_length.get(bar_count, 0) < MAX_DISTINCT_PER_LENGTH and all(
            overlap_ratio(candidate, other) < 0.70 for other in same_length
        ):
            selected.append(candidate)
            counts_by_length[bar_count] = counts_by_length.get(bar_count, 0) + 1
            if len(selected) >= MAX_DISTINCT_CANDIDATES:
                break
    selected.sort(key=lambda row: (-float(row["score"]), int(row["bar_start"]), -int(row["bar_count"])))
    return [str(candidate["candidate_id"]) for candidate in selected]


def analyze_track(track_id: str, timing: Dict[str, Any], source_root: Path) -> Dict[str, Any]:
    source_filename = str(timing.get("source_filename", ""))
    source_path = source_root / Path(str(timing.get("project_path", source_filename))).name
    if not source_path.is_file():
        source_path = source_root / source_filename
    if not source_path.is_file():
        raise FileNotFoundError(f"Missing source WAV for {track_id}: {source_path}")
    samples, channels, width, sample_rate, frame_count = read_wav(source_path)
    duration = frame_count / float(sample_rate)
    bars = make_bars(timing, sample_rate, frame_count, duration)
    if len(bars) < 2:
        raise ValueError(f"Not enough complete bars for {track_id}")
    raw = extract_bar_features(samples, bars, sample_rate)
    normalized = robust_standardize(raw)
    candidates = [
        candidate_for(track_id, start, length, bars, raw, normalized, samples)
        for length in PHRASE_LENGTHS
        if length <= len(bars)
        for start in range(0, len(bars) - length + 1)
    ]
    candidates.sort(key=lambda row: (-float(row["score"]), int(row["bar_start"]), -int(row["bar_count"])))
    for rank, candidate in enumerate(candidates, start=1):
        candidate["machine_rank"] = rank
    distinct_ids = choose_distinct(candidates)
    return {
        "track_id": track_id,
        "source_filename": source_filename,
        "project_path": str(timing.get("project_path", f"res://assets/audio/ost/{source_path.name}")),
        "duration_seconds": finite(duration),
        "sample_rate": sample_rate,
        "frame_count": frame_count,
        "channels": channels,
        "sample_width_bits": width * 8,
        "tempo_bpm": finite(float(timing.get("estimated_bpm", 0.0))),
        "beats_per_bar": int(timing.get("beats_per_bar", 4)),
        "bars": bars,
        "complete_bar_count": len(bars),
        "candidate_count": len(candidates),
        "distinct_candidate_count": len(distinct_ids),
        "distinct_candidate_ids": distinct_ids,
        "loop_candidates": candidates,
        "whole_track_loop_allowed": False,
        "role_labels_assigned": False,
        "manual_listening_required": True,
    }


def make_report(catalog: Dict[str, Any]) -> str:
    lines = [
        "# TRADATALA exhaustive loop mining",
        "",
        "Every complete bar-aligned phrase window is retained. Machine scores order auditions; they do not approve or reject music.",
        "Narrative roles and transitions are intentionally unassigned.",
        "",
        "| Track | Bars | All candidates | Distinct audition set | Top candidate |",
        "|---|---:|---:|---:|---|",
    ]
    for track_id, track in catalog["tracks"].items():
        top = track["loop_candidates"][0]
        lines.append(
            f"| `{track_id}` | {track['complete_bar_count']} | {track['candidate_count']} | "
            f"{track['distinct_candidate_count']} | {top['display_name']} score={top['score']:.3f} |"
        )
    lines.extend(["", "All candidates begin with `manual_status: unreviewed`.", ""])
    return "\n".join(lines)


def write_text(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8", newline="\n")


def main() -> int:
    args = parse_args()
    timing_catalog = read_json(args.timing_catalog)
    tracks = timing_catalog.get("tracks", {})
    if not isinstance(tracks, dict) or not tracks:
        raise ValueError("Timing catalog contains no tracks")
    output_tracks = {track_id: analyze_track(track_id, timing, args.source_root) for track_id, timing in tracks.items()}
    catalog = {
        "schema": SCHEMA,
        "generated_at_utc": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "timing_catalog": "res://assets/audio/ost/ost_timing.json",
        "analysis_policy": "exhaustive_bar_aligned_windows_no_role_labels_no_automatic_rejection",
        "phrase_lengths_bars": list(PHRASE_LENGTHS),
        "whole_track_loop_allowed": False,
        "track_count": len(output_tracks),
        "tracks": output_tracks,
    }
    write_text(args.output_json, json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    write_text(args.output_report, make_report(catalog))
    total = sum(int(track["candidate_count"]) for track in output_tracks.values())
    distinct = sum(int(track["distinct_candidate_count"]) for track in output_tracks.values())
    print(f"OST_LOOP_MINING: PASS tracks={len(output_tracks)} candidates={total} distinct={distinct}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
