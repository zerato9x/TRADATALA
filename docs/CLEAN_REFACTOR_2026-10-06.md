# Continued codebase refactor

The requested scope is the game as a whole. This document tracks that work beyond
the initial refactor pass. Passing one batch of tests does not complete this scope.
Existing worktree changes and authored gameplay content are preserved; this work
does not authorize a commit, push, release, or change to gameplay rules.

## Completion criteria

- The match scene is a composition and presentation coordinator. Music policy,
  menu pages, card interaction state, receipt construction/playback, session/save
  orchestration, and domain queries each have one explicit owner.
- Production components communicate through public intent, facts, and events.
  They do not call another component's private methods or mutate compatibility
  aliases to state owned elsewhere.
- Retired menu/tutorial paths and unnecessary forwarding methods are removed.
  Tests exercise the controls and routes players actually use.
- Gameplay/economy authority stays in its services. Physical card IDs, isolated
  deterministic RNG, committed wallet transactions, and save object identity are
  preserved. Existing saves and authored Zodiac content remain compatible.
- Deferred callbacks, queues, signal subscriptions, and text work sets have an
  explicit lifecycle; cancellation and scene replacement do not carry stale work.
- The final static/reference audit has no unexplained duplicate ownership, dead
  application paths, or private calls between production components. Remaining
  large modules have a coherent responsibility and documented boundaries.
- Relevant core, scene, transport, fresh-process save/resume, input, and rendered
  checks pass on the final sources. Reports distinguish automated/rendered
  evidence from physical-touch and audible evidence.

## Progress

The first pass introduced session coordination, money playback, interaction and
query owners, explicit save schemas, and shared advisory formatting. Its evidence
is recorded in `REFACTOR_PASS_2026-10-06.md`.

The continuation has completed the music, focused service-view, receipt-construction,
query, text-registration, and card presentation boundaries below. The final whole-game
reference audit and required validation are complete. The completion criteria above
are satisfied by the boundaries and evidence recorded here.

### Completed boundaries

- `MatchMusic` owns transport settings, conductor policy, and music checkpoints.
  `MusicPlayerView` owns the player controls; `FrontEnd` owns its pages and sends
  music intent. The obsolete `main_menu.tscn`, opening gate, old title script, and
  hidden tutorial/menu controls are removed. Runtime and progression tests use
  the actual Home, Setup, Handbook, Settings, and Music routes.
- `DealQueries` owns advice, legal enumeration, swap opportunities, and query
  caches. Removed the DealState forwarding cycle and private query calls. Shared
  physical validation and payout previews have explicit authority APIs. The
  independent exhaustive test oracle checks every hand subset.
- Removed 21 writable state aliases in MatchUI and six aliases to Event Table
  controls. Consumers address the session, interaction, and playback owners.
- `MoneyFeedback` builds visual receipts from committed scoring/settlement,
  Zodiac, exhaustion, and bonus facts. `MoneyPlaybackQueue` owns jobs and displayed
  balances. Queue generation guards stop an old bonus coroutine from draining a
  replacement buffer; scene exit also cancels the queue. VndWallet still commits
  every payment.
- `EventTableServices` owns focused NPC service views and sends public signals for
  orders, card picks, feedback, debt acknowledgement, and Zodiac conversation.
  `EventTableController.enter_resolution()` cancels stage transitions, releases
  focus, and closes the table for receipts. Collection/outcome checks wait for
  prior transitions and confirm the receipt still owns the stage.
- `VisibleTextControls` registers text by tree and inherited visibility, removes
  it immediately on detachment, and shares visible work sets between semantic
  presentation and reveal. Repeated replacement tests verify no retained controls
  or duplicate renderers; hiding a parent cancels manual reveal. This establishes
  lifecycle behavior; no frame-time improvement is claimed without profiling.
- Removed the always-hidden CampaignCoach overlay and its frame polling.
  CampaignManager observes committed Deal/wallet learning and owns Monday
  progression. Selection intent teaches selection. `CampaignHints` supplies the
  existing tutorial copy on request; its authored string literals match the
  starting source exactly. Core coverage proves learning works without a UI.
- Public visual anchors and guidance targets replace access to Event Table
  internals. Zodiac persuasion receives its existing isolated RNG explicitly and
  uses service-owned commit guards. Boss Lab setup goes through CampaignManager
  and still requires detached progress providers. Removed the UI's duplicate
  difficulty unlock.

