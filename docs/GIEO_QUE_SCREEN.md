# Gieo Quẻ screen audit — 2026-09-10

The post-pull failure was reproduced in Godot 4.7.1: `_activate_oracle_group()`
assigned the untyped result of an array-valued conditional to `Array[Label]`.
The runtime error interrupted the reveal and left the panel busy. Both label
groups now use typed-array `assign()`.

## Screen corrections

- Resize and position the animated lever against the cabinet mount; compensate
  for the painted base drifting between the eight atlas cells.
- Fit the campaign fortune-teller sprite within the left side of the viewport.
  Previously its generic left-NPC placement cropped it, and its size differed
  substantially from the standalone preview.
- Keep hidden panels, repeated key events, and unaffordable pulls from consuming
  the keyboard cast action.
- Hide result decisions until their reveal, preventing invisible buttons from
  receiving focus/input. Action handlers continue to guard the busy state.
- Show the next pull cost on the cabinet and in the lever tooltip.
- Use dark reel labels on the pale reels, and display the already-resolved
  random rank/suit before acceptance.
- Constrain committed-flow content to a scrolling panel within the stage.
  Long card-property descriptions no longer force the panel off-screen.
- Retain visible before/after cards on completion so the player can inspect
  permanent changes after the short transformation animation.

The existing card-material work is preserved. This fix does not change the
trigram tables, prices, target selection rules, or permanent card effects.

## Verification

- Headless editor import: exit 0.
- `tests/run_headless.gd` passed 95/95 during the original screen-fix pass; the
  expanded September 13 suite now passes 114/114 (see
  [Drink roster and NPC conversation testing](DRINK_ROSTER_TESTING.md)).
- `tests/gieo_que_screen_smoke.gd`: 385 checks, 0 failures. Instantiates
  `scenes/match.tscn`, opens the campaign fortune teller, runs the actual pull
  and reroll animations, checks charges and navigation locks, and accepts all
  64 compositions through destination/target selection and transformation.
  Includes both jackpots, final-card visibility, hidden keyboard input, atlas
  bounds, sprite bounds, empty-wallet eligibility, and return to the roster.
- Live editor reproduction and visual review use the real campaign screen as
  well as `scenes/debug/gieo_que_preview.tscn`.

Run the regression smoke with Godot 4.7.1:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/gieo_que_screen_smoke.gd
```

The smoke accelerates presentation time inside its own process. The shipped
animation timing is unchanged.
