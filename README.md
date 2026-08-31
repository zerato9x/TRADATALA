# TRADATALA / TRÀ ĐÁ TÁ LẢ

A Godot 4.7.1 early-campaign prototype built above the existing solo-derived Phỏm Deal. The project uses the complete card-face set in `res://cards/` and separates campaign progression, events, economy, rules, and presentation.

The official presentation uses the generated Vietnamese sidewalk-table plate at `res://assets/environment/sidewalk_table.png`, with `DFVN Pexel Grotesk` as the global game font. Cards and HUD elements remain live Godot controls layered over the environment.

The project opens on a dedicated title menu over the fixed sidewalk-table background. Choosing **VÁN MỚI** starts Monday's Starter Event, where Cô Trà Đá supplies the Drink used by the Morning and Noon Deals. The same table then carries the player through four Deals and four Event slots per day for seven days. The match layout shows the active Drink, current day/goal, and an expandable Relics grid initialized with four presentation-only slots.

## Run

Open `project.godot` in Godot 4.7.1 Stable and run the project (`F6`/`F5`), or launch from a console:

```powershell
Godot_v4.7.1-stable_win64_console.exe --path .
```

## Windows V1 build

The committed `Windows Desktop` preset produces the x86_64 V1 build in `build/windows/`. Install the matching Godot 4.7.1 export templates, then run:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --export-release "Windows Desktop"
```

Distribute `TRADATALA-v1.0.1.exe` together with `TRADATALA-v1.0.1.pck`. The PCK remains separate so the build can be code-signed later and is less likely to trigger antivirus heuristics. The current local checkpoint is unsigned; signing requires a Windows signing certificate and is a separate release operation.

## Controls

- Click cards to select/deselect them; selected cards lift and glow.
- `Enter` / `Space`: start from the title menu.
- `H`: HẠ a legal new Set or Run.
- Click a table Meld to target it, then `E`: EXTEND it with the selected legal card(s).
- `D`: DISCARD exactly one selected loose card and end the turn. Discard #4 opens LAST CALL instead of settling immediately.
- `C`: CHỐT the Phase from LAST CALL after any final HẠ / EXTEND actions.
- `S`: cycle rank/suit hand sorting.
- `G`: select the highest-scoring legal new Meld; if none exists, select the best legal table extension.
- Hover a loose card to reveal its top-right meld badge: `✓` means it already belongs to a ready Phỏm; otherwise the badge shows that card's best exact completion percentage. The badge hides again when the pointer leaves.
- Ready action cards carry an animated outline: flowing green for a legal new Phỏm, yellow for a legal table extension, and a blended green/yellow sweep when both actions are available. A separate blue gradient surrounds the right-side Drink box while its charge is available and disappears when spent; cards committed to Sâm dứa preservation keep the matching blue outline until the Phase transition resolves.
- Click the `BỎ • XEM` pile to open every discarded card grouped into Bích, Cơ, Rô, and Tép columns.
- Hover the active Drink for its complete effect and timing. Click the charged Drink first to arm it, then click the required loose or table card; blue gradients identify Drink targets.
- For Sâm dứa, click the Drink during Phase 1 LAST CALL, select up to two blue-outlined loose cards, then click the Drink again to confirm before CHỐT; those marked cards survive only if the following choice is DUMP.
- `K` / `X`: KEEP / DUMP at the Phase 1 settlement.
- `Esc`: clear card and Meld selection.
- After Phase 2, continue into the next campaign Event; the wallet persists across all 28 Deals.

Buttons remain disabled until their action is legal. The footer explains the current selection.

## Architecture

- `scripts/cards/` — card identity, rank, independently mutable scoring value, enhancements, and asset lookup.
- `scripts/deck/` — standard-deck generation, deterministic seeded shuffle, draw, discard, and refill.
- `scripts/melds/` — Set/Run authority, extension legality, and persistent table Meld state.
- `scripts/scoring/` — reusable scoring contexts, the Drink catalog, extension deltas, settlement deadwood, and controlled modifier hooks.
- `scripts/economy/` — 64-bit integer VND wallet and point conversion.
- `scripts/campaign/` — seven-day state machine, data-configured requirements, generic Event/NPC interactions, Drink purchase windows, and progression signals.
- `scripts/gameplay/` — the authoritative two-Phase Deal state machine, read-only hand advisor, and exact meld-probability analysis.
- `scenes/match.tscn` — editor-authored composition root: stationary café background plus instanced board, menu, and reactive-music scenes.
- `scenes/ui/match_board.tscn` and `scenes/ui/main_menu.tscn` — static match HUD/overlay and menu ownership. Their named bindings are resolved by `MatchUI`; cards, Melds, discard history, campaign participants, archive contents, and audio players remain runtime-generated because their counts depend on game state.
- `scripts/ui/` — match coordination and dynamic card/Meld presentation, staged equations, wallet tweening, card travel, banners, and settlements. `match_ui.gd` no longer constructs the static interface.
- `tests/` — pure-rule suite plus a runtime scene smoke.

## Implemented rules

The prototype now follows the two-Phase Deal contract: each Phase has four mandatory discards, a player-confirmed LAST CALL window, and its own settlement. Table Phỏm persist across Phases; Phase 1 then offers KEEP or DUMP, with DUMP refilling toward ten.

- Deadwood is calculated once per Phase. A safe Phase uses the simple sum of remaining loose-card values; a MÓM Phase uses `value sum × loose-card count`. Phase Net is `Gross after Ù − Deadwood`.
- MÓM is checked independently per Phase from new Phỏm count. Its multiplied Deadwood is charged immediately at that Phase's settlement, with no later Wallet percentage penalty.
- Active-turn HẠ / EXTEND must preserve one mandatory discard card; LAST CALL removes that restriction and forbids further discards/refills.
- Ù is Phase-scoped: a ten-card turn that commits exactly nine cards and discards the last doubles that Phase's Gross, not Deadwood.
- Ù Khan uses the prototype near-meld definition, pays `hand value × 10`, replaces the hand, and checks the refill again.
- Sets accept any number of same-rank physical cards; Runs require one suit, unique consecutive ranks, A low, and no wrap.
- Every card sent to the discard pile remains available through the suit-grouped discard archive; mandatory discards retain Phase and discard-number provenance in the Deal record.
- Each card's hover badge summarizes its best canonical three-card Set/Run target. Percentages are exact without-replacement odds for the next refill toward ten, using the known remaining deck; the full target and missing-card calculation stay in the tooltip so probability information does not obstruct the table.
- Exactly one Drink is active at a time, and basic Drinks manipulate card flow only—never scoring: Trà đá swaps one selected loose card with the latest discard once per turn; Nhân trần grants one optional extra discard per turn without an immediate refill and is unavailable after mandatory discard #4; Nước vối returns one legal card from a table Meld once per Phase without removing banked score; Sâm dứa preserves up to two marked loose cards during the Phase 1 DUMP before the normal refill toward ten. Trà đá is the current free starter. Advanced Caffeine/Energy/Sugar IDs and categories exist without invented formulas.
- Scoring and resolution expose controlled hooks for new Phỏm, Extensions, settlement, Deadwood, MÓM, Deal resolution, and Ù.

## Early campaign

- A run is Monday through Sunday. Every day follows `Starter Event → Morning Deal → Morning Event → Noon Deal → Noon Event → Afternoon Deal → Afternoon Event → Evening Deal → requirement check` with no Evening Event.
- Cô Trà Đá is a guaranteed participant in Starter and Noon Events, but Events own participant lists and can contain zero, one, or multiple NPCs. Her mandatory interaction selects/purchases the Drink for the next two Deals.
- Morning and Afternoon Events are valid empty Events with an enabled Continue action. The same interaction model supports optional future NPCs without changing campaign progression.
- Daily VND thresholds and Drink prices are provisional data in `campaign_config.gd` and `drink_manager.gd`; thresholds are not deducted, and the wallet carries across days.
- Failing any end-of-day threshold ends the run. Passing Sunday's threshold wins the current early campaign without a Zodiac boss.

The menu includes persistent Music/Sound controls, Vietnamese/English localization, and a looping reactive music mix with four frequency bands driving presentation pulses. Relics, advanced Drink formulas, Xăm, Zodiac bosses, special weekday mechanics, story chains, shops, multiplayer, AI opponents, sound effects, and 3D presentation remain intentionally unimplemented.

## Verification

Current Godot 4.7.1 source checkpoint (2026-08-31):

- Core Deal and campaign suite: **49 / 49 passed** in both normal headless execution and the connected editor MCP runner.
- Runtime scene smoke: **passed**.
- Tutorial scene smoke: **passed**.
- Headless editor import and global-class registration: **passed**.
- Connected-editor migration proof: **passed**. The modular `match.tscn` opened and ran at 1280×720, the real Play button transitioned from menu to game, runtime cards/audio were rebuilt, and the stationary background remained outside the animated UI layers.
- Previous v1.0.0 exported Windows startup: **passed**; v1.0.1 was not rebuilt during this source-fix pass.

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/run_headless.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/runtime_scene_smoke.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/tutorial_scene_smoke.gd
```

