# TRADATALA 1.1 content kit

Release title: **TRADATALA 1.1 — The Zodiac Boss System Update**

## Short announcement

TRADATALA 1.1 brings eleven Zodiac bosses to the sidewalk table. Meet them at Noon, make promises, face the consequences at Afternoon, and adapt to their evening rules. Includes bilingual stories, lasting relationships, Emblems, separate save files, and a refreshed table.

## Store-page addition

### The Zodiac Boss System

Meet eleven Zodiac visitors, each with authored English and Vietnamese conversations and a distinct evening boss rule. Your choices, promises, and play shape their disposition. Build relationships across runs, uncover remembered encounters, and work toward permanent Emblems.

Rooster, Cat, Dog, Monkey, Pig, Buffalo, Horse, Goat, Rat, Tiger, and Snake are playable. Dragon is reserved for a future update.

### Play in your browser or on Windows

The complete current seven-day campaign and Endless continuation are included in both builds. Each of the three save files keeps its own run, unlocks, and Zodiac progression.

The existing page's sentence describing Zodiac bosses as a future full-release feature should be replaced with this text for 1.1.

## Suggested image sequence

| File | Caption / alt text |
| --- | --- |
| `03-conversation-cat-en.png` | Cat asks a question at Noon. Choose an answer and build a relationship. |
| `02-noon-table-en.png` | The day's Zodiac joins the familiar visitors around the sidewalk table. |
| `05-evening-rooster-en.png` | Rooster's evening register closes early. Watch the discard windows. |
| `05-evening-cat-en.png` | Cat locks physical cards during the evening Deal. |
| `05-evening-snake-en.png` | Snake's command changes the next play. |
| `03-conversation-monkey-en.png` | Every Zodiac has its own authored voice and choices. |
| `07-zodiac-collection-en.png` | Track permanent Zodiac history and Emblem requirements. |
| `04-conversation-cat-vi.png` | The same authored encounter is available in Vietnamese. |

All images are 1920 × 1080 PNGs. `screenshots/captions.json` records their renderer, language, staging, and individual captions. These are actual rendered game frames from deterministic staged scenes in an isolated save profile. Evening fixtures use the tutorial opening hand, Normal boss difficulty, Iced Tea, a VND253,000 opening wallet, and a real legal Meld where the boss permits. No retouching or invented game UI was used. Home is captured from a development runtime; Boss Lab is developer-only and is not advertised as a release feature.

## Upload handoff

1. Use the ZIPs from `build/TRADATALA-v1.1/`.
2. On the existing [TRADATALA itch.io page](https://naixdev.itch.io/tradatala), upload `TRADATALA-v1.1-web-itch.zip` as the browser build and enable play in browser. The archive already has `index.html` at its root.
3. Upload `TRADATALA-v1.1-windows-itch.zip` as the Windows download. Keep the EXE and PCK together when extracting.
4. Use `DEVLOG.md` for the update post and the suggested screenshots above for its gallery.
5. Replace the old store-page paragraph that still calls Zodiac bosses a future feature. Preserve the existing page's music description.
6. Read `build/TRADATALA-v1.1/release-receipt.json` and verify the hashes in `manifest.json` before upload.

Publication to the existing itch.io page and its devlog was authorized on 15 October 2026. The build release receipt records the final upload and publication results.
