# Đánh Giày identity overhaul — 2026-10-07

## Audit before implementation

- `ShoeShineService` previously selected two random unpolished cards, granted a day-long Shiny scoring property, sold tips, and exposed a lottery Special-number hint. Its prices used `VndWallet.player_service_cost()`, which depended on current wallet balance. This conflicted with the requested identity-only role.
- `CampaignManager.gieo_que.persistent_deck` owns the run's physical cards. Hàng Rong controls composition. Deals receive `CardData.copy_for_deal()` copies through `DeckManager`; a transformed card must retain its existing `unique_id`.
- `CardData.apply_rank()` and `apply_suit()` already own permanent identity mutation, revision and notification. Rank changes also update canonical rank index/base value. Negative derives its legal identities from current Rank/Suit; GLITCH derives from Liquid + Negative and remains wildcard.
- The existing V3 save envelope serializes owner-declared card/service fields and independent RNG states, then rebinds services to the canonical deck. A new card representation or second deck authority was unnecessary.
- Starter roster eligibility already excluded Đánh Giày from later events. The focused Event Table supported placing the NPC, dialogue, service and common wallet together.
- The initial worktree contained substantial unrelated WIP. The pre-change core suite passed 371/371. Task-specific copies of touched existing files are under `.godot/shoe-overhaul/baseline/`; unrelated WIP was preserved.

## Result

Đánh Giày is a Starter-only Rank/Suit transformation service. The campaign phase and day are checked by the service, so stale UI or calls to `begin_event(STARTER)` cannot operate during another phase.

The player commits one physical card at a time, up to two. Each committed ID is irreversible for that visit. One card is sufficient; the second may be added later. Reopening and restoring do not clear selections, free another slot, reset prices, replay work or consume RNG. Missing cards do not free a committed slot.

Both services exclude the current identity. All 13 standard ranks and all four standard suits remain available over repeated rolls. Rank and Suit are permanent on the canonical physical card, while Fortune, Gold/Black Ink, Liquid, Negative, GLITCH, Shiny legacy metadata, enhancements/modifiers and seals are preserved. Sealed cards refuse selection/work. Deal copies inherit the transformed canonical Rank/Suit and existing permanent properties.

The task does not alter CardData, deck composition, Gieo, scoring or Hàng Rong mechanics. Legacy day-polish expiry stays in campaign day setup; the new identity service neither grants nor strips properties.

## Prices and RNG

`scripts/campaign/shoe_shine_config.gd` owns the tuning data:

| Service | Initial price | Monday prices for successive uses |
| --- | --- | --- |
| Rank | max(5,000 VNĐ, 2% of day target), rounded up to 500 VNĐ | 5,000 / 10,000 / 20,000 / 40,000… |
| Suit | max(2,500 VNĐ, 1% of day target), rounded up to 500 VNĐ | 2,500 / 5,000 / 10,000 / 20,000… |

Each service doubles independently after a successful use. Both cards share the visit's Rank curve and the visit's Suit curve, preventing cheaper fishing by switching cards. Actual quotes, counters and the tuning dictionary persist. Changing wallet balance never reprices the visit. There is no reroll count limit; prices saturate at 4,000,000,000,000,000 VNĐ to avoid integer overflow. A regression performs 60 paid Rank rerolls.

The `shoe_identity` campaign seed stream initializes a dedicated RNG. Selection, reopening, pricing and presentation consume no random results. Saves restore its exact state. Gameplay draw, Gieo, Zodiac, lottery and Hàng Rong RNG are isolated.

## Transactions and persistence

`VndWallet.try_spend_and_commit()` debits first, runs the synchronous service commit, then journals and notifies observers once. Failed affordability checks and rejected mutations leave balance and journal unchanged. A rejected CardData mutation also restores identity, revision and RNG.

Card notifications are held until the complete service state is committed. Wallet observers see the new card, counters, prices, RNG and receipt. A reentrancy guard prevents another selection/payment inside a transaction notification. UI code sends card IDs and reroll intent; it never changes money or owns identity mutation.

The existing V3 envelope carries:
- visit-started flag and day/event context;
- selected physical IDs, with selected count derived from their array;
- separate Rank/Suit counts, next quotes and price curve;
- dedicated RNG state;
- the last committed before/after receipt;
- canonical card fields through the existing CardData object records.

Selection-only changes now request autosave through `RunSessionCoordinator`. Successful payments use the existing wallet save path; closing the application flushes it. Legacy polish/tip fields are ignored as identity-reroll counts. Existing card printing/properties remain intact when loading older saves.

## Presentation

The two work mats sit beside the existing full NPC and dialogue. Each selected card has actual card art, current Rank with its suit icon, persistent property text, separate Rank/Suit buttons and prices. The visit-wide usage counters and last before → after identity/payment are visible.

Paid work lifts and turns only the worked card, sweeps a brush highlight across it, then settles it. The committed new identity is visible immediately. Closing mid-animation leaves the completed authority intact; reopening restores the receipt without replaying the animation or charging again.

The shared wallet presents the payment flight. Existing bounded Sound-bus feedback is reused. English/Vietnamese strings, the picker confirmation, NPC greeting, Strawy guidance, Handbook pricing/role explanations and transaction ledger names are updated. Lottery hints and polish/tip actions are removed from this NPC.

## Validation

Fresh isolated Godot 4.7.1 processes were used.

- Core: 391/391 tests passed, including 23 new deterministic identity-service tests and existing NPC/card suites.
- Separate-process save/quit/resume: writer 9/9 and reader 19/19 checks passed; exact next Rank and Suit outcomes reproduced.
- Rendered English/Vietnamese at 1280×720 and 1920×1080: 89/89 checks in each run (356 total). Synthetic pointer input exercised the existing deck picker, commitment, both paid tools, repeated rerolls, disabled states and Back.
- Closing during work: committed identity, selection, prices/counts and RNG survived; reopening did not replay/charge.
- Runtime, tutorial, full/demo campaign, Event Table, miscellaneous NPC and Gieo screen checks passed.
- Fortune and Hàng Rong separate-process resume checks passed.
- Final parsing, Strawy and resolve receipt scene checks passed; the final core rerun remained 391/391.
- `git -c core.safecrlf=false diff --check` passed.

The English 720p and Vietnamese 1080p captures were visually inspected for readability and NPC/dialogue overlap. Captures are under `.godot/shoe-overhaul/shoe-bench-*.png` and `shoe-empty-*.png`.

Input proof is automated viewport pointer injection, not human mouse/touch QA. The checks use Dummy audio; they do not establish audible quality. No release/export/publication, staging, commit or push was performed.