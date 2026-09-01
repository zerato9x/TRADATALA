# TRADATALA checkpoint: Drink targeting reconciliation

Date: 2026-09-01
Status: local checkpoint commit created; remote push pending authorization

This document records the state frozen before the next Drink-rule correction.
The current code is the baseline for the next task; it is not a claim that every
newly stated rule has already been applied.

## Authority decisions

- The current implementation of MOM and U Khan is accepted as correct. The
  pasted source is not authoritative for those two mechanics, so this
  checkpoint does not change their scoring or payout behavior.
- The latest user correction supersedes the current Trà đá implementation:
  Trà đá should increase the current turn's discard allowance by one, and the
  player must be able to use all discards before that turn ends. That correction
  is intentionally recorded as the next follow-up and is not included in this
  frozen baseline.

## Included in this checkpoint

The tracked changes being frozen cover the Drink-source reconciliation and its
targeting presentation:

- Drink effects are kept in the authoritative Deal/Drink layer rather than in
  UI-only code.
- Nhân trần swaps one loose card with one mandatory discard from the current
  Phase, once per Phase, including the final commit window.
- Nước vối recovers a legal card from a table Meld once per Phase without
  unscoring points already banked on that Meld; later extensions score only the
  newly added value.
- Sâm dứa marks up to three loose cards during Phase 1 LAST CALL and preserves
  them only when the following settlement choice is DUMP.
- Mandatory discard records retain Phase/discard provenance and are kept
  separate from Drink-driven card-flow actions.
- The active Drink is the in-world table prop. Clicking it arms targeting, and
  eligible hand, Meld, and discard-history objects receive the shared blue
  target cue. The UI supports partial multi-target selection and canceling
  without spending a charge.
- The runtime scene smoke, core Deal tests, and tutorial smoke cover the
  reconciled Drink behaviors and the target cue wiring.

## Current Trà đá baseline behavior

At this checkpoint, Trà đá still uses the previous selected-loose-card versus
latest-mandatory-discard swap path. This is known to be superseded by the
latest user instruction. The follow-up must remove that swap target requirement,
grant one additional discard in the active turn, keep the turn open while the
available discards remain, and only then resolve/refill the turn normally.

## Verification at checkpoint time

Godot 4.7.1 stable:

- Core Deal suite: ``TRADATALA_TESTS total=51 passed=51 failed=0 skipped=0``
- Runtime scene smoke: ``TRADATALA_SCENE_SMOKE passed``
- Tutorial scene smoke: ``TRADATALA_TUTORIAL_SMOKE passed``
- Tutorial shutdown still reports the known non-failing cleanup warning of two
  leaked ObjectDB instances and one resource in use.
- Connected-editor physical-input proof for the target interaction was not
  rerun in this checkpoint; the automated scene smoke is the acceptance
  evidence currently available.

Commands:

``````powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/run_headless.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/runtime_scene_smoke.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/tutorial_scene_smoke.gd
``````

## Scope and preserved WIP

The checkpoint includes the tracked source, scene, locale, README, asset, and
test changes visible in ``git diff`` at checkpoint creation. These untracked
environment assets were deliberately left out because they were not required
by the Drink reconciliation and were already part of the mixed worktree:

- ``assets/environment/012c71c6-b680-476f-8847-41032a666b96.png`` and import
- ``assets/environment/276b215a-c0c6-4ffd-a71e-e5cd0ee5ce17.png`` and import
- ``assets/environment/49c63135-3b7d-4753-9834-be650efcade1.png`` and import
- ``assets/environment/8eda250f-9196-47f3-acd9-f95f88b5fced.png`` and import
- ``assets/environment/9bdb44d5-7dbf-40da-991f-a82e60732517.png`` and import
- ``assets/environment/hangrongauntie.png`` and import
- ``assets/environment/sidewalk_table.aseprite``

No reset, clean, force-push, or unrelated WIP deletion is part of this
checkpoint.
