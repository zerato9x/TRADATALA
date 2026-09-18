# Resolve accounting and money economy — 2026-09-18

## IMPLEMENTED NOW

Every committed VndWallet.apply_vnd/apply_points mutation appends a journal entry before balance observers run. An entry contains its reason, amount, opening balance, and closing balance. A source scan found no production balance mutations outside VndWallet. Reports reconcile opening + income - expense = closing; viewing a report never pays again. Reset starts a new journal. Tutorial restoration preserves the live journal.

DealState retains successful action counts and action history, ordinary and exhaustion card-trigger counts, retriggers, relic triggers, draws, discards, phase decisions, both phase settlements, U, U Khan, Mom, and exhaustion counts. Scoring pass reasons distinguish originating scores, native SET/RUN retriggers, Gieo retriggers, and exhaustion. Relic bonuses remain separate wallet entries. Action histories include ordinary scoring pass origins, points, and card-hit details. These counters are descriptive and do not change scoring or U timing.

CampaignManager owns completed deal/day reports and non-monetary activity records for drink choices, free/paid Gieo casts, and transformations. All purchases and service rewards flow into the same money journal. Existing paid shoe services and lottery settlement are included automatically. No UI calculates or applies gameplay rewards.

After each deal, ResolveReceipt shows the whole deal's net change, income, losses, opening/closing wallet, itemized sources, action counts, both phase results, and expandable transactions. End-of-run results aggregate the journal and completed-day counts. The old overlapping outcome labels/panel are replaced by one scrollable screen with a fixed Continue/New Run control. English and Vietnamese primary labels are supported; uncommon action IDs have readable fallback labels.

At day end, lottery settles first. Progression then pauses for the supplied Doi No portrait and debt receipt. The existing required_vnd schedule is now money owed, not a non-spending threshold. Payment checks affordability again, deducts exactly once, and only then advances or declares seven-day victory. Insufficient funds ends the run without a partial deduction. A guard prevents reentrant collection. Monday remains zero debt in the full-game schedule; the demo retains its own starting schedule.

## Initial cost policy

Prices use max(existing base price, wallet percentage), rounded up to 500 VND. Negative balances never produce negative prices. Scaling activates for campaign play; standalone service fixtures can retain base prices.

| Purchase | Wallet share | Base / quote rule |
| --- | --- | --- |
| Drinks | 2% | Existing basic prices; other full-game drinks 25,000 VND; demo keeps its day-target base |
| Gieo paid casts | 5% | Existing escalating cast base; daily free cast remains free |
| Shoe polish | 2% | Existing polish base |
| Tips | 1% | Existing tip base; actual payment contributes to favor |
| Lottery | 1% | Existing stake floor; quote fixed when daily offers are generated; payouts use purchased stake |
| Relics | 5% | 50,000 VND base; owned relics can be re-equipped free; four-slot cap |

Tra Da stays free so a zero-wallet start has a valid drink choice. The full-game free-drink development override is off by default; the explicit test override remains available. UI quotes use the same service methods as charging. Relic purchase commits ownership before emitting wallet payment to prevent duplicate purchases through observers.

## Verification

- Headless suite: 175/175 passed, including eight focused accounting/economy regressions.
- Actual two-phase deal test reconciles phase totals, eight discards, Mom, and wallet delta.
- Rendered resolve smoke: 1280x720 Vietnamese and 1920x1080 English; actual synthetic pointer clicks cover deal continuation, debt payment, next day, and New Run. Money stays on one line and within the viewport. Screenshots were visually inspected.
- Final isolated tutorial smoke passed without a shutdown warning in its log. Running tutorial and runtime smokes together with shared settings initially caused language assertions; independent settings removed that interference.
- Broad runtime_scene_smoke stopped at its null drink texture resource_path access at line 353. It did not establish a full runtime pass.
- Scoped diff whitespace check passed.

## Limits / further tuning

This is an in-memory run ledger, not a disk save or external analytics service. It records financial changes and committed gameplay/service actions, not every hover, rejected click, or frame. Some uncommon action labels use a fallback rather than bespoke bilingual copy. Debt schedules and percentage floors are initial balancing values, not evidence of a playtested difficulty curve. The collector has portrait arrival and an itemized payment interaction; no new voice/audio asset was authored. No export, commit, or push was performed.
