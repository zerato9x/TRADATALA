# Codebase audit — 29 September 2026

Audited commit: `ad5d60483a78ae7fd153695b0b9e12e20e4d0ba7` on `main`.
Pull range: `62e9c06..ad5d604`, six commits, 276 files, 21,128 insertions and 7,628 deletions. Local HEAD, tracking `origin/main`, and the live remote matched when checked.

**Original audit verdict: this checkout was not runnable as pulled.** The latest commit corrupted the main script's syntax. The rules suite passed independently, which was useful evidence about rules and persistence, but did not establish that the game could start. The authorized repair and its current verification are recorded below.

The initial audit changed no production code. Diagnostic UI runs used a managed worktree at the same commit with only the stray prefix at `match_ui.gd:3625` removed. All test processes used isolated application-data directories to protect real settings, saves, and unlock profiles. Results from that worktree were conditional, not passes for the original checkout. The user subsequently authorized repairs in the primary checkout and clarified the authored-music contract.

## Confirmed findings

### 1. P1 — Latest commit prevents the main gameplay script from loading

- Location: `scripts/ui/match_ui.gd:3625`; referenced by `scenes/match.tscn:3`.
- Introduced in `ad5d604`.
- The function declaration has the prefix `,'.":vb  vb cv cv ` before `func _on_deal_new_phom_scored(...)`.
- Godot 4.7.1 reports `Parse Error: Unexpected "," in class body` on editor import, main-scene boot, and explicit script parsing. The main scene cannot attach its gameplay coordinator.
- Editor import and bounded main boot both returned **exit 0 despite the logged script error**. Explicit `--check-only --script res://scripts/ui/match_ui.gd` returned exit 1.
- Fix: remove the accidental text, then require explicit script parsing and a main-scene smoke that inspects errors and reaches initialized UI. Running only the deterministic suite is insufficient.
- Evidence: `.godot/audit-2026-09-29/import.log`, `boot.log`, `parse.log`.

### 2. P2 — Successful oversized autosaves can destroy both resumable copies

- Locations: `scripts/campaign/run_save.gd:139`, `:153`, `:178`.
- `_read()` rejects files larger than 64 MiB. `write_snapshot()` imposes no matching size limit before replacing the active file or copying it to `.bak`.
- Reproduced with a valid campaign snapshot containing a synthetic 64 MiB value archive. This tests the persistence boundary; it is not a claim that ordinary campaigns already reach that size.
- First oversized write: returns `true`, with no error. Loading falls back to the earlier backup, restoring 25,000 VNĐ instead of the live 25,777 VNĐ.
- A second oversized write through the original writer also returns `true`, replaces the backup with the oversized active file, and leaves both files unloadable. `load_run()` returns an empty dictionary with `Invalid save file`.
- Retained Endless history makes growth relevant. The documentation already acknowledges the load limit, but acknowledging it does not prevent the writer from invalidating a playable run.
- Fix: share explicit reader/writer limits, validate the complete staged envelope before backup rotation, and preserve the last readable file on rejection. If truly unbounded history is required, separate archives from the resumable checkpoint rather than silently trimming gameplay records.
- Evidence: `.godot/audit-2026-09-29/save_limit_probe.gd`, `save-limit-final.log`.

### 3. P2 — Continue Saved Run resets authored music to the day opening

- Locations: `scripts/ui/match_ui.gd:4441`, `:4455`; `scripts/audio/gameplay_music_conductor.gd:35`, `:93`, `:107`.
- Resume calls `_on_campaign_day_started()`, which starts the day's authored set at its Starter cue and clears `active_period`. The subsequent UI restoration does not route the conductor to the saved event/deal/phase.
- Reproduced from a real Morning Phase 2 state, reached through a legal Set, four mandatory discards with optional Trà Đá discards skipped, settlement, and DUMP.
- Before resume: `phase=2`, `active_period=morning`. After successful resume: gameplay remains at Phase 2, but `active_period` is empty. `on_new_phom(2, 1)` returns false, so the phase-specific cleanup route cannot fire.
- The save contained no music transport or conductor checkpoint. Reconstructing a cue from the round phase would lose the authored transition's real position and could hard-jump into a set.
- Corrected fix: persist and restore the actual transport and conductor, including position, cue/pending transition, reprise boundary, pause, filter descent, period, and once-only flags. Resume must not replay Starter or invent a cue from the gameplay phase.
- Evidence: `.godot/audit-2026-09-29/audit_music_resume.gd`, `music-confirmed.log`; requires the parser repair to run.

