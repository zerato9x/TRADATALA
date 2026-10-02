# Zodiac Noon / Afternoon negotiation — 2026-10-02

This records the October 2 implementation and validation. Rooster continues to use this demand grammar. Fresh Cat encounters now use [the authored Tier 1 / Tier 1+ persuasion flow](CAT_PERSUASION_VERTICAL_SLICE_2026-10-03.md); Cat demand counts, old personality favorites, and Special-scene progression described below apply only to historical behavior or an already-started legacy save. The October 3 report contains current validation results.

The fixed pay → promise → alter → gift sequence has been replaced with campaign-owned, configurable Noon demand chains. The day's Zodiac uses its supplied overlay in the Event Table's top-right NPC slot at **NOON** and **AFTERNOON**. Lottery Uncle still occupies that slot in Morning; in Afternoon he appears only in the lottery result receipt. Dragon remains the existing post-Snake endgame encounter.

## Behavior

- Each demand shows its speech, exact cost, quantity, targeting rule, selection authority, and revealed physical cards. Mechanical terms are always visible; the optional details button expands tonight's boss rule.
- Responses are **ACCEPT / REFUSE / HAGGLE**. Haggle previews a concrete counteroffer and spends nothing. A separate Accept commits it. Both current profiles preserve respected, cost-free refusals and state this before the decision. Repeated/stale UI clicks cannot accept a following demand or an altered offer.
- Rooster currently asks for 2–4 demands; Cat asks for 2–3. The range and completion thresholds are catalog configuration. Further profiles can use other counts. The last demand prefers a legal next-Deal commitment.
- Noon promises include scoring before the first mandatory discard, performing an action, avoiding an action, or maintaining a wallet floor. They concern the **Afternoon Deal** and remain pending even after a breach/success is observed. The **Afternoon Event** publishes their outcomes once, shows the agreement history, and finalizes disposition.
- The Zodiac leaves Noon's overview after the chain. Normal fortune-teller/drink service remains available. Noon Continue requires the negotiation and existing mandatory drink interaction to finish. Refusal completes a demand without a resource cost.
- The new interface no longer offers the old Stay/Deal-skip response. Already scheduled skips in legacy saves remain valid. An already resolved legacy Noon visit is not charged again or turned into another chain on resume.

## Architecture

`ZodiacService` owns negotiation state, generation, authority, costs, promises, counteroffers, history, disposition, and a dedicated campaign-seeded RNG stream. `ZodiacCatalog` supplies Rooster/Cat templates, preferences, thresholds, demand ranges, haggle strategies, and favorites. Other daytime profiles are deliberately inert and use the existing NORMAL middle difficulty; their authored evening mechanics remain available.

`ZodiacDemand` is a value-only dictionary grammar: verb × targeting × authority, plus quantity, destination, resource amount, metadata, and stable target/offer IDs. It validates each verb before preparing a candidate pool and checks the entire selection again before any mutation. Invalid preferred groups fall back to an explicit legal ANY group of the same quantity; insufficient quantities are never silently reduced.

`CardTargetQuery` owns current-suit/rank queries, transformed-card queries, property queries, exact same-suit/consecutive groups, partial player-selection feasibility, and seeded card selection. Gieo Quẻ reuses the extracted random/group helpers while retaining its cast state machine and existing reduced-count fallbacks. A comparison against the former helpers verified identical selected IDs and RNG states for 45 cases, including transformed, partially sealed, and fully sealed decks.

Card verbs use existing `CardData` APIs: REMOVE_PROPERTY removes the last Gieo property; RESET uses existing reset semantics and keeps seals; SEAL locks future transformations; SET_RANK and SET_SUIT use the same permanent mutations as Gieo Quẻ. Physical IDs and deck size remain stable. UI selection uses the existing inspect/sort/search `DeckScreen`, including exact offered-three pools and sequential multi-card selection.

The Event Table owns overlay composition, focused character staging, mouse/touch input, Back, and Continue. Dynamic silhouette masks rebuild when the Zodiac texture changes. The UI observes journaled Zodiac wallet changes through the existing service-payment presentation path.

## Persistence and preserved behavior

The service snapshot stores primitive negotiation values, current demand, displayed counteroffer, counts, history, observations, disposition, and RNG state. Card references are `unique_id` strings. `RunSave` already captures/restores the nested Zodiac snapshot, so its version-2 envelope needs no schema change. Legacy successes, completed Noon requests, pending promises, and scheduled skips are adapted without replaying costs.

