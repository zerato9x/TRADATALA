# Gieo Quẻ / Card Fortune — 2026-10-05

The existing six-reel slot machine and five-frame lever remain the interaction.
The upper trigram changes Fortune; the lower chooses physical cards. Reels settle
in order, the upper reading appears first, and cards remain hidden until Accept.
Jackpots add a cabinet flash, brief glints and an independent property stamp.
Accept reveals real cards in a tray on the cabinet; the treatment grows directly
on each card face. Tap, Enter or Space during animation accelerates presentation.

## Authoritative card state

`CardData` owns one clamped signed `fortune` (-6..+6), `liquid`, and `negative`.
Glitch is derived from both flags; it is never a third independent stored flag.
Gieo never changes actual rank, suit, base value or physical ID. Other systems'
rank/suit changes, day polish, transformation seals and physical duplicates survive.

| First trigram | Fortune adjustment |
| --- | ---: |
| PPP | +3 |
| PPN | +2 |
| PNP | +2 |
| PNN | +1 |
| NPP | -1 |
| NPN | -2 |
| NNP | -2 |
| NNN | -3 |

Mixed lower trigrams select one random eligible physical card. PPP selects three
cards with consecutive **actual** ranks; NNN selects three with the same **actual**
suit. No wraparound, wildcard substitution, duplicated ID or reduced-count fallback
is used for these promises. If seals or actual identities prevent the pattern, the
reading stays unaccepted so the player can reroll or refuse.

PPP | PPP asks for an exact eligible card and adds +3 Fortune and Liquid.
NNN | NNN asks for an exact eligible card and adds -3 Fortune and Negative.
Receiving the opposite property creates Glitch while Fortune continues independently.
One free reading per day spans Morning/Noon/Afternoon; subsequent readings retain
existing scaled prices and doubling. Charges publish a coherent reading/counter
state to wallet/save observers and reject reentrant input.

## Meld identities and economy

Positive Fortune counts the intrinsic card value `fortune` times for every scored
Meld contribution, including extensions and exhaustion. Gold has ordinary Deadwood
value. Black Ink scores ordinary Meld value but pays `intrinsic × abs(fortune)` as
Deadwood income. Normal cost and Ink profit are committed as separate wallet entries,
even at zero net. Móm/boss Deadwood multipliers affect cost; the profit uses income
hooks, including Pig/Dragon siphons. UI receipts observe these entries without paying.

Negative may represent bounded actual-rank ±1 and either suit of the actual color.
Glitch may represent any rank/suit. Bipartite matching gives each distinct physical
card one slot, with no Ace/King wrap. Payout still uses the printed card's value.
Liquid grants one finite full-Meld Echo per card; existing delta-only SET extensions
between four-card milestones are retained. Glitch retains this one Echo.
C2's completion highlights also match flexible ranks while retaining every selected
physical card and excluding Zodiac-locked cards.

Advice and completion probability include flexible identities. Probability uses
sampling without replacement and reachable slot subsets, so one physical Glitch
cannot count as multiple independent outs. Advice does not advance gameplay RNG.
Rank-bound intersections and direct ordinary-run checks avoid unnecessary matching.
On the isolated seeded profiling hand, wildcard advice fell from about 1.56 s to
0.28 s; timings describe that measurement rather than a hardware-independent limit.

## Visual language

Gold and Black Ink share one Đông Sơn-inspired engraving anchored on the former
double sun ring. Triangular bands, four Lạc birds, a fine frame and paired lotus
terminals grow in defined spaces. Increasing Fortune fills this same engraving
outward into metallic Gold or matte Ink; level 6 covers the field. The intersecting
brocade mesh and repeated petal field were removed. A paper-width clearance around
printed pips and court artwork preserves their shapes at table and hand sizes.
The engraving strokes are roughly 25–30% heavier, with deeper Gold incisions and
clearer pale lines in mature Ink. Gold uses a warm reflection; plain Ink remains
still. The transformation
front takes 1.2 seconds per card and uses a small, smooth lift. Fast-forward remains
available. The front itself provides the travelling highlight.

