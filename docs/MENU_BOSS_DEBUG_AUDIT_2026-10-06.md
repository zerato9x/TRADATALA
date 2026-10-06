# Menu and Boss Lab bug audit — 2026-10-06

The reported menu overlap and Boss Lab Start Test flow are fixed in the working tree. The audit reproduced several related navigation and encounter-replacement failures and added regression coverage.

## Confirmed defects and fixes

| Trigger | Failure | Fix |
| --- | --- | --- |
| Open Menu during a live deal | Hand, turn history and drink props draw over the menu | Restore the menu's z_index = 500 in scenes/match.tscn |
| Open Boss Lab with the deck browser active | Its higher CanvasLayer covers Start Test and survives into the new encounter | Close session browsers on lab entry and session replacement |
| Press F9 inside the Handbook | The Handbook consumes the shortcut | Let the available Boss Lab shortcut reach the host |
| Resume or replace a boss while a decision modal was hidden by the lab | Closing a later menu resurrects the old modal | Clear suspended modal state on session reset |
| Replace an encounter while settlement presentation is awaiting completion | The old callback reads a cleared resolution dictionary and throws a script error | Guard asynchronous gameplay continuations with the existing presentation generation |
| Open Boss Lab during event-to-deal entry | Entry completion unlocks gameplay behind the lab; returning can restore a stale lock | Record completed input release for the suspended game and keep lab input exclusive |
| Open Boss Lab from a receipt | The receipt covers the lab; hiding it normally destroys the report and controls | Suspend its canvas without destroying report state, then restore it on Back to Game |
| Open Boss Lab during a card drag | The previous drag retains pointer ownership | Cancel card and quick-drink drags before opening the lab |
| Start a new normal run after leaving a receipt suspended by Boss Lab | Future receipts remain invisible | Use the same session presentation reset for a new normal run |
| Open Boss Lab during delayed Nước Vối recovery | Recovery unlocks gameplay behind the lab and returning restores an obsolete lock | Use the shared input-release helper for successful and rejected drink completion |

Session reset also retires deck, Zodiac conversation, action legend, Handbook, lottery receipt and wallet inspection screens. Delayed discard, phase-choice and drink-recovery continuations check the existing presentation generation before acting on a replacement encounter.

## Regression coverage

- tests/menu_deal_smoke.gd: pointer Menu, Settings, Back to Game, Escape, full DealState preservation and physical-card accounting. Rendered capture compares the menu with the underlying game shown and hidden to prove complete coverage.
- tests/boss_debug_navigation_smoke.gd: F9, Start Test, Replay, Boss Lab, Exit, receipt suspension/restoration, active drag cancellation, entry/recovery timing, replacement during settlement, modal state reset and new normal run after suspended receipt.
- Existing campaign/progression checks now assert the current Hang Rong shop: three relics, three physical cards, removal, authoritative catalog explanations and persistent unbought stock. The pointer helper waits for layout and injects motion before clicking.

## Final verification

Fresh Godot 4.7.1 processes used isolated project-local APPDATA and LOCALAPPDATA. Real user save files were not used.

- tools/validate_project.ps1 -Full: **64/64 checks pass**, including parsing, gameplay, runtime, campaign/demo, progression write/read, Boss Lab save isolation, front end, services, Strawy, all bosses, presentation, persistence and music.
- Core: **371/371 tests pass**.
- Full Zodiac roster: **746 checks, 0 failures**.
- Boss Lab save-isolation writer: **225 checks, 0 failures**; fresh-process reader: **15 checks, 0 failures**. Coverage includes all 12 bosses at all three tiers and preserves normal save bytes and permanent unlocks.
- Final rendered Boss Lab navigation: **39 checks per variant, 156 total, 0 failures**, at 1280×720 and 2548×1368 in English and Vietnamese.
- git diff --check: passes.

Evidence is in .godot/validation/results.json, .godot/boss-debug-audit/final-gate-results.json, .godot/boss-debug-audit/*-acceptance.log, and .godot/boss-debug-audit/screens/. The screenshots were visually inspected for the lab footer and the resulting encounter.

The UI checks inject pointer/key events through Godot's viewport. Boss dropdown coverage opens the actual popup by pointer and selects through its control signal. This establishes automated and rendered behavior; it does not establish physical-device input, audio listening, or exported-build behavior. The audit cannot prove the absence of every undiscovered bug.

Existing unrelated work remains in place. No commit, push or release was performed. Restart an already running debug game to load the fixes.