Persistent campaign deck, Gieo Quẻ, card mutation/reset/seal semantics, wallet authority, Relic ownership/equipment, favorite IDs/tags, history/Emblems, seeded campaign streams, localization, and all existing evening scoring/boss rules are retained. The middle disposition remains the project's current NORMAL value; legacy NEUTRAL remains compatible with boss configuration.

Favorite Relic substitution works now: an owned favorite by ID/tag can be shown as a counteroffer; only Accept calls `RelicRuntime.gift()`, removing ownership and equipment and committing the existing gift counters. Expanded Relic demands, weighting, tolerance bonuses, and additional character favorites/personalities are deferred.

## Files

Added:

- `scripts/cards/card_target_query.gd` and UID; `scripts/zodiac/zodiac_demand.gd` and UID.
- `tests/zodiac_negotiation_tests.gd`, `tests/zodiac_negotiation_resume_smoke.gd`.
- `tools/validate_zodiac_negotiation.ps1`; this report and its validation JSON.

Modified for this change:

- `scripts/zodiac/{zodiac_service,zodiac_catalog}.gd`.
- `scripts/campaign/{campaign_manager,campaign_npc_catalog,gieo_que_service}.gd`.
- `scripts/ui/{zodiac_table,event_table_controller,match_ui,npc_tap_target}.gd`.
- `tests/{test_zodiac,test_campaign,test_gieo_que,test_misc_npc,zodiac_scene_smoke,event_table_overhaul_smoke,campaign_overhaul_scene_smoke}.gd`.
- README and the existing Zodiac runtime/historical slice documentation.

Removed: placeholder `dragon/goat/horse/monkey/ox/rat/snake/tiger.svg` and their `.svg.import` sidecars. All twelve catalog sprite entries use the supplied PNG artwork; the eleven ordinary visitors use their supplied `_overlay.png` files.

Existing unrelated WIP was preserved. No Git checkpoint, export, or publication was performed.

## Validation and manual review

Run `tools/validate_zodiac_negotiation.ps1 -Full -Rendered` with Godot 4.7.1, or pass `-Godot` for another executable location. Each check uses isolated app data; the intentional write/read pair shares only its own temporary profile. Logs and rendered screenshots are under `.godot/negotiation-validation/`. Exact results are recorded in `ZODIAC_NEGOTIATION_VALIDATION_2026-10-02.json`.

| Check | Result |
| --- | --- |
| Complete core suite after final legacy-save changes | 308/308 passed |
| Focused negotiation and Gieo suite | 46/46 passed |
| Rendered Zodiac UI and synthetic touch | 107 checks, 0 failures |
| Separate-process save/write and restore/read | 5 + 10 checks, 0 failures |
| Former/new Gieo targeting comparison | 45 cases, identical IDs and RNG states |
| Rendered Event Table | 116 checks, 0 failures |
| Rendered Gieo screen | 474 checks, 0 failures |
| All twelve evening bosses | 746 checks, 0 failures |
| Runtime, tutorial, campaign progression, and miscellaneous NPC scenes | Passed |

The broad rendered suite ran before the final legacy-save adaptation; the final focused suite, complete core suite, rendered Zodiac scene, and separate-process resume checks ran afterward. Screenshot review confirms readable English/Vietnamese terms, counteroffer/card selection, and the separate Afternoon lottery receipt. Final test stderr logs were empty.

1. Start a full-build run and reach Monday's Morning Event. Lottery Uncle should occupy top-right; no Zodiac appears yet.
2. Reach Noon. Click/tap the Zodiac name or visible animal in top-right. Confirm the full character, terms, card faces, and all three responses are readable in English and Vietnamese.
3. Haggle. Inspect the changed terms and confirm the wallet/deck remain untouched until Accept. For a card demand, open the shared deck browser and inspect/select the offered physical card(s); confirm that only legal groups can be accepted.
4. Finish/refuse the remaining demands. Return to the table; the Zodiac should leave and the drink/fortune-teller flow should remain usable.
5. Accept a next-Deal commitment, play the Afternoon Deal, and check that its outcome remains pending during play. At Afternoon, close Lottery Uncle's result receipt and talk to the returning Zodiac to see each result and final disposition.
6. Save with a counteroffer displayed or a promise pending; restart and continue. Verify identical terms/cards and no duplicate cost or resolution. Tonight's boss should use the final disposition.

Automated coverage includes real rendered scenes plus synthetic pointer/native-touch events, 720p/1080p bounds, every ordinary visitor's silhouette/focus artwork, deterministic card targeting, counteroffers, mutations, legacy save adaptation, separate-process resume, and existing boss compatibility. Physical touchscreen hardware and extended balancing/playtesting remain manual review work. Additional daytime personalities and broad Relic negotiations remain content TODOs.
