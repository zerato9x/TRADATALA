# Campaign progression, seeded saves, Endless — 2026-09-19

## IMPLEMENTED NOW

The full campaign now uses the online-demo debt curve: Monday 250,000; Tuesday 500,000; Wednesday 1,000,000; Thursday 2,000,000; Friday 4,000,000; Saturday 8,000,000; Sunday 16,000,000 VND. Debt is collected once, after the evening deal, through the existing collection receipt.

### Drink availability and permanent unlocks

Both event availability and achievement unlocks are required. Locked drinks within an available tier remain inspectable, with a goal and progress shown; Order remains the only purchase action.

| Day | Starter | Noon |
| --- | --- | --- |
| 1 | Trà đá | Four basic drinks |
| 2 | Four basic drinks | Basics + Đen đá, Nâu đá, Bạc xỉu, Sting, C2 |
| 3 onward | Basics + tier 2; never Bò Húc or either Nước mía | Same roster; add Bò Húc only if that morning's choice was Sting; add both Nước mía only if that morning's choice was C2 |

Branches reset with the morning choice each day. Unlocks persist across runs using the existing achievement profile (`user://demo_drink_progress.cfg`, retained for compatibility). Existing goals now apply to the full game: 5 melds for Nước vối; one morning deal for Nhân trần; Monday paid for Sâm dứa; 10 Nhân trần swaps for Đen đá; 5 Nước vối returns for Nâu đá; 15 preserved cards for Bạc xỉu; 10 sets for Sting; 10 runs for C2; 10 Sting pairs for Bò Húc; 15 red/black runs for the respective Nước mía.

Full-game prices are a percentage of the day's debt, rounded up to 500 VND, independent of current wallet balance:

| Drink | Goal percentage | Sunday |
| --- | ---: | ---: |
| Trà đá | 0% | Free |
| Nước vối | 2% | 320,000 |
| Nhân trần | 3% | 480,000 |
| Sâm dứa | 4% | 640,000 |
| Đen đá / Bạc xỉu / Sting / C2 | 5% | 800,000 |
| Nâu đá | 6% | 960,000 |
| Bò Húc / both Nước mía | 8% | 1,280,000 |

The separate demo configuration retains its existing drink rules and prices. No export or online deployment was performed.

### Hàng Rong

`RelicShop` owns each visit independently of the panel. Morning and afternoon visits offer three distinct unowned relics (fewer only when fewer unowned relics remain). Same visit + same seed always opens the same offer. A purchase closes the offer; the unchosen items disappear. Reroll before purchase costs 2% of the day's debt times `(rerolls + 1)`; item price is 5%. Prices round up to 500 VND. Rerolls avoid the previous three when at least three alternatives exist.

Owned relics remain in the collection. Equipping/removing owned relics is free, with four equipped slots. Buying when slots are full adds to inventory; the player can remove/equip in the collection. Relaunching or reopening the panel does not replenish a visit. Relic gameplay bonuses remain separate from intrinsic scoring.

### Seeds and saves

The Play action opens a run menu with Continue Saved Run, seed entry, New Run, and drink unlock progress. Blank seed generates a random seed; supplied seeds are case-sensitive and capped at 64 characters. Gameplay uses versioned SHA-256-derived streams for deal shuffles, Gieo Quẻ, lottery, shoe polish, and relic visits. Same seed plus the same gameplay choices/version reproduces gameplay randomness. Cosmetic/audio randomness is independent. Persistent unlock profiles can differ between players; a seed does not unlock drinks.

One active full-game slot: `user://run_v1.save`, with `.bak` previous complete save and `.tmp` staging. Demo uses `user://demo_run_v1.save`. These are Godot's application-data paths, not files beside the executable. New Run replaces the active run, while unlock progress remains.

Autosaves follow committed deal actions, wallet mutations, campaign phases, event interaction completion, inventory changes, and Gieo/shop state changes. Writes are deferred to the end of the current synchronous action so intermediate wallet signals do not persist half a transaction. Animations are not serialized: loading restores committed gameplay and reconstructs the relevant screen.

