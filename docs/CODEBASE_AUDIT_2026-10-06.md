# Codebase audit and refactor decision — 6 October 2026

Follow-up: these findings describe the starting source state. The completed cleanup,
remaining-module assessment, and final validation are recorded in
[CLEAN_REFACTOR_2026-10-06.md](CLEAN_REFACTOR_2026-10-06.md).

**Verdict: a focused, incremental refactor is justified. Start with UI/session coordination and cache lifetime. Preserve the existing gameplay, wallet, physical-card, and Zodiac authorities.**

This audits the current working tree on `main`, based on HEAD `651ebada6a4b0324199ea080ba878b440d6202ee`. It includes the uncommitted Fortune, card-input, Strawy, and text-presentation work: 78 modified tracked files and 29 untracked files were present before this report. It is not an audit of HEAD alone. No production code, existing tests, settings, or authored content was changed. Diagnostic scripts and isolated profiles are under `.godot/codebase-audit-2026-10-06/`.

## Evidence and scope

The inventory covers 123 first-party GDScript files in `scripts/` and `audio_system/`, totaling 28,031 physical lines including whitespace/comments. Tools, scenes, shaders, test entry points, and the previous audit were inspected around the affected boundaries. Third-party add-on internals were not audited comprehensively. This is a structural audit with targeted execution, not exhaustive line coverage or certification of every asset and export.

| Area | Files | Physical lines | Assessment |
| --- | ---: | ---: | --- |
| UI | 51 | 16,058 | Main concentration of coordination and shared mutable state |
| Gameplay | 7 | 2,918 | Authoritative state machine plus growing advisory/query work |
| Zodiac | 23 | 2,577 | Useful service/dispatcher/per-boss separation |
| Campaign | 18 | 2,249 | Clear progression/services; persistence knows private fields |
| Audio, both directories | 9 | 2,382 | Distinct transport, routing, and reactive presentation responsibilities |

`MatchUI` alone has 5,057 lines, 259 top-level functions, and 209 member-variable declarations. It lexically references 52 first-party named classes and was touched in 31 of the 60 most recent commits touching first-party scripts/audio. `DealState` has 1,968 lines and 106 functions; `EventTableController` has 1,031 lines and 46 functions. Size is a screening signal; the ownership problems below are the reasons to refactor. Lexical reference counts include types/comments and are not measured runtime dependencies.

All 21 `test_*.gd` suites are registered in `tests/run_headless.gd`; there are 354 test methods. No line-coverage percentage was measured.

## Confirmed defects to fix before extraction

### P2 — Global deferred text styling outlives its control

Locations: `scripts/ui/game_text_presentation.gd:17–24`.

`_watch()` schedules `_style_form.call_deferred(node)` with a live `Node` argument. If that control is destroyed before dispatch, Godot cannot convert the freed argument to the typed parameter. The `is_instance_valid(node)` check inside `_style_form()` cannot run because argument conversion already failed.

The standard `tools/validate_project.ps1 -Full -Strawy` gate passed its first 15 checks, then rejected this logged runtime error at `meta-debug-write`. A second fresh Boss Lab write run completed 221 assertions with zero assertion failures but logged the same error repeatedly. Its completion marker therefore does not constitute a clean pass. A minimal fresh process that adds a `LineEdit` and immediately frees it reproduces the same error. The separate Boss Lab resume process passes.

Fix the deferred boundary with a weak reference or instance ID resolved at dispatch, and retain a destruction-before-dispatch regression. Preserve native control ownership and authored text. This is a small correctness repair; a larger text-system rewrite is not required to resolve it.

Evidence: `.godot/codebase-audit-2026-10-06/gate/meta-debug-write.err.log`, `meta-debug-repeat-write.err.log`, `text-lifetime-probe.gd`, and `text-lifetime-probe.err.log`.

### P3 — Same-process restore reuses advice containing obsolete card objects

