# TRADATALA OST loop audition

The active analysis scope is the original 26-track soundtrack. No V2 material
is included in this catalog or tester.

## Policy

- BeatNet downbeats provide the timing grid.
- Every complete 2, 4, 8, 12, 16, 24, and 32-bar window is retained.
- Machine scores order listening work; they do not approve or reject loops.
- Tracks have no required section count.
- Candidates receive no Event, Deal, transition, or time-of-day label.
- A source interval may be useful both as a loop and as forward-moving material.
- Every candidate begins with `manual_status: unreviewed`.
- Whole-track fallback loops remain forbidden.

## Active files

- `assets/audio/ost/ost_timing.json`: measured BeatNet timing for 26 tracks.
- `assets/audio/ost/ost_loops.json`: exhaustive candidate catalog.
- `assets/audio/ost/ost_loops_report.md`: compact generation summary.
- `tools/mine_ost_loops.py`: offline whole-track candidate miner.
- `audio_system/MusicLoopPlayer.gd`: isolated audition playback.
- `debug/MusicLoopAudition.tscn`: listening tester.

## Tester

Open `res://debug/MusicLoopAudition.tscn` and run the scene with F6.

The default list is a de-duplicated audition set balanced across phrase lengths.
Choose **Every candidate** to inspect all overlapping bar-aligned windows.

- **Audition Loop** starts directly at the selected boundary.
- **Audition + 2-Bar Lead-In** provides musical context before looping.
- **Play Source From Start** plays without an automatic loop.
- **Release Loop** disables looping and lets the original WAV continue forward.
- **Stop** stops playback.

## Validation

The clean rebuild produced 6,724 exhaustive candidates and 1,046 distinct
audition candidates across 26 tracks.

```text
OST_LOOP_CATALOG_SMOKE: PASS tracks=26 exhaustive=true roles=none
MUSIC_LOOP_PLAYER_SMOKE: PASS tracks=26 exhaustive-audition=true
```

These checks prove catalog coverage, sample-boundary transport, and tester
loading. They do not prove that a loop sounds good; live listening remains the
authority.

The earlier section-based files remain temporarily present only as rollback
material and are not read by the new loop player or audition scene.
