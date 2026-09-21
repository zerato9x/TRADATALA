# Presentation and readability pass — 21 September 2026

This pass continues the existing mixed campaign-overhaul work. The file list below describes this pass, not all outstanding changes in the checkout. No commit, export or publication was performed.

## Collector encounter

The collector no longer belongs to the Starter table roster. The old 210 × 260 table overlay and its special click region were removed. The campaign's Starter event opens a full character encounter when its existing `debt_intro` interaction is incomplete. A full-size rider enters from the right, settles beside the dialogue, and presents the current authoritative requirement, evening deadline and shortfall. Acknowledgement slides him out. There is no collector overlay or service button left on the table. Future requirements remain available through the journey and handbook.

The campaign's existing collection signal opens the evening return. Receipt, character and payment remain separate owners. Collection clears old event presentation before opening, including when the state is restored from an event. Payment calls `CampaignManager.collect_day_debt()` once before money flies; `VndWallet.balance_changed` observes the already-journaled deduction. The receiving actor stays until banknotes arrive and then leaves. The next Starter presentation waits for departure. Repeated continuation is gated. Insufficient money follows the existing campaign failure route.

## Wallet and money

One top-right wallet persists across gameplay, event overview, focused services and receipts. The competing central event balance and tabletop cash pile are hidden. Removed the old center-to-top wallet teleport. The supplied banknote assets still provide physical transfers from wallet to service, and back for rewards. Service transfers also show a brief signed amount; larger amounts use a larger amount label, while existing major-event/scoring ceremonies remain responsible for large gameplay rewards.

`VndWallet.format_vnd()` now formats presentation as `₫250.000`, `+₫250.000`, or `−₫50.000`. Grouping is consistent in both languages. Purchase, tip, ticket, reroll and cast prices have negative signs. Lottery payouts have positive signs. Static currency examples in the handbook, menu, receipt and translations were brought into the same format. This changes formatting only, not arithmetic or journal contents.

## Shared text system

`PresentationTheme` defines body/muted, wallet, gain, cost, debt, number, card/action, success, warning/danger, speaker, mechanic and jackpot roles. Paper receipts use darker variants for contrast. The shared helpers provide label styling and inline money emphasis without recoloring entire dialogue paragraphs. Existing action vocabulary still distinguishes actual card verbs.

The global default and standard buttons use 16 px text; disabled text has stronger contrast. Wallet labels, debt figures and NPC names have explicit hierarchy. NPC responses were enlarged. Debt's deadline, service prices, glossary money examples and relic descriptions receive inline emphasis. Lottery tickets retain dark text on paper and distinguish purchased state by its written label. Service text and relic price/effect text receive dark backing against the table texture. The debt receipt uses a large dedicated amount-due field; prose remains neutral.

## Localization

Added four bilingual debt-intro keys in `locale/ui.csv`. Corrected a malformed fortune-teller greeting row: its unquoted Vietnamese comma previously shifted Vietnamese text into the English column. Rebuilt both imported translation resources in a fresh editor import. Added a regression that validates all nonempty CSV rows have exactly three columns, plus direct English/Vietnamese greeting and signed inline-emphasis regressions.

## Files changed in this pass

- `scripts/ui/event_table_controller.gd`, `debt_collector_arrival.gd`, `match_ui.gd`: encounter staging, cleanup and transaction/transition ordering.
- `scripts/ui/campaign_money_hud.gd`, `event_table_overview.gd`, `money_presentation.gd`: persistent anchor, committed service flights, signed feedback and shared colors.
- `scripts/ui/presentation_theme.gd`, `npc_conversation.gd`, `scenes/ui/npc_conversation.tscn`: semantic styling, defaults and dialogue hierarchy.
- `scripts/ui/drink_shop.gd`, `gieo_que_panel.gd`, `misc_npc_panel.gd`, `relic_table_shop.gd`, `lottery_receipt.gd`: readable service costs, labels, backing and rewards.
- `scripts/ui/resolve_receipt.gd`, `game_glossary.gd`, `run_menu.gd`: receipt contrast, debt hierarchy, reference emphasis and currency examples.
- `scripts/economy/vnd_wallet.gd`: formatter only in this pass; existing economy edits were preserved.
- `locale/ui.csv`, `locale/ui.en.translation`, `locale/ui.vi.translation`: bilingual copy and rebuilt translations.
- `tests/test_presentation_text.gd` and generated UID; `tests/run_headless.gd`, `test_campaign.gd`, `test_core_deal.gd`, `test_money_presentation.gd`, `runtime_scene_smoke.gd`, `campaign_overhaul_scene_smoke.gd`, `progression_scene_smoke.gd`: regressions and rendered coverage.

No scoring, debt calculation, campaign schedule, service pricing or physical card identity logic was changed in this pass. The only transaction-path change is UI ordering: the existing campaign payment call runs before its animation instead of after a speculative preview.

## Validation and visual coverage

Godot 4.7.1 fresh processes, isolated test user data, supplied project assets.

- Core: **196/196 passed**, including CSV, bilingual greeting, money formatting and semantic emphasis checks.
- Runtime scene: **passed**. Starter auto-focus assertion, collector exit and subsequent service/deck interaction covered.
- Handbook/tutorial replacement: **0 failures**; the reference preserves the live deal.
- Resolve presentation: **PASS**, including repeated continuation, interruption, sound lifecycle and unchanged wallet.
- Campaign rendered smoke: **0 failures**, English 1280 × 720 and Vietnamese 1920 × 1080. Covers real Monday legal play, services, scoring, evening collection and Tuesday. Assertions include no tabletop collector, persistent wallet, no duplicate balance, committed balance before flight, one journal payment after repeated continuation, current next-day requirement and cleared departure gate.
- Progression rendered smoke: **PASS** in both languages. Seed menu, resume, relic ownership, victory scroll, MVPs, stats, endless day, shortfall and failure use isolated fixtures.
- Live MCP: viewed starter encounter, checked imported English fortune-teller text, sent acknowledgement mouse press/release, and queried collector sprite/overlay/button visibility afterward.
- `git diff --check`: **passed**.

Rendered review includes starter, overview, HUD/hand prompts, shoe service, drink shelf, relic offers and details, lottery purchase/results, Gieo cabinet and reference, handbook, deal receipt, collection, next day, seed menu, victory/MVP/stat pages, endless, shortfall and failure. Screenshots are local QA artifacts under `.godot/overhaul-en-*.png`, `.godot/overhaul-vi-*.png` and `.godot/progression-*.png`.

## Remaining limitations

Runtime and handbook smoke processes pass their assertions but report ObjectDB/resource cleanup warnings on exit (runtime: 8 instances / 4 resources; handbook: 6 / 3). These are not claimed as clean teardown. Fresh rendered campaign/progression/resolve runs complete without those errors.

The review covers major screens and representative states, not every procedurally generated card, relic, drink and jackpot combination. Tiny secondary labels in older card/board assets retain their established layout; the shared theme does not override every intentionally authored micro-label. Existing relic proper names remain Vietnamese in the English catalog while effect descriptions are localized. Audio lifecycle was tested; no perceptual listening acceptance or physical-device input claim is made. MCP mouse input is synthetic.
