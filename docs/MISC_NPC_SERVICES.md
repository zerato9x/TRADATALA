# Đánh Giày and Vé Số

IMPLEMENTED NOW

- CampaignManager owns ShoeShineService and LotteryService and shares its VndWallet.
- The existing campaign-owned GieoQueService persistent deck remains the physical-card authority.
- Starter: pay for exactly two distinct, currently unpolished physical cards. The service randomly draws two eligible cards without replacement using its own seedable RNG; the player cannot select cards. Stable IDs identify the result. Another pair may be purchased. No rank, suit, identity or Gieo mutation occurs.
- CardData.shiny is separate from permanent properties and permanent snapshots. Deal copies retain it; the next campaign day clears it on the persistent deck.
- ScoringPipeline adds exactly one self contribution for each polished card in each existing pass. Gold contributions on that card are included. Polish neither creates nor counts as a full-meld pass. Extension polish uses the added card contribution or the older card's intrinsic growth plus its qualifying Gold. Intrinsic meld values remain unchanged.
- The shared card material has an independent clear-polish uniform, gloss sweep and small cleaning glint. Reused card faces clear the state.
- Tips spend real VND. Run goodwill and the small favor registry are internal; no balance or progress meter is displayed. The Starter dialogue reads LotteryService.special_number().
- A daily draw is generated before Starter, with seven distinct numbers from 00–99 in categories 1 / 1 / 2 / 3.
- Morning sells the pre-generated offers. Reopening does not refresh them. Buy All purchases affordable unowned tickets in display order through the normal single-ticket authority; its quote shows count and total cost. Purchases require a currently offered ticket ID; arbitrary-number requests are invalid.
- Entry to the Afternoon Event settles all purchased tickets and closes purchases before the Evening Deal. Vé Số reveals categories, winning numbers, tickets, matches and total payout. Settlement commits before wallet signals and is idempotent, including days with no tickets. Winnings fly to the shared top wallet.
- Payouts use integer numerator/denominator arithmetic. Third prize is stake * 5 / 2, rounding down a fractional dong; default stakes divide exactly.
- A receipt shows the draw, category and payout per ticket, and total credited. It survives next-day state creation and can be revisited at Vé Số. Viewing never pays.
- Existing demo gating is retained; these NPCs are full-campaign services.

## Provisional tuning

Base values and prize data are in scripts/campaign/misc_service_config.gd. Polish uses 2% of the current player wallet; tips and tickets use 1%, with the following minimums and rounding up to VNĐ500. Each category independently multiplies that base by its next daily purchase number (1, 2, 3, ...). Reopening and resuming preserve counts; a new day resets counts. Buy All simulates every successive wallet deduction and repeat multiplier. Purchased ticket stakes remain fixed for payouts.

| Setting | Value |
| --- | ---: |
| Polish two cards | VNĐ10,000 |
| Optional tip | VNĐ5,000 |
| Cumulative tips for Special-number information | VNĐ20,000 |
| Ticket stake | VNĐ10,000 |
| Tickets per appearance | 8 |
| Refresh | None |

The favor registry supports additional favors without a UI progression tree. Thresholds and additional favors are not design-locked.

## Validation

Deterministic coverage: tests/test_misc_npc.gd, included in tests/run_headless.gd.
Interaction/render coverage: tests/misc_npc_scene_smoke.gd uses viewport clicks for random-polish payment, tips, tickets, Back and receipt dismissal. Bilingual 720p/1080p regressions check that both NPC sprites stay clear of dialogue and service controls, with matching column edges. Its Special-win fixture finds a seed with an actually offered winning ticket; it does not replace the draw or inject a ticket.

Fresh validation results are recorded in the task handoff. Automated viewport input is not a claim of manual physical-input testing.


### Historical verification (original services implementation)

- Fresh Godot 4.7.1 deterministic suite: 148 passed / 148 total.
- NPC scene smoke: PASS headless and OpenGL-rendered at 1280×720, with viewport clicks and an actual offered Special ticket paying ×80.
- Tutorial scene smoke: PASS.
- Gieo screen smoke: 404 checks, zero failures.
- Trigger presentation smoke: PASS.
- Drink-shop smoke: PASS; shutdown reported 8 ObjectDB instances and 3 resources still in use.
- Restricted-demo smoke: 263 checks, zero failures.
- git diff --check: PASS.
- Existing runtime_scene_smoke.gd stops at line 353 while dereferencing a null drink texture. Its fixture expects a Trà Đá sprite while the deal has no active drink; the relevant drink behavior was not changed by this implementation. This smoke is not reported as passing.

Rendered review images are generated under .godot/misc_shoe.png, .godot/misc_lottery.png and .godot/misc_lottery_result.png. The deterministic Special-win capture uses 03 and credits VNĐ800,000 for a VNĐ10,000 ticket.

Current overhaul validation is recorded in CAMPAIGN_OVERHAUL_2026-09-20.md.