### 4. Music policy — Mid-round DJ entry now starts the selected authored set

- Location: `scripts/ui/match_ui.gd:597`.
- `_on_music_system_selected()` implements stopping the conductor when switching to Playlist. The reverse selection saves the preference and refreshes labels, but never starts/reconstructs the authored route.
- Reproduced with the real settings/controller: Authored DJ → Playlist → Authored DJ leaves `settings.music_system=authored_dj`, `gameplay_music.active=false`, and `music_controller.dj_mode=false`.
- The user initially confirmed deferred entry as intentional, so the original P2 classification was withdrawn and the first repair preserved that behavior.
- The user subsequently changed the requirement: switching to DJ during a round should start the selected authored set immediately. The follow-up enters the approved cue matching the live campaign period/deal phase and respects already-committed first-meld cleanup. Changing Dog/Cat also switches immediately. The same chooser now shows Dog/Cat in DJ mode or all 26 tracks in Playlist mode.
- Resume remains a distinct operation: it restores the recorded transport and conductor without inferring a cue or replaying Starter. An older deferred preference with actual Playlist audio resumes as Playlist. The run-menu explanation distinguishes New Run music from saved music.
- Evidence: `.godot/audit-2026-09-29/music-confirmed.log`.

### 5. P2 — The advertised complete Monday smoke crashes after receipt removal

- Locations: `tests/campaign_overhaul_scene_smoke.gd:99`, `:145`, `:153`, `:170`; documented entry point at `README.md:139`.
- The newest commit changes `_show_deal_over()` to archive and advance automatically, removing per-deal receipts. The complete campaign smoke still clicks `scene.resolve_receipt.primary` after those deals.
- With only the parser corruption removed, it fails at line 99 with `Invalid access to property or key 'primary' on a base object of type 'Nil'`, then never reaches its final assertions or `quit()`. The audit killed it after its 120-second timeout.
- Therefore this run does **not** verify the entire Monday-to-Tuesday flow. Older acceptance counts in documentation cannot be reused for this commit.
- Fix: wait for automatic campaign/event transitions and assert the archived report and active phase. Keep explicit pointer payment for the daily collection, which still exists. Ensure runtime errors produce a bounded failure instead of a hanging smoke process.
- Evidence: `.godot/audit-2026-09-29/campaign_overhaul_scene_smoke.err.log`.

### 6. P3 — Initial documentation contained contradictory mechanics and delivery claims

- `docs/RESOLVE_ACCOUNTING.md:17` and `:28` say every quote derives from debt and no quote uses wallet balance. Current polish, tips, and lottery use `VndWallet.player_service_cost()` with current balance and daily repeat counts; the 1.0.3 polish report and in-game Handbook describe that correctly.
- `docs/RUN_PROGRESSION_SAVES_2026-09-19.md:47` describes save schema 1; the current writer emits envelope version 2 and accepts versions 1 and 2. `docs/ENDLESS_HISTORY_OPTIMIZATION.md` has the newer contract.
- `README.md:135` still says all Drinks use a temporary zero test price, while `DrinkManager.TEST_ALL_DRINKS_AVAILABLE` is false and the current production prices are enabled.
- The 1.0.3 report says its changes are local and uncommitted, although the pulled Git history contains them. The newest commit is named 1.0.3.1 while project/export metadata remains 1.0.3; decide whether that name denotes a release before changing version metadata.
- Fix: distinguish dated historical evidence from the current mechanics contract and link the current audit/validation state. Do not rewrite implemented pricing to satisfy obsolete prose.

