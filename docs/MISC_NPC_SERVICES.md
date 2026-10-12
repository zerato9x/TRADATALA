# Đánh Giày and Vé Số

IMPLEMENTED NOW

- CampaignManager owns ShoeShineService and LotteryService and shares its VndWallet.
- The existing campaign-owned GieoQueService persistent deck remains the physical-card authority.
- Starter, from Tuesday onward: commit exactly two distinct physical cards, then pay once to transform both Ranks or both Suits. Results are independent per card and exclude each card's current identity. The pair cannot be replaced during that visit; rerolls have no count limit while affordable.
- Campaign participant eligibility and service authority both enforce the Tuesday/Starter gate. Monday artwork and selection targets are absent.
- Transformations retain physical IDs and all other card properties. The service neither grants Shiny nor sells tips or lottery hints. Legacy day-polish expiry remains in campaign setup.
- Future outcome relics can modify each card's result through `RelicRuntime.modify_shoe_shine_outcome()`. The service validates outputs and commits or rolls back the entire pair with one payment.
- A daily draw is generated before Starter, with seven distinct numbers from 00–99 in categories 1 / 1 / 2 / 3.
- Morning sells the pre-generated offers. Reopening does not refresh them. Buy All purchases affordable unowned tickets in display order through the normal single-ticket authority; its quote shows count and total cost. Purchases require a currently offered ticket ID; arbitrary-number requests are invalid.
- Entry to the Afternoon Event settles all purchased tickets and closes purchases before the Evening Deal. Vé Số reveals categories, winning numbers, tickets, matches and total payout. Settlement commits before wallet signals and is idempotent, including days with no tickets. Winnings fly to the shared top wallet.
- Payouts use integer numerator/denominator arithmetic. Third prize is stake * 5 / 2, rounding down a fractional dong; default stakes divide exactly.
- A receipt shows the draw, category and payout per ticket, and total credited. It survives next-day state creation and can be revisited at Vé Số. Viewing never pays.
- Existing demo gating is retained; these NPCs are full-campaign services.

## Provisional tuning

Pair transformation tuning is in `scripts/campaign/shoe_shine_config.gd`; lottery prize data is in `scripts/campaign/misc_service_config.gd`.

| Setting | Value |
| --- | ---: |
| Pair Rank transformation | 10% of daily debt, minimum 25,000 VNĐ |
| Pair Suit transformation | 5% of daily debt, minimum 15,000 VNĐ |
| Transformation rounding | Up to 500 VNĐ |
| Transformation repeat price | Each service doubles independently after one successful pair purchase |
| Ticket stake | 1% of current wallet, minimum 10,000 VNĐ, rounded up to 500 VNĐ; multiplied by purchased count + 1 |
| Tickets per appearance | 8 |
| Refresh | None |

Pair quotes, selections and RNG persist through reopening and saves; new days reset the visit. Versioned pricing migrates old cheap quotes while preserving previous card results. Lottery Buy All simulates each remaining balance; purchased stakes remain fixed for payout.

## Validation

Deterministic coverage: tests/test_misc_npc.gd, included in tests/run_headless.gd.
Interaction/render coverage: tests/misc_npc_scene_smoke.gd uses viewport clicks for pair-transformation payment, tickets, Back and receipt dismissal. Bilingual 720p/1080p regressions check that both NPC sprites stay clear of dialogue and service controls, with matching column edges. Its Special-win fixture finds a seed with an actually offered winning ticket; it does not replace the draw or inject a ticket.

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

Current pair transformation architecture and verification: [DANH_GIAY_IDENTITY_OVERHAUL_2026-10-07.md](DANH_GIAY_IDENTITY_OVERHAUL_2026-10-07.md).
