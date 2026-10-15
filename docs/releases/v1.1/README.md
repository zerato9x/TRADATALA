# TRADATALA 1.1 — The Zodiac Boss System Update

Release date: 15 October 2026.

The current release includes the complete seven-day campaign and Endless continuation for Web and Windows x86_64. The game version is `1.1`; Windows file and product versions are `1.1.0.0`.

## Update scope

- Eleven available evening Zodiac bosses: Rooster, Cat, Dog, Monkey, Pig, Buffalo, Horse, Goat, Rat, Tiger, and Snake. Dragon remains unavailable.
- Authored English and Vietnamese Noon encounters and Afternoon follow-through, remembered relationships, Kindred progression, Last Chance encounters, and private Emblem scenes.
- Three boss difficulty tiers, collectible Emblems, permanent history, and three independent save profiles.
- Updated table presentation, boss effects, pile archives, collection presentation, receipts, Handbook text, and campaign music direction.

The web pack uses lossless Brotli transport encoding to fit itch.io's extracted-file limit. The debug-only full-reference table artwork is excluded from release packages. itch.io serves the .br file with Content-Encoding: br; other hosts must provide the same header. The uncompressed verification copy stays outside the web upload folder.

The release version changes metadata and packaging. Existing game content and gameplay authority are preserved. The validation pass updates older assertions to follow the current authored wording and the single-visitor Monday tour; the headless lighting check compares the home material before and after gameplay instead of requiring an implicit shader default to be loaded.

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
