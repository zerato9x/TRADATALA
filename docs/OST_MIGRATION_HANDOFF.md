# TRADATALA OST migration handoff

Date: 2026-09-01  
Project: `G:\PHOM\TRADATALA`  
Godot tested: 4.7.1

## Executive status

This is a handoff of the audio work and its limits. It is not a claim that the
current soundtrack data is production-ready.

The important distinction is:

1. The V1 tracks are generally technically loopable according to the existing
   timing/candidate data, and the user reports that most of them do loop.
2. Technical loopability does not mean the composition follows the intended
   TRADATALA musical vision. That creative requirement was not audited by the
   V1 tooling.
3. New tracks must enter the primary catalog through measured BeatNet timing
   and audio-derived structural analysis, never through authored prompt layout.

No WAV files were edited, trimmed, normalized, rendered, or copied by this
work.

## User's actual audio requirement

The composition prompt is an expected arrangement brief, not proof of what a
render contains. The rendered audio must be audited independently.

For every track, keep these questions separate:

- Does the audio contain the intended sections and transitions?
- Is a section locally stable and musically suitable for looping?
- Does the loop boundary actually sound acceptable when repeated?
- Does the composition fit the intended instrumentation, energy, motif, and
  phase role?

An Event section is expected to be simple but loopable. It does **not** need to
use all 12 authored bars. The correct rule is: find a short, locally stable,
bar-aligned Event window in the audio; if no such window exists, mark the
section as having no safe candidate. Never create a loop only because the
prompt names an Event.

## Original V1 work

The original V1 source folder was:

`G:\PHOM\Sound\TRADATALA\_OST`

The V1 pipeline used the existing BeatNet downbeat timing catalog and produced
section-local structure data. The intended policy was:

- sections remain chronological;
- candidates stay inside their section's stable core;
- loop boundaries use exact sample positions when available;
- original source intervals outside loop cores remain one-shot transitions;
- whole-track looping is forbidden;
- a section may have no candidate and can be skipped.

The V1 catalog contains 26 tracks. The user's current creative assessment is
that most V1 tracks loop mechanically, but most do not follow the desired
composition vision. This means the V1 catalog is useful as a technical
prototype, not as proof that the OST is compositionally correct.

### V1 files

| File | Purpose | Migration status |
|---|---|---|
| `assets/audio/ost/ost_timing.json` | BeatNet/downbeat timing catalog | Useful timing input; verify paths on the new machine |
| `assets/audio/ost/ost_structure.json` | 27-track section/candidate catalog, schema `tradatala.ost_structure.v2` | Eight-state structural audit; creative fit still requires listening |
| `assets/audio/ost/ost_timing_report.md` | Timing report | Evidence/report only |
| `assets/audio/ost/ost_structure_report.md` | Structural/candidate report | Evidence/report only |
| `tools/analyze_ost_structure.py` | Structure/candidate generation tool | Reusable only after reviewing its scoring assumptions |
| `tools/ost_structure_catalog_smoke.gd` | Catalog schema/content smoke test | Reusable parser/catalog check |

The current primary catalog is untracked in the working tree. Migration must
copy or commit it explicitly; do not assume it exists in Git history.

## Runtime implementation

### Controller

`audio_system/MusicDirector.gd`

`MusicDirector` is the reusable controller used by the tester. It loads the
primary structure catalog and can merge supplemental catalogs. It loads WAVs,
duplicates the imported `AudioStreamWAV` as a runtime resource, and does not
mutate the shared imported asset.

Core public API:

```gdscript
play_track(track_id: String) -> bool
request_phase(section_index: int) -> bool
set_candidate_rank(section_index: int, rank: int) -> bool
release_loop() -> bool
finish_track() -> bool
stop() -> void
```

Useful catalog/debug API currently exposed:

```gdscript
load_catalog(path: String = "") -> bool
get_track_ids() -> Array[String]
get_track(track_id: String) -> Dictionary
get_section_count(track_id: String = "") -> int
get_section(track_id: String, section_index: int) -> Dictionary
get_selected_candidate_rank(section_index: int) -> int
get_candidate_count(track_id: String, section_index: int) -> int
get_candidate(track_id: String, section_index: int, rank: int) -> Dictionary
approximate_bar_index() -> int
get_debug_snapshot() -> Dictionary
```

States:

```text
STOPPED
PLAYING_TO_LOOP
LOOPING
RELEASING_TO_NEXT
PLAYING_TO_NEXT_LOOP
FINISHING
PLAYING_FORWARD
```

Important public debug fields include:

```text
current_track_id
current_section_index
current_candidate_rank
current_loop_start / current_loop_end
current_loop_start_sample / current_loop_end_sample
current_playback_position
pending_section_index / pending_candidate_rank
stream_length_seconds
state
last_error
```

### Current phase behavior

The controller's intended source-preserving behavior is:

1. Start the original WAV at position zero.
2. Continue forward until the selected loop start.
3. Configure the runtime WAV loop at the JSON sample boundaries.
4. On a phase request, disable the current loop at its next loop end.
5. Continue forward through the original WAV to the next candidate start.
6. Enable the next section loop there.
7. On Finish, release the active loop and play to the natural source ending.

