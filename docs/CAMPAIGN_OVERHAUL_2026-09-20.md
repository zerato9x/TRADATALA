# Campaign overhaul acceptance ledger — 2026-09-20

Implemented against the supplied 24-section campaign/presentation/onboarding plan. Local gameplay services remain authoritative. No exports, commits or pushes were performed.

## Completed scope

- [x] Debt-based prices across Drinks, Gieo, polish/tips, tickets and relic purchases/rerolls; zero/low/high wallet regression coverage.
- [x] Starter Đòi Nợ, weekly ledger, concise later-day briefing, evening entrance, explicit authoritative payment, bill flight and departure. Supplied bike_sound.mp3 plays on Sound; interruption cancels playback.
- [x] One persistent top wallet pile across gameplay and events. NPC transactions observe committed journal changes; gameplay retains its existing scoring flights into the same anchor. Retired duplicate event cash display.
- [x] Vé Số Buy All quotes affordable unowned offers, uses normal purchase authority, and preserves ownership. Afternoon results precede Evening; settlement is idempotent and closes purchases.
- [x] Table-native Hàng Rong offers with sprites, hover/inspection, effect/slot details, explicit purchase, reroll, inventory/equip controls and physical item flight. Four-slot authority retained.
- [x] All six NPCs use event-table entrance, focus, service, return and exit handling. Collector uses the same roster plus a distinct motorcycle ceremony.
- [x] Permanent Gieo Guide: six lines, all eight effect/target mappings from authoritative tables, hidden-target commitment, choice/refuse/reroll, permanent cards, Gold, Liquid, jackpots, prices and examples. Random Rank/Suit are explicitly identified as obsolete effects.
- [x] Standalone playable tutorial deprecated. Both former tutorial entry methods open the read-only Handbook. Old helper code/DealState fixture remains for compatibility but has no production tutorial route.
- [x] Real Monday onboarding with authored shuffle/opening IDs: obvious Set, next-draw extension, normal scoring, discards, LAST CALL, settlement/deadwood, Phase 2 and NPC services. Legal deviations remain available.
- [x] Noon prioritizes an existing polished/transformed card or relic-relevant cards, retaining all physical identities. No fake payouts or tutorial-only effects.
- [x] Per-campaign learned/dismissed bilingual hints observe real actions, retire demonstrated mechanics, cover Noon Drink progression, and stop on Tuesday. Phase 2/Afternoon reduce intervention.
- [x] Searchable bilingual Handbook covers core play, scoring, cards, all Drinks, Gieo, relics, NPCs, lottery, campaign/economy and controls, with service/debt contextual links.
- [x] Optional save fields preserve knowledge; New Run resets it. Deck/financial/service snapshots retain existing authority. Restricted demo skips unavailable services without blocking Monday.

## Intentional economy and onboarding choices

New full/demo runs start with VNĐ25,000 so optional Starter polish is affordable. Monday still owes VNĐ250,000. Introductory relic prices remain the existing campaign shop's 5% of debt (VNĐ12,500 on Monday), not the legacy standalone relic-runtime minimum. All daily service quotes are independent of current wallet balance. The normal free Trà Đá route remains available.

Monday curates physical card order, not outcomes. Players may ignore hints, skip optional services, lose money, or fail debt collection. The small lottery win suggested in the plan was optional; draws and prize rules remain unchanged. Random two-card shoe polish is retained and documented accurately. Onboarding knowledge is run-local, not a permanent unlock profile.

## Verification

- Godot 4.7.1 deterministic suite: **193/193 passed**. Covers rules, economy, persistent cards, services, exact saves, ledger/collection, seeds and onboarding regression cases.
- Gieo screen integration: **404 checks, zero failures**.
- Restricted demo smoke: **264 checks passed**.
- Broad runtime scene smoke: **PASS** after updating retired wallet/Handbook assertions and protecting deck browsing from delayed collector autofocus.
- Save/resume/relic/victory/Endless scene smoke: **PASS**, including pointer inspection followed by explicit purchase, exact saved hand and future draws.
- Retired tutorial/Handbook safety smoke: **PASS**; live hand is unchanged, legal selection remains available.
- Resolve scene smoke and collector presentation smoke: **PASS**, including finite entrance, Sound routing/playback lifecycle, interruption and wallet isolation.
- Complete Monday scene flow: **zero failures**, in full game and restricted demo. The full deterministic playthrough earned VNĐ1,393,500 before paying VNĐ250,000 and entering Tuesday; no fixture money was added to this flow.
- Rendered full flow inspected in Vietnamese at 1280×720 and English at 1920×1080: Starter ledger, polish, real Morning, Handbook/Gieo guide, relic table, lottery purchase/results, evening collection and next-day transition. Synthetic viewport pointer input verifies key purchase/continue/payment controls. Most later Deal actions use normal rule methods, not simulated human card input.
- `git diff --check`: PASS.

Representative generated captures are `.godot/overhaul-starter-debt.png`, `overhaul-relics.png`, `overhaul-gieo-guide.png`, `overhaul-lottery-results.png`, and `overhaul-collection.png`. Logs are under `.godot/final-*.log` and earlier `.godot/*overhaul*.log`. These are local validation artifacts, not packaged deliverables.

## Evidence boundaries

Automated audio routing/playback checks and rendered scenes do not establish audible mix quality or manual physical-input acceptance. Bike sound still needs listening in the user's setup. Some demo/presentation/progression processes and the final rendered Monday process reported ObjectDB/audio resource shutdown warnings after passing; the final core, runtime and headless Monday error logs are clean. The debt curve and starting bankroll have not received extended human balance playtesting. Browser persistence and export/publication were outside this task.