## Verification performed

Godot executable: `Godot_v4.7.1-stable_win64_console.exe`, `4.7.1.stable.official.a13da4feb`.

### Original checkout, production code unchanged

| Check | Result |
| --- | --- |
| Live Git identity | HEAD = tracking `origin/main` = live remote `ad5d604` |
| Editor import | Main-script parse error; process exit 0 |
| Main boot, five iterations | Main-script parse error; process exit 0 |
| Explicit main-script parse | FAIL, exit 1 |
| `tests/run_headless.gd` | 204 passed, 0 failed, 0 skipped |
| `tests/endless_history_smoke.gd` | PASS; 900 archived deal fixtures; v1 read and v2 write/read/restore |
| `tools/gameplay_music_smoke.gd` | PASS; standalone conductor routes |
| `tools/music_director_smoke.gd` | PASS |
| `tools/music_arrangement_smoke.gd` | PASS |
| `tools/ost_loop_catalog_smoke.gd` | PASS; 26 tracks |
| Save-size reproduction | Confirms successful writes followed by backup rollback and complete load failure |
| Literal quoted production `res://` references | No missing files found by the static scan; dynamic paths excluded |
| Pull-range whitespace | FAIL: trailing spaces at `match_ui.gd:3622` |

The history smoke measured recursive encoding 322.48 ms, compact encoding 69.73 ms, and a complete save 332.91 ms on this machine. Its compact payload was 1,720,660 bytes. These are single synthetic measurements, not ordinary gameplay FPS or a proven regression against the earlier machine's measurements.

### Conditional diagnostic worktree: only parser prefix removed

| Scene check | Result |
| --- | --- |
| Broad runtime | PASS |
| Progression, resume, relic shop, victory and Endless | PASS |
| Menu release flow | 0 failures |
| Money HUD resize flow | 0 failures; 1280×720, 1920×1080, 2548×1368 and back |
| 1.0.3 quality-of-life smoke | 13 checks, 0 failures |
| Retired tutorial / Handbook safety | 0 failures |
| Resolve scene / debt pointer payment | PASS |
| Gieo screen | 404 checks, 0 failures |
| Drink shop | PASS; twelve Drinks, bilingual interactions/layout assertions |
| Event table overhaul | 105 checks, 0 failures |
| Miscellaneous NPC services | PASS |
| Relic gameplay/presentation | PASS |
| Resolve presentation | PASS |
| Complete Monday campaign | Runtime error at line 99; timed out |
| Resume/music-selection reproduction | Confirms findings 3 and 4 |

Rendered Compatibility runs of the menu, HUD, and collection scene also passed. English 1280×720 run-menu and collection captures were inspected: fixed primary controls fit, and the collection's scrollable content remained usable. The HUD run exercised the resize sequence above on Intel Iris Xe. This does not certify every screen, every resolution, the Forward+ renderer, or physical input.

Raw logs, audit probes, and selected rendered captures are retained in `.godot/audit-2026-09-29/` and ignored by Git. No shutdown warnings or additional script errors appeared in the passing runs' captured logs.

## Architecture and remaining risks

