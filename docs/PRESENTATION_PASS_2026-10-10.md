# Presentation pass — 10 October 2026

The existing blue sidewalk table and large centered title now anchor a shared street-café presentation. Home uses a brass-edged enamel sign, existing playing-card and money art, the supplied iced-tea sprite, and a drawn record sleeve. Small light changes on the glass and record, button edge animation, and short page fades add motion without moving hit targets.

## Screens and ownership

- `scenes/ui/front_end.tscn` composes the backdrop, light layer, decorative still life, and existing navigation. `scripts/ui/menu_tableau.gd` reads layout only, stops processing when hidden, and caps decorative redraws at 30 Hz.
- `scripts/ui/presentation_theme.gd` supplies teal enamel controls, warm primary actions, visible keyboard focus, pressed depth, and disabled states. `enamel_button_fx.gd` draws only edges and passes pointer input through to the original buttons.
- Setup presents daily debt as a paper slip using the existing dark semantic ink palette. Collection art is larger. Six small authored SVG navigation icons accompany the existing menu labels.
- `scenes/ui/table_ambience.tscn` and `shaders/street_table_light.gdshader` add edge shading and a warm light source behind UI and cards, without screen sampling.
- `scripts/ui/table_hud_presentation.gd` distinguishes wallet and earnings surfaces and applies the same button treatment while retaining compact control sizes.
- `scripts/ui/event_table_controller.gd` now animates the original control offsets. Previously, returning from an event restored positions captured at startup, so resizing could place the drink across the action dock. Anchors now remain effective during transitions.

Rules, card art, scoring, campaign progression, saves, music, and Drink behavior remain with their existing owners. The decorative home cards and banknote never instantiate gameplay objects or consume game RNG.

## Verification

Delivery checks use an export of the Git index, fresh Godot imports, and isolated user profiles. The exported snapshot's 804 scene, script, shader, resource, and UID files matched their staged blob hashes before execution. The runtime assertion refinement was then staged and checked separately.

- Rendered `PRESENTATION_PASS_SMOKE`: 306 checks, zero failures; clean runtime and teardown logs. English and Vietnamese at 1280×720, 960×620, and 1920×1080. Real pointer clicks navigate to setup, select a hint, commit a Meld, and finish its payout. Checks cover rapid navigation, paper text, input transparency, and resized event-return layout.
- Core rules suite in the staged snapshot: 391 passed, zero failed.
- Focused runtime, front-end navigation, release menu, and parse checks passed. Drink presentation: 594 checks, zero failures. Boss presentation: 631 checks, zero failures. Event Table: 116 checks, zero failures. Text readability: 66 checks, zero failures. Rendered responsive UI layout: 163 checks, zero failures.
- The runtime smoke's Drink footprint check now uses approximate vector equality. The same 112×178 control and 112×144 sprite contract remains; offset animation produced a 0.0001-pixel floating-point difference that made the previous exact comparison fail. Failure output includes both observed sizes.
- The main scene booted for 120 frames with the default Forward+ renderer (Direct3D 12); logs contain no script, parse, or runtime errors. The complete front-end capture run passed with OpenGL compatibility and clean teardown.
- A cold import initially reported missing ignored translation outputs and an uncached UID. After regeneration, the confirmation import was clean.
- Screenshots: `docs/screenshots/presentation-2026-10-10/` contains Home, setup, and live table captures from the staged snapshot for both languages and all three sizes.
- Delivery logs and checkpoint hash manifests: `.godot/validation/checkpoint-2026-10-10/`. The original development audit remains in `.godot/validation/presentation-2026-10-10/`.

## Checkpoint scope

The checkpoint contains this presentation pass and its focused runtime assertion fix. Earlier Zodiac, shoe-shine, music, and localization work remains outside this commit. Only the presentation hunks were staged in the already-dirty front-end, theme, Event Table, and runtime smoke files. The six new SVGs include their import configuration; existing import metadata and `default_bus_layout.tres` remain untouched. Unrelated dirty files were preserved and hash-checked.
