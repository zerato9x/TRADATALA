# TRADATALA / TRÀ ĐÁ TÁ LẢ

A Godot 4.7.1 early-campaign prototype built above the existing solo-derived Phỏm Deal. The project uses the complete card-face set in `res://cards/` and separates campaign progression, events, economy, rules, and presentation.

The official presentation uses the generated Vietnamese sidewalk-table plate at `res://assets/environment/sidewalk_table.png`, with `DFVN Pexel Grotesk` as the global game font. Cards and HUD elements remain live Godot controls layered over the environment.

The project opens on a dedicated title menu over the fixed sidewalk-table background. Choosing **VÁN MỚI** starts Monday's Starter Event, where Cô Trà Đá supplies the Drink used by the Morning and Noon Deals. The same table then carries the player through four Deals and four Event slots per day for seven days. The match layout uses a compact top status strip, a lower-right active Drink beside the hand, and a separate quiet Relics rail initialized with four presentation-only slots.

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
- Ready action cards carry one reusable animated outline: flowing green for a legal new Phỏm, orange for a legal table extension, and blue for an active Drink target. Any combination can coexist in the same multicolor sweep without covering the card face. The Drink box keeps its own blue charge outline until spent, while Sâm dứa preservation keeps blue on marked cards until the Phase transition resolves.
- Click the `BỎ • XEM` pile to open every discarded card grouped into Bích, Cơ, Rô, and Tép columns.
- Hover the active Drink for its complete effect and timing. Click the charged Drink first to arm it, then choose its eligible target objects; blue gradients identify every current Drink target.
- For Sâm dứa, click the Drink during Phase 1 LAST CALL, select up to three blue-outlined loose cards, then click the Drink again to confirm before CHỐT; those marked cards survive only if the following choice is DUMP.
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
- `scenes/ui/match_board.tscn` and `scenes/ui/main_menu.tscn` — static match HUD/overlay and menu ownership. The board keeps status at the top, passive Relics on the right, the interactive Drink and hand near the bottom, and context/utility/core actions in stable dock groups. Named bindings are resolved by `MatchUI`; cards, Melds, discard history, campaign participants, archive contents, and audio players remain runtime-generated because their counts depend on game state.
- `scripts/ui/` — match coordination and dynamic card/Meld presentation, staged equations, wallet tweening, card travel, banners, and settlements. `match_ui.gd` no longer constructs the static interface.
- `tests/` — pure-rule suite plus a runtime scene smoke.

## Implemented rules

- Deck Exhaustion (implemented 2026-09-03) is Deal-scoped across both Phases: the first empty stock recycles the eligible spent pool at most once, while a stock empty with no permitted recycle activates permanent True Exhaustion. Locked discard archives, table Melds, loose cards, and S?m d?a-preserved cards are never recycled.
- While True Exhaustion is active, canonical discard actions award the discarded card's current scoring value as a normal Phase Gross event. DUMP and U Khan hand replacement are spent-card removals, not discard-archive records.

The prototype now follows the two-Phase Deal contract: each Phase has four mandatory discards, a player-confirmed LAST CALL window, and its own settlement. Table Phỏm persist across Phases; Phase 1 then offers KEEP or DUMP, with DUMP refilling toward ten.

