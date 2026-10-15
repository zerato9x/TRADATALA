# TRADATALA text refinement — 15 October 2026

## Editorial direction

The Zodiac should sound like people who keep returning to the same street table. Give each a recognizable rhythm, a desire, a contradiction, and something they can admit only after trust develops. Keep action labels brief and terms of a bargain explicit. Public portraits suggest character; earned conversations reveal personal history.

Both English and Vietnamese were authored together. Local names and existing card notation remain intact. Mechanical terms stay consistent with the actions they describe, while conversations avoid internal implementation language.

| Zodiac | Voice and tension |
| --- | --- |
| Rooster | Precise, punctual, quietly worried; can balance a ledger more easily than an unaccounted hour. |
| Cat | Terse, teasing, possessive; disguises attachment as indifference. |
| Monkey | Improvises jokes and little performances; must learn that silence need not mean abandonment. |
| Dog | Plainspoken, loyal, stubborn; wants willing returns rather than promises that trap someone. |
| Pig | Warm, sociable, quick to pay; learning that company need not be purchased. |
| Buffalo | Practical, spare, observant; carries the heavy end and struggles to accept rest. |
| Horse | Restless and kinetic; learning the difference between movement and direction. |
| Goat | Exacting, dryly funny, attentive to sound; harsher toward her own unfinished work than others' mistakes. |
| Rat | Resourceful, concrete, alert to hidden costs; keeps some things no calculation can justify. |
| Tiger | Direct and imposing; learning that frightened silence is not respect or welcome. |
| Snake | Musical, deliberate, persuasive; trying to make a request without shaping the answer first. |
| Dragon | Measures the player against their own history. Public portrait only; encounter availability is unchanged. |

## Implemented scope

- Revised 603 existing bilingual dialogue entries across 11 Zodiac content files: greetings, relationship questions, player replies, reactions, remembered promises, and private moments. Rooster's private scene in the table UI was also rewritten.
- Added 12 bilingual public portraits and an About this Zodiac action in Collections. It opens the existing searchable Zodiac Handbook entry, which includes the portrait and available mood rules.
- Revised 89 shared localization entries, including four control-glyph cleanups, plus copy across eight UI scripts: menus, tutorial, Strawy, service explanations, evening remarks, deck guidance, and Handbook text.
- Corrected explanations of turn-scoped Nhân trần charges, current-Deal Ù earnings, Sets larger than four cards, and active owned Relics.
- Kept useful short labels and precise formal bargain terms. Cat's original Tier 1 source stays intact; Cat's expansion provides the new depth. Dragon remains unavailable, and no new Cat private scene was introduced.

For all 11 edited Zodiac content files, comparing the source with English/Vietnamese values removed yields identical structure. IDs, choice order, rewards, requirements, promise predicates, progression, card targeting, and save behavior were not edited. The pre-existing project.godot modification was preserved. No commit or push was made.

## Validation evidence

Fresh Godot 4.7.1 processes used isolated application-data profiles.

- Core suite: 539/539 passed after the dialogue and localization revisions.
- New rendered editorial smoke: 344 checks, zero failures. Exercises all 12 Collections portrait buttons in English and Vietnamese at 1280×720 and 960×720, localized headings/content, unique entries, Dragon availability wording, Handbook search, and screen-space reading bounds.
- Runtime and tutorial smoke passed after the final Handbook navigation change.
- Roster, readability, all existing Cat/Rooster/Monkey/Dog/Pig/Buffalo/Horse/Goat/Rat/Tiger/Snake dialogue scene checks and their fresh-process save/resume checks passed during the pass. A subsequent dialogue-only polish corrected question/reply fit; core was rerun afterward.
- Final Snake rendered scene check: 1,014 checks, zero failures; art review also aligned the private scene with her wind instrument.
- English/Vietnamese rendered portraits and representative dialogue captures were inspected. Rendered checks use synthetic pointer input; they are not physical-input or exported-build verification.
- Localization checks cover duplicate keys, both languages, placeholders, memory tokens, and accidental control glyphs.

Local test logs and screenshots are under `.godot/validation` and `.godot/text-refinement/screens`; they are generated evidence, not tracked game assets.
