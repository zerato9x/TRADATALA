# Trigger-first scoring presentation

Implemented: scoring remains authoritative in ScoringPipeline and VndWallet. Each scoring pass now carries value snapshots in presentation_hits; MatchUI converts those point receipts at the current payout multiplier and VND rate. Presentation never applies a wallet transaction.

- Physical card hits include ID, face, printed properties and points after the local multiplier.
- Making/Extend echoes immediately follow the same card. Whole Set/Run replays identify their source card and remain finite. New Melds at SET sizes 4/8/12/... and perfected A–K RUNs retain one native full-meld retrigger.
- Every Extension pays its intrinsic delta first. If the resulting SET reaches 4/8/12/... or the RUN becomes a perfected A–K sequence at 13 cards, one complete-meld retrigger follows that delta; Gieo full-meld retriggers follow it as additional finite passes.
- Ordinary extensions show committed-card hits followed by an explicit meld-delta adjustment. Other modifier/clamping differences are explicit signed adjustments. Hit totals exactly reconcile to each existing pass total.
- Exhaustion uses the same receipt and then overlapping card returns. It does not reapply Making echoes or duplicate payout.
- The compact receipt and its labels ignore pointer input. Existing ordinary gameplay remains unlocked.
- The first three card triggers each hold for 0.36 seconds. Subsequent hits gradually accelerate by 9% per card trigger to a 0.045-second minimum. Only cards already triggered determine speed; total event count and queue backlog never accelerate the opening. The counter persists across meld replays and resets for each new resolution. Replay announcements retain at least 0.18 seconds. Every hit receives its own frame-visible beat.
- Concurrent cosmetic bills are capped at eight; audio is throttled. Shared bill flight duration is 0.30 seconds.
- Tutorial receipt cancellation restores the shared layout and invalidates stale queue completions.

Validation: tests/test_money_presentation.gd covers order, physical identity, finite replay sources, extension delta, exhaustion, signed adjustments and pacing. tests/trigger_presentation_smoke.gd covers runtime wallet separation, input-transparent labels, cancellation, layout restoration and ghost cleanup. Existing runtime and tutorial smokes also exercise integration.

Visual QA uses synthetic live melds, not a saved campaign. The previous fixed-budget stress timing has been superseded by the user-requested gradual ramp; extremely long chains now take longer so every card trigger remains individually animated.

Each physical card rocks left/right on its own scoring hit and immediate retrigger. Other cards, score text, and the table remain still. A receipt card shakes only as a fallback when its physical table card is no longer available. Shakes restore the original rotation and pivot on completion, retrigger, and cancellation.
