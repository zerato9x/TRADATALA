# Strawy helper and Event Table touch controls

Implemented locally on 2026-10-01–02. No commit, push, or publication was performed. Existing ChatGPT documentation files and the supplied eye archive were preserved.

## Player behavior

Strawy lives in a dedicated screen-space CanvasLayer during the game, including NPC services, deck browser, Handbook, and results. Home, setup, settings, and other front-end menus hide him and reserve no helper space in their footer. His bottom-left dock clears the game's action controls, conversation, and inspection/results layouts.

- Tap once for a compact contextual menu: one short hint and at most three relevant actions. During a Deal, double tap to select and highlight the recommended discard; the next tap confirms that exact card. Preview changes no cards, wallet, RNG, or saves. A changed hand, selection, lock, screen, or phase cancels confirmation.
- Pointing tours are available from the single-tap menu; double tap still tours the Event Table. Next/Done only highlight controls. Dismissal, completion, target disappearance, or a changed screen returns him to his dock.
- Card badges use the previous hover-only display: completion percentages, or the straw-hat symbol for a ready Meld. No persistent Keep score, play-text label, or badge click target is added. Requested card explanations remain in Strawy's Card info action.
- Play Meld/Extend and confirmed discards recompute current advice and use MatchUI's existing handlers. Each request performs at most one action. Trà Đá's optional discard or Skip requires another preview/confirmation or an explicit Skip menu action.
- Card commands are unavailable during NPC services, incompatible overlays, Drink targeting, dragging, and required transitions. Ordinary queued money feedback does not lock helper actions. Native touch plus its emulated mouse event cannot duplicate a helper command.
- Speech is request-driven. Context hints retain the action instructions instead of cutting off after the first sentence. NPC and Deal tours explain the service or card action and its purpose; recommended Meld steps name every required card. Phase choices, Drink targets, refills, and Last Call have brief instructions.
- Popup text uses a silent typewriter reveal, capped at two seconds. Tapping the text finishes it immediately; Next or an action remains available while it types. Full paragraph space and actual response sizes are reserved, keeping the buttons still and visible. New text, language changes, dismissal, and disabling Strawy cancel the previous reveal. Idle floating, blinking, gaze, hat poses, squash/stretch, travel trails, highlights, and success/rejection reactions remain silent.

The eight hat crops use individual silhouette bounds, a shared 400×336 transparent canvas, aligned pivots, and per-pose eye anchors. Normal/half-blink/blink assets and all sixteen supplied expressions load locally. `tools/extract_strawy_assets.py` reproduces the extraction. The original sheet contains alpha-1 speckles across blank space; padded bounds exclude those distant speckles. Every retained crop pixel preserves its original RGBA values.

## Advice contract

`DealState.hand_advice()` returns recommended play, discard physical ID, per-card relative Keep scores, target odds, reasoning, and the Trà Đá extra-discard/Skip choice for Strawy. Card hover badges separately retain `MeldProbabilityAdvisor`'s original completion percentages and draw horizon.

Each legal discard is evaluated against the resulting hand and next refill. Outcomes rank by strongest identified target probability, projected scoring potential, then lower deadwood. Currently playable Meld/Extend cards are preserved when another unlocked discard exists. Physical `unique_id` breaks remaining ties; equal outcomes share a score. Keep 0–100 is a relative ranking, not a percentage.

Target odds use without-replacement combinations over accessible card composition. Crossing exhaustion guarantees the current draw pool, then samples eligible recycled discards, spent cards, and cleared table melds. Mandatory discards remain excluded. Trà Đá compares deferred refill after one discard against the optional extra discard and recomputes after the first action. Last Call uses available plays/deadwood with no refill. Ordinary Sets/Runs, passive color-compatible Drink Runs, and extension targets are considered; analysis does not spend active Drink charges.

Odds describe the named target, rather than the union of every possible meld or a guaranteed payout. Analysis is cached until relevant state or locale changes. It does not read shuffled order, advance RNG, mutate cards, charge money, or write saves.

## Helper preference, Tutorial, and First Seed

The Monday coach banner is retired. Its real campaign observations and learned-mechanic tracking provide Strawy's requested tutorial copy.

Tutorial and First Seed are independently persisted, enabled by default. Tutorial changes immediately; ordinary help remains available when disabled. First Seed is captured at run start and saved. Enabling it preserves Monday's fixed shuffle/curated openings; disabling it uses normal run-seed shuffling. Existing saves without the new field retain curated behavior. Changing the preference does not rewrite an active run's policy.

Settings has an independent Show Strawy switch, enabled by default. Disabling it immediately hides him and closes his menu, tour, or discard preview. Re-enabling it restores him during gameplay. The preference does not change Tutorial or First Seed.

After Monday's real tutorial play finishes, a compact Keep Strawy / Turn off choice appears once, after results, required transitions, and other overlays have cleared. Touch and keyboard work. The answer persists across runs and launches and can be changed in Settings; an explicit Settings choice also prevents a redundant question. Interrupted completion resumes the question when gameplay is unobstructed. Legacy preferences default to Strawy enabled with no answer recorded. Closing the question with × or Escape retains the current preference and records the choice.

