# Boss speech and text reveal — 2026-10-03

The Evening boss no longer adds a separate sprite to the top-left corner. The supplied Zodiac table overlay remains the boss artwork, including during the existing money ceremony. Boss speech sits immediately below the wallet panel on the right, with a 0.2-second scale/fade entrance followed by a character reveal. Its lifetime includes the reveal and a separate reading period. Speech uses the full paragraph rather than the previous two-line ellipsis.

The speech panel reserves a small lane beside the scrolling Meld area. The normal Meld width returns when the boss HUD becomes unavailable. Speech font sizing accommodates the gap above the discard pile. The rule badge and rule drawer retain their existing interaction.

`scripts/ui/text_reveal.gd` reveals conversational copy only. NpcConversation, Strawy, and boss speech explicitly use its reveal/cancellation helper; Zodiac conversation paragraphs opt in with `conversation_text` metadata. It reveals newly shown or replaced conversational text, restarts on language changes, preserves full strings for layout, and finishes visible reveals on a left click, touch press, or confirm input. Reveals finish within two seconds.

Menu text, button captions, character nameplates, prices, counters, general HUD labels, and text entry remain immediate. There is no button-caption adapter or global text-animation policy.

NpcConversation covers the shared NPC greetings, service explanations, small talk, receipts, and responses routed through EventTableController. Zodiac negotiation dialogue and accompanying conversation paragraphs are marked explicitly; the boss rule badge and inspector remain immediate. Boss speech delays its reveal until its entrance animation completes. This changes presentation only; campaign, wallet, card, and Zodiac rules stay with their existing owners.

## Verification

- `tests/text_reveal_scene_smoke.gd` exercises conversational formatted text, ordinary labels/buttons/counters remaining immediate, explicit Zodiac opt-in, show/hide, replacement/cancellation, NPC speech, and real boss speech in English and Vietnamese at 1280×720, 960×620, and 1920×1080. Rendered captures are written under `.godot/typewriter-*.png`.
- `tests/boss_presentation_smoke.gd` checks the removed sprite, speech lane, real Rooster/Cat turns, rule drawer, pointer access, and card accounting.
- `tests/boss_money_presence_smoke.gd` retains its existing real money-queue checks and now checks the supplied overlay rather than the removed corner sprite.

Final conversation-only scope: the native Vulkan/Forward+ rendered smoke passed 88 checks; Strawy speech passed 68, Zodiac scene integration passed 106, UI layout passed 163, and the twelve-Drink interaction smoke passed. Boss presentation passed 631 checks and its real money-queue check passed 29. English and Vietnamese rendered captures were inspected, including the smaller window. The core suite passed 335/335; main-scene boot and the final validation logs contain no script/engine errors.

Existing asset-import changes, audio bus changes, card-render work, and validation-tool changes were already present before this task and are retained. No Git checkpoint or push was requested.
