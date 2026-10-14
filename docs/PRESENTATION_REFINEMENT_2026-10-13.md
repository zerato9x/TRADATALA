# Presentation refinement — 13 October 2026

Collections now uses the existing drink and Zodiac art as a browsable shelf. Drink tiles use two columns for longer names; Zodiac portraits use three. Brass selection, two-line captions, status labels, full-name tooltips and accessibility names identify each item. Decorative children pass pointer input to their original Button. Keyboard focus scrolls the selected tile into view after rebuilding the page.

The detail panel places the original art on a static display plinth with a subtle circular accent. Zodiac requirement bars read the same current/required values as the existing labels. The setup debt slip now has ruled rows and a shaded Sunday row. Disabled brass buttons use the shared paper ink color.

No authored copy, catalog prices, unlock rules, gameplay, saves or RNG were changed. The new helpers only compose controls and draw decorations; the display does not process every frame.

## Validation

Fresh Godot 4.7.1 processes and isolated user profiles:

- Collection refinement: 511/511 rendered checks in OpenGL Compatibility and 511/511 in Direct3D 12 Forward+. English and Vietnamese at 1280×720, 960×540 and 1920×1080. Covers thumbnail pointer clicks, keyboard activation, focus scrolling, caption bounds, accessible names and wallet/card invariance.
- Core: 537/537.
- Existing drink presentation: 594/594; readability: 66/66; rendered responsive layout: 163/163.
- Parse, front-end navigation, release-menu flow, runtime scene and tutorial replacement checks passed.
- The initial Forward+ run overlapped another rendered test and missed one synthetic click. A fresh isolated rerun passed without source changes. The failed log is retained; rendered input tests should run sequentially.
- Final diff whitespace check passed. These checks do not establish physical touch or audio-listening quality.

Logs and final rendered screenshots are local ignored artifacts under `.godot/validation/refinement-2026-10-13/`. `regression-results.json` records the eight existing regression checks. `screens/` contains the final Forward+ captures. The standard validation runner now exposes `collection-refinement` and the existing `ui-polish-layout` check.

Changes remain uncommitted.

## Settings and save-file continuation

Settings now groups audio/language and table preferences into two compact panels. Brass slider handles and native CheckButton switches use small SVG assets matching the enamel controls. On/off differs by thumb position and check/dash symbols as well as color. Checked-hover styling is explicit. Opening Settings refreshes the controls from the existing settings owner, and compact-layout transitions rebuild the panel.

Save files now show aligned difficulty, drinks, emblems and endings rows. The active file has a green surface and border; damaged files keep their warning state. Equal space for two-line player names keeps statistics aligned. Load/Create actions share a baseline, and Rename fits without scrolling at the tested landscape sizes. The existing MetaSaveFiles methods still own selection, progress and renaming.

Validation for this continuation:

- Final forms smoke: 151/151 in OpenGL Compatibility and 151/151 in Direct3D 12 Forward+, both in fresh isolated profiles. English and Vietnamese at 1280x720, 960x540 and 1920x1080. Checks cover pointer toggles, keyboard toggles/sliders, settings values, locale refresh, file creation/loading, 40-character renaming, aligned rows/actions and unchanged cards/wallet while browsing.
- Existing settings persistence: 39 write checks and 5 independent-process read checks, all passed.
- Existing profile/debug isolation: 211 write checks and 15 independent-process read checks, all passed.
- Parse, runtime, front-end navigation, tutorial replacement and 66 readability checks passed.
- Visual review corrected a missing checked-hover background and excess save-card spacing before the final runs.
- An earlier Forward+ run missed synthetic clicks delivered across separate frames. The forms test now injects motion plus press/release together through the viewport, without emitting Button signals directly. Both final rendered runs passed. This is synthetic input evidence, not a physical-input claim.

Logs and final Forward+ screenshots: `.godot/validation/forms-2026-10-13/`. The final rendered logs are `compatibility-gesture.log` and `forward-gesture.log`; `regression-results.json` records the existing persistence/navigation checks. The standard runner exposes `front-end-forms`.

## Street atmosphere and physical receipts

The game table now follows the campaign's morning, noon, afternoon and evening phases. Sunlight shifts across the pavement, afternoon light warms, and evening darkens the street around a warm pool of light. Slow awning shadows add restrained movement. The shared ambience scene duplicates its shader material per instance, so gameplay time does not change the menu backdrop. Phase signals drive normal transitions; HUD refresh also catches restored or replaced sessions. Interrupted transitions finish at the newest phase. The decorative layer remains behind cards, characters and controls and ignores input.

Nightly collection and run outcomes now sit on one warm paper sheet over the actual street, with fine ruling, staples, a perforated edge, shadow and a short settling animation. Panels within the sheet are light printed divisions. The persistent wallet has clear space above the paper, and the collector keeps his own right-hand space. Currency totals fit their available columns, preserving the complete amount. The masthead refreshes with the active language. The afternoon HUD label now has room for its full English name.

