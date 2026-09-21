# TRADATALA / TRÀ ĐÁ TÁ LẢ

A Godot 4.7.1 solo Phỏm roguelike with a seven-day campaign and Endless continuation. The project uses the complete card-face set in `res://cards/` and separates campaign progression, events, economy, rules, and presentation.

The official presentation uses the generated Vietnamese sidewalk-table plate at `res://assets/environment/sidewalk_table.png`, with `DFVN Pexel Grotesk` as the global game font. Cards and HUD elements remain live Godot controls layered over the environment.

The project opens on a dedicated title menu over the fixed sidewalk-table background. Choosing **VÁN MỚI** opens the run menu: continue the autosave, enter a seed, or start a random run. A new run begins with VNĐ25,000 at Monday's Starter Event: Đòi Nợ presents the day's debt, Đánh Giày offers polish, and Cô Trà Đá supplies the Drink used by the Morning and Noon Deals. Monday teaches through real curated hands and optional contextual hints; the bilingual searchable Handbook replaces the standalone tutorial. The same table then carries the player through four Deals and four Event slots per day for seven days. The match layout uses a compact top status strip, a lower-right active Drink beside the hand, and a separate Relics rail with four equipped slots.

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

Distribute `TRADATALA-v1.0.2.exe` together with `TRADATALA-v1.0.2.pck`. The PCK remains separate so the build can be code-signed later and is less likely to trigger antivirus heuristics. The current local checkpoint is unsigned; signing requires a Windows signing certificate and is a separate release operation.

## Full itch.io release

The `Web Full Release` preset exports the complete campaign without the demo feature flag. The existing `Web Demo` preset retains the restricted configuration. Both browser presets use the official no-threads Compatibility template.

Run `tools/build_full_release.ps1` to export fresh browser and Windows ZIPs with a version, source-state manifest, SHA256 hashes, and itch.io archive-limit checks. Use a new output directory for each build. The official `web_nothreads_release.zip` must be installed at `build/demo-tools/`, and matching Windows export templates must be installed in Godot's application-data directory.

See [the 1.0.2 release checkpoint](docs/releases/2026-09-19-v1.0.2.md) for release scope and validation, and [itch.io page copy](docs/releases/ITCH_PAGE_v1.0.2.md) for the prepared description.

## Controls

- Click cards to select/deselect them; selected cards lift and glow.
- `Enter` / `Space`: start from the title menu.
- `H`: HẠ a legal new Set or Run.
- Click a table Meld to target it, then `E`: EXTEND it with the selected legal card(s).
- `D`: DISCARD exactly one selected loose card and end the turn. Discard #4 opens LAST CALL instead of settling immediately.
- `C`: CHỐT the Phase from LAST CALL after any final HẠ / EXTEND actions.
- `S`: cycle rank/suit hand sorting.
- `G`: select the highest-scoring legal new Meld; if none exists, select the best legal table extension.
- Hover a loose card to reveal its top-right meld badge: the supplied white straw-hat symbol means it already belongs to a ready Phỏm; otherwise the badge shows that card's best exact completion percentage. The badge hides again when the pointer leaves.
- Ready action cards carry one reusable animated outline: flowing green for a legal new Phỏm, orange for a legal table extension, and blue for an active Drink target. Any combination can coexist in the same multicolor sweep without covering the card face. The Drink box keeps its own blue charge outline until spent, while Sâm dứa preservation keeps blue on marked cards until the Phase transition resolves.
- Click the `BỎ • XEM` pile to open every discarded card grouped into Bích, Cơ, Rô, and Tép columns.
- Hover the active Drink for its complete effect and timing. Click the charged Drink first to arm it, then choose its eligible target objects; blue gradients identify every current Drink target.
- Drink targeting raises selected cards and exposes **Use Drink** and **Cancel / Esc**. Swap Drinks open a larger legal-discard picker after choosing a hand card. For Sâm dứa, select up to three cards during Phase 1 LAST CALL and press **Use Drink** before CHỐT; those marked cards survive only if the following choice is DUMP.
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

- Exhaustion is checked only when an active draw/refill requests a card from an already-empty draw deck. The interrupted request triggers each current table Meld once, rebuilds and shuffles the draw deck from discard, spent/DUMP, and table-Meld cards, then resumes until the original request is satisfied. Drawing the final requested stock card does not trigger Exhaustion.

