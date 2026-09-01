# TRADATALA MusicDirector DJ tester

The standalone DJ tester is the authority for cue discovery, listening review,
and transport proof. It is deliberately not connected to gameplay yet.

Open `res://debug/MusicLoopAudition.tscn` and run the scene with F6.

## The contract

TRADATALA keeps each original WAV intact. The DJ system may:

- audition any mined, bar-aligned candidate without approving it;
- hold an approved cue indefinitely using exact sample boundaries;
- release a held cue into the original authored audio;
- catch the next reachable approved cue when the source reaches it;
- finish the current loop pass and jump backward for a reprise;
- hard-jump to an approved cue for an explicit DJ moment;
- release all looping and play the original source ending.

The controller duplicates the imported `AudioStreamWAV` before changing loop
fields. It never edits the source asset and never manufactures transition audio.

## Review workflow

1. Pick a track.
2. Start with **Audition shortlist**. Use **Every candidate** only when the
   shortlist misses a useful phrase.
3. Double-click a row or use **Audition Loop** to hear the seam repeatedly.
4. Use **Audition + 2-Bar Lead-In** to check the entry into the cue.
5. Give the cue a useful name and write listening notes.
6. Approve it only after the loop, entry, and eventual release all sound valid.
7. Switch to **Approved cue sequence** and test the DJ deck from beginning to
   end: Hold, Release/Catch Next, Reprise, Hard Jump, Release to Ending.

Machine scores are triage, not approval. Short hooks and vocal phrases are
allowed when they survive listening. Whole-track fallback loops remain forbidden.

## Transport rules

- **Release → Catch Next** chooses the first approved cue whose start is
  reachable after the current cue's end. Overlapping candidates are skipped.
- Directly requesting an overlapping cue is rejected because the authored
  timeline cannot reach its start after leaving the current loop. Use a hard
  jump only when that discontinuity is intentional.
- **Finish Loop → Reprise** disables the current loop, waits for its end, then
  jumps to the previous approved cue.
- A move already in progress must finish before another release/reprise request.
- Reaching the natural WAV ending returns the director to `STOPPED`.

## Files

- `assets/audio/ost/ost_timing.json`: measured BeatNet timing for 26 tracks.
- `assets/audio/ost/ost_loops.json`: 6,724 exhaustive candidates and 1,046
  de-duplicated audition candidates.
- `assets/audio/ost/ost_cues.json`: human review decisions; currently no cues
  are approved in the production catalog.
- `audio_system/MusicCueCatalog.gd`: candidate and review authority.
- `audio_system/MusicDirector.gd`: cue audition and DJ transport authority.
- `debug/MusicLoopAudition.tscn`: standalone tester.
- `tools/ost_loop_catalog_smoke.gd`: catalog/schema verification.
- `tools/music_director_smoke.gd`: deterministic tester and transport proof.
- `tools/fixtures/music_director_test_cues.json`: test-only approved sequence;
  it is not a claim that those boundaries passed human listening.

The obsolete section-based tester and the intermediate `MusicLoopPlayer` were
removed. There is now one standalone tester and one transport controller.

## Automated proof

```text
OST_LOOP_CATALOG_SMOKE: PASS tracks=26 exhaustive=true roles=none
MUSIC_DIRECTOR_SMOKE: PASS audition approval hold release catch reprise jump finish
```

These checks prove catalog coverage, review persistence, exact sample-boundary
configuration, state transitions, source-preserving forward travel, backward
reprise timing, and tester wiring. They cannot prove that a seam sounds good.
That decision remains human listening work inside the tester.

## Scope boundary

Do not wire gameplay actions to `MusicDirector` until the tester has a real,
listening-approved cue sequence for the target track. The current in-game music
path remains untouched during this tester-first pass.
