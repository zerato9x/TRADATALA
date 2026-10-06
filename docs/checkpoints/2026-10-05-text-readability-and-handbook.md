# Text readability and Handbook — 2026-10-05

Main screens show short labels, the next action, and the numbers needed to act. Full rules, property descriptions, accepted terms, and settlement consequences open in the Handbook.

## Visible changes

- Deck details use a large A, 2–10, J, Q, K + existing suit icon badge and points. Removed repeated ORIGINAL / CHOOSE labels and empty-property explanations.
- Drinks and collections show one short effect. NPC speech shows the first sentence; shop explanations and unlock conditions are available in the Handbook.
- Zodiac panels show concise demands, mood, counters, and targets. Boss arrival paragraphs and repeated history are removed from the main table. Cat's latest spoken line and exact answers stay visible; full authored speech and terms remain in the Handbook.
- Promise reminders identify the affected card or relic with a short instruction. Strawy phase previews use two concise content lines. Normal settlement is immediate; full consequences remain in its nonblocking tooltip.
- Gieo selectors, relic panels, card hover text, and Strawy's initial help omit repeated instructions and full rule paragraphs.
- Contextual Handbook links work above the deck overlay. All twelve Zodiac rules are also searchable as permanent Handbook entries.

## Shared display policy

`GameTextPresentation` applies to scene and dynamically created Label, Button, RichTextLabel, and form controls. `SemanticText` formats card references and semantic tokens without changing physical card IDs or the owning Label/Button's source text, input, layout, or typewriter timing.

| Meaning | Color |
| --- | --- |
| Actions | Cyan |
| Values and progress | Gold |
| Gains and success | Green |
| Costs and danger | Coral |
| Mechanics and speakers | Violet |
| Secondary information | Muted |
| Zodiac names | Per-animal override |

Paper surfaces use darker versions of the same palette. Suit ranks have four distinct colors. The existing suit icon assets are reused; card sprite faces are unchanged.

## Validation

Fresh Godot 4.7.1 processes used isolated APPDATA/LOCALAPPDATA and Dummy audio. Rendered checks used compatibility rendering.

- Core: 342/342 passed.
- Rendered readability: 65 checks, zero failures; English and Vietnamese at 1280×720 and 960×620. Reviewed table, deck, Handbook, Strawy, confirmation, drinks, relics, collections, and paper receipt captures. Synthetic pointer checks cover contextual links, card buttons, and pass-through captions. Receipt foreground contrast is checked against its paper background.
- Runtime, tutorial, front end, Event Table, drinks, quick drink input, relics, Gieo, Zodiac, Cat persuasion, resolve receipt, text reveal, and Strawy regressions passed.
- Final rendered Gieo: 477 checks, zero failures, including the real-time cabinet reveal, picker, and Handbook access after rebuilding the cabinet. Final rendered Cat: 333 checks, zero failures, 29 captures; reviewed the concise demand, target badge, and promise reminder.
- Boss presentation: 631 checks; Dog/Monkey: 709; full presentation roster: 5417. All passed, headless.
- `git diff --check` passed. Unrelated pre-existing diff blocks were compared with the initial snapshot and preserved.

Reproduce with `tools/validate_text_readability.ps1 -Rendered`. Use `-Only` for a focused rerun and `-RenderChecks` to render specific suites. Captures and logs are under `.godot/text-readability`; this does not establish physical touchscreen, audio listening, or export validation. No staging, commit, or push was performed.