- `CardTablePresentation` owns physical-ID-keyed hand/meld views, card layout,
  probability/action decorations, pile faces, turn-register holders, music visual
  targets, drag previews, and drop overlays. It returns card/meld/discard intent
  through signals. MatchInteraction owns selection/Drink/drop policy. The visual
  owner stops syncing and disconnects intent when detached, preventing hover-exit
  callbacks from rebuilding views during teardown.
- `PileArchive` owns the existing draw/discard browser controls, grouping, sorting,
  animation, and discard selection. `InputHitTest` shares canvas-coordinate and
  clipping-aware pointer geometry. No physical card is generated or replaced.
- DealState validates hand-order intent against the exact owned physical references.
  Reordering preserves accounting, wallet/journal, deck, and action history; missing,
  duplicated, and cloned impostor references are rejected. UI geometry still chooses
  insertion order.
- RunSessionCoordinator explicitly releases all domain subscriptions and rejects
  pending saves after detachment. Actual active-run regressions verify later wallet
  payments cannot write either the run file or permanent progress. Removed the root
  save forwarding methods and repeated interaction constants.
- Removed the unused Event Table outcome renderer, CafeTableBackground and
  RelicSelector prototypes, and 18 unreferenced helper/forwarding methods. Music
  transport no longer keeps a second `stem_players` map or an inert debug toggle.
  The active audition tool and its arrangement implementation are retained.

The current reference scan finds no private method or field access between
production components. Remaining matches are factories working on another
instance of their own class in GameGlossary and LotteryReceipt. The other lexical
match is the tagged `__int64` dictionary field in MetaSaveFiles, not private object
access. No gameplay or save shape was changed to satisfy this scan.

### Earlier verification checkpoints

Targeted gates are preserved in `.godot/clean-refactor-2026-10-06/`:

- `music-query-gate`: 12/12 checks passed, covering runtime, interaction, music
  transport, music fresh-process write/read, FrontEnd, Handbook, boss presentation,
  negotiation, parsing, and core.
- `receipt-gate`: 10/10 checks passed after alias and receipt extraction, including
  cross-run/deferred cancellation, money presence, profile/debug write/read, and
  relic presentation.
- `event-text-gate`: 8/8 checks passed after service-view and text registration
  changes, including real focused-service controls and 116 text-reveal checks.

At the earlier checkpoint, the production sources passed all 357 core tests. Fresh OpenGL compatibility
processes pass 66 readability and 116 text-reveal checks. Inspected Music at
1280x720 English and 960x540 Vietnamese, plus the Vietnamese Home at 960x540;
these exercised controls fit without clipping. Also inspected the current English
1280 table and Vietnamese 960 Handbook from the readability captures. Captures and logs are under
`.godot/clean-refactor-2026-10-06/rendered/` and `.godot/front-*.png`.

The independent preserved pre-refactor V3 writer produces byte-identical files
for the played-meld fixture. The current reader restores physical accounting,
snapshot identity, and shared persistent cards. Evidence:
`.godot/clean-refactor-2026-10-06/schema-legacy.log`.

The full run completed with 53/56 checks passing. Its three failures exposed
test calls to removed resume, conversion, and day-start forwarding methods. The
production sources were unchanged while those fixtures were corrected to use
the session owner, currency authority, and real day-start event. The fresh repair
gate passes 4/4: settings writer, settings reader, money HUD, and demo.

At that checkpoint, **56 unique required checks had accepted passing evidence**, including
357/357 core tests. This combines the 53 passing full-run checks with fresh
fixture repairs; it is not a single zero-failure full rerun. Original full and
repair records remain in `full-gate/` and `repair-gate/`; the accepted index is
`.godot/clean-refactor-2026-10-06/accepted-results.json`. Only the expected unknown
period warning from the audio negative fixture is present in accepted logs. Other
intermediate failures
included stale menu/test entry points, content replacement closing its enclosing
panel, and an untyped visual port; these were corrected, not waived.

The Cat authored authority remains SHA-256
`84a401a39732edef2e1ee44a44bc48bad5d4643245c4eab6e69b08a65be7df1d`.
`project.godot` remains byte-identical to the starting audit hash
`b914e13dabdade4ea5edf497f914ec1e8860de001bcc38dfe6ebc8620d05e4fd`.

