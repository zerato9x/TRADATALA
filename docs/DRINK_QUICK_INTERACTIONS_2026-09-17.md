# Drink quick interactions - 2026-09-17

Implemented in the current project. Drink rules, charge cadence, scoring, and ownership remain in DealState.

## Choosing a drink

Click a shelf drink to inspect and select it without spending. The explicit Order button commits the purchase. Locked/unaffordable drinks cannot be ordered; a completed order cannot fire twice. A visible hint explains the controls.

## Using all twelve drinks

| Drink | Quick interaction |
| --- | --- |
| Trà đá | Passive: discard normally; the optional extra discard plays this drink's Objects cue. No cup activation required. |
| Nước vối | Drag a legal endpoint/removable meld card back into the hand or onto the cup; alternatively drag the cup onto that card. Cup-then-target click remains available. |
| Nhân trần | Drag a loose hand card onto a current-phase mandatory discard, or drag that discard onto a hand card. Select a hand card then click the cup once to open the legal discard picker. |
| Sâm dứa | At the existing phase-one transition window, select up to three cards then click the cup once or drag the group onto it. Cup-first selection can also finish with H; zero-card confirmation remains available through the existing confirm action. |
| Đen đá | Same swap gestures as Nhân trần, using its existing wider live-discard/DUMP eligibility. The picker supports dragging a discard back onto a hand card. |
| Nâu đá | Drag a meld back to the hand or onto the cup; alternatively drop the cup onto the meld. Selecting a meld then clicking the cup uses it immediately. |
| Bạc xỉu | Same preservation shortcuts as Sâm dứa with its existing preservation limit. |
| Sting | Select the pair normally, then drop it onto the table/cup or press H/click the cup. If the cup was armed first, the second matching card click completes the pair automatically. |
| Bò Húc | Same quick pair controls as Sting; its existing charge/reset rules apply. |
| C2 | Select the complete mixed-suit run, then drop it onto the table/cup or press H/click the cup. Armed selection remains draggable and does not auto-commit at three cards, allowing longer runs. Normal same-suit table melds do not spend C2 unnecessarily. |
| Nước Mía Quất | Passive: normal table drops/H and extensions use the existing red-run permission automatically. An actual mixed-suit run action plays this drink's cue. |
| Nước Mía Sầu Riêng | Passive: normal table drops/H and extensions use the existing black-run permission automatically, with its own cue. |

Cards keep drag support during targeting. Valid destinations use the existing outlined drop-target style; a moving preview represents the selected group or cup. Twelve-pixel movement tolerance keeps small click jitter from becoming a drag. Escape and focus loss clear cup/recovery drags. Invalid drops and invalid recovery attempts do not spend a charge. Pointer hit tests honor ancestor clipping.

Quick drink gestures and discard picking remain available during nonblocking payout animation. Rapid recovery exposed an unused, stale physical-source argument in MoneyPresentation; the bill-stack function no longer accepts that argument, so recovering a scoring meld cannot break that receipt.

## Sounds

Every drink has a distinct unchanged copy from `G:/PHOM/Sound/Objects/` in `assets/audio/sfx/drinks/`. Successful purchases, active uses, and actual passive uses route through the existing Sound bus/slider. Existing availability cues use the current drink's recording at lower gain. Playback remains bounded and rate-limited; scene exit releases feedback streams.

| Drink asset | Original Objects recording |
| --- | --- |
| tra_da.wav | iced beverage in plastic cup 1.wav |
| nuoc_voi.wav | glass clink 1.wav |
| nhan_tran.wav | glass clink 2.wav |
| sam_dua.wav | iced beverage in plastic cup 2.wav |
| den_da.wav | glass clink 3.wav |
| nau_da.wav | glass clink 6.wav |
| bac_xiu.wav | iced beverage in plastic cup 5.wav |
| sting.wav | iced beverage in plastic cup shaken 1.wav |
| bo_huc.wav | iced beverage in plastic cup shaken 4.wav |
| c2_iced_tea.wav | iced beverage in plastic cup 7.wav |
| mia_tac.wav | iced beverage in plastic cup 8.wav |
| mia_sau_rieng.wav | iced beverage in plastic cup 9.wav |

## Validation

- Fresh Godot 4.7.1 core suite: 125/125 passed.
- Rendered whole-roster pointer regression: 151 checks, zero failures. Covers all twelve shop previews/orders and audio assets, selected-first quick use, armed pairs, multi-card C2/preservation drags, both recovery directions, swap gestures, passive effects, ordinary table drops, charge preservation, cancellation, and recovery during an active payout.
- Runtime scene, twelve-drink shop, tutorial, and trigger-presentation smokes passed.
- Shared UI feedback regression: 82 checks, zero failures.
- Rendered drag preview inspected: `.godot/drink_quick_drag.png`.
- Scoped `git diff --check` passed.

The shop smoke still reports resource-in-use/ObjectDB warnings at shutdown; functional pass markers are separate from clean teardown. Audio validation used the Dummy driver and proves imported streams, routing, event playback, cooldowns, and lifecycle checks, not speaker/headphone listening quality. No build/export, commit, or unrelated cleanup was performed.