Ordinary deals still return directly to play without a receipt. Existing accounting, payment, progression, authored copy, card art and sound cues remain authoritative and unchanged.

Final validation (fresh Godot 4.7.1 processes, isolated profiles):

- Street presentation: 218/218 in OpenGL Compatibility and 218/218 in Direct3D 12 Forward+. Includes four lighting periods, interrupted transitions, independent menu material, unchanged wallet/cards/deck RNG during lighting, receipt bounds, complete totals, localized masthead, viewport-injected ledger clicks and receipt suspension/cleanup.
- Receipt renders reviewed in English and Vietnamese at 1280x720, 960x540 and 1920x1080, plus a shortfall state. Final screenshots are from Forward+.
- Core: 537/537; readability: 66/66; rendered responsive layout: 163/163.
- Runtime, tutorial replacement, actual collection/payment and outcome-return scene, standalone receipt lifecycle, menu/deal navigation (22 checks) and Boss Lab navigation (51 checks) all passed. The real collection scene verifies payment once, next-day advancement and no normal-deal interruption.
- Visual review caught and fixed wallet/header overlap, collector/paper overlap from wider currency digits, an abbreviated afternoon label and a stale-language receipt masthead. The exploratory failure log is retained as `inspect.err.log`.
- Diff whitespace check passed. These are rendered and synthetic-input checks; no physical touch or audio-listening claim is made.

Evidence: `.godot/validation/street-2026-10-13/` contains `compatibility.log`, `forward.log`, their error logs, `regression-results.json` and `screens/`. Existing regression logs remain under `.godot/validation/`. The standard runner exposes `street-presentation`. Changes remain uncommitted.

## Physical card piles and sorting tray - 14 October 2026

The draw and discard piles now have paper edges whose depth follows the actual visible count. Single cards have no extra layers; empty piles leave a quiet footprint instead of a ghost card back. Hovering the existing archive target adds restrained brass corner marks. The original top-card art, fortune effects, Tiger claws, count labels and drop targets remain in place. Pile decorations ignore input and do not process every frame.

Cards now cast a longer, softer shadow when hovered or selected and settle back to their contact shadow on release. The existing card motion and hit targets remain unchanged.

The archive is a felt sorting tray with a wooden rim, small brass fasteners and four tinted suit lanes. Larger cards, contact shadows, larger original suit icons and readable counts improve browsing. Suit headings keep their localized words beside the original icons. The street remains visible around the tray. Each suit retains its own scrollbar, including when a full deck requires a fifth row.

Final validation in fresh Godot 4.7.1 processes with isolated user profiles:

- Pile/archive presentation: 356/356 in OpenGL Compatibility and 356/356 in Direct3D 12 Forward+. English and Vietnamese at 1280x720, 960x540 and 1920x1080, plus full-deck wheel scrolling at 1280x720 and 960x540. Checks include empty/single/deep piles, top-card identity, staged-hand exclusions, exact counts, card shadow transitions, viewport archive clicks, all 52 physical cards, scrollbar clearance and final-row access. Browsing checks preserve wallet, hand, physical zones and deck RNG.
- Core: 537/537. Card interaction: 43/43. Quick-drink gestures: 164/164. Readability: 66/66. Responsive layout: 163/163. Menu/deal: 22/22. Runtime and tutorial replacement passed.
- Drink-shop selection and money fast-forward checks passed. The drink test previously began its Bac xiu fixture while the preceding payout was still running; the first click correctly accelerated that payout. It now waits, with a ten-second deadline and completion assertion, before beginning the next fixture. The original pointer helper and gameplay input behavior are unchanged. The money test now creates its screenshot directory before saving captures in a fresh checkout.
- Rat/Tiger: 882/882 on a fresh rendered rerun. An earlier run missed the Rat collection scrolling assertion; it did not recur without source changes to that behavior.
- The full-deck archive was visually reviewed at the smaller size. Both renderers completed with empty error logs. These checks establish rendered layout and synthetic input behavior, not physical touch or audio-listening quality.

Evidence is under `.godot/validation/piles-2026-10-14/`: final `compatibility.log`, `forward.log`, `screens/`, copied regression logs and the retained drink-input investigation. The standard runner exposes `pile-presentation`. Test-generated changes to the three existing documentation screenshots were removed; final screenshots remain in the ignored evidence folder. Changes remain uncommitted.

The final editor scan found that the audio-bus UID was not registered at startup even though `default_bus_layout.tres` existed with that UID. `project.godot` now references the same resource by its stable `res://` path. Bus contents, routing and volume settings were not changed. A fresh editor import completed without errors; parse, runtime and jukebox smoke checks passed after this fix. See `import.log`, `import-initial.err.log`, the now-empty `import.err.log` and `audio-path-results.json`. New script UIDs were generated, and the final diff whitespace check passed.
