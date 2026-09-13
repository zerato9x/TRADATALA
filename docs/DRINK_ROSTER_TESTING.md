# Drink roster and NPC conversation testing

Updated through September 13, 2026. Mechanics testing; final prices, art and day/tier progression are not implemented.

## Player flow

Start a campaign, select Cô Trà Đá, then point to a Drink on the table. She explains its effect in the current language. Inspecting never spends money or selects the active Drink. Choose “I'll have this one” to order. Back closes the conversation; returning recalls the ordered Drink. Starter and Noon both show all twelve Drinks. Ordering still uses the existing once-per-service flow and one active Drink; Noon replaces the morning selection.

The shop occupies the left of the table, clear of Cô Trà Đá's sprite, with four labeled groups: Basic, Caffeine, Energy and Sugar. Đánh Giày is a kid; his greeting and small talk use child-appropriate Vietnamese/English.

The top-right `?` opens the shared action-word legend. HẠ/MELD is green, EXTEND amber, DISCARD/DUMP coral, KEEP/SWAP/RECOVER cyan, DRAW pale blue, SETTLE lavender, and ORDER gold. Dialogue verbs and primary action controls use the same vocabulary. Text labels remain present so colors are not the only identifier.

`DrinkManager.TEST_ALL_DRINKS_AVAILABLE` defaults to true. Its instance override can be disabled to retain the existing Basic shop path. The zero test price is explicitly provisional. Tier/category/charge metadata stays in DrinkCatalog; Caffeine entries have no parent relationships.

Every Drink effect is optional. Trà đá's extra discard can be skipped with **End Turn**. Ordinary Phase transitions automatically DUMP the loose hand and refill toward ten after settlement. **KEEP is available only with Sâm dứa or Bạc xỉu**; their optional preservation applies when DUMP is chosen. Preservation selections count as deadwood before either choice.

| Drink | Tier / category | Effect and charge |
|---|---|---|
| Trà đá | 0 / Basic | Optional extra discard after the mandatory discard each Turn; separate provenance; End Turn skips it. |
| Nhân trần | 1 / Basic | Swap one loose card with a current-Phase mandatory discard, once per Turn. |
| Nước vối | 1 / Basic | Recover one Meld card, leaving at least three legal cards; once per Phase; keep banked score. |
| Sâm dứa | 1 / Basic | Before Phase 1 settlement, preserve zero to three loose cards for optional DUMP. |
| Đen đá | 2 / Caffeine | Swap one loose card with any live Deal discard, including extra and DUMP cards; once per Turn. |
| Nâu đá | 2 / Caffeine | Recover a whole Meld once per Phase. Banked score stays; legally laying those same cards scores a new Phỏm. |
| Bạc xỉu | 2 / Caffeine | Sâm dứa timing with no preservation cap; zero through all loose cards. Refill toward ten, never ten plus preserved cards. |
| Sting | 2 / Energy | Explicitly create one two-card same-rank Set per Phase. Normal new-Phỏm scoring and matching-rank extensions. |
| Bò Húc | 3 / Energy | Sting permission once per normal Turn. |
| C2 | 2 / Sugar | Explicitly create one Run per Deal ignoring suit. The Meld retains compatibility for endpoint extensions. |
| Nước Mía Quất | 3 / Sugar | Hearts/Diamonds compatible in Run creation and extension. |
| Nước Mía Sầu Riêng | 3 / Sugar | Spades/Clubs compatible in Run creation and extension. |

LAST CALL grants no extra Turn charge. All Runs retain consecutive unique ranks, Ace low, no wrap. Ordinary same-suit Runs and ordinary Sets stay unchanged. No Drink adds a direct score multiplier; Pair Sets score through the normal new-Phỏm/Gieo path and prevent MÓM.

## Controls and ownership

- Click the Drink first. Blue outlines show eligible targets; selected hand cards rise. The action row exposes **Use Drink** for effects requiring confirmation and **Cancel / Esc** without spending. Card movement while clicking cannot accidentally start a drag in Drink mode.
- Nhân trần / Đen đá: choose a loose card and a highlighted discard in either order. Selecting the loose card opens a larger, scrollable picker of legal targets. Closing it preserves the pending hand selection; the discard archive button reopens it. Đen đá includes live extra-discard and DUMP records. Picking the second target completes the swap.
- Nước vối: click an eligible card within a Meld. Nâu đá: click any part of the highlighted Meld to reclaim the whole unit.
- Sting / Bò Húc / C2: select highlighted cards, then press **Use Drink** (or click the glass again). Confirmation stays disabled until the selection is legal. Click selected cards again to deselect; C2 permits choosing endpoints before filling the middle, including in large hands.
- Sâm dứa / Bạc xỉu: select preserved cards during Phase 1 LAST CALL and press **Use Drink**, including an empty selection. Settle, then choose KEEP or DUMP.
- Sugar compatibility effects apply to optional Meld actions; they never force a Meld.

DealState owns legality, charges, discard-zone checks, and Meld creation. MeldState owns persistent Run compatibility and Pair provenance. ScoringPipeline remains unchanged. Large recovered hands avoid exponential subset allocation for target cues and hints.

`scenes/ui/drink_shop.tscn` owns the shop composition. The existing DrinkManager purchase path commits orders. `scenes/ui/npc_conversation.tscn` provides reusable speaker/text presentation, cancellable text reveal, click-to-reveal, small-talk responses and departure. All five table NPCs use localized greetings; their existing service/placeholder behavior remains intact. Departure respects an in-progress Gieo service. This is authored local dialogue, without a generated dialogue backend or new quest system. Drink images reuse existing glasses as temporary mechanics-test art.

## Verification

- Full headless suite: 114/114, including Gieo hooks, oversized recovery hands, mandatory normal DUMP, colored action vocabulary, and exact large-hand C2 target completion.
- Existing runtime scene smoke: PASS, including inspect/order and preservation targeting.
- Tutorial scene smoke: PASS.
- `tests/drink_shop_smoke.gd`: PASS in rendered Godot. Covers all twelve inspections in English/Vietnamese, explicit order, layout bounds at 1280×720 and 1920×1080, shared NPC speech, and viewport mouse input for Sting, both discard swaps, C2, Nước vối, whole-Meld Nâu đá, and Bạc xỉu. Includes cancellation, deselection, invalid targets, zero-card preservation, filled/spent glass states, and stationary-pointer versus moving-card drag regression checks.

Run with Godot 4.7.1:

```
Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --quit
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/run_headless.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/runtime_scene_smoke.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/tutorial_scene_smoke.gd
Godot_v4.7.1-stable_win64_console.exe --path . --script res://tests/drink_shop_smoke.gd
```

The rendered shop smoke writes `docs/images/drink_shop_testing.png`, `docs/images/action_vocabulary.png`, and `docs/images/drink_targeting.png`.

September 13 interaction pass: unused testing Drinks use filled class-tinted placeholder glasses; spent Drinks use half-full art. Noon does not override the actual charge presentation. The editor MCP session was disconnected during final verification; rendered executable tests provide the mouse-input and screenshot evidence for this pass.
