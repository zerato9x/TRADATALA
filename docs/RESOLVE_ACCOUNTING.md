# Resolve accounting and money economy — 2026-09-18

## IMPLEMENTED NOW

Every committed VndWallet.apply_vnd/apply_points mutation appends a journal entry before balance observers run. An entry contains its reason, amount, opening balance, and closing balance. A source scan found no production balance mutations outside VndWallet. Reports reconcile opening + income - expense = closing; viewing a report never pays again. Reset starts a new journal. Tutorial restoration preserves the live journal.

DealState retains successful action counts and action history, ordinary and exhaustion card-trigger counts, retriggers, relic triggers, draws, discards, phase decisions, both phase settlements, U, U Khan, Mom, and exhaustion counts. Scoring pass reasons distinguish originating scores, native SET/RUN retriggers, Gieo retriggers, and exhaustion. Relic bonuses remain separate wallet entries. Action histories include ordinary scoring pass origins, points, and card-hit details. These counters are descriptive and do not change scoring or U timing.

CampaignManager owns completed deal/day reports and non-monetary activity records for drink choices, free/paid Gieo casts, and transformations. All purchases and service rewards flow into the same money journal. Existing paid shoe services and lottery settlement are included automatically. No UI calculates or applies gameplay rewards.

After each deal, ResolveReceipt shows the whole deal's net change, income, losses, opening/closing wallet, itemized sources, action counts, both phase results, and expandable transactions. End-of-run results aggregate the journal and completed-day counts. The old overlapping outcome labels/panel are replaced by one scrollable screen with a fixed Continue/New Run control. English and Vietnamese primary labels are supported; uncommon action IDs have readable fallback labels.

Lottery settles on entry to the Afternoon Event, before the Evening Deal. After the Evening Deal, progression pauses for the supplied Doi No portrait and debt receipt. The existing required_vnd schedule is now money owed, not a non-spending threshold. Payment checks affordability again, deducts exactly once, and only then advances or declares seven-day victory. Insufficient funds ends the run without a partial deduction. A guard prevents reentrant collection. Monday debt is VNĐ250,000. New campaigns start with VNĐ25,000, and the Starter collector presents the authoritative weekly ledger.

## Current cost policy — 2026-09-20

All quotes derive from the current final daily debt target. Wallet balance affects affordability only. `CampaignManager` sets the shared `VndWallet.day_target_vnd` before generating offers and keeps the Drink authority's target synchronized. `RunSave` restores it from the saved campaign day. Scaling activates in campaigns; standalone fixtures can retain base prices.

| Purchase | Debt share | Base / quote rule |
| --- | --- | --- |
| Drinks | 0–8% | `DrinkManager.PRICE_PERCENT`; round up to VNĐ500; Trà Đá is free |
| Gieo paid casts | 4% | Minimum VNĐ10,000, round up to VNĐ500; each paid cast doubles the next quote; one free cast daily |
| Shoe polish | 2% | Minimum VNĐ10,000 |
| Tips | 1% | Minimum VNĐ5,000; actual payment contributes to favor |
| Lottery | 1% | Minimum VNĐ10,000; quote fixed when offers are generated; payouts use purchased stake |
| Relics | 5% | Campaign shop minimum VNĐ500; rerolls start at 2% and scale with visit reroll count; re-equipping is free; four-slot cap |

The shared wallet's scaling helper rounds up to VNĐ500. Demo Drink base quotes retain their configured unlock-price table, with the shared debt-based floor. No quote uses the wallet's balance. Relic purchase commits ownership before emitting wallet payment to prevent duplicate purchases through observers.

The persistent top wallet is the common origin/destination for gameplay and NPC bill flights. These animations observe committed transactions and never mutate money. Explicit debt payment remains guarded against repeated activation.

## Historical verification (2026-09-18)

- Headless suite: 175/175 passed, including eight focused accounting/economy regressions.
- Actual two-phase deal test reconciles phase totals, eight discards, Mom, and wallet delta.
- Rendered resolve smoke: 1280x720 Vietnamese and 1920x1080 English; actual synthetic pointer clicks cover deal continuation, debt payment, next day, and New Run. Money stays on one line and within the viewport. Screenshots were visually inspected.
- Final isolated tutorial smoke passed without a shutdown warning in its log. Running tutorial and runtime smokes together with shared settings initially caused language assertions; independent settings removed that interference.
- Broad runtime_scene_smoke stopped at its null drink texture resource_path access at line 353. It did not establish a full runtime pass.
- Scoped diff whitespace check passed.

## Limits / further tuning

The ledger is included in the current RunSave snapshot; it is not an external analytics service. It records financial changes and committed gameplay/service actions, not every hover, rejected click, or frame. Some uncommon action labels use a fallback rather than bespoke bilingual copy. Debt schedules and percentage floors are initial balancing values, not evidence of a playtested difficulty curve. The collector has Starter and evening motorcycle entrances, using the supplied bike audio on the Sound bus, and an itemized payment interaction. See CAMPAIGN_OVERHAUL_2026-09-20.md for current validation. No export, commit, or push was performed.