The prototype now follows the two-Phase Deal contract: each Phase has four mandatory discards, a player-confirmed LAST CALL window, and its own settlement. Table Phỏm persist across Phases. Normal Phase 2 entry automatically DUMPs loose cards and refills toward ten; only Sâm dứa and Bạc xỉu allow KEEP / preservation.

- Deadwood is calculated once per Phase. A safe Phase uses the simple sum of remaining loose-card values; a MÓM Phase uses `value sum × loose-card count`. Phase Net is `Gross after Ù − Deadwood`.
- MÓM is checked independently per Phase from new Phỏm count. Its multiplied Deadwood is charged immediately at that Phase's settlement, with no later Wallet percentage penalty.
- Active-turn HẠ / EXTEND must preserve one mandatory discard card; LAST CALL removes that restriction and forbids further discards/refills.
- Ù is Phase-scoped: a ten-card turn that commits exactly nine cards and discards the last doubles that Phase's Gross, not Deadwood.
- Ù Khan uses the prototype near-meld definition, pays `hand value × 10`, replaces the hand, and checks the refill again.
- Sets accept any number of same-rank physical cards; Runs require one suit, unique consecutive ranks, A low, and no wrap.
- Every card sent to the discard pile remains available through the suit-grouped discard archive; mandatory discards retain Phase and discard-number provenance in the Deal record.
- Each card's hover badge summarizes its best canonical three-card Set/Run target. Percentages are exact without-replacement odds for the next refill toward ten, using the known remaining deck; the full target and missing-card calculation stay in the tooltip so probability information does not obstruct the table.
- Exactly one Drink is active at a time. All 12 Drinks have implemented mechanics. Campaign day/event gates and persistent achievement unlocks control availability; paid drinks cost 2–8% of the current debt goal, while Trà đá remains free. Every Drink effect is optional: Trà đá lets you skip its extra discard with End Turn. Nhân trần and Đen đá reset each normal Turn, with no bonus LAST CALL charge. Energy Pair creation and C2 Run creation require explicit Drink targeting. Drinks add no score multiplier; new Phỏm use the ordinary scoring pipeline. See [Drink roster and conversation flow](docs/DRINK_ROSTER_TESTING.md) for rules and controls.
- Every implemented basic Drink has a reactive opportunity cue on the Sound bus. The three glass-clink variants rotate without immediate repetition and fire only on the inactive-to-active edge: Trà đá after its first discard, Nhân trần when a current-Phase discard completes a hand Meld, Nước vối when a legal Meld card can be recovered, and Sâm dứa on entry to the Phase 1 preservation window.
- Card manipulation also routes through the Sound bus: selecting a card plays the dedicated choose clip, successful Phỏm/extension/discard placement rotates three non-repeating place clips, every non-empty draw result plays the draw clip once, and an authoritative Deal reset plays the shuffle clip. Hidden boot setup stays silent.
- Scoring and resolution expose controlled hooks for new Phỏm, Extensions, settlement, Deadwood, MÓM, Deal resolution, and Ù.

## Early campaign

- A run is Monday through Sunday. Every day follows `Starter Event → Morning Deal → Morning Event → Noon Deal → Noon Event → Afternoon Deal → Afternoon Event → Evening Deal → requirement check` with no Evening Event.
- Cô Trà Đá is a guaranteed participant in Starter and Noon Events, but Events own participant lists and can contain zero, one, or multiple NPCs. Her mandatory interaction selects/purchases the Drink for the next two Deals.
- Morning and Afternoon Events include optional Gieo Quẻ, lottery and Hàng Rong visits. Hàng Rong offers three seeded unowned relics per visit; buy one or pay to reroll before buying. Owned relics can be equipped or removed for free.
- Daily debts are 250k, 500k, 1m, 2m, 4m, 8m and 16m VND. The collection receipt deducts that day's debt exactly once; the remaining wallet carries forward.
- A collection shortfall ends the run. Paying Sunday opens a scroll of MVP cards, finances and run statistics; choose New Run or continue into Endless. Endless begins at 24m debt and grows 50% each day, retaining the current seed, deck, relics and wallet.
- Runs autosave committed gameplay, including exact draw order, card state, NPC/shop choices, RNG state and pending collection. Continue Saved Run restores the last committed state; previous-file backup recovery is available. Drink unlocks persist independently.

