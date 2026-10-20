# TRADATALA 1.1 — The Zodiac Boss System Update

Release date: 15 October 2026.

**Current itch.io availability:** browser 1.0.3; Windows download 1.1. The 1.1 browser upload is hidden while reported bugs are fixed and further revisions are prepared. The following release scope describes 1.1 and its preserved packages.

The 1.1 packages include the complete seven-day campaign and Endless continuation for Web and Windows x86_64. Only Windows 1.1 is currently public on itch.io; browser play uses the retained 1.0.3 upload. The game version is `1.1`; Windows file and product versions are `1.1.0.0`.

## Update scope

Compared with 1.0.3, this release includes:

- Eleven Zodiac visitors and evening bosses, three boss tiers, authored bilingual encounters, same-day commitments, relationships through Kindred, Last Chance encounters, permanent history and Emblems. Dragon remains unavailable.
- Hàng Rong deckbuilding: individual Relic purchases, ordinary card purchases, paid card removal, and all owned Relics active without the former four-slot equipment limit.
- Gieo Quẻ's signed Fortune, Gold/Black Ink economy, Liquid Echoes, Negative/Glitch flexibility, revised machine flow and card materials.
- Đánh Giày's Tuesday-onward paired Rank/Suit transformations, committed daily selections and revised prices.
- New Drink artwork, refined targeting/gestures, and explicit marked-card carryover into Phase 2 for Sâm dứa and Bạc xỉu.
- Strawy's animated contextual help, move previews, tutorial tours and independent Tutorial/First Seed/visibility preferences.
- Three save profiles, rebuilt menu flow, clearer Handbook and Collections, day/night ambience, physical pile/archive and receipt presentation.
- Updated music controls, authored cue/resume behavior, input/selection performance, and service/save reliability.

[DEVLOG.md](DEVLOG.md) contains the detailed published change description; [ITCH-PAGE.md](ITCH-PAGE.md) records the official store copy.

The web pack uses lossless Brotli transport encoding to fit itch.io's extracted-file limit. The debug-only full-reference table artwork is excluded from release packages. itch.io serves the .br file with Content-Encoding: br; other hosts must provide the same header. The uncompressed verification copy stays outside the web upload folder.

The release validation repaired stale test expectations to match current authored wording, tutorial behavior, and presentation contracts. No gameplay changes were made during packaging. The build manifest remains tied to source commit 53180dd7dcba7c5fe23907937f3fbce99031189d; later publication-copy edits do not retag or rebuild those packages.

## Release files

Run `tools/build_full_release.ps1 -OutputDirectory build/TRADATALA-v1.1` from the repository root with Godot 4.7.1 and its matching export templates installed.

The release directory contains:

- `TRADATALA-v1.1-web-itch.zip`: no-threads Compatibility browser export, with `index.html` at the ZIP root.
- `TRADATALA-v1.1-windows-itch.zip`: Windows x86_64 EXE and separate PCK.
- `manifest.json`: exact source commit, worktree state, package sizes, and SHA-256 hashes.
- `release-receipt.json`: package, runtime, browser, and publication evidence.
- `TRADATALA-v1.1-content-kit.zip`: devlog copy and 20 screenshots.

See [DEVLOG.md](DEVLOG.md), [CONTENT-KIT.md](CONTENT-KIT.md), and [contact-sheet.jpg](contact-sheet.jpg). Screenshot captions and staging details are in [screenshots/captions.json](screenshots/captions.json); hashes are in [screenshots/sha256.json](screenshots/sha256.json).

## Validation workflow

The complete release gate uses `tools/validate_project.ps1 -Full`. `-LogDirectory` gives separate runs their own evidence and isolated profiles. Focused rendered checks cover the table lighting, boss HUD, Cat conversations, and Snake conversations. The exported-package probe is `tools/release_pack_check.gd`; it checks both exported packs for version, required boss/dialogue/audio resources, absence of development content, new-run startup, Noon encounters, evening boss selection, and save/restore.

The final receipt lists the checks actually completed. Automated tests and rendered checks do not constitute an extended human campaign playthrough or an audio-listening review.

The package probe runs through the Godot console executable with an explicit PCK. Official Windows release templates disable command-line path overrides, so native executable checks use the normal game UI.
