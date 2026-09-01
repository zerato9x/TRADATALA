#!/usr/bin/env python3
"""Analyze one WAV with BeatNet and upsert it into the OST timing catalog."""

from __future__ import annotations

import argparse
import json
import math
import os
import time
import wave
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-wav", type=Path, required=True)
    parser.add_argument("--track-id", required=True)
    parser.add_argument("--project-path", required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--output-report", type=Path, required=True)
    parser.add_argument("--cache-root", type=Path, required=True)
    return parser.parse_args()


def rounded(value: float, digits: int = 6) -> float:
    return float(f"{value:.{digits}f}")


def wav_info(path: Path) -> dict:
    with wave.open(str(path), "rb") as source:
        sample_rate = source.getframerate()
        frame_count = source.getnframes()
        return {
            "channels": source.getnchannels(),
            "sample_width_bits": source.getsampwidth() * 8,
            "sample_rate": sample_rate,
            "frame_count": frame_count,
            "duration_seconds": frame_count / float(sample_rate),
        }


def finite_rows(output, duration_seconds: float):
    import numpy as np

    rows = np.asarray(output, dtype=float)
    if rows.ndim == 1:
        rows = rows.reshape((-1, 2))
    if rows.ndim != 2 or rows.shape[1] < 2:
        raise ValueError(f"BeatNet returned an unexpected shape: {rows.shape}")
    rows = rows[:, :2]
    mask = np.isfinite(rows).all(axis=1)
    mask &= rows[:, 0] >= 0.0
    mask &= rows[:, 0] <= duration_seconds + 0.25
    rows = rows[mask]
    rows = rows[np.argsort(rows[:, 0], kind="stable")]
    if rows.size == 0:
        raise ValueError("BeatNet returned no valid beat rows")
    return rows


def mode_or(values: list[int], fallback: int) -> int:
    if not values:
        return fallback
    counts = Counter(values)
    return int(sorted(counts.items(), key=lambda item: (-item[1], item[0]))[0][0])


def analyze_rows(rows, audio: dict) -> dict:
    import numpy as np

    duration = float(audio["duration_seconds"])
    beat_times = rows[:, 0]
    beat_numbers = np.rint(rows[:, 1]).astype(int)
    intervals = np.diff(beat_times)
    usable = intervals[(intervals >= 0.20) & (intervals <= 2.00)]
    if usable.size == 0:
        usable = intervals[intervals > 0.0]
    if usable.size == 0:
        raise ValueError("BeatNet returned fewer than two usable beats")

    beat_interval = float(np.median(usable))
    bpm = 60.0 / beat_interval
    downbeat_mask = beat_numbers == 1
    downbeat_times = beat_times[downbeat_mask]
    if downbeat_times.size == 0:
        raise ValueError("BeatNet returned no downbeats")

    downbeat_indices = np.flatnonzero(downbeat_mask)
    bar_spans = np.diff(downbeat_indices)
    bar_spans = bar_spans[(bar_spans >= 2) & (bar_spans <= 8)]
    fallback_meter = int(np.max(beat_numbers)) if beat_numbers.size else 4
    beats_per_bar = max(2, min(8, mode_or([int(value) for value in bar_spans], fallback_meter)))
    downbeat_intervals = np.diff(downbeat_times)

    sample_rate = int(audio["sample_rate"])
    beats = [
        {
            "time_seconds": rounded(float(when)),
            "sample": int(round(float(when) * sample_rate)),
            "beat_number": int(number),
            "is_downbeat": bool(number == 1),
        }
        for when, number in zip(beat_times, beat_numbers)
    ]
    downbeats = [
        {"time_seconds": rounded(float(when)), "sample": int(round(float(when) * sample_rate))}
        for when in downbeat_times
    ]
    first_downbeat = float(downbeat_times[0])
    tail_guard = min(0.50, max(0.05, beat_interval * 0.50))
    eligible_ends = downbeat_times[downbeat_times <= duration - tail_guard]
    loop_end = float(eligible_ends[-1] if eligible_ends.size else downbeat_times[-1])
    loop_length = max(0.0, loop_end - first_downbeat)
    loop_bars = max(1, int(round(loop_length / max(beat_interval * beats_per_bar, 1.0e-9))))

    beat_cv = float(np.std(usable) / max(np.mean(usable), 1.0e-9))
    downbeat_cv = 0.0
    if downbeat_intervals.size:
        downbeat_cv = float(np.std(downbeat_intervals) / max(np.mean(downbeat_intervals), 1.0e-9))
    quality = "usable"
    if len(beats) < 8 or bpm < 45.0 or bpm > 240.0:
        quality = "review"
    elif beat_cv > 0.15 or downbeat_cv > 0.20:
        quality = "variable_tempo_review"

    return {
        "duration_seconds": rounded(duration),
        "channels": int(audio["channels"]),
        "sample_width_bits": int(audio["sample_width_bits"]),
        "sample_rate": sample_rate,
        "frame_count": int(audio["frame_count"]),
        "beat_count": len(beats),
        "downbeat_count": len(downbeats),
        "estimated_bpm": rounded(bpm, 4),
        "estimated_bpm_range": [
            rounded(60.0 / float(np.percentile(usable, 95)), 4),
            rounded(60.0 / float(np.percentile(usable, 5)), 4),
        ],
        "beat_interval_seconds": rounded(beat_interval),
        "beats_per_bar": beats_per_bar,
        "meter_label": f"{beats_per_bar}/4",
        "first_beat_seconds": rounded(float(beat_times[0])),
        "first_downbeat_seconds": rounded(first_downbeat),
        "last_beat_seconds": rounded(float(beat_times[-1])),
        "last_downbeat_seconds": rounded(float(downbeat_times[-1])),
        "beat_interval_cv": rounded(beat_cv, 5),
        "downbeat_interval_cv": rounded(downbeat_cv, 5),
        "analysis_quality": quality,
        "beats": beats,
        "downbeats": downbeats,
        "godot": {
            "loop_mode": "forward",
            "loop_begin_samples": int(round(first_downbeat * sample_rate)),
            "loop_end_samples": int(round(loop_end * sample_rate)),
            "loop_begin_seconds": rounded(first_downbeat),
            "loop_end_seconds": rounded(loop_end),
            "loop_length_seconds": rounded(loop_length),
            "loop_bars": loop_bars,
            "tail_ignored_seconds": rounded(max(0.0, duration - loop_end)),
            "beat_offset_seconds": rounded(first_downbeat),
            "tempo_bpm": rounded(bpm, 4),
            "beats_per_bar": beats_per_bar,
        },
    }


def make_report(catalog: dict) -> str:
    lines = [
        "# TRADATALA OST BeatNet timing catalog",
        "",
        "Generated with BeatNet offline/DBN analysis. Timing is measured from audio; loop seams still require listening QA.",
        "",
        "| Track | Duration | BPM | Meter | Beats | Downbeats | Quality |",
        "| --- | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for track_id, track in catalog["tracks"].items():
        lines.append(
            f"| `{track_id}` | {track['duration_seconds']:.2f}s | {track['estimated_bpm']:.2f} | "
            f"{track['meter_label']} | {track['beat_count']} | {track['downbeat_count']} | {track['analysis_quality']} |"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    if not args.input_wav.is_file():
        raise FileNotFoundError(args.input_wav)
    args.cache_root.mkdir(parents=True, exist_ok=True)
    os.environ["MPLCONFIGDIR"] = str(args.cache_root / "matplotlib")
    os.environ["NUMBA_CACHE_DIR"] = str(args.cache_root / "numba")
    Path(os.environ["MPLCONFIGDIR"]).mkdir(parents=True, exist_ok=True)
    Path(os.environ["NUMBA_CACHE_DIR"]).mkdir(parents=True, exist_ok=True)

    from BeatNet.BeatNet import BeatNet

    started = time.monotonic()
    audio = wav_info(args.input_wav)
    estimator = BeatNet(1, mode="offline", inference_model="DBN", plot=[], thread=False, device="cpu")
    rows = finite_rows(estimator.process(str(args.input_wav)), float(audio["duration_seconds"]))
    track = analyze_rows(rows, audio)
    track.update(
        {
            "track_id": args.track_id,
            "theme_id": args.track_id.rsplit("_", 1)[0],
            "variant": int(args.track_id.rsplit("_", 1)[1]),
            "source_filename": Path(args.project_path).name,
            "project_path": args.project_path,
            "project_file_present": True,
            "beatnet_output_shape": [int(rows.shape[0]), int(rows.shape[1])],
            "analysis_seconds": rounded(time.monotonic() - started, 3),
        }
    )

    catalog = json.loads(args.catalog.read_text(encoding="utf-8"))
    tracks = catalog.setdefault("tracks", {})
    tracks[args.track_id] = track
    catalog["tracks"] = dict(sorted(tracks.items()))
    catalog["generated_at_utc"] = datetime.now(timezone.utc).isoformat()
    catalog["analysis"]["track_count"] = len(tracks)
    catalog["analysis"]["source_folder_label"] = "TRADATALA_OST_PRIMARY"
    args.catalog.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    args.output_report.write_text(make_report(catalog), encoding="utf-8")
    print(
        f"OST_TIMING_TRACK: PASS track={args.track_id} bpm={track['estimated_bpm']:.2f} "
        f"meter={track['meter_label']} beats={track['beat_count']} downbeats={track['downbeat_count']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