- **Authority separation remains useful.** `DealState` owns physical card/rule state; `ScoringPipeline` owns scoring; `VndWallet` owns financial mutations/journaling; campaign/services own progression and purchases. Successful deterministic and focused integration checks support those boundaries. The audit did not find a new Drink scoring multiplier or change the optional Trà Đá contract.
- **`MatchUI` remains the coupling hotspot:** the audited commit had 4,517 lines and 233 functions, mixing save/resume, campaign routing, music policy, input, money queues, screen construction, and retired tutorial helpers. Extract state-reconstruction coordination and persistence orchestration first, preserving gameplay authority. Do not start with a broad rules rewrite.
- **Autosaves remain synchronous whole snapshots.** Deferred scheduling avoids intermediate transaction snapshots but does not move serialization off the gameplay thread. Cost and retained memory grow with Endless history. Profile actual long runs before selecting a storage redesign; the size-limit guard is independently necessary.
- **Validation was fragmented.** The original 204-test runner did not exercise the main scene, and an import exit code of zero does not establish successful script compilation. `tools/validate_project.ps1` now combines explicit parsing, core/runtime checks, music and fresh-process resume, full/demo campaign, and optional broader smokes, with isolated profiles, completion markers, error-log inspection, and timeouts. There is still no hosted CI workflow.
- **Most pulled churn is vendor tooling.** `addons/` accounts for 145 files and 14,885 added lines; the Godot AI addon identifies itself as 4.1.0. Its import and runtime helper loaded in these checks. Editor MCP behavior, client configuration migration, addon updates, and exported helper behavior were not comprehensively exercised; this is not certification of all vendor code.
- **Release and balance remain unverified here.** No Windows/Web package was exported or published. Browser persistence, audible mix quality, human input, full seven-day balance, high difficulty and long real Endless play remain outside the evidence. Full/demo Monday-to-Tuesday acceptance is now covered by the repaired smoke.

## Suggested repair order

1. Remove the main-script syntax corruption and establish a failure-sensitive startup gate.
2. Protect the last readable save before any oversized replacement/backup rotation.
3. Persist actual music transport/conductor state for resume; implement explicit mid-round DJ entry under the revised user requirement.
4. Update the complete campaign smoke for automatic deal progression and rerun full/demo Monday-to-Tuesday checks.
5. Reconcile the current docs. Further `MatchUI` extractions remain separate work.

## Workspace preservation

At the initial audit stage on 2026-09-29, the checkout had 78 dirty import sidecars. They were preserved. Editor import added line-ending-only dirtiness in four newly pulled asset sidecars and `default_bus_layout.tres`; normalized Git diffs showed no content edits for those files. The audit report was the only authored addition at the end of the read-only audit. Authorized repairs subsequently changed the bounded code/test/doc paths below. Nothing was staged, committed, pushed, reset, or discarded at that audit stage.

## Authorized repairs — 29 September 2026

