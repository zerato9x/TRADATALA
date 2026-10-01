# UI refinement, 1 October 2026

The menu uses the original sidewalk-table image and a large, centered gold title. Its four words keep their independent music pulses, with spacing based on the glyphs rather than fixed-width cells. Home has direct New Run, Continue/Back to Game, and four navigation controls.

Decorative subtitles and slogans were removed from Home, shop and tutorial headings, deck browsing, Zodiac scenes, lottery receipts, and run summaries in both languages. Prices, consequences, progression counts, character dialogue, and Handbook rules remain available. Card-selection consequences appear beside the confirmation action rather than beneath the browser title.

Readability changes include clearer form fields and focus outlines, visible scrollbars, larger music controls, one-line volume percentages, and larger discard-history captions. Collections scroll independently of their detail panel and retain focus on the chosen item. The card browser fits its column count to the available width. Start and Back stay outside scrolling page content.

Game rules, scoring, campaign ownership, and the HUD's arrangement remain unchanged.

Validation:

- Core suite: 230/230 passed.
- UI layout smoke: 139 checks passed across English/Vietnamese and 960×540, 1280×720, and 1920×1080 windows. It checks button bounds, fixed footer access, volume layout, collection reachability/focus, card-grid bounds, and unchanged wallet balance.
- Front end, menu release, title, runtime scene, tutorial, Gieo screen, Zodiac, relics, NPCs, resolve presentation, Endless history, jukebox, and Drink shop smokes passed. The Drink shop harness now finds named navigation rather than assuming a container type and child index.
- Render captures cover Home, Setup, Customize, Drink/Zodiac collections, Music, Settings, Handbook, Deck, and the table. Live MCP confirmed a running main scene and captured its framebuffer.

Reproduce layout validation with Godot `--headless --path . --script res://tests/ui_polish_layout_smoke.gd`.

Run `--path . --script res://tests/front_end_render_capture.gd` with a graphical renderer for captures. Append `-- --small --vi` or `-- --large` for size/language variants. Images are saved under `.godot/front-*.png`; the capture harness restores the prior locale.