Locations: `scripts/gameplay/deal_state.gd:97–102`, `:267–329`; `scripts/gameplay/hand_advice.gd:18–37`, `:93–95`.

Advice is cached by card values/physical IDs and other deal state. Its `play.cards` array contains live `CardData` references. `RunSave.load_run()` reconstructs new objects; restoring equivalent values produces the same advice fingerprint, and `restore_snapshot()` does not clear the advice cache. The legal-action cache already accounts for object identity, but the advice cache does not.

A real standard-deck save/load/restore in the same `DealState` reproduces this while physical-card accounting remains valid: the cached three-card move contains **zero current hand objects**, fails `can_create_meld()`, and retains the old fingerprint. Fresh analysis returns three current objects and passes legality. Existing advice tests check value changes and dictionary independence, not this primed-cache restore case. The action-cache restore fixture uses an in-memory snapshot and does not recreate cards through disk decoding.

Clear/rebind runtime advisory caches on restore. Prefer physical IDs at the advisory/presentation boundary and resolve current objects before a command. Current Strawy play handlers select by ID, which mitigates immediate impact; this audit did not reproduce card loss or a visible Strawy execution failure.

Evidence: `.godot/codebase-audit-2026-10-06/advice_restore_probe.gd` and `advice-restore-probe.log` (`signature_same=true`, `cached_current=0`, `fresh_current=3`, `cached_legal=false`, `fresh_legal=true`, `physical_accounting=true`).

### P2 — Acceptance gates still assume removed UI behavior

Locations: `tests/strawy_settings_smoke.gd:40`, `:173`; `tests/strawy_scene_smoke.gd:296`, `:345`; `tests/strawy_speech_smoke.gd:41`, `:93`; `tests/zodiac_full_roster_smoke.gd:97`.

The current readability contract puts full explanations in the Handbook. Six assertions across the Strawy scene/speech smokes still expect old full sentences in the compact bubble or the old English Back caption. The settings smoke calls the removed `_prepare_discard()` method, aborting the preference exercise; its subsequent reader failure therefore cannot establish that product preferences fail to persist.

The Zodiac smoke expects `hud.details.visible` after clicking the rules button. That button now opens `GameGlossary`. The smoke leaves the Handbook open, which blocks later empty-hand and Dragon-choice clicks and produces five cascading failures.

Diagnostic copies under `.godot/` demonstrate the difference without editing production or the original tests: changing the Zodiac assertion to the current Handbook route and closing it restores **746/746** checks; adapting the settings fixture to `preview_action()` and the relocated full-detail copy restores **39/39** write and **5/5** fresh-process read checks. These are conditional diagnostics, not passes for the original suites.

Update the tests to exercise the current public behavior and Handbook destination. Do not restore verbose UI or deleted helpers merely to satisfy obsolete assertions. The direct private-method dependency in the settings test is also evidence for narrowing the UI command interface.

## Refactor priorities

### 1. Extract session restoration and persistence coordination from MatchUI

Evidence: `match_ui.gd:311`, `:4664`, `:4760`, `:4930`, and `:4969`.

The composition root constructs/binds the domain services, schedules autosaves, restores music and gameplay, reconstructs event/collection/endgame screens, switches permanent profiles, and temporarily replaces progression objects for Boss Lab. These operations share `_restoring_run`, `game_started`, save objects, interaction locks, presentation resets, and UI visibility.

Create a session coordinator with explicit start/resume/select-profile/enter-debug/leave-debug operations. Keep `RunSave` responsible for serialization and domain owners responsible for committed state. Let screen routing consume the restored state rather than repeat restoration policy in menu handlers. Preserve exact music transport, saved RNG, observer rebinds, pending promises, and profile isolation.

This is the first substantial extraction because mistakes here cross several otherwise well-separated systems. Retain the existing fresh-process resume tests and add the same-process advisory-cache reproduction before moving this boundary.

### 2. Give input and money playback narrow owners and public commands