- Removed the stray prefix and trailing whitespace from the main gameplay script.
- Shared writer/reader limits reject an oversized complete envelope or excessive value-object count before either active save or backup is rotated. No retained history is trimmed.
- Added optional value-only music checkpoints to the existing version-2 envelope. MusicDirector restores source/position/current and pending cues/loop/reprise state. ReactiveMusicController restores actual DJ or Playlist playback, pause, shuffle/repeat/RNG/next track, and remaining two-channel crossfade. MusicAntiFatigue restores held-loop count and filter descent. GameplayMusicConductor restores its set/track/period/once-only routing flags without playing a role.
- Continue uses saved music independently of the New Run selection. The subsequent jukebox follow-up replaces deferred mid-round entry with an explicit start at the approved current-state cue. Saves without usable music restore gameplay, use Playlist, and show a notice rather than inventing an authored position. Older files cannot recover music data they never stored; the player can explicitly start DJ afterward.
- Autosave captures music changes alongside committed gameplay; entering the menu and normal window close flush the current transport. Paused streams use `has_stream_playback()` so pause is not mistaken for stop ([Godot API contract](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html#class-audiostreamplayer-method-has-stream-playback)).
- Updated the complete Monday smoke to wait for automatic phases and assert all four archived deal reports/card accounting, while retaining explicit daily debt payment. Its shutdown now allows the audio mixer to release stopped resources.
- Added a bounded Windows validation gate and reconciled current pricing, save version, production Drink prices, and historical release-delivery wording.

### Repair verification

The first repair's evidence below preceded the revised jukebox request. Its logs are retained under `.godot/fix-2026-09-29/`; `.godot/validation/` contains the latest gate logs. Every gate invocation creates fresh test application-data directories, with only the intended writer/reader pairs sharing a profile. Real player settings, saves, and unlocks are protected.

| Check | First repair result |
| --- | --- |
| `tools/validate_project.ps1 -Godot <console executable> -Full` | PASS, exit 0; all 26 checks completed |
| Explicit main-script parse and initialized runtime scene | PASS |
| Deterministic rules/economy/save suite | 205 passed, 0 failed, 0 skipped |
| Complete full and restricted-demo Monday smoke | PASS, 0 failures each; four deal archives, explicit debt payment once, Tuesday playable |
| Music transport | PASS, 0 failures; held/filter descent, forward catch, reprise boundary, release, source play, audition lead-in, unpaused playback, finished source, Playlist, stopped Playlist, crossfade completion, and invalid-position rejection |
| Separate-process music save/Continue | PASS; actual Morning Phase 2 state, cue/pending/position/loop/pause, conductor period and once-only flags; New Run selection does not override saved music; mid-round DJ preference remains deferred; legacy gameplay remains loadable |
| Progression save and separate-process Endless Continue | PASS |
| Eleven additional focused scene checks | PASS: menu, money HUD, 1.0.3 QoL, Handbook, receipts, Gieo, Drink shop, event table, miscellaneous NPCs, relics, presentation. Gieo completed 404 checks with a two-instance ObjectDB shutdown warning; its shutdown cleanliness is not established |
| Retained-history compatibility | PASS, 900 archived deal fixtures, version-1 read and version-2 write/read/restore |
| Four existing audio tools | PASS: gameplay conductor, cue director, arranger, 26-track loop catalog |
| Original synthetic 64 MiB archive reproduction | Both writes now return false with a size-limit error; active save remains readable; no backup rollback or loss |
| Rendered menu and Continue | PASS; English/Vietnamese menu at 1280×720 visually inspected; fresh-process Morning Phase 2 Continue rendered and actionable |
| Scoped normalized diff whitespace | PASS |

The abrupt headless window-close notification probe separately confirmed that the live transport is flushed before quit. It printed PASS but emitted four ObjectDB/one resource teardown diagnostics; this is not counted as a clean shutdown check. The standalone transport and fresh-process/rendered resume tests explicitly allow stopped audio resources to drain and finish without those diagnostics. Audio used Dummy; audible quality and physical-device output were not judged.

At the first repair checkpoint, there were 13 tracked source/test/doc content changes and four authored new files (this report, two music regressions, and the validation gate). The jukebox follow-up expands that bounded scope as recorded below. Existing import/bus-layout dirtiness and the subsequent user/editor change to `project.godot` are preserved. No commit, push, tag, export, or publication had been performed at that checkpoint.

## Jukebox follow-up — revised music requirement

- Added explicit current-state entry for CAT/DOG, covering Starter, Morning/Noon/Afternoon events, both phases of each deal, committed first-meld cleanup, resolved deals and collection. Ordinary authored transitions still travel forward through their approved cues; Continue still restores exact recorded transport.
- Reused the existing track chooser below the mode selector: DJ lists only Dog/Cat; Playlist lists all 26 original tracks. Removed the separate set selector. Playlist-only Shuffle/Repeat controls hide in DJ mode. Cover/title/source side and active-set text follow actual playback.
- Fresh settings start the selected DJ set in the menu; the selection persists into New Run and subsequent day openings. Mode/set switches preserve pause. Save checkpoints include the selected set, and older deferred-DJ checkpoints normalize the chooser to their actual Playlist playback.
- Added a scene regression that exercises the native popup-selection connection, reaches a real Morning Phase 2 through legal actions, switches both modes/sets, verifies gameplay/wallet/history/RNG invariance, resumes the selected set, checks both closing-source orders with a separate late-deal fixture, and returns to an arbitrary Playlist track. Extended the conductor's golden cue checks across both sets and all entry periods.
- Rendered the jukebox and both chooser popups in English at 1280×720 and Vietnamese at 1920×1080 with Compatibility/Dummy audio. Both scene runs completed with zero failures and no logged errors or shutdown diagnostics. Captures are retained under `.godot/jukebox-2026-09-29/`. Physical input and audible mix quality remain outside this evidence.

### Follow-up verification

| Check | Result |
| --- | --- |
| Full Windows validation gate | PASS, exit 0; all 27 checks completed, no logged script/runtime errors |
| Deterministic rules/economy/save suite | 205 passed, 0 failed, 0 skipped |
| Full/demo Monday campaign and fresh-process progression | PASS; Tuesday and saved Endless resume remain covered |
| Fresh-process music save/Continue | PASS; original pending transition/position/pause/conductor restored before testing the new explicit DJ switch |
| Authored conductor | PASS; 38 golden entry fixtures across CAT/DOG plus rejected unknown-period entry, alongside existing forward-route and runtime-bridge checks |
| Native jukebox selection and real Morning Phase 2 | PASS; immediate mode/set entry, selected set on New Run, pause preservation, encoded gameplay fields unchanged, selected-set resume, both closing-source orders, arbitrary Playlist selection |
| Strengthened final jukebox regression | Headless and rendered EN/VI PASS, 0 failures; includes full value-object field comparison and chooser-popup viewport bounds |
| Scoped whitespace | PASS |

The jukebox follow-up gate had one receipt-scene teardown warning: `resolve_scene` reported two ObjectDB instances at exit after PASS. The unknown-period warning in the conductor tool is expected from its deliberate rejected-entry fixture. Music transport, fresh-process music resume and jukebox runs completed without shutdown warnings. These results do not claim every existing smoke has a clean shutdown.

At the time of the 2026-09-29 audit, the changes remained local and uncommitted on `ad5d604`. They were checkpointed to `main` and pushed to `origin/main` on 2026-09-30. The follow-up includes the two regenerated locale translation resources and preserves unrelated existing imports, bus-layout line endings and the user/editor's `project.godot` addition.

## Money animation follow-up — normal pacing with manual fast-forward

- Removed the new automatic four-second scoring compression and its queue-age clock. Default card/replay/relic beats, shakes and bill-flight durations retain the earlier pacing, including individually revealing physical cards during long resolutions.
- A mouse click, non-repeating key press, controller button or touch press requests acceleration for the current money queue. Scoring retains the existing 0.012-second fast beat; remaining reveals are skipped, and active/new money tweens, transfers, phase feedback, major-event bursts and exhaustion returns accelerate eight times. Gameplay and music speed are unchanged.
- The activating press is consumed before GUI/gameplay handling. Later inputs remain available. Menu/modal navigation, mouse motion, scrolling, releases and held-key echoes do not request acceleration. Queue completion and cancellation clear the speed latch so the next queue starts normally.
- Added a regression that keeps a synthetic twenty-relic receipt at normal speed beyond four seconds, requests speed through native viewport input, observes every receipt frame including the next queued job, checks all four input devices and exact transfer totals, verifies full encoded gameplay/wallet/history/RNG invariance, and checks cancellation and bill cleanup. This fixture tests presentation independently of authoritative payouts.
- Headless and rendered Compatibility money regression: PASS, zero failures. Existing physical-card trigger/replay/exhaustion regression: PASS headless and rendered, including original shakes, layout restoration, wallet separation and ghost cleanup. Rendered captures and logs are retained under `.godot/money-2026-09-29/`; the physical-card stack capture is `.godot/money_stack_receipt.png`. Automated audio uses Dummy and input is injected through Godot's viewport.

Final full validation gate on 2026-09-29: **PASS, exit 0, all 28 checks completed**; core **205 passed, 0 failed, 0 skipped**. Full/demo Monday, fresh-process music and progression, jukebox and all broader scene/history/audio checks pass. Scoped whitespace is clean. The money and physical-card regression runs have no logged errors or shutdown warnings. This gate reports two ObjectDB instances at exit from the existing arranger tool after PASS; the conductor's unknown-period warning remains its expected rejected-entry fixture. The changes were subsequently checkpointed to `main` and pushed to `origin/main` on 2026-09-30; unrelated dirty work was preserved.