## NPC input

NPC character targets follow alpha silhouettes with small touch tolerance. Always-visible, separated name buttons are at least 48 logical pixels high. Both routes invoke the same focus action on release. Native and mouse drags, outside releases, OS cancellation, window interruption, extra fingers, repeated taps, and emulated mouse duplicates are guarded.

Selectors operate only on the unobstructed Event overview. Pending gestures are canceled during transitions; focused services, deck screens, Strawy help, Handbook, Zodiac, receipts, and other overlays prevent selection underneath. Required-service gating, roster/demo restrictions, and overview-only Continue remain intact.

## Verification

Fresh Godot 4.7.1 processes used isolated project-local APPDATA/LOCALAPPDATA. Reproduce automated validation with:

```powershell
./tools/validate_project.ps1 -Godot '<path to Godot 4.7.1 console executable>' -Strawy
```

- Core after restoring the hover badges: **287 passed / 287** in the current worktree, including numerical advice, joint odds, rare-probability ordering, ties, advice/recommendation agreement, playable preservation, locks, phase boundaries, exhaustion, Trà Đá discard/Skip, cache isolation, and legacy-save behavior. Snapshot and both RNG streams are checked for read-only analysis. The card-symbol smoke, runtime scene, tutorial replacement, and 36 Strawy command checks also pass.
- Scene commands: **36 checks** cover Meld, Extend, mandatory discard, optional discard, and Skip through ordinary state/wallet/save flows. Double-tap previews remain read-only; the next tap confirms once. Native helper taps followed by emulated mouse cannot duplicate a command. Ordinary mouse, changed selections, new locks, drag cancellation, menu interruption, and Last Call are covered.
- Speech: **66 checks / 0 failures** cover English/Vietnamese action instructions, gradual reveal and completion, native touch with emulated mouse, ordinary mouse, stable response layout, unclipped brief-help responses, rapid language replacement, advancing a tour before text finishes, all NPC explanations, all recommended Meld card identities, card details, the tutorial choice, dismissal, disable cancellation, and unchanged cards/wallet/RNG. Core **287 / 287**, runtime, tutorial replacement, helper commands **36 / 36**, scene **144 / 144**, and settings **39 / 39** plus fresh-process resume **5 / 5** pass after the speech changes.
- Settings: **39 checks / 0 failures** cover all four Tutorial/First Seed combinations, immediate helper visibility and interaction cancellation, deferred post-tutorial choices, native touch plus emulated mouse, keyboard focus/confirmation, and legacy defaults. **5 checks / 0 failures** in a separate fresh-process resume retain the helper preference, answer/completion flags, and saved run policy despite a changed First Seed preference.
- Regression suites pass parse, runtime, jukebox, money fast-forward, music transport/resume, campaign/full/demo, progression/resume, front-end, tutorial, Event Table, miscellaneous NPC, Gieo Quẻ, Drink, Zodiac, and Strawy. Tests formerly targeting the retired setup entry point, old footer child index, old probability badge, old dialogue position, and full tutorial paragraph now exercise the current contracts.
- Rendered checks pass **144 / 144** in each English/Vietnamese run at **1280×720** and **1920×1080**, using the compatibility renderer. Home/Settings hide Strawy. The small menu, discard preview, Event overview, focused fortune teller, card advice, tours, deck browser, Handbook, and results were inspected. The restored badge checks cover hidden idle cards, percentages and the straw symbol on hover, and hiding after pointer exit. Eight pose captures exercise alignment. Captures are under `.godot/strawy-*.png`, including `odds-ready-<locale>` and `odds-percent-<locale>`.
- The new Show Strawy setting, centered tutorial choice, and disabled gameplay capture also pass **39 / 39** in each of those four locale/viewport combinations. Captures are `.godot/settings-strawy-<locale>[-large].png`, `.godot/strawy-choice-<locale>[-large].png`, and `.godot/strawy-disabled-<locale>[-large].png`; the Settings and choice layouts were visually inspected.
- Typewriter and explanatory help render checks pass **33 / 33** per run in English and Vietnamese at **1280×720** and **1920×1080**. Partial/full text, unclipped responses, and explanatory Deal tours were inspected in `.godot/strawy-speech-{partial,help,tour,deal,deal-tour}-<locale>[-large].png`. The reveal reserves paragraph height, so the response buttons do not move as letters appear.
- Asset audit: eight pixel-exact RGBA crops on consistent canvases; original normal/half-blink/blink files remain byte-identical. The maximum alpha outside the padded silhouette bounds is 1.
- `git diff --check` passes; no files were staged.

Native touch tests inject `InputEventScreenTouch`/`InputEventScreenDrag` through Godot's viewport and also exercise touch-emulated mouse and ordinary mouse. **Physical phone/tablet touchscreen verification has not been performed.** The rendered result capture uses a committed real Deal report fixture; the campaign/progression suites separately exercise the full result flows. No export, publication, listening test, or physical-device pass is claimed.
