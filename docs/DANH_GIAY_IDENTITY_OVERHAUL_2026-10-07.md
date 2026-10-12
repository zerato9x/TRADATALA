# Đánh Giày pair transformation overhaul — 2026-10-07

## Current behavior

Đánh Giày appears at Starter from Tuesday onward. Monday has neither his table artwork nor a selection target. Campaign NPC eligibility owns availability; the table consumes the actual participants. The service independently checks day, event slot, campaign phase, and run status, including stale panels and old saves.

The player commits exactly two distinct physical cards before paid work becomes available. Each commitment is irreversible for that day's visit. Reopening, saving, and continuing preserve the same pair. A missing or sealed member blocks the entire purchase and never frees a third selection. The next day opens a fresh selection while retaining transformed printing.

One Transform Rank or Transform Suit purchase changes BOTH cards. Each physical card receives its own random result from its own legal pool; results may match each other. Each pool excludes that card's current identity. Rank updates canonical rank index and base value; Suit changes only Suit. Other card properties and physical IDs survive. The existing campaign persistent deck remains the owner; future Deal copies inherit the changes.

## Prices

`ShoeShineConfig.SERVICES` owns tuning. Quotes are fixed for the daily visit, based on debt rather than the current wallet.

| Pair service | Starting quote | Normal Tuesday sequence |
| --- | --- | --- |
| Transform Rank | 10% of daily debt, minimum 25,000 VNĐ | 50,000 / 100,000 / 200,000… |
| Transform Suit | 5% of daily debt, minimum 15,000 VNĐ | 25,000 / 50,000 / 100,000… |

Round up to 500 VNĐ. Each service doubles once per successful PAIR purchase, independently of the other. Day and difficulty debt growth automatically increase initial quotes. There is no reroll count limit while the player can pay. Prices saturate at 4,000,000,000,000,000 VNĐ to prevent overflow.

Save pricing version 2 migrates the former 2%/1% curves to these quotes without resetting selected IDs, reroll counters, card printing, receipts, or RNG. Current-version quotes resume exactly. Older Monday saves retain their transformed cards but cannot use the service on Monday.

## Outcome relic extension

`ShoeShineService._resolve_outcome()` consumes one dedicated RNG draw per physical card. It then calls `RelicRuntime.modify_shoe_shine_outcome(card_snapshot, kind, allowed, rolled)` separately for each card. The current default returns the rolled identity unchanged; no new relic is granted or implemented.

Future relic rules belong in this runtime hook. They receive detached card data and a copied candidate pool, and return an allowed identity. They must not mutate money, cards, counters, or RNG. The service validates their result and keeps transaction ownership. Tests cover different forced outcomes for each card, matching outcomes, both attributes, and an invalid second output.

## Transactions and saves

One `VndWallet.try_spend_and_commit()` transaction pays once and commits both mutations, one service counter increment, the next price, and a receipt containing two physical-ID-specific before/after results. If either mutation or relic output is rejected, both card printing/revisions, wallet, and RNG roll back. No payment or card notification is published for a rejected pair.

Wallet observers see the complete pair. Reentrant purchases/selection are rejected. Each card publishes its own permanent-change signal after the completed transaction; the campaign records one activity with two changes. UI sends only pair-service intent and selected physical IDs.

The existing V3 save envelope stores the locked IDs, visit context, counters, quotes, pricing version/curve, receipt, and dedicated RNG. Partial selection saves remain valid; the second card is still required after resuming. Selection autosaves without payment. The service does not consume deal, Gieo, Zodiac, lottery, or vendor RNG.

## Presentation and verification

The existing two work mats show each physical card and its own before → after result. Shared Transform Rank/Suit controls explicitly act on both cards and display the total pair quote. Both tools remain disabled until both cards are committed, and both cards animate together. English/Vietnamese picker terms, dialogue, Handbook, hints, and Strawy guidance describe the pair and Tuesday gate.

Before this change, the isolated core suite passed 391/391. The final revised core suite passes 392/392, including partial-pair resume, independent outcomes, one-payment accounting, invalid second-result rollback, metadata preservation, price migration, debt/difficulty scaling and 60 paid pair rerolls.

Fresh-process save/quit/resume passes writer 9/9 and reader 19/19, reproducing both cards' exact next results. Rendered English/Vietnamese at 1280×720 and 1920×1080 passes 94/94 checks per run (376 total). Pointer injection covers both deck-picker commitments, the one-card lockout, both pair tools, repeated work, separate result ownership, closing during animation, reopening, and future Deal inheritance. The English 720p and Vietnamese 1080p captures were visually inspected.

The final editor import and script parse are clean. Full/demo campaign progression, tutorial, Event Table, miscellaneous NPC, Gieo, and resolve-receipt smokes pass. The final runtime, Drink shop, and Strawy mouse/touch smokes also pass. Their fixtures verify Monday absence, exercise Tuesday services, and retain the curated Monday hands for gameplay checks.

QA captures are under `.godot/shoe-overhaul/`; process logs and isolated save profiles are under `.godot/validation/`. Input proof is automated pointer/touch injection. Checks use Dummy audio and do not establish audible quality. No export, staging, commit or push was performed. Pre-existing import/audio metadata changes and the two untracked smoke UID files were preserved.
