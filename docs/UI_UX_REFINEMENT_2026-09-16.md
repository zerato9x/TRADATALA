# UI / UX refinement - 2026-09-16

Implemented in the current project:

- Localized scoring/replay copy in English and Vietnamese; first-pass headings omit the redundant pass number. Echo/Flow cues no longer concatenate internal hit labels. Replay announcements no longer show a question mark in the amount line.
- Receipt and major-payout typography explicitly uses the official game font, with thinner outlines and the shared gain/loss colors. Compact scoring sits higher above its source; the smaller denomination stack sits below the total without crowding the meld header. Card-only trigger motion and existing trigger-count pacing remain intact.
- Scene-owned UIFeedback supplies quiet button hover/press, gain/loss, rejection, transition, drink, lever, reel, reel-stop and jackpot cues. Existing and dynamically added buttons participate; hidden/disabled controls stay silent. Button binding is synchronous so rapid Gieo rebuild/free cycles do not queue callbacks to dead objects.
- Previously unconnected money-impact signals now drive feedback. Scoring-stack flights and opening/menu page changes use a short whoosh. Successful drink use and purchase use iced-cup audio. Gieo uses the supplied slot-machine cues; jackpot playback is emitted only for an actual jackpot result. Reels stop at result reveal or panel removal.
- Sound uses the existing Sound bus/slider. Each cue has one voice, a cooldown, conservative gain, a bounded duration, and a short tail fade. No music transport or scoring/economy authority changes were made for this refinement.
- Shared tooltip styling matches the ink/gold/dark palette. New banner messages cancel old banner tweens so stale fades cannot hide fresh feedback. Missing drink-unlock translations are supplied.

## Supplied audio mapping

Project copies live in `assets/audio/sfx/feedback/`. Originals were copied unchanged.

| Project asset | Supplied source | Use |
| --- | --- | --- |
| transition.wav | S:/Asset/_Audio/16 Free Wooshes/Woosh 8.wav | transitions, money flight, transformations |
| reward.wav | G:/PHOM/Sound/Objects/glass ding 11.wav | score/reveal confirmation |
| tap.wav | G:/PHOM/Sound/Objects/glass clink 5.wav | buttons, losses, rejection, reel stops |
| drink.wav | G:/PHOM/Sound/Objects/iced beverage in plastic cup 4.wav | successful drink purchase/use |
| lever.mp3 | G:/PHOM/Sound/slot_machine/slot_machine_pull.mp3 | Gieo lever |
| reels.mp3 | G:/PHOM/Sound/slot_machine/slot_machine_sound.mp3 | Gieo spinning |
| jackpot.mp3 | G:/PHOM/Sound/slot_machine/slot_machine_jackpot.mp3 | actual Gieo jackpot |

## Verification

Fresh Godot 4.7.1 processes with isolated user settings:

- Core suite: 125 passed, zero failed.
- Dedicated UI refinement smoke: 58 checks, zero failures, including actual viewport pointer input, disabled-button silence, dynamic controls, rapid rebuild/free, reward rate limiting/tail stop, reel stop, banner cancellation, bilingual runtime text, and unchanged authoritative wallet.
- Runtime scene, tutorial, trigger presentation, title, drink-shop and major-event smokes passed.
- Gieo screen smoke: 404 checks, zero failures after fixing the new button-binding lifecycle defect.
- The drink-shop harness now dismisses the existing opening title before testing menu clicks. Its former first-click failure was a setup error: the title correctly consumed that click.
- Rendered OpenGL receipt captures inspected in English and Vietnamese; actual physical-card scoring capture inspected after spacing changes. Captures: `.godot/ui_refinement_en.png`, `.godot/ui_refinement_vi.png`, `.godot/money_stack_receipt.png`.
- Scoped `git diff --check` passed.

Some shutdowns report ObjectDB/resource-in-use warnings. A verbose dedicated smoke identifies `AudioStreamPlaybackWAV` / `AudioStreamWAV` for the existing `res://assets/audio/ost/main_1.wav`, rather than the added feedback cues. Functional checks pass; this is not a warning-free shutdown claim.

Audio tests use the Dummy driver and establish routing, stream availability, timing/cutoff, and rate limits. They do not establish speaker/headphone mix quality; a listening playtest remains necessary. Render inspection covers the captured receipts, not every screen and resolution. Existing mixed work was preserved; no build was exported and no commit was made.
