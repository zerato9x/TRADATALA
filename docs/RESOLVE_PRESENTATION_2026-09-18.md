# Resolve presentation overhaul — 2026-09-18

IMPLEMENTED NOW

- Shared game font and blue/cream palette; persistent net, income, and expense cards.
- Summary, scoring-card inspection, and transaction tabs. Wallet opening/closing and the continuation action stay outside the scrolling detail area.
- Card faces and point contributions come from committed scoring-pass snapshots, grouped by physical card ID within each action. All passes are included once; meld adjustments and separate relic bonuses retain their own lines. Points are not displayed as currency.
- Click or keyboard-activate a card to inspect localized properties. Card appearance, total count-up, tab fades, and exit fade use short finite tweens. Existing card-placement audio routes through Sound.
- Collection and outcome reports include completed-deal card history. The collection summary explicitly shows debt, remaining wallet, or shortfall.
- Presentation holds a detached report and never changes the wallet. Continue is guarded against repeated activation; MatchUI and campaign services retain progression/payment authority.

VALIDATION

- Core: 175/175 passed.
- Rendered resolve scene smoke: Vietnamese at 1280x720 and English at 1920x1080; deal summary, card inspection, transactions, collection, and outcome captures inspected.
- Pointer checks: tabs, card inspection, deal continuation, one debt payment, and clean new-run ledger.
- Focused presentation smoke: rapid tab switching, exact final positive/negative totals, empty reports, repeated opening, no wallet mutation, shortfall layout, and double continuation.
- One 1080p scene run emitted a two-instance ObjectDB shutdown warning after PASS; focused presentation smoke exited cleanly. Shutdown cleanliness of the full match scene remains unverified.
- Audio uses Dummy during automated checks: routing is implemented; physical listening quality is not verified.

Entry points: `scripts/ui/resolve_receipt.gd`, `MatchUI._resolve_card_history()`.
Tests: `tests/resolve_scene_smoke.gd`, `tests/resolve_presentation_smoke.gd`.

## Collector arrival — 2026-09-20

Collection receipts now introduce Đòi Nợ with a large motorcycle ride-in, braking lean, brief settle, and docking into the receipt portrait. The supplied `bike_sound.mp3` plays through the Sound bus with an approach/fade envelope. Tabs, continuation, report replacement, and hiding the receipt cancel the entrance and audio; payment remains immediately actionable and authoritative accounting is unchanged. The Starter Event also introduces him with this entrance and the weekly ledger. Evening collection clears the played table, foregrounds a large collector, and keeps the shared top wallet visible. Paying flies bills to him and plays a short departure while campaign authority advances the day.

Focused headless and rendered presentation checks pass, including sound routing/playback, entrance duration, docking, interruption, repeat opening, and wallet isolation. Entrance and final portrait captures were inspected at 1280×720. Final audio mix quality still requires listening.
