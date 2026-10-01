# Zodiac vertical slice: Rooster / Cat

This document and the September 30 implementation brief supersede older Zodiac relationship/boss proposals for this slice. Full builds enable the feature; demo builds do not. No opponent AI, affection, degradation, invocation, curse, or additional boss mechanics are introduced.

## Playable flow

- Monday and Sunday use the Rooster/Cat pair. The other five conceptual pairs occupy Tuesday–Saturday but remain unauthored, so those days play normally. `ZodiacCatalog.DAY_PAIRS` owns this tunable schedule, which repeats in Endless.
- A dedicated `zodiac_selection` seed stream picks the visitor. Owned Emblems can override a future matching pair day. The run menu and **History & Emblems** expose this preference; it never replaces a visitor already selected today or changes the deck/Gieo RNG.
- Click the visitor's nameplate beside the table to talk. Each of the four event slots offers one optional request. Leaving requests unanswered is valid and costs nothing.
- Starter: immediate money demand (5,000 VNĐ, or 2,500 counteroffer). Morning: Rooster asks for a scoring Meld/Extension before the next Deal's first mandatory discard; Cat asks the player to retain at least 5,000 VNĐ until the Afternoon event, including against deadwood losses. Noon: card alteration. Afternoon: gift an owned Relic. These are explicit commitments, not success guarantees.
- **Stay** is available at the first three event slots. It resolves that request by spending time and skips exactly the upcoming normal Deal after the event's other requirements are finished. No Deal simulation, settlement, report, income, or compensation is generated. Evening cannot be skipped.
- Daily successes map to UNPLEASED (0), NEUTRAL (1), PLEASED (2–4). There is no disposition multiplier on money.

Costs are committed by the service through existing authorities. Gifts remove ownership as well as equipment. Card costs preserve all 52 physical IDs: remove the last property, reset a genuinely changed card to its original rank/suit/properties, or seal further transformations for this run. Resetting a card does not remove a seal; new runs rebuild the deck. Sealed cards are excluded from Gieo random targeting and rejected as manual targets. A fully sealed deck cannot buy an unusable cast.

## Evening rules

**Rooster — Closing Register:** Phase 1 starts open. It closes immediately after mandatory discard 3 / 2 / 1 for PLEASED / NEUTRAL / UNPLEASED. Optional Trà Đá discards do not advance the deadline. New Melds and Extensions remain legal after closure, move the real cards, and count toward normal Phỏm/deadwood/Ù rules, but their normal scoring passes, retriggers, and attached Relic payouts pay zero. Receipts retain `rooster_register_closed`. Phase 2 scores normally. Exhaustion triggers, deadwood, and the existing Ù rules are otherwise unchanged.

**Cat — The Stalk:** Phase 1 has no modifier. After Phase 2's draw/refill and any automatic Ù Khan replacement, each turn locks 1 / 2 / 3 current hand cards. Locks prevent Melds, Extensions, normal/extra discards, and player-targeted hand effects. They do not alter ownership, identity, or deadwood value. A Meld/Extension must leave an unlocked mandatory-discard candidate during active turns, preventing a softlock. LAST CALL may consume every remaining unlocked card. Locks persist through optional Trà Đá actions and LAST CALL, then clear and reroll at the next turn. Selection uses a separate saved RNG.

In this solo game a boss victory is completion of both evening Phases, recorded once. Daily debt collection remains a separate normal campaign condition; there is no invented enemy HP, payout, or disposition prize.

## Persistent payoff

History contains additive request, refusal, counteroffer, gift, time, promise, disposition-victory, and perfect-day counters. Unique committed event IDs prevent replayed checkpoints from awarding the same history twice. Run restore merges history monotonically with the permanent profile.

Tunable first-pass special-scene prerequisites:

| Zodiac | Prerequisites |
| --- | --- |
| Rooster | 4 resolved requests, 1 respected refusal, 1 pleased victory |
| Cat | 4 resolved requests, 1 kept restraint promise, 1 pleased victory |

The next encounter evaluates these conditions. Its optional three-beat scene grants the permanent Emblem only at the final choice. An interrupted scene may be replayed; completion and ownership survive new runs. Emblem definitions have an empty extension dictionary reserved for future features; no curse/invocation behavior exists.

## Ownership and persistence

| Owner | Responsibility |
| --- | --- |
| `ZodiacCatalog` | Pair/day data, thresholds, Rooster/Cat definitions, preferences, unlock conditions, bilingual rules |
| `ZodiacService` (CampaignManager-owned) | Request commitments and interpretation, authoritative promise observations, skip scheduling, boss configuration, progression |
| `ZodiacProgress` | Atomic `user://zodiac_progress_v1.cfg` plus backup; monotonic counters/flags and deduplication IDs |
| `ZodiacBossRule` (DealState-owned) | Register state, locks, turn serial, dedicated RNG snapshot |
| `DealState` | Card legality, turn boundaries, scoring suppression at the existing payout commit path |
| `VndWallet`, `RelicRuntime`, `CardData` | Journaled payments, ownership removal, canonical card changes |
| `RunSave` | Daily selection/forced choice, requests/promises, skipped phases, profile snapshot; Deal snapshot includes current boss state/RNG |
| `ZodiacTable`, `PlayingCardView` | Dialogue, explicit costs/promises, history, cutscene, nameplate, portrait, lock indicators; no progression truth |

Save additions are backward-compatible optional fields in the existing version-2 envelope. Old saves continue without retroactively adding a visitor to the already-started day. Restore does not re-enter campaign phases or reroll the current visitor/locks. Permanent history also lives outside the run save, so New Run cannot erase it. Profile save failures report a warning and remain in memory/run snapshots for recovery.

## Presentation and assets

Rooster and Cat use their dedicated sprites from `assets/zodiacboss/`. Rank/suit corners remain readable under the purple Cat lock treatment. Register/phase changes pulse the nameplate and use the existing transition SFX. Existing authored music routing receives the normal evening and Phase 2 events; no tracks, cue timings, vocal layers, or fabricated Rooster DJ plan were created. The current catalog has Cat and Dog authored routes, and the player's jukebox choice remains intact.

English and Vietnamese text are supplied at the feature boundary. The modal blocks underlying keyboard/Drink input and suppresses the onboarding hint while open. Emblem choice is also available before starting a new run.

## Validation

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script tests/run_headless.gd
Godot_v4.7.1-stable_win64_console.exe --path . --rendering-method gl_compatibility --script tests/zodiac_scene_smoke.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script tests/runtime_scene_smoke.gd
```

The deterministic suite includes the existing regression suites and Zodiac selection, RNG isolation, response interpretation, cost/re-entry checks, identity preservation, ownership removal, exact Deal skipping, promises, all boss severities, legal zero-payout actions, Phase 2 restoration, lock legality/softlock prevention, serialized resume, progression replay/merge, scene gating, and complete Rooster/Cat campaign-day flows.

The rendered smoke uses isolated progression/save state. It checks real pointer input, both languages, main-scene wiring, costs, Phase 2 locks, resume without reroll, scene completion, register labels, and 1280×720 / 1920×1080 bounds. Screenshots are written to ignored `.godot/zodiac_validation/`. Do not treat exit code alone as success: inspect output for `SCRIPT ERROR:` and `ERROR:` as well as the test summary.