Evidence: `match_ui.gd:2485`, `:2629`, `:2674`, `:3088`, and `:3712`; `quick_drink_input.gd:12`; `strawy.gd:283`, `:345`; `front_end.gd:455`, `:485`, `:644`; `campaign_money_hud.gd:85`.

Selection, drag/drop, Drink targeting, modal/input suppression, and enabled-action policy span the root and several children. The root supplies a long obstruction predicate listing individual overlays. Extracted screens still call private root handlers or mutate its fields. `FrontEnd` duplicates navigation state through `host.menu_page`; money HUD code writes the root's displayed/queued wallet fields while the root owns queue generation, completion, and cancellation.

Introduce a small public command surface for selection, card/Drink intent, menu navigation, and profile/debug requests, plus a shared read-only interaction state. Extract the receipt-playback queue with its generation cancellation and fast-forward lifecycle. Views observe committed receipts and display values; `VndWallet` continues to commit all money. Moving methods into files while retaining unrestricted `host._...` access would leave the principal coupling intact.

### 3. Remove retired tutorial machinery while preserving shared teardown

Evidence: `match_ui.gd:157–177`, `:1074–1310`, `:2997`, `:4456`.

The standalone tutorial entry points now open the Handbook. No first-party production assignment sets `tutorial_active = true`, yet legacy step state, coaching/outcome/rewind helpers, and action branches remain. A demo test still forces that flag directly. Remove this unreachable machinery after updating its compatibility fixtures.

Keep the current Strawy/onboarding tutorial and Handbook behavior. `_reset_tutorial_ui_state()` is now shared by resume, profile switching, and Boss Lab; preserve its selection, drag, modal, queue-generation, and presentation cleanup as a general teardown operation. Deleting that function along with the retired tutorial would be unsafe.

### 4. Separate DealState queries and make save schemas owner-defined

Evidence: `deal_state.gd:987–1277`; `hand_advice.gd:6`; `meld_probability_advisor.gd:125`; `run_save.gd:19–24`, `:55–112`, `:247`.

Deal mutation and physical accounting belong in `DealState`. Legal-option enumeration, fingerprints, masks, and recommendation selection form a separable read-only query/cache responsibility. Extract that responsibility after fixing its restore lifetime, keeping existing exhaustive-versus-cached comparisons and deterministic RNG checks. `HandAdvice` and probability analysis currently depend on UI `GameGlossary.words()`; presentation formatting can move outward while analysis returns facts and translation keys.

`RunSave` captures private fields of multiple services by name and discovers value-object fields through script-property reflection. A renamed or newly added internal variable can affect persistence without an explicit schema decision. Incrementally give services explicit versioned snapshot/restore adapters. Preserve versions 1–3, physical reference sharing, limits/checksums/backup behavior, and migration tests. The existing save safeguards work; there is no evidence requiring an immediate storage-format replacement.

## Keep and monitor

Keep the existing `VndWallet` journal, `MeldRules`, `ScoringPipeline`, campaign/service authority, and Zodiac dispatch to all twelve rule modules. They already separate legality, committed payouts, physical identity, deterministic random streams, and presentation. Large rendering/configuration methods alone do not justify splitting every screen or boss.

Monitor the two broad text watchers: `GameTextPresentation._process()` examines registered text controls each frame, and `TextReveal._process()` also scans a broad registry to find conversational text. Central styling is useful, but control registration and dirty/active sets would make lifecycle and work more explicit. Profile real screens before treating this as an FPS defect; no frame-cost measurement was made here.

Autosaves remain synchronous whole snapshots. The fresh 900-report Endless fixture reports **107.27 ms** to save (`legacy_encode_ms=399.12`, `compact_encode_ms=72.68`); this is a synthetic long-history measurement, not ordinary-run latency or an FPS guarantee. The fixture verifies retained history, compatibility, and compact encoding. Measure actual long runs before choosing archive partitioning or background serialization, which would require a coherent immutable snapshot.

## Validation