`RunSave` uses schema version 1, binary Variant data with full object deserialization disabled, a SHA-256 checksum, atomic temp-file replacement, and backup recovery. Only whitelisted card/meld/discard/settlement/scoring value types are reconstructed. A reference table preserves physical-card identity and keeps permanent campaign cards separate from deal-local copies. Snapshots include exact draw order/RNG states, hand/melds/discards, active drink and charges, preserved cards, relics and offers/rerolls, permanent transformations, polish, pending Gieo decisions, lottery tickets/draw/settlement state, event completion, accounting history, and pending collection. Unsupported versions or damaged files are rejected; a usable backup is offered automatically. No cloud sync or multi-slot browser was added.

### Sunday victory and Endless

Paying Sunday opens the run scroll with seed/copy action, debt repaid, days/deals, top-three MVP cards by accumulated point contribution, strongest action, day-by-day finances, drink choices, all action counters, and relic earnings. Card totals include native/Gieo retriggers and exhaustion payouts; shared score adjustments and relic bonuses remain separate. Full card/transaction tabs are retained.

Continue Endless preserves seed, deck transformations, relic collection, wallet, history, and unlocks. Day 8 debt is 24m; each subsequent day grows by 50%, rounded to 500. The existing daily drink reset, free cast, polish expiry, NPC visits, and lottery cycle continue. Subsequent successful collections advance immediately; a shortfall ends the run with its report. Debt growth saturates at 4 quadrillion VND to avoid integer overflow. New Run returns to the seven-day campaign.

## Validation

- Full deterministic suite: 188/188 passed, including new day/branch/price gates, seeded independent streams, offer/purchase/reroll lifecycle, exact file round-trip identity, RNG continuation, corrupted-save backup, persistent unlocks, phase choice, pending Gieo target state, exhaustion contributions, collection idempotence, and multi-day Endless.
- Rendered pointer smoke passed in Vietnamese at 1280×720 and English at 1920×1080: seed entry/New Run, autosave, fresh-scene resume, exact hand and future draws, relic reroll/buy, victory MVP scroll, and Endless entry.
- Demo smoke: 264 checks passed. Tutorial, relic equipment/scoring, and resolve scene smokes passed.
- A separate fresh Godot process loaded the saved Endless run through Continue Saved Run and retained day 8, the seed and starter event. It emitted a two-instance ObjectDB shutdown warning after PASS.
- Full drink-roster input/layout smoke passed; emitted ObjectDB/resource shutdown warnings. Gameplay assertions passed, but that smoke's shutdown cleanliness is not established.
- Automated audio used Dummy; physical listening, browser persistence/export, and long-run economy balance have not been playtested. Visual test finances use explicit fixtures, not a claim that the debt curve is balanced.

## Main ownership

- `CampaignConfig`: debt curve.
- `DrinkManager` / `DrinkProgress`: availability, prices, purchases, unlocks.
- `CampaignManager` / `RelicShop`: seeds, campaign/Endless state, visit offers.
- `RunSave`: persistence codec and file lifecycle.
- `MatchUI`: autosave triggers, menu/resume routing and reconstructed presentation.
- `run_menu.gd`, `relic_selector.gd`, `resolve_receipt.gd`: player-facing UI.

## Campaign-integrated onboarding — 2026-09-20

New campaigns start with VNĐ25,000 and real Monday onboarding. Monday uses the authored onboarding shuffle and reorders only existing physical card IDs for its opening Set and extension. Noon prioritizes a real polished/transformed card (or a relic-relevant opening) without adding cards or applying fake effects. Later days retain their normal seeded shuffles.

Learned and dismissed hints are optional fields in the version-1 campaign snapshot. Older saves default to empty knowledge. Knowledge is per campaign, resets with New Run, and survives save/resume independently of animation state. It does not replace persistent drink unlock progress. The Handbook remains available after hints disappear. Legacy tutorial entry points now open that read-only reference and never replace the live deal.

The restricted demo skips unavailable NPC services and follows the same debt/day progression without onboarding gates. Current validation: CAMPAIGN_OVERHAUL_2026-09-20.md.
