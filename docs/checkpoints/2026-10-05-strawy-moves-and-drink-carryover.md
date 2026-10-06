# Strawy moves and Drink carryover — 2026-10-05

Strawy double-click/double-tap previews a suggested legal move, selects its physical cards and target Meld, and explains the move in his speech bubble. The next click/tap confirms exactly that move through the ordinary MatchUI/DealState handlers. Previewing does not change gameplay state, wallet, RNG, or the save. Changed selections, locks, charges, phases, menus, and other contexts invalidate the preview.

The coach prefers a new Meld, then an Extend; recommendations include drink-only Pair/Run permission. When ordinary scoring is unavailable, he can suggest a swap that enables a legal Meld/Extend, recover eligible cards to score again, choose a discard or Trà Đá skip, end an empty turn, or settle Last Call. These are deterministic legal recommendations, not a guarantee of optimal play. One confirmation commits one action; a recovered card's subsequent scoring requires another request.

The original Hint button and G shortcut remain available for quick selection of a legal Meld or Extend, without committing the action or opening Strawy's preview. Hint also works when Strawy is hidden. With no legal Meld/Extend it clears the selection and reports no suggestion; it never falls back to discarding. Its space is used for Cancel during drink targeting. Strawy retains his separate double-click preview and third-click confirmation; single-click Strawy opens contextual help.

Nhân trần and Đen đá blue cues now require a legal Meld or Extend after the outgoing card is removed. The analysis checks current charges, live discard scope, boss locks, and the required loose card for the mandatory discard. Selecting an outgoing card narrows discard cues to that card's opportunities. Hand, turn-register, archive, cup, and drag cues use these opportunities. Manual swap legality remains governed by the normal validators.

Sâm dứa and Bạc xỉu mark specific loose cards during Phase 1, including active play. Sâm dứa marks up to three; Bạc xỉu marks any number, including zero or all. Players can edit the marks before settlement. Marks survive the real save codec and are removed when the physical card leaves the hand. All loose cards still count as deadwood before the Phase 2 refill.

There is no keep-all/redraw choice. After Phase 1 settlement, marked cards carry into Phase 2, the other loose cards enter the discard pile, and the hand refills toward ten. Table Melds remain. Legacy keep-all API requests are rejected; saved transition states resume through the automatic transition. Progress counters and receipts observe the new phase-transition action.

Ordinary Discard, drag-discard, End Turn, and settlement commit immediately. Only Strawy uses a preview followed by a confirmation click. Keep-drink suggestions appear during explicit drink targeting and at the end of Phase 1; actual marked cards remain identifiable during play. Blue cues are informational and do not block discarding or settlement. The settlement tooltip names cards carried into Phase 2 and the number replaced. There is no end-action confirmation panel or keep/dump prompt.

## Validation

Fresh Godot 4.7.1 processes used isolated APPDATA/LOCALAPPDATA, Dummy audio, and compatibility rendering.

- Core after the immediate-action correction: `TRADATALA_TESTS total=342 passed=342 failed=0 skipped=0`.
- Runtime: `TRADATALA_SCENE_SMOKE passed`.
- Tutorial: `TUTORIAL_REPLACEMENT_SMOKE: 0 failures`.
- New move/drink regression: `STRAWY_MOVES_DRINKS_SMOKE checks=107 failures=0` in fresh rendered English 1280×720 and Vietnamese 1920×1080 runs, with clean error logs. Covers native touch with duplicate emulated mouse, mouse gestures, Strawy preview immutability, normal scoring, useful/unhelpful swaps, saved physical keep marks, first-click discard/End Turn/settlement, nonblocking phase cues, automatic transition, and physical-card accounting.
- Strawy commands after the correction: 36 checks, zero failures. The earlier implementation also passed Speech (68 checks) and Scene (136 checks).
- Drink quick gestures after the correction: 164 checks, zero failures. The earlier implementation also passed Drink shop.
- Text readability after removing the confirmation overlay: 65 checks, zero failures.
- English and Vietnamese phase-end captures visually checked: blue keep cues remain visible, settlement stays enabled, and the confirmation panel is absent.
- Hint restoration: fresh English 1280×720 rendered regression passed 123 checks, covering single-click Meld/Extend selection, G shortcut, Strawy hidden, cancellation of a pending Strawy preview, no-play/no-discard behavior, and action-bar fit. The restored Hint and Strawy preview layout was visually checked. Fresh core (342), runtime, tutorial, and drink quick (164) checks passed; the drink quick rerun exited with a clean log after a first-run teardown resource warning. Logs: `.godot/restore-hint-*`.
- Fresh editor import and `git diff --check` passed.

Correction logs are under `.godot/quick-turn-*`; rendered captures are `.godot/strawy-overhaul-*.png`. The new regression is `tests/strawy_moves_drinks_smoke.gd` and is included in `tools/validate_project.ps1 -Strawy`.

Synthetic input and rendered inspection do not establish physical-device touchscreen behavior or audio listening quality. No export, commit, push, or live publication was performed. The four pre-existing Dog/Monkey screenshot `.png.import` files were left untouched.