The implementation does not create transition WAVs and does not jump directly
from one section's loop to another section's loop.

### Godot limitation and validation limit

Godot's `AudioStreamWAV` forward loop is a hard boundary. It provides
`loop_begin`, `loop_end`, and `loop_mode`, but it does not prove that two
musical regions are a seamless perceptual seam. The current controller has no
crossfade and no waveform repair, by design.

The controller changes the runtime stream's loop fields while playback is
already running. The smoke test showed that Godot did wrap playback, but this
does not establish that the boundary is musically or sonically acceptable.

`AudioStreamPlayer.finished` is not a loop-quality signal and does not fire for
ordinary forward-loop wraps. Playback position is read with
`AudioServer.get_time_since_last_mix()` added for a more current debug value.

## Tester

Files:

```text
debug/MusicReactiveTest.tscn
debug/MusicReactiveTest.gd
```

The project main scene was not replaced. To open the tester in Godot:

1. Open `res://debug/MusicReactiveTest.tscn`.
2. Run the scene with F6.
3. The default track is `tiger_2` when available.

Controls:

- Track dropdown: select one of the merged catalog tracks.
- Play From Start: start the selected source and request the selected section.
- Previous Section / Next Section: change the tester selection.
- Request Selected Section: queue that section without an immediate jump.
- Release Loop: release the active loop and continue source playback.
- Finish Track: release the active loop and continue through the source ending.
- Candidate rank selector: choose a candidate before requesting that section.

The tester loads all 27 entries directly from the primary structure catalog.
`pig_3` is a project-local WAV analyzed through the same timing and structure
pipeline as the original tracks.

## New primary Pig track

`pig_3` was measured with BeatNet offline/DBN and then passed through the same
audio-derived structural analyzer used by the original catalog.

- duration: 202.76 seconds;
- format: 48,000 Hz, stereo, 16-bit;
- timing: 120 BPM, 4/4, 397 beats and 99 downbeats;
- structure: 98 complete bars, eight detected loop states and seven between-state transitions;
- automatic loop gates: five states accepted, three states rejected;
- whole-track looping remains forbidden.

These measurements do not prove that a loop seam sounds good. Default
candidates still require listening QA.

## Validation already performed

These checks passed:

```text
OST_STRUCTURE_GODOT_SMOKE: PASS schema=v2 tracks=27 vision=8-states unsafe-candidates=rejected
MUSIC_DIRECTOR_SMOKE: PASS tiger_2 source-continuation and analyzed pig_3 verified
```

What those checks prove:

- JSON parses and the primary catalog has 27 tracks;
- BeatNet timing metadata is present;
- candidate and transition fields have the expected shape;
- the tester loads the project-local `pig_3.wav`;
- the controller enters `LOOPING` and playback position wraps;
- a phase request disables the current loop and preserves forward timeline state;
- Finish releases the loop state.

What they do **not** prove:

- that a loop boundary sounds seamless;
- that a candidate is musically repetitive rather than merely feature-similar;
- that a V1 composition follows the intended creative vision;
- that the SUNO prompt was realized in the WAV;
- that every candidate is worth exposing to the player.

The smoke test was therefore too narrow for the user's actual requirement. It
tested transport behavior, not audio quality or creative correctness.

## Recommended migration rules

Use these rules in the next implementation or analysis environment:

1. Keep prompt expectations, measured audio structure, and manual creative
   annotations in separate fields/files.
2. Use BeatNet/downbeat timing for bar alignment, not for composition labels.
3. Detect sections from the rendered audio first. Do not instantiate all prompt
   sections merely because they were written in the brief.
4. Generate Event candidates only from observed Event-like audio. They may be
   shorter than 12 bars, but must be genuinely repeatable and simple.
5. Rank candidates using both local musical stability and an actual boundary
   continuity test. A low-quality candidate must be rejected, not merely ranked
   lower.
6. If a section has no safe candidate, leave `loop_candidates` empty and allow
   the tester to skip it.
7. Keep one-shot transitions as untouched source intervals between stable
   sections.
8. Treat “mechanically loops” and “matches the composition vision” as separate
   pass/fail results.
9. Require manual listening at every default rank-1 boundary before calling a
   track ready.
10. Do not use a whole-track loop as a fallback.

A useful future schema addition would be separate annotations such as:

```json
{
  "detected_from_audio": true,
  "creative_fit": "pass|fail|unknown",
  "loop_quality": "safe|unsafe|unknown",
  "manual_listening_note": "..."
}
```

Those fields should never be inferred from the prompt alone.

## Scoped file inventory for migration

Copy only the audio-system/tester scope below first. The working tree also
contains unrelated untracked environment art and other WIP; do not blanket-copy
or clean the entire tree without reviewing it.

```text
audio_system/MusicDirector.gd
debug/MusicReactiveTest.gd
debug/MusicReactiveTest.tscn
tools/music_director_smoke.gd
tools/ost_structure_catalog_smoke.gd
assets/audio/ost/ost_timing.json
assets/audio/ost/ost_structure.json
assets/audio/ost/ost_timing_report.md
assets/audio/ost/ost_structure_report.md
```

The new primary asset and reusable single-track timing tool are:

```text
assets/audio/ost/pig_3.wav
tools/analyze_ost_timing_track.py
```