- Deadwood is calculated once per Phase. A safe Phase uses the simple sum of remaining loose-card values; a MÓM Phase uses `value sum × loose-card count`. Phase Net is `Gross after Ù − Deadwood`.
- MÓM is checked independently per Phase from new Phỏm count. Its multiplied Deadwood is charged immediately at that Phase's settlement, with no later Wallet percentage penalty.
- Active-turn HẠ / EXTEND must preserve one mandatory discard card; LAST CALL removes that restriction and forbids further discards/refills.
- Ù is Phase-scoped: a ten-card turn that commits exactly nine cards and discards the last doubles that Phase's Gross, not Deadwood.
- Ù Khan uses the prototype near-meld definition, pays `hand value × 10`, replaces the hand, and checks the refill again.
- Sets accept any number of same-rank physical cards; Runs require one suit, unique consecutive ranks, A low, and no wrap.
- Every card sent to the discard pile remains available through the suit-grouped discard archive; mandatory discards retain Phase and discard-number provenance in the Deal record.
- Each card's hover badge summarizes its best canonical three-card Set/Run target. Percentages are exact without-replacement odds for the next refill toward ten, using the known remaining deck; the full target and missing-card calculation stay in the tooltip so probability information does not obstruct the table.
- Exactly one Drink is active at a time, and basic Drinks manipulate card flow only—never scoring. Trà đá passively requires two discards per turn: the first is the Phase's mandatory discard, the second is separately recorded and must resolve before refill/LAST CALL. Nhân trần swaps one selected loose card with any mandatory discard from the current Phase once per Phase; Nước vối returns one legal card from a table Meld once per Phase without removing banked score; Sâm dứa preserves up to three marked loose cards during the Phase 1 DUMP before the normal refill toward ten. Trà đá is the current free starter. Advanced Caffeine/Energy/Sugar IDs and categories exist without invented formulas.
- Every implemented basic Drink has a reactive opportunity cue on the Sound bus. The three glass-clink variants rotate without immediate repetition and fire only on the inactive-to-active edge: Trà đá after its first discard, Nhân trần when a current-Phase discard completes a hand Meld, Nước vối when a legal Meld card can be recovered, and Sâm dứa on entry to the Phase 1 preservation window.
- Card manipulation also routes through the Sound bus: selecting a card plays the dedicated choose clip, successful Phỏm/extension/discard placement rotates three non-repeating place clips, every non-empty draw result plays the draw clip once, and an authoritative Deal reset plays the shuffle clip. Hidden boot setup stays silent.
- Scoring and resolution expose controlled hooks for new Phỏm, Extensions, settlement, Deadwood, MÓM, Deal resolution, and Ù.

## Early campaign

- A run is Monday through Sunday. Every day follows `Starter Event → Morning Deal → Morning Event → Noon Deal → Noon Event → Afternoon Deal → Afternoon Event → Evening Deal → requirement check` with no Evening Event.
- Cô Trà Đá is a guaranteed participant in Starter and Noon Events, but Events own participant lists and can contain zero, one, or multiple NPCs. Her mandatory interaction selects/purchases the Drink for the next two Deals.
- Morning and Afternoon Events are valid empty Events with an enabled Continue action. The same interaction model supports optional future NPCs without changing campaign progression.
- Daily VND thresholds and Drink prices are provisional data in `campaign_config.gd` and `drink_manager.gd`; thresholds are not deducted, and the wallet carries across days.
- Failing any end-of-day threshold ends the run. Passing Sunday's threshold wins the current early campaign without a Zodiac boss.

The Escape/Menu window defaults to the reactive Authored DJ system for a new campaign: the approved Mèo/CAT route plays on day one, the Chó/DOG route on day two, and the two routes alternate by day. The standalone album player for all 26 OST files remains available as an explicit Playing Tracks option, with cover art, track selection, progress, next-track preview, play/pause, Shuffle, and Repeat Off/All/One; its spectrum still drives four presentation frequency bands. Relics, advanced Drink formulas, Zodiac bosses, special weekday mechanics, story chains, shops, multiplayer, AI opponents, broader ambient/UI sound design, and 3D presentation remain intentionally unimplemented.

## Verification

Current Drink-source reconciliation checkpoint (2026-09-01):

- Deterministic suites: **68 / 68 passed** in Godot 4.7.1 headless execution (**60 Core Deal + 8 Campaign**), including Deck Exhaustion / True Exhaustion and the revised Drink rules; MÓM and Ù Khan coverage remains unchanged.
- Runtime scene smoke: **passed**, including the in-world Drink prop, hand/discard/meld target cues, three-card Sâm dứa selection, and the LAST CALL boundary.
- Tutorial scene smoke: **passed** after the Drink changes.
- Godot editor filesystem refresh and project relaunch: **passed**; the connected project reached live with no current parse errors after the stale editor cache was refreshed.
- Connected-editor live visual/physical-input proof for the new target interaction: **not rerun** in this pass because the debug window could not be foregrounded reliably; scene smoke is the current target-handler/cue acceptance evidence.
- Previous v1.0.0 exported Windows startup: **passed**; v1.0.1 was not rebuilt during this source-fix pass.

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/run_headless.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/runtime_scene_smoke.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/tutorial_scene_smoke.gd
```

