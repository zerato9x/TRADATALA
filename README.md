# TRADATALA / TRÀ ĐÁ TÁ LẢ

A Godot 4.7.1 vertical prototype for one solo-derived Phỏm Deal. The project uses the complete card-face set in `res://cards/` and separates testable rules from presentation.

## Run

Open `project.godot` in Godot 4.7.1 Stable and run the project (`F6`/`F5`), or launch from a console:

```powershell
Godot_v4.7.1-stable_win64_console.exe --path G:\PHOM
```

## Controls

- Click cards to select/deselect them; selected cards lift and glow.
- `H`: HẠ a legal new Set or Run.
- Click a table Meld to target it, then `E`: EXTEND it with the selected legal card(s).
- `D`: DISCARD exactly one selected loose card and end the turn.
- `S`: cycle rank/suit hand sorting.
- `K` / `X`: KEEP / DUMP at the Phase 1 settlement.
- `Esc`: clear card and Meld selection.
- `R`: start another Deal after Phase 2 while preserving the wallet.

Buttons remain disabled until their action is legal. The footer explains the current selection.

## Architecture

- `scripts/cards/` — card identity, rank, independently mutable scoring value, enhancements, and asset lookup.
- `scripts/deck/` — standard-deck generation, deterministic seeded shuffle, draw, discard, and refill.
- `scripts/melds/` — Set/Run authority, extension legality, and persistent table Meld state.
- `scripts/scoring/` — reusable scoring contexts, local multiplier pipeline, extension deltas, and deadwood.
- `scripts/economy/` — 64-bit integer VND wallet and point conversion.
- `scripts/gameplay/` — the authoritative two-Phase Deal state machine.
- `scripts/ui/` — card fan, Meld views, café-table composition, staged equations, wallet tweening, card travel, banners, and settlements.
- `tests/` — pure-rule suite plus a runtime scene smoke.

## Implemented rules

The prototype includes a 52-card deck, 9-card resting/10-card active refill behavior, voluntary HẠ, Sets, A-low Runs, persistent Melds, delta-paid extensions, four discards per Phase, Móm, KEEP/DUMP, Phase 2 deadwood, and integer VND scoring at ₫1,000 per point. A Meld commit must leave one loose card for the mandatory discard.

Drinks, Relics, Xăm, bosses, events, shops, campaign progression, multiplayer, AI opponents, audio, and 3D presentation are intentionally not implemented. The neutral `ScoringContext` and modifier registration seam are the integration points for later effects.

## Verification

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path G:\PHOM --script res://tests/run_headless.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path G:\PHOM --script res://tests/runtime_scene_smoke.gd
```

