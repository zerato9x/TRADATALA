# Drink artwork

The table, shop, collection, and cup drag preview use each Drink's own
`<drink_id>_full.png`, `_half.png`, and `_empty.png` assets. All twelve Drinks use
the replacement sheets supplied in `C:\Stuffs\Asset\drink`, with their original
colors. Bò Húc uses the two crops from `energy_redbull.png`: its sealed can for
full and its opened can for both half and empty. The sheet has no separate
empty-can drawing. `sprite_layout.json` records this alias. The unused previous
placeholder sources remain archived in `placeholders/`.

Every production sprite uses a **700 × 900 transparent canvas**, with the
vessel's base centre at **(280, 776)**. The table's existing 112 × 144 sprite
footprint has the same aspect ratio, so swapping any state keeps the same scale
and contact point. Glasses and bottles retain their distinct silhouettes and
their supplied shadows. Sting and Bò Húc's larger source resolutions are scaled by 0.8 with
nearest-neighbour sampling. Padding outside the canvas may omit faint stray
background pixels; vessel and shadow art remain intact.

`ActiveDrink` in `scenes/ui/match_board.tscn` anchors to the table's bottom-right
edge, with offsets `(-183, -8)` through `(-71, 170)`. This moves every Drink
64 logical pixels left of the previous slot, onto the painted blue tabletop,
while following viewport resizing. The button, nameplate,
charge outline, and sprite footprint never move when the Drink or fill changes.
Do not independently fit each raw crop to this footprint: their differing
margins would make the vessel jump or change size.

`scripts/ui/drink_presentation.gd` only selects art. It reads the existing usage
flags and Deal state. Unused Drinks show full;
spent renewable windows show half; spent Deal/transition charges and the last
Phase's spent recovery/Pair charge show empty. Finished Deals show the matching
empty vessel. Missing targets, modal locks, and other temporary inability to use
a Drink do not consume its visual fill. Rules, prices, unlocks, and persistence
remain owned by their existing gameplay/campaign services.

To rebuild these assets with Pillow from the earlier extracted pieces:

```powershell
python tools/import_drink_sprites.py C:/Stuffs/Asset/drink/pieces
# Rebuild only the new can without rewriting the other eleven Drinks:
python tools/import_drink_sprites.py C:/Stuffs/Asset/drink/pieces --only bo_huc
```

`sprite_layout.json` records the source crop hashes, inspected source-space
contact points, and shared layout. Replacement source art with different geometry
requires updating the importer's contact points. `tests/drink_presentation_smoke.gd`
checks all 36 states, actual base pixels, sealed/opened can mapping, the painted
tabletop under the contact point, table geometry at four window sizes,
usage refresh/restore, and matching shop/collection textures. Run it rendered via
`tools/validate_project.ps1 -Only drink-presentation -RenderedChecks drink-presentation`.
