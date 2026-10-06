# Refactor pass — 6 October 2026

Implemented the ownership changes identified in [the audit](CODEBASE_AUDIT_2026-10-06.md). Work starts from the complete existing worktree, including the Fortune, card-input, Strawy, and readability WIP.

## Changes

- `RunSessionCoordinator` owns deferred autosave, profile switching, run restoration, and Boss Lab progress/save isolation. The view supplies explicit music and presentation callbacks. Actual saved music transport and campaign/service RNG state remain authoritative.
- `MoneyPlaybackQueue` owns receipt jobs, displayed/queued balances, completion, cancellation generations, and fast-forwarding. A cancelled deferred drain cannot consume a replacement queue; new-run startup cancels receipts from the previous run. `VndWallet` continues to commit money.
- `MatchInteraction` owns selection and Drink/drag target policy. Strawy, Drink gestures, and the front end use public commands. Those three files have **63 fewer private root calls, with none remaining**. Interaction snapshots expose copied selection IDs and availability state. Front-end navigation has one page owner.
- Removed unreachable standalone tutorial state, handlers, and action branches. Compatibility entry points still open the Handbook. Shared cleanup survives as `reset_transient_presentation()`; real first-day Strawy teaching remains.
- `DealQueries` owns advisory/legal-option caches, enumeration, masks, and recommendations. `DealState` keeps mutation and physical accounting, and forwards its existing query API. Restore invalidates caches; advice fingerprints include physical object identity. `AdvisoryText` formats analysis facts in the UI, removing gameplay dependencies on `GameGlossary`.
- Services and whitelisted value classes declare their V3 save fields and restoration adapters. `RunSave` no longer enumerates script properties or owns private service-field lists. The existing envelope, reference table, checksum, limits, atomic write, backup, and migration behavior are retained.
- Deferred form styling now resolves a `WeakRef` inside the callback. Added real disk-cache restore, same-value card replacement, freed-form lifecycle, and deferred receipt-cancellation and cross-run playback regressions. Updated stale Strawy/Handbook expectations and made the pointer fixture explicitly enable its live hand.
- `validate_project.ps1 -Full` includes Strawy, current Fortune/Cat/negotiation resume, readability, text-reveal, and boss checks. It deduplicates checks, records results, and rejects engine errors and missing completion markers. The text and negotiation entry points delegate to the same runner.

`MatchUI` is 5,057 → 4,557 lines; `DealState` is 1,968 → 1,706. Presentation assembly and choreography remain in the view. Forwarding properties keep existing scene/test consumers compatible while the new owners hold the state.

## Verification

**Final `tools/validate_project.ps1 -Full`: 56/56 checks pass**, including main-script parsing, **356/356 core tests**, runtime, pointer/Drink/Strawy interaction, tutorial replacement, money queue/fast-forward, normal/demo campaign, progress/profile/Boss Lab, real music transport, Fortune/Cat/negotiation separate-process restoration, every Zodiac presentation, current text checks, resolve/relics, long history, and audio tools.

All headless processes use Godot 4.7.1, isolated APPDATA/LOCALAPPDATA, and Dummy audio. No logged engine errors, failed markers, or timeouts in the final run. Original and preserved final records: `.godot/validation/results.json` and `.godot/refactor-2026-10-06/final-gate/`. The audio negative fixture emits its expected unknown-period warning.

The initial full attempt exposed the remaining obsolete Strawy settings-copy assertion and its aborted reader. Both are corrected: final writer **39/39**, fresh reader **5/5**. The cross-run receipt regression reproduced uncancelled old jobs before the startup cancellation fix; it passes in the final run.

A separate fresh OpenGL compatibility process passes **66 rendered readability checks, 0 failures**. It exercises freed forms, bilingual semantic text, pointer input, Handbook, Deck, Drink/relic screens, and receipts at 1280×720 and 960×620. Inspected the English 1280 table and Vietnamese 960 Handbook captures. Logs: `.godot/refactor-2026-10-06/rendered/`; captures: `.godot/text-readability/screens/`.

An independent fresh-process compatibility probe uses the exact pre-refactor V3 serializer from the preserved WIP baseline. Old and new save files are **byte-identical** for the seeded played-meld fixture. The new reader restores that old file with valid physical accounting and shared persistent-card references. Diagnostic: `.godot/refactor-2026-10-06/schema-legacy.log`.

## Boundaries

Text-watcher profiling and a long-history storage redesign remain monitoring items from the audit. This pass keeps synchronous saves and current rendering/composition. The rendered readability case adds GPU evidence for those exercised screens. Audio checks use Dummy output; listening, physical touchscreen, export, and publication remain unverified.

The initial audit remains a historical report. Original WIP bytes are preserved for untouched files; `project.godot` matches its audit hash. No staging, commit, push, export, or publication is performed.
