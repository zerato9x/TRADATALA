# TRADATALA 1.1 — The Zodiac Boss System Update

**Availability update - 15 October 2026:** Browser play has been rolled back to version 1.0.3 while bugs in 1.1 are fixed and further revisions are prepared. Version 1.1 remains available as a Windows download. This article and its screenshots describe the 1.1 overhaul.

TRADATALA 1.1 is a major overhaul of the game around the sidewalk table. The Zodiac bosses are the headline, but this release also rebuilds deckbuilding, permanent card treatments, the street vendor and shoe-shine services, Drink carryover, player guidance, save profiles, and much of the interface and presentation.

If you last played 1.0.3, there is a lot more to discover than a new evening opponent. Here is what has changed.

## Eleven Zodiac visitors, from conversation to confrontation

Meet Rooster, Cat, Dog, Monkey, Pig, Buffalo, Horse, Goat, Rat, Tiger, and Snake. The day's visitor arrives at Noon with authored English and Vietnamese conversations. Choose your answers, negotiate counteroffers, and decide which promises you can keep. Their Afternoon return judges what you actually did at the table, and your dealings shape the evening boss challenge.

Each of the eleven has its own evening rules and three difficulty tiers. Rooster closes his register, Cat locks cards, Monkey asks you to change your play, and Snake issues commands. Their effects, targets, and progress are shown on the table.

Relationships remember your actions across runs. The authored encounter chains continue through Kindred, remembered promises, Last Chance encounters, and private Emblem scenes. Permanent history and collectible Emblems give those meetings a place beyond a single run. Dragon remains reserved for a future update.

![Cat at Noon: conversations and commitments are part of the daily game.](https://raw.githubusercontent.com/zerato9x/TRADATALA/v1.1/docs/releases/v1.1/screenshots/03-conversation-cat-en.png)

*Cat at Noon: conversations and commitments are part of the daily game.*

![By evening, the visitor's rules change the way you play the Deal.](https://raw.githubusercontent.com/zerato9x/TRADATALA/v1.1/docs/releases/v1.1/screenshots/05-evening-snake-en.png)

*By evening, the visitor's rules change the way you play the Deal.*

## A rebuilt deckbuilding shop and relic system

Hàng Rong now sells individual Relics, ordinary playing cards to add to your deck, and a paid service to remove a chosen card permanently from the current run. Each visit has three Relic offers and three card offers. Purchases mark individual items sold, so the rest of the stock stays available.

Every owned Relic is now active. The old four-Relic equipment limit and manual equip/unequip management are gone. Your collection appears as a scrollable rail during Deals and as objects on the Event table. Card purchases and removals change the deck you take into later Deals, making the street vendor a much larger part of building a run.

![Hàng Rong's rebuilt shop during 1.1 development: individual Relics, card stock, and permanent removal.](https://raw.githubusercontent.com/zerato9x/TRADATALA/v1.1/docs/screenshots/hang-rong-presentation-2026-10-06/selected-en.png)

*Hàng Rong's rebuilt shop during 1.1 development: individual Relics, card stock, and permanent removal.*

## Gieo Quẻ rebuilt around Fortune

The fortune machine now works with a signed Fortune value from -6 to +6. Positive Fortune creates Gold scoring growth; negative Fortune creates Black Ink, which earns income from affected cards at Deadwood settlement. Liquid adds Meld Echoes, Negative allows bounded rank and color-compatible suit flexibility, and combining Liquid with Negative creates Glitch's full rank/suit flexibility.

The six-reel reading, Accept step, jackpot selections, and on-card transformations have been reworked around these rules. Gold and Ink grow across the card face, while Liquid, Negative, and Glitch have distinct animated treatments. Printed card identities remain readable, and inspection and the Handbook explain the exact properties. These changes stay with the affected cards throughout the run.

## Đánh Giày transforms a committed pair

From Tuesday onward, Đánh Giày appears at the Starter Event. Commit two distinct cards for that day's visit, then pay once to transform both Ranks or both Suits. Each card rolls its own result, excluding its current identity. The cards keep their other properties, and their new printing carries into future Deals.

The chosen pair stays committed for the visit, including after saving and continuing. You can pay for further transformations while you can afford them; Rank and Suit prices rise separately with repeat purchases and scale with the day's debt.

## Drinks, carryover, and quicker table interactions

All twelve Drinks have new full, half, and empty artwork, with visible usage states on the table, in the shop, and in Collections. Target cues and quick gestures have been refined so it is easier to see which cards and table objects a Drink can use.

Sâm dứa and Bạc xỉu now let you mark the exact loose cards to carry into Phase 2 during Phase 1. Sâm dứa keeps up to three; Bạc xỉu can keep any number. After settlement, marked cards stay, other loose cards are discarded, and the hand refills automatically. All loose cards still count toward that Phase's Deadwood before the transition. The old KEEP/DUMP choice is gone.

![The new Drink art and usage cues, captured during 1.1 development.](https://raw.githubusercontent.com/zerato9x/TRADATALA/v1.1/docs/images/drinks_table_2026-10-07.png)

*The new Drink art and usage cues, captured during 1.1 development.*

## Strawy, tutorials, and advice

Strawy is now an animated helper you can ask for short contextual explanations, pointing tours, and advice about your current hand. He can preview a legal Meld, Extension, useful Drink action, or discard; another click confirms the specific suggested action. A preview leaves the game state alone, and changing the hand or context cancels it.

The ordinary Hint button and G shortcut still select a legal Meld or Extension. Tutorial, First Seed, and Show Strawy are separate settings, so you can choose the amount of guidance and whether to use the curated opening. The searchable bilingual Handbook now holds more of the detailed rules, with contextual links from the table and services.

## Three save files and a clearer front end

Home now leads directly to New Run or Continue, with separate Collections, Handbook, Music, Settings, and Save Files pages. Three named save profiles each keep their own current run, Drink unlocks, difficulty progression, Zodiac history, Emblems, and endings. Existing legacy progress imports into File 1.

Run and service persistence has been strengthened around the expanded deck and NPC systems. Committed card choices, paid services, shop stock, Zodiac commitments, and music transport resume with the run. Long Endless histories also have more efficient save handling.

## A new presentation pass across the table

The street now changes through morning, noon, afternoon, and evening lighting. Card piles have visible depth, hovered cards lift with softer shadows, and the discard archive is a larger sorting tray with separate suit lanes. Collections, setup, settings, save files, nightly debt receipts, and run results have all received layout and readability work.

NPC speech has animated reveals, while action terms, costs, and key numbers stay available at a glance. Zodiac rules have clearer counters and target feedback. Card selection and flexible-card analysis have been optimized, with smoother hand movement and more robust mouse, keyboard, and touch-event handling.

## Music and fixes

The music player now puts Authored DJ and Playlist in one clearer interface. The CAT and DOG authored sets can be selected directly; the 26-track playlist keeps its shuffle and repeat controls. Saved music transport resumes with the game, and campaign cues and anti-fatigue behavior have been refined.

This release also includes fixes and cleanup across save recovery, service payments, card inspection, interrupted input, and transitions. The release has been checked with automated gameplay and save/resume tests, rendered UI checks, and exported-package checks for Web and Windows.

TRADATALA 1.1 remains available as a Windows download, in English and Vietnamese. Browser play currently uses version 1.0.3 while the 1.1 build receives further fixes and revisions. The 1.1 overhaul includes the seven-day campaign and Endless; Dragon's encounter is still to come.

Thank you for playing, testing, and helping this sidewalk table grow. See you at the table!
