# Cat and Rooster checkpoint — 11 October 2026

This checkpoint delivers Cat's Kindred expansion and Rooster's authored Stranger-to-Kindred visits, action commitments, remembered outcomes, Last Chance, and private Emblem route. Shared changes cover persuasion, relationship history, profile persistence, conversation controls, and compact action reminders.

Shared files were staged by comparing the saved pre-expansion baselines with the final implementation and applying only the authored differences to `main`. Unrelated boss animation work, gameplay/service changes, import metadata, generated translations, and audio configuration remain local. The evening Cat and Rooster rule scripts are unchanged.

Validation used a separate export of the Git index. Its assets were imported afresh and its own isolated user profiles held all saves and settings. The first bootstrap regenerated ignored translation binaries; the subsequent editor import completed with zero engine errors. No unrelated working-tree code or import cache was copied into the validation project.

The core suite has 418 passing tests in this staged snapshot. The earlier 431-test working-tree run included additional local changes outside the checkpoint. Scene smoke assertions and captures are reported separately from the deterministic suite.

| Check | Result |
| --- | --- |
| Fresh editor import | Passed, zero engine errors |
| parse | Passed |
| core | TRADATALA_TESTS total=418 passed=418 failed=0 skipped=0 |
| runtime | TRADATALA_SCENE_SMOKE passed |
| zodiac_scene | ZODIAC_SCENE_SMOKE checks=106 failures=0 |
| boss-presentation | BOSS_PRESENTATION_SMOKE checks=631 failures=0 rendered=true |
| cat-scene | CAT_PERSUASION_SCENE_SMOKE checks=333 failures=0 captures=29 |
| cat-expansion | CAT_EXPANSION_SCENE_SMOKE checks=617 failures=0 captures=60 |
| rooster-scene | ROOSTER_PERSUASION_SCENE_SMOKE checks=920 failures=0 captures=111 |
| rooster-write | ROOSTER_PERSUASION_RESUME_WRITE checks=17 failures=0 |
| rooster-read | ROOSTER_PERSUASION_RESUME_READ checks=47 failures=0 |
| cat-write | CAT_PERSUASION_RESUME_WRITE checks=14 failures=0 |
| cat-read | CAT_PERSUASION_RESUME_READ checks=44 failures=0 |
| negotiation-write | ZODIAC_NEGOTIATION_RESUME_WRITE checks=5 failures=0 |
| negotiation-read | ZODIAC_NEGOTIATION_RESUME_READ checks=10 failures=0 |

Both expanded conversation flows render English and Vietnamese at 1280×720 and 1920×1080. Rooster's scene check commits an actual GUI Meld, completes the Afternoon Deal, publishes the remembered result, and reaches the private scene and Emblem. Cat's scene check selects a physical card through the shared deck picker, judges the accepted promise, inspects remembered outcomes, and exercises Last Chance. Save write/read pairs use separate Godot processes. All 14 checks passed without engine errors.

Disk space ran out during the initial capture pass. Redundant raw audio copies were removed only from the temporary export after checking that the original files and imported runtime resources were intact. Both capture helpers now fail on PNG write errors. The affected flows were rerun; all 60 Cat and 111 Rooster images have complete PNG endings. The final rendered counts include these additional write assertions.

All original dirty/untracked file bytes were preserved except the two expansion documents, updated to link this delivery report, and the two authored capture helpers strengthened during delivery. No stash was created. New proof documents are the only additions after validation; staged runtime and test source blobs were checked against the exported files before committing.

[Full source, log, and rendered capture hashes](CAT_ROOSTER_CHECKPOINT_VALIDATION_2026-10-11.json). The [Cat implementation report](CAT_EXPANSION_2026-10-10.md) and [Rooster implementation report](ROOSTER_EXPANSION_2026-10-10.md) retain their historical working-tree evidence.
