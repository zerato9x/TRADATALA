> Updated 2026-09-18: acquisition now uses wallet-priced purchases; see [Resolve accounting](RESOLVE_ACCOUNTING.md). Historical free-selector notes below describe the original implementation.

# First relic set — implemented 2026-09-17

## Implemented now

Hàng Rong's existing morning/afternoon interaction opens a temporary, free relic selector. All ten supplied sprites are used directly. Equip up to four relics; remove one before equipping a fifth. Removed relics remain owned. Equipment persists between deals within the run; New Game clears it. This is a test acquisition path, not a final shop economy.

| Stable ID | Display name | Temporary Point bonus |
|---|---|---|
| hair_clip | Kẹp Tóc | New SET: +30 |
| comb | Lược | New RUN: +8 per card |
| rubber_band | Dây Thun | Each successful Extension action: +20 |
| chewing_gum | Kẹo Cao Su | Same meld's Extension index this Phase × 10 |
| sunflower_seeds | Hạt Hướng Dương | New SET/RUN: +5 per card |
| toothpicks | Que Tăm | New meld with exactly 3 cards: +20 |
| hard_candy | Kẹo Cứng | New meld with 4+ cards: +50 |
| sunglasses | Kính Râm | New meld where every card is Spades/Clubs: +40 |
| lipstick | Son Môi | New meld where every card is Hearts/Diamonds: +40 |
| buttons | Cúc Áo | New SET with exactly 4 cards: +75 |

## Authority and scoring

- RelicCatalog holds stable IDs, names, trigger conditions, balance values, sprite paths, and localized effect keys.
- DealState owns RelicRuntime's acquired inventory, equipped IDs, and per-physical-meld extension counts.
- DealState calls resolve exactly once after normal scoring has been applied for a successful create_meld or extend_meld.
- Results are separate ScoringContext.relic_bonuses receipts. They never modify final_points, theoretical_score, meld.scored_points, extension delta, presentation_hits, or scoring_passes.
- Each bonus goes through DealState._record_phase_points with a relic-specific reason, preserving the existing phase accounting and VndWallet conversion. The UI never awards points.
- Relics do not subscribe to per-pass scoring signals. Previews, failed actions, exhaustion replays, native retriggers, and Gieo retriggers do not create extra relic activations.
- Extension counts use the table meld_id, increment once per successful action (regardless of added-card count), and reset in the existing phase reset path and on a new deal. Unequipping does not reset a counter.
- Existing in-memory tutorial snapshots include inventory/equipment/counters. Tutorial entry clears equipment; interrupted-deal restoration restores the saved state. No disk save system was introduced.

## Presentation

The four existing framed HUD slots show supplied sprites and Vietnamese names, with localized name/effect tooltips. Bonuses append to the existing scoring presentation after every normal scoring pass. Each receives a readable 0.65-second beat, the shared blue animated CardActionOutline and a brief tint pulse on its slot, plus a named Point receipt and converted VND contribution. All contributions flow through the existing money stack and wallet display. Multiple relics follow equipped order without overlapping receipts.

Hàng Rong keeps the existing NPC focus/back/dialogue interaction. Continue is hidden while the selector is open and restored by the existing return flow. Demo content gating remains in place.

## Files added

- scripts/relics/relic_catalog.gd
- scripts/relics/relic_runtime.gd
- scripts/ui/relic_selector.gd
- scripts/ui/relic_slot.gd
- tests/test_relics.gd
- tests/relic_scene_smoke.gd
- assets/relics/basic_*.png: ten original supplied sprites and Godot import files
- Godot UID sidecars for new scripts
- This report and docs/images/relic_selector.png, relic_trigger.png, relic_hud.png

## Files updated by this implementation

- scripts/gameplay/deal_state.gd: authoritative action integration, phase resets, in-memory snapshot.
- scripts/scoring/scoring_context.gd: separate bonus receipts.
- scripts/ui/match_ui.gd: Hàng Rong selector, HUD slots, ordered money receipts, run/tutorial lifecycle.
- scripts/ui/money_presentation.gd: relic receipt beat and activation callback.
- locale/ui.csv and imported ui.vi.translation / ui.en.translation: descriptions, controls, greeting.
- tests/run_headless.gd: include relic suite.

These existing files already contained unrelated work when implementation began; that work was preserved. ScoringPipeline itself was not modified by this relic implementation.

## Validation

- Full deterministic runner: 167 passed, 0 failed, 0 skipped.
- 19 new relic tests cover all locked triggers and exclusions, multi-relic stacking, native/Gieo pass isolation, intrinsic score/delta preservation, invalid actions, previews, exhaustion exclusion, independent/phase-reset extension counts, inventory limits, snapshots, and deal carry-over.
- Rendered relic smoke: passed. Synthetic pointer clicks equipped and removed all ten relics; tested four-slot rejection, removal/re-equip, all four named bonus receipts, activation outlines, queue completion, authoritative-wallet immutability during playback, and final displayed balance.
- Inspected real rendered captures of the corrected selector, activation receipt/outline, and completed HUD.
- Existing tutorial smoke: passed.
- Scoped git diff --check: passed.
- Existing runtime_scene_smoke.gd could not complete: line 353 accesses resource_path on a null drink texture in its noon-drink assertion. The process was stopped after the script stalled. This is outside the relic path; the broader runtime suite is not reported as passing.

## Remaining limits

Balance is temporary. Acquisition is free testing only; no prices, rarity, upgrades, selling, replacement economy, meta progression, or disk persistence. Pointer checks are synthetic, not human physical-input testing. No packaged build was exported. No commits or pushes were made.