All execution used fresh Godot 4.7.1 processes, isolated APPDATA/LOCALAPPDATA, and headless rendering. The continuation/diagnostic runners also used Dummy audio. Real user profiles and the running editor session were not used by these checks.

| Check | Fresh result |
| --- | --- |
| Main-script parse | PASS |
| Core, all 21 registered suites | **354 passed, 0 failed, 0 skipped** |
| Runtime and tutorial replacement | PASS |
| Routed synthetic card input | PASS, 40 checks |
| Full/demo Monday campaign; progression write/read | PASS |
| Jukebox, money queues/fast-forward, boss money/presentation, transport and music write/read | PASS |
| Text readability, Cat scene, text reveal, boss presentation | PASS: 65, 333, 88, and 631 checks respectively |
| Event Table, front end, NPCs, Gieo, Drink shop/quick gestures, relics and resolve flows | PASS |
| Current Strawy commands and moves/drinks | PASS; moves/drinks has 123 checks |
| Full presentation roster | PASS, 5,417 checks |
| Fortune and Cat persuasion fresh-process write/read | PASS; Cat has 11 write and 32 read checks |
| Endless history and audio tool checks | PASS; history retains 900 reports |
| Boss Lab write | **FAIL** on freed-control deferred styling; repeat has 221 passing assertions plus logged engine errors |
| Boss Lab separate-process resume | PASS |
| Original Strawy scene/speech suites | **FAIL**: 139 checks/2 failures and 68 checks/4 failures; obsolete text expectations |
| Original Strawy settings writer/reader | **FAIL**: writer calls removed helper; reader is downstream of the aborted preference exercise |
| Original full-roster UI smoke | **FAIL**: 746 checks/6 failures; obsolete inline-rule assertion and unclosed Handbook |
| Adapted isolated diagnostic copies | PASS: roster 746, settings write 39/read 5; original tests remain unchanged and failing |
| Same-process advice restore probe | Reproduces obsolete cached card references with valid physical accounting |
| Whitespace | `git diff --check` passes; Git emits existing CRLF normalization warnings |

**The canonical full gate does not pass for this working tree.** It stops at Boss Lab write; independent checks were then run with bounded processes to inspect the remaining areas. The continuation runner records 28 clean completions out of 35 checks/probes, including the cleanly exiting advice reproduction; six original acceptance checks and the intentional freed-control probe fail. Its three later diagnostic checks pass. No process timed out. These runner totals are not assertion totals or a declaration that the defects are fixed.

The audio routing fixture emits its expected `Unknown gameplay music period: unknown` warning; no audio listening was performed. This audit does not establish new GPU visual, physical-device input, exported-build, or live-publication evidence.

Logs, the exact bounded diagnostic harnesses, result JSON, and preserved initial gate/text logs are in `.godot/codebase-audit-2026-10-06/`. Hash comparison confirms the 206 recorded source/test/validator/config files are unchanged during report preparation. The only new non-ignored worktree entry is this report; all pre-existing WIP remains present. No staging, commit, push, export, or publication occurred.

## Suggested order and acceptance

1. Repair the freed-control deferred call and same-process advice-cache lifetime; make both reproductions regression cases and require the full gate to be clean.
2. Consolidate the validation entry points so the current Fortune, Cat, semantic-text, and fresh-process checks cannot be omitted accidentally. All deterministic suites are already registered; this concerns separate scene/resume gates.
3. Remove unreachable standalone-tutorial branches while retaining general teardown and current Strawy teaching.
4. Extract session coordination, then public input commands and money playback. Make one boundary change per checkpoint and rerun its relevant scene/resume checks.
5. Extract read-only deal queries and explicit service save adapters as those systems next change. Profile text and long-history saves before undertaking performance/storage redesigns.

Successful refactoring means narrower ownership, fewer child-to-root private calls, unchanged physical-card accounting and committed journal values, unchanged authored content and RNG behavior, and clean restoration across normal, profile, debug, legacy, and pending-service states. An arbitrary file-size target is not the acceptance criterion.
