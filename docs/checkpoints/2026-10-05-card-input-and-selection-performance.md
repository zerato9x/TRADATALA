# Card input and selection performance — 2026-10-05

Mouse clicks opened PlayingCardView's keyboard inspection and retained it after
the pointer left. The native hover tooltip could then appear alongside that panel.
Every selection also rebuilt all hand subsets and repeated legality/matching for
each table Meld. Hand layout snapped all cards before creating their tweens.

## Changes

- Pointer focus and keyboard inspection use separate input modes. Stationary GUI
  mouse updates preserve keyboard inspection; real pointer activity dismisses it.
- Inspection descendants ignore pointer input. Keyboard panels follow moving cards
  and clamp to the viewport. Keyboard confirmation selects a physical card once.
- Disabled/hidden hands, window focus loss, removed cards and cancelled drags clear
  transient input and inspection state. Window focus loss cancels the table's drag
  payload, preview and targets as well as the source card's pressed state.
- One hand layout update applies position, rotation and selection together.
  Unchanged targets preserve active tweens, and selection starts from the current
  pose instead of snapping the whole fan.
- DealState caches legal action options until physical cards, table Melds, drink,
  phase, state or boss policy change. Restore is tracked by CardData instance IDs.
  Cue results are returned as independent dictionaries.
- Necessary rank/suit bounds prune impossible groups. Equivalent represented
  identities share structural matching; physical ID, lock, discard and Zodiac
  legality checks remain authoritative. Bit masks answer repeated selection
  queries without rescanning all cards in every legal group.
- Passive color drinks retain ordinary same-suit runs of either color alongside
  the extra compatible runs they enable.

## Measurements

Fresh Godot 4.7.1 processes, the same scripted hand, four table Melds, dummy audio
and isolated user data. These are CPU callback measurements, not an FPS guarantee.

| Case | Selection before | Selection after |
| --- | --- | --- |
| Ordinary 10-card hand | 166–190 ms | 3.2–4.7 ms |
| 10 cards with Glitch/Negative | 174–197 ms | 2.7–4.8 ms |
| 12 cards with Glitch/Negative | 747–897 ms | 2.7–4.1 ms |

Final analysis rebuilds in those profiling cases took 12.6, 14.3 and 46.8 ms.
An additional extreme 12-Glitch hand originally took 5,179 ms to rebuild; after
the matching/mask changes it took 86.7 ms, with repeated target queries at 0.81 ms.
That extreme rebuild can still exceed one frame; it no longer repeats on selection.

## Verification

- Core: 354 tests passed, including comparisons with exhaustive uncached rules
  across flexible identities, color compatibility, boss locks, mandatory discard,
  table edits and save restore. Selection-only changes reuse the analysis.
- Card input: 40 checks passed through actual viewport input routing, including
  the real MatchUI hand, outside releases, drag cancellation, keyboard navigation,
  passive inspection controls, visibility and focus transitions.
- Rendered input: the same 40 checks passed with the OpenGL compatibility renderer
  on the GTX 1070 Ti. The current-pose hand capture was inspected.
- Runtime scene smoke passed. Tutorial replacement smoke reported zero failures.
- Full worktree diff whitespace check passed; unrelated WIP was preserved.
- The editor game was relaunched and the saved run resumed. Live mouse selection
  raised the source card; moving away restored its non-hover scale and stacking.
  The card retained only its normal visual children, with no pinned inspection.
  No gameplay action was committed. The live session ended before the final
  selection-reset check; inspection and pose cleanup had already been confirmed.

Logs, baseline source copies, timing scripts and the rendered capture are under
`.godot/input-fixes`. New regression entry points are
`tests/test_card_action_cache.gd` and `tests/card_interaction_smoke.gd`.

The initial rendered harness exposed a keyboard-mode issue from stationary mouse
updates, which was corrected. It also required synchronizing the rendered OS
cursor with injected positions. An intermediate script type-inference error and
a typed-array test-fixture error were repaired before the final fresh passes.
A one-off profiling process reported resource cleanup warnings; subsequent fresh
final profiling, core, runtime and rendered logs were clean. The editor launch
command initially timed out, but its new game process subsequently checked in as
live and was inspected through MCP.
