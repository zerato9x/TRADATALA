# Event table overhaul — 2026-09-19

## Implemented now

The revised physical layout removes inventory captions and empty-slot markers, enlarges relic hit areas to 130 × 104 and banknotes to 155 × 68, and uses staggered positions, individual rotations, close contact shadows, and a restrained hover lift.

The event overview shows the player's actual wallet as VND banknote stacks and their four equipped relics as physical objects beside the persistent deck. Cash hover shows the exact balance. Relic hover, keyboard focus, and click reveal the catalog effect in an in-scene card. These views never apply scoring or change inventory.

The journey defaults to a compact toggle, with the entire board hidden. Opening it shows the current day, completed/current/upcoming days, tonight's debt, remaining shortfall or readiness, and a progress bar. The nine-step sequence explicitly shows Starter Event, Morning Deal, Morning Event, Noon Deal, Noon Event, Afternoon Deal, Afternoon Event, Evening Deal, and night debt collection. Escape, clicking outside, service focus, or changing event closes it; click a day to inspect its debt requirement. Day inspection does not advance the campaign. Endless runs show seven days around the player's position to keep the controls inside the table.

Three quick clicks on event cash now open the existing music-reactive wallet easter egg. Small balances use compact, evenly spaced rings; greater wealth increases the radius and spreads dense wallets into separate rings. Logical banknote value is retained under the bounded visual budget. The exact wallet still includes sub-1,000 VND remainder, which has no banknote sprite. Click or Escape dismisses the ceremony and restores the table. Existing gameplay wallet entry remains supported.

NPC and deck focus clear the inventory/journey from the service area; Back restores the overview. The outcome screen hides the possessions. English/Vietnamese labels refresh together, including the empty cash state. Restricted demo relic visibility is preserved.

## Validation

- Rendered `tests/event_table_overhaul_smoke.gd`: PASS, 105 checks, with no script/shader errors in its final log. Checks real viewport pointer input, cash and all four relic effects, day preview, all four event rosters, three focused NPC services, deck inspection and Back, cash rings from 1,000 through 500,000,000 VND, represented value, exit restoration, empty cash, localization, 720p/1080p captures, and an endless day window.
- `tests/progression_scene_smoke.gd`: PASS using isolated user data; current run-menu/progression flow remains functional.
- `tests/tutorial_scene_smoke.gd`: PASS.
- Rendered `tests/demo_refinements_smoke.gd`: PASS, 30 checks. A concurrent headless run failed the timed completed-run bounce check; the rendered rerun passed it and the existing gameplay wallet/large-ring checks.
- Core suite initially passed 188/188. A later run of the shared workspace passed 185/188: three probability-advisor assertions still search for old suit-glyph labels while concurrent symbol work changed those labels. No probability rules were edited by this event overhaul.
- The legacy `tests/runtime_scene_smoke.gd` cannot complete: its direct New Game signal now opens the existing run menu, leaving its assumed campaign event null. Its source was preserved; current progression and the focused event smoke cover the applicable flow.
- Scoped `git diff --check`: PASS.

Rendered captures were visually inspected. Pointer checks use synthetic viewport input; they do not constitute physical mouse or listening QA. A shader declaration syntax error in the shared symbol-art helper was corrected when the new journey markers exposed it in a rendered run.

## Files

- `scripts/ui/event_table_overview.gd`: physical possessions, item inspection, journey/debt board.
- `scripts/ui/event_table_controller.gd`: overview ownership and focus/outcome transitions; two-line deck caption.
- `scripts/ui/match_ui.gd`: authoritative campaign/wallet/equipment synchronization and shared triple-click entry.
- `scripts/ui/wallet_spiral.gd`: wealth-sensitive ring geometry and event cash origin.
- `scripts/ui/card_symbol_art.gd`: one-line shader syntax correction; concurrent symbol work retained.
- `tests/event_table_overhaul_smoke.gd`: focused interaction and visual regression coverage.

Unrelated mixed work was preserved. No commit, push, export, or packaging was performed.