### Responsibility and reference audit

The final sweep inspected 238 production, scene, test, tool, and debug source files.
It found no unreferenced application classes, missing literal resource paths, or
unexplained private access between production components. Engine callbacks and
same-class factories are accounted for. The two uncalled public methods retained
are paired extension lifecycle contracts: EventManager.unregister_npc and
ScoringPipeline.remove_modifier. The final orphan helper found in GieoQuePanel was
removed; a fresh parse and rendered Gieo screen check cover that last deletion.

Large modules remain where their responsibility is coherent:

| Owner | Responsibility and boundary |
| --- | --- |
| MatchUI (2,717 lines, 150 methods) | Composes the scene, routes physical intent to authorities, and coordinates menus, modals, HUD and committed feedback. Session, music, card views, interaction policy, receipt jobs and queries have their own owners. It was 5,057 lines before the first pass and 4,557 at the start of this continuation. |
| DealState (1,628 lines, 93 methods) | Commits legal gameplay actions, physical-card moves and turn/phase transitions through scoring, wallet, relic and boss services. Advice/enumeration/caches live in DealQueries; boss rules live in Zodiac modules. |
| EventTableController | Owns table stage, NPC placement, focus, pointer routing and transitions. Focused service content lives in EventTableServices; gameplay and costs stay in campaign services. |
| MoneyPresentation | Renders committed receipt jobs and animates wallet/card/bill surfaces. VndWallet commits currency; MoneyFeedback constructs receipts; MoneyPlaybackQueue sequences/cancels jobs. |
| GieoQuePanel | Owns the lever/reel/result/target/transform presentation states. GieoQueService owns the deterministic roll, commitment, card transformation and resumable operation. |
| StrawyController / FrontEnd | Each owns a player-facing surface, its pages/copy/navigation and public intent. These UI flows use the shared queries, settings, progress and session authorities. |
| ZodiacService / ZodiacPersuasion | Own daytime negotiations, observers, promises and judgement. Individual boss rule modules own encounter gameplay and isolated RNG. Authored Cat authority is preserved exactly. |
| ReactiveMusicController / audio_system | Own transport, deterministic arrangement/cue state and checkpoints. MatchMusic owns game-driven policy, while MusicPlayerView renders controls. |
| CardTablePresentation | Owns the keyed card visual lifecycle and geometry. It observes committed facts and emits intent; it does not commit scoring or payments. |

No additional broad split is justified by this audit. The remaining coordination
and domain transaction modules express cohesive responsibilities. Future refactors
should follow a demonstrated ownership or lifecycle problem; line count alone is
not a reason to split an authority.

### Final verification checkpoint

The final required full run passes **56/56 checks**, with **359/359 core tests**,
zero engine errors, and zero timeouts. This is a successful complete run after the
earlier checkpoint repairs. It includes normal/demo runtime, card and Drink input,
service/NPC scenes, all boss presentation, Cat persuasion, money cancellation, music
transport/arrangements, progression, profile/debug and independent-process saves.
Original final logs and results are in `final-full-gate/`; `final-validation.json`
indexes the evidence. The only warning is the expected unknown-period audio
negative fixture.

Fresh OpenGL processes additionally pass **43 card interaction**, **66 readability**,
**116 text reveal**, and **460 Gieo screen** checks. The last unreferenced Gieo helper
deletion occurred during the full run; a fresh root parse and rendered Gieo process
verify that final source separately. Trimming an extra EOF newline in the music
controller made no executable change. Current English 1280 table and Vietnamese
960 Handbook captures were inspected.

The final independent legacy-writer probe passes byte equality, restoration,
physical accounting, snapshot identity, and shared persistent refs. The Cat authored
authority and project settings still match the starting hashes stated above.

Evidence is under `.godot/clean-refactor-2026-10-06/` in `final-full-gate/`,
`card-session-gate/`, `final-rendered/`, `final-panel/`, `final-schema/`,
`final-reference-audit.json`, and `final-source-hashes.json`. The earlier accepted
index remains an explicitly historical checkpoint. Scoped whitespace checks pass;
the index is empty. A fresh editor import is clean and removes the retired class
cache entries.

Automated pointer/keyboard and rendered evidence does not establish physical
screen-touch, listening, or export/publication evidence. No staging, commit,
push, export, or publication has been performed. Unrelated worktree changes and
authored sources are preserved.
