# TRADATALA / TRÀ ĐÁ TÁ LẢ

A Godot 4.7.1 solo Phỏm roguelike with a seven-day campaign and Endless continuation. The project uses the complete card-face set in `res://cards/` and separates campaign progression, events, economy, rules, and presentation.

The official presentation uses the generated Vietnamese sidewalk-table plate at `res://assets/environment/sidewalk_table.png`, with `DFVN Pexel Grotesk` as the global game font. Cards and HUD elements remain live Godot controls layered over the environment.

The current full-build working tree includes all twelve [Zodiac bosses](docs/ZODIAC_RUNTIME_2026-10-02.md), their three difficulty tiers, permanent history and Emblems, and the post-Snake Dragon encounter. The day's Zodiac occupies the top-right slot at Noon and Afternoon. [Cat's authored Tier 1 / Tier 1+ persuasion](docs/CAT_PERSUASION_VERTICAL_SLICE_2026-10-03.md) adds Questions, daily Patience, permanent progression, visible counteroffers, and physical card / owned Relic promises judged on the same-day Afternoon return. [Cat now continues through Kindred](docs/CAT_EXPANSION_2026-10-10.md), with remembered outcomes across runs, six deeper conversation nodes, a player-selected card promise, and an authored Last Chance. [Rooster now continues through Kindred](docs/ROOSTER_EXPANSION_2026-10-10.md), with twelve bilingual encounters, positive action commitments, remembered deadlines, a Last Chance, and a reachable private Emblem scene. Already-started demand chains keep their saved terms. All Zodiac artwork uses the supplied PNGs; additional daytime personalities and story content remain to be authored. Existing published release notes describe their historical builds.

The project opens on a centered gold TRADATALA title over the original sidewalk-table background. **VÁN MỚI** opens difficulty selection and the seven daily debts; **TÙY CHỈNH** holds the optional seed, music mode, and owned Zodiac Emblem preference. Continue is available directly on Home when an autosave exists, and replacing it requires confirmation. Collections, Handbook, Music, and Settings have separate pages. A new run begins with VNĐ25,000 at Monday's Starter Event: Đòi Nợ presents the day's debt, Đánh Giày offers polish, and Cô Trà Đá supplies the Drink used by the Morning and Noon Deals. Monday teaches through real play when you ask Strawy; Tutorial and curated First Seed openings can be switched independently. The bilingual searchable Handbook replaces the standalone tutorial. The same table then carries the player through four Deals and four Event slots per day for seven days. The match layout uses a compact top status strip, a lower-right active Drink beside the hand, and a separate Relics rail with four equipped slots.

Home now includes **SAVE FILES** with three named profiles. Each keeps its own drink unlocks, difficulty progression, Zodiac history, emblems, endings, and current run. Existing saves import into File 1. Press **F9** or choose **DEBUG BOSSES** to open Boss Lab: pick any boss, its difficulty, phase, seed, opening hand, Drink, and wallet; Replay, Resume Test, and Exit keep test progress separate from the normal files. See [save files and Boss Lab](docs/META_SAVE_BOSS_DEBUG_2026-10-02.md).

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
- `Enter` / `Space`: activate the focused menu control.
- `H`: HẠ a legal new Set or Run.
- Click a table Meld to target it, then `E`: EXTEND it with the selected legal card(s).
- `D`: DISCARD exactly one selected loose card and end the turn. Discard #4 opens LAST CALL instead of settling immediately.
- `C`: CHỐT the Phase from LAST CALL after any final HẠ / EXTEND actions.
- `S`: cycle rank/suit hand sorting.
- `G`: select the highest-scoring legal new Meld; if none exists, select the best legal table extension.
- Hover a loose card to see its completion percentage, or the straw-hat symbol when it is ready to Meld. The badge hides when the pointer leaves. Strawy's Card info action provides requested discard advice separately; card selection and green/yellow play cues retain their normal behavior.
- Strawy appears during the game, with a small contextual menu on one tap. His brief explanations say what to do and why, using a silent typewriter animation; tap the text to reveal the rest immediately. During a Deal, double tap him to select the recommended discard, then tap again to discard it. A changed hand or selection cancels confirmation. Trà Đá's extra discard/Skip needs another request. Pointing tours explain each step and are available through the menu. Settings → Show Strawy hides or restores him immediately. After Monday's tutorial, players choose Keep Strawy or Turn off once; that preference persists. Tutorial and First Seed are independent persisted switches in Settings; First Seed is captured when a run starts.
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
- `scripts/zodiac/` — Zodiac definitions, daily negotiation, permanent concrete history/Emblems, and Deal-owned boss rules with independent saved RNG.
- `scripts/gameplay/` — the authoritative two-Phase Deal state machine, read-only hand advisor, and exact meld-probability analysis.
- `scenes/match.tscn` — editor-authored composition root: stationary café background plus instanced board, menu, and reactive-music scenes.
- `scenes/ui/match_board.tscn`, `scenes/ui/main_menu.tscn`, and `scenes/ui/front_end.tscn` — static match HUD/overlay, wired jukebox/legacy controls, and current menu shell. `FrontEnd` renders menu content and emits navigation/start requests to `MatchUI`. The board keeps status at the top, passive Relics on the right, the interactive Drink and hand near the bottom, and context/utility/core actions in stable dock groups. Named bindings are resolved by `MatchUI`; cards, Melds, discard history, campaign participants, archive contents, and audio players remain runtime-generated because their counts depend on game state.
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
- `DealState.hand_advice()` supplies Strawy's discard decisions and requested explanations. It evaluates each legal discard against the resulting hand and next refill, preserving playable cards when alternatives exist. Outcomes rank by target completion odds, projected score, then deadwood; physical IDs break ties. Keep is a relative score used in this advice. Card hover badges retain `MeldProbabilityAdvisor`'s original completion percentages and ready-meld straw symbol. Exhaustion excludes locked mandatory discards and Trà Đá compares deferred refill with extra discard versus Skip. Analysis neither consumes RNG nor commits game state.
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

