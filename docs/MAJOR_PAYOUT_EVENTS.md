# Major payout events — implemented

Ù pays at the qualifying discard, once per qualifying turn. It adds the current deal earnings (previous phase net plus this phase income less already charged deadwood), immediately. The signed earnings become exactly ×2 (zero stays zero). Existing wallet savings are excluded. Future payouts retain their normal value. Settlement does not pay the bonus again. The earnings HUD and both tutorial locales describe the same deal-wide amount.

Ù, Ù Khan and Exhaustion use a centered title and payout, a darkened table, 36 enlarged decorative VND notes emitted in a radial burst, and a staggered collection into the wallet. Exhaustion combines its meld payouts and then returns captured cards to the draw pile. The economy remains in DealState; presentation never pays a second time. Cancellation kills the burst and wallet-count tweens.

Checks: tests/run_headless.gd covers the payout and repeat-trigger regressions; tests/major_event_smoke.gd covers all three ceremonies, cancellation, and real exhaustion queue settlement. Run that smoke with a graphical renderer and -- --capture for screenshots in .godot/major_event_*.png. Runtime, tutorial and trigger-presentation smokes cover integration. These checks do not establish physical-input or listening acceptance.