Liquid restores the earlier flowing cyan/violet/amber rivers, nested ripples and
bright caustics. Negative uses exactly that same flowing photograph and then
inverts it, including when the Liquid flag is absent. The reflection also reaches
mature Gold and Ink fields, so the tattoo cannot hide jackpot motion. Glitch again
uses seven torn bands moving through the actual 52-card deck, horizontal tearing,
RGB separation and travelling coloured seams. Compact physical rank indices remain
readable throughout.
All materials now extend through the corners and to the card's edges; there are no
reserved pale corner panels. The renderer extracts the existing rank/suit ink as
small connected components and caches that print per face texture. It reprints
only those original glyphs with contrasting light/dark ink and a one-texel keyline.
Red suits keep red indices. Glitch clears alternate index artwork beneath this
print before applying its full-card material, so physical identity remains stable
while the surrounding paper tears and flows. No replacement typeface, corner label
node or backing rectangle is added.

Original alpha remains protected. Hand faces carry no Fortune-number badge;
hover, keyboard focus and the shared DeckScreen expose the exact signed value.
Snapshot, picker, table, discard, flying and scoring faces reuse one shared shader
with independent materials. The renderer enforces crisp sampling, and both permanent
snapshots (`unique_id`) and score receipts (`card_id`) derive their animation phase
from the same physical card identity as the live hand.

## Saves

RunSave envelope version 3 accepts versions 1/2/3. Old conditional Gold marks migrate
to `min(1 + Gold-mark count, 6)`; MELD_RETRIGGER becomes Liquid. Old physical rank,
suit, modifiers, polish and seals remain intact. Expanded decks are accepted with
unique nonempty physical IDs. Pending D/A readings migrate to P/N while retaining
prices and RNG. Already-applied transformations resume presentation without paying
or applying the change again.

## Validation evidence

- Core: 350 tests passed in the final fresh process, with no shutdown errors or
  resource-leak warnings. The focused Fortune/FX/advice suite passed all 48 tests.
- Campaign Gieo screen: 460 rendered checks, zero failures; all 64 compositions,
  both jackpot pickers, charges, navigation, lever frames and final card visibility.
- Runtime, tutorial and scoring presentation smokes passed.
- GPU matrix: 156 Fortune/Jackpot/card variants; zero alpha, printed-ink, normal-face,
  growth-coverage, dynamic-material or freeze errors. Automatic material motion verified.
- Flair pass: all 13 Negative-only Fortune levels animate. Across two sampled times
  and three real faces, 5766 interior pixels match Liquid's inverted photograph,
  with zero inverse errors. Core (350), focused (48), card-backend (172188 sampled
  checks), day-polish, runtime and tutorial checks passed again after the flair
  changes. The live MCP
  gallery was inspected at native sizes and with enlarged Negative/Glitch faces.
- Whole-card pass: the 156 material variants still pass. An additional 416 rendered
  variants cover all 52 physical identities at 49×68 across eight treatments and
  three animation times. All 128280 glyph samples passed the local keyline-contrast
  check; red-index, missing-index, corner-paper-treatment and corner-motion checks
  had zero failures. Core (350), day-polish, runtime, tutorial, the Gieo screen
  (460 checks) and the final fresh card-backend run (172188 sampled checks) passed.
  An initial simultaneous backend render failed
  nine paper-sampling cases; isolated diagnostic and unmodified reruns passed.
- Existing card backend: 172188 sampled checks passed. Day-polish rendering passed.
- Fresh-process save writer/reader passed with Gold/Ink Glitch, an expanded deck,
  pending applied receipt and preserved prices; v2 migration is covered by core tests.
- Live MCP pointer input exercised the lever, acceptance, exact DeckScreen inspection
  and commitment. Synthetic pointer and GPU evidence do not claim physical touchscreen
  testing, audible listening or exported-build validation.

Logs and captured images are under `.godot/fortune-validation`; the progression
comparison is `fortune-growth.png`. New automated entry points are
`tests/fortune_material_render_smoke.gd` and `tests/fortune_resume_smoke.gd`.
The subsequent visual consistency pass has its own logs under `.godot/fortune-polish`.
Its `before-after.png` compares the same physical cards, Fortune and sample time,
at native table size and actual hand size.
The follow-up flair pass is recorded under `.godot/fortune-flair`; its
`before-after.png` compares the restrained consistency pass with restored Liquid,
animated Negative, torn Glitch and deeper engraving strokes.
The full-card treatment and rank/suit-print comparison, captures and fresh logs are
under `.godot/fortune-whole-card`.
