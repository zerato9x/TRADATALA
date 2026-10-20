# TRADATALA 1.1 content kit

Release title: **TRADATALA 1.1 — The Zodiac Boss System Update**

**Current availability - 15 October 2026:** Browser play has been rolled back to version 1.0.3 while bugs in 1.1 are fixed and further revisions are prepared. Version 1.1 remains available as a Windows download. The content and screenshots in this kit describe 1.1.

## Announcement

TRADATALA 1.1 overhauls the sidewalk table: eleven Zodiac bosses, a rebuilt deckbuilding shop, Fortune and paired card transformations, revised Drink carryover, Strawy guidance, three save files, and refreshed presentation. Meet the Zodiac, shape your deck, and survive the debt.

## Published copy

- [DEVLOG.md](DEVLOG.md): the full overhaul post, comparing the 1.1 release with 1.0.3.
- [ITCH-PAGE.md](ITCH-PAGE.md): the official game description and download instructions.
- `devlog.html` and `itch-description.html` in the content ZIP: corresponding rich-text versions.

The post covers Zodiac encounters and relationships; Hàng Rong card purchases/removal and all-owned Relics; Gieo Quẻ Fortune and special card properties; Đánh Giày paired Rank/Suit changes; Drink artwork and Phase 2 carryover; Strawy and tutorial settings; save profiles, UI, table atmosphere, music controls, and reliability work. Existing campaign/Endless content and the 26-track soundtrack are distinguished from newly added systems.

## Screenshots

The `screenshots/` folder contains 20 release-pass captures, each 1920 × 1080. Their captions, renderer, language, staging and SHA-256 hashes are in `captions.json` and `sha256.json`. These are actual rendered game frames from deterministic scenes in an isolated save profile. Evening fixtures use the tutorial opening hand, Normal boss difficulty, Iced Tea, a VND253,000 opening wallet, and a real legal Meld where the boss permits. No retouching or invented UI was used. The Home capture uses a development runtime; its Boss Lab button is developer-only.

The published devlog uses Cat's Noon encounter and Snake's evening encounter from this set. It also uses two clearly captioned 1280 × 720 development captures from the 1.1 cycle: Hàng Rong's shop (6 October) and Drink presentation (7 October). Those two PNGs are included under `development-screenshots/` in the updated content ZIP.

## Publication

- [Official game page](https://naixdev.itch.io/tradatala)
- [Published major-update devlog](https://naixdev.itch.io/tradatala/devlog/1708077/tradatala-11-the-zodiac-boss-system-update)

The 1.1 web upload is ID 19775840; Windows is ID 19775842. The web file is the browser build and the Windows file is the public download. Prior versions remain hidden for rollback. The official embed is 960 × 540 with fullscreen available.

Publication screenshots and exact verification results are in `build/TRADATALA-v1.1/verification/` and `release-receipt.json`. The downloaded Windows ZIP matches the local manifest's SHA-256. Before the rollback, the 1.1 web build was checked through Home, New Run, Start Run and campaign arrival without browser warnings/errors. These limited checks did not rule out the subsequently reported bugs. The rollback was verified from the public iframe upload ID and the public download listing; browser screenshots were unavailable during the rollback. This does not constitute an extended human campaign or listening review.
