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
- Morning and Afternoon use the same draw and separate pre-generated batches. Reopening does not refresh offers. Purchases require a currently offered ticket ID; arbitrary-number requests are invalid.
- The existing day-end lifecycle settles all purchased tickets before checking the daily money requirement. Settlement commits before wallet signals and is idempotent.
- Payouts use integer numerator/denominator arithmetic. Third prize is stake * 5 / 2, rounding down a fractional dong; default stakes divide exactly.
- A receipt shows the draw, category and payout per ticket, and total credited. It survives next-day state creation and can be revisited at Vé Số. Viewing never pays.
- Existing demo gating is retained; these NPCs are full-campaign services.

## Provisional tuning

All balance is in scripts/campaign/misc_service_config.gd:

| Setting | Value |
| --- | ---: |
| Polish two cards | ₫10,000 |
| Optional tip | ₫5,000 |
| Cumulative tips for Special-number information | ₫20,000 |
| Ticket stake | ₫10,000 |
| Tickets per appearance | 8 |
| Refresh | None |

The favor registry supports additional favors without a UI progression tree. Thresholds and additional favors are not design-locked.

## Validation

Deterministic coverage: tests/test_misc_npc.gd, included in tests/run_headless.gd.
Interaction/render coverage: tests/misc_npc_scene_smoke.gd uses viewport clicks for random-polish payment, tips, tickets, Back and receipt dismissal. Bilingual 720p/1080p regressions check that both NPC sprites stay clear of dialogue and service controls, with matching column edges. Its Special-win fixture finds a seed with an actually offered winning ticket; it does not replace the draw or inject a ticket.

Fresh validation results are recorded in the task handoff. Automated viewport input is not a claim of manual physical-input testing.


### Verified in this implementation

- Fresh Godot 4.7.1 deterministic suite: 148 passed / 148 total.
- NPC scene smoke: PASS headless and OpenGL-rendered at 1280×720, with viewport clicks and an actual offered Special ticket paying ×80.
- Tutorial scene smoke: PASS.
- Gieo screen smoke: 404 checks, zero failures.
- Trigger presentation smoke: PASS.
- Drink-shop smoke: PASS; shutdown reported 8 ObjectDB instances and 3 resources still in use.
- Restricted-demo smoke: 263 checks, zero failures.
- git diff --check: PASS.
- Existing runtime_scene_smoke.gd stops at line 353 while dereferencing a null drink texture. Its fixture expects a Trà Đá sprite while the deal has no active drink; the relevant drink behavior was not changed by this implementation. This smoke is not reported as passing.

Rendered review images are generated under .godot/misc_shoe.png, .godot/misc_lottery.png and .godot/misc_lottery_result.png. The deterministic Special-win capture uses 03 and credits ₫800,000 for a ₫10,000 ticket.
