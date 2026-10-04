# Card rendering and boss payout investigation — 2026-10-03

## Card corruption on the affected PC

The screenshot shows black rectangular patches in otherwise white hand-card paper.
The affected machine uses Intel Iris Xe, driver 32.0.101.6737, and Godot 4.7.1
Forward+ with Direct3D 12. The user confirmed that stopping and restarting the
game clears the patches.

The source PNG is intact. A copy of the user's saved Rooster encounter restored
the exact same ten hand cards and melds without corruption, both in a standalone
rendered process at 2880×1782 and in the editor's embedded game at 2860×1782.
Those hand cards have neither polish nor Gieo properties, so their faces have no
Gieo shader material. This is evidence of intermittent local rendering state;
the precise engine/driver fault has **not** been reproduced or established.

`tests/card_backend_render_smoke.gd` renders all 52 rotating hand faces, with
plain, polished, Gold Set, and Liquid treatments at three sample times. It checks
white source-paper neighborhoods for unexpected black output pixels. Direct3D 12
and Vulkan each passed 172188 pixel checks. The existing polish comparison also
passed on both backends.

A local `override.cfg` selects Vulkan for Windows to bypass the suspected D3D12
path. It is excluded through `.git/info/exclude`, so the shared `project.godot`
and other devices' rendering defaults remain unchanged. Removing `override.cfg`
restores the project default. This is a tested workaround, not a claim that the
intermittent corruption's root cause is fixed. Godot documents this mechanism in
[ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html).

## Boss disappears during card payouts

`ZodiacBossHUD._blocked()` treated `score_overlay` as a dialog. That node is
actually MoneyPresentation's transparent ceremony, so both `refresh()` and
`_process()` hid the boss portrait and evening artwork during every payout.

Boss art now uses `_presence_blocked()`, which excludes the money ceremony.
Speech and the rule drawer still clear during payout. Modal dialogs, discard
inspection, deck inspection, and resolution receipts still clear decorative art.
Gameplay, payout accounting, and authoritative Zodiac rules are unchanged.

`tests/boss_money_presence_smoke.gd` runs the real money queue for card scoring,
transfers, and phase settlement, checks both refresh and subsequent frames,
checks completion totals, and verifies wallet/boss state is unchanged. It also
checks modal, discard, and deck inspection. It is included in the normal
`tools/validate_project.ps1` suite.

## Validation

- Core: 335/335 passed.
- Existing boss presentation: 607 checks, zero failures.
- Rendered boss money presence on D3D12: 29 checks, zero failures.
- Card backend render on D3D12 and Vulkan: 172188 checks each, zero failures.
- Existing polish render comparison on D3D12 and Vulkan: PASS.
- Rendered local override launch reports Vulkan without a CLI driver override.
- Embedded editor launch also confirms Vulkan and restores the same saved hand
  with intact card faces. The original debug-save SHA-256 remains unchanged.
- Boss money presence in headless validation: 29 checks, zero failures.

For the render check, run Godot with `--path . --script
res://tests/card_backend_render_smoke.gd`; do not use `--headless`. To compare
backends, add `--rendering-driver d3d12` or `--rendering-driver vulkan`.
Captures and detailed logs are local under `.godot/`.