Money feedback uses the original card-by-card pacing. A click, key/controller button or tap during the animation speeds up the current money queue; the next queue starts normally. The speed-up press is consumed so it cannot also play a card or activate a gameplay button. [Scoring presentation](docs/TRIGGER_FIRST_SCORING.md) documents the exact pacing and validation.

The Escape/Menu jukebox offers Authored DJ and Playlist through one mode selector and one source chooser. DJ shows Mèo/CAT and Chó/DOG; Playlist shows all 26 OST files, with Shuffle and Repeat Off/All/One. Choosing DJ or changing its set immediately starts that authored set at the approved cue for the current event/deal/phase, preserving pause and gameplay state. The chosen set also applies at subsequent day openings; fresh settings default to CAT. Continue restores the actual saved transport, including pending authored transitions, rather than starting a new cue. Cover art, progress, play/pause and the four presentation frequency bands follow the actual audio source. The offline `MusicLoopAudition` tester also supports arranging bar-aligned segments into named, repeatable sections without changing the source WAVs. The full build implements all twelve Zodiac boss mechanics; some character story and gift content still uses placeholders. AI opponents, multiplayer and 3D presentation are out of current product scope. The new progression prices and Endless curve are implemented balance values that still need extended playtesting.

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

All twelve Drinks have implemented card-flow effects, production prices, and campaign unlock/day gates; Trà Đá remains free and its extra discard is optional. The table shop uses inspect-before-order interactions, shared localized NPC speech, and an action-word legend; only Sâm dứa and Bạc xỉu offer the Phase transition preservation choice. See [Drink roster and NPC conversation testing](docs/DRINK_ROSTER_TESTING.md) for the rules and historical verification evidence.

## Campaign overhaul validation

See [the implementation and acceptance ledger](docs/CAMPAIGN_OVERHAUL_2026-09-20.md) for current scope and evidence. Run `tests/run_headless.gd` for deterministic rules, economy and save checks. Run `tests/campaign_overhaul_scene_smoke.gd` for the complete real Monday-to-Tuesday flow, using `-- --english --large` for English at 1920×1080 or `-- --tradatala-demo` for restricted-demo coverage. Omit `--headless` to render its review captures. `tests/tutorial_scene_smoke.gd` checks that the retired tutorial route opens the Handbook without modifying the live deal.

The public/release baseline and current project/export metadata remain **1.0.3**. The September 29 repair/follow-up set and its documentation were checkpointed on `main` and pushed to `origin/main` on 2026-09-30. They remain source-tree WIP relative to the public v1.0.3 build: no new package, release tag, or game publication was made. The 1.0.2 package instructions above describe the previous release.

For the September 29 pull and fixes, see [the codebase audit and repair evidence](docs/CODEBASE_AUDIT_2026-09-29.md). On Windows, run `tools/validate_project.ps1 -Godot <console-executable> -Full` for bounded parsing, core, runtime, music resume, full/demo campaign, progression, and focused checks. The gate isolates save/settings profiles and rejects logged script errors even when Godot exits zero. Continue restores saved music; new-run music choices do not restart a resumed DJ set. See [the save contract](docs/RUN_PROGRESSION_SAVES_2026-09-19.md) for legacy-save behavior.