See [progression, saves, prices and validation](docs/RUN_PROGRESSION_SAVES_2026-09-19.md) for the exact day gates, Sting → Bò Húc / C2 → Nước mía branches, unlock goals, save schema and limitations.

The Escape/Menu window defaults to the reactive Authored DJ system for a new campaign: the approved Mèo/CAT route plays on day one, the Chó/DOG route on day two, and the two routes alternate by day. The standalone album player for all 26 OST files remains available as an explicit Playing Tracks option, with cover art, track selection, progress, next-track preview, play/pause, Shuffle, and Repeat Off/All/One; its spectrum still drives four presentation frequency bands. The offline `MusicLoopAudition` tester also supports arranging bar-aligned segments into named, repeatable sections without changing the source WAVs. Zodiac bosses, special weekday mechanics, story chains, multiplayer, AI opponents and 3D presentation remain unimplemented. The new progression prices and Endless curve are implemented balance values that still need extended playtesting.

## Verification

Current Drink-source reconciliation checkpoint (2026-09-01):

- Deterministic coverage includes draw-boundary timing, interrupted refill resumption, shuffled full-zone recycling, exactly-once per-Meld Exhaustion triggers, card accounting, Drinks, MÓM, and Ù Khan.
- Runtime scene smoke: **passed**, including the in-world Drink prop, hand/discard/meld target cues, three-card Sâm dứa selection, and the LAST CALL boundary.
- Tutorial scene smoke: **passed** after the Drink changes.
- Godot editor filesystem refresh and project relaunch: **passed**; the connected project reached live with no current parse errors after the stale editor cache was refreshed.
- Connected-editor live visual/physical-input proof for the new target interaction: **not rerun** in this pass because the debug window could not be foregrounded reliably; scene smoke is the current target-handler/cue acceptance evidence.
- Previous v1.0.0 exported Windows startup: **passed**; v1.0.1 was rebuilt after this source-fix pass and its packaged headless startup smoke **passed**.

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/run_headless.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/runtime_scene_smoke.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/tutorial_scene_smoke.gd
```

## Gieo permanent card marks

For the pull-error fix, sprite alignment, screen behavior, and the 64-composition
runtime regression, see [Gieo Quẻ screen audit](docs/GIEO_QUE_SCREEN.md).

Gieo-modified cards combine four always-on signatures: a vermilion seal, spectral
frame, gilded diagonal cuts and liquid foil. The developer comparison at
`scenes/debug/gieo_card_fx_preview.tscn` (F6) shows all 16 property states on 48 cards,
with native-size artwork and a clickable enlarged inspector.
See [Gieo materials](docs/GIEO_CARD_FX.md) for composition, tuning and actual checks.
Focused tests passed 90/90; the runtime smoke passed with shutdown resource
diagnostics documented there. Live GPU checks cover all combinations and animation.


## Drink roster and NPC conversations

All twelve Drinks have mechanics-testing effects at a temporary zero test price. The table shop uses inspect-before-order interactions, shared localized NPC speech, and an action-word legend; only Sâm dứa and Bạc xỉu offer the Phase transition preservation choice. See [Drink roster and NPC conversation testing](docs/DRINK_ROSTER_TESTING.md) for the rules and current verification evidence.

## Campaign overhaul validation

See [the implementation and acceptance ledger](docs/CAMPAIGN_OVERHAUL_2026-09-20.md) for current scope and evidence. Run `tests/run_headless.gd` for deterministic rules, economy and save checks. Run `tests/campaign_overhaul_scene_smoke.gd` for the complete real Monday-to-Tuesday flow, using `-- --english --large` for English at 1920×1080 or `-- --tradatala-demo` for restricted-demo coverage. Omit `--headless` to render its review captures. `tests/tutorial_scene_smoke.gd` checks that the retired tutorial route opens the Handbook without modifying the live deal.

Current working version: **1.0.3**. See [the polish and validation report](docs/releases/2026-09-21-v1.0.3-polish.md). The 1.0.2 package instructions above describe the previous release; this pass has not exported or published new packages.
