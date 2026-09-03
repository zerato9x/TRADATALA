extends SceneTree

const STARTER := "dog_2_bars_001_002"
const MORNING_1 := "dog_2_bars_003_004"
const MORNING_2 := "dog_2_bars_005_008"
const MORNING_EVENT := "dog_2_bars_005_008"
const NOON_1 := "dog_2_bars_009_012"
const NOON_2 := "dog_2_bars_011_014"
const NOON_FINAL := "dog_2_bars_016_019"
const DOG_1_NOON_EVENT := "dog_1_bars_001_002"
const AFTERNOON_1 := "dog_1_bars_006_009"
const AFTERNOON_2 := "dog_1_bars_014_021"
const AFTERNOON_EVENT := "dog_1_bars_025_026"
const BOSS_1 := "dog_1_bars_029_032"
const BOSS_2 := "dog_1_bars_035_036"
const BOSS_CLEANUP := "dog_1_bars_047_050"
const CAT_STARTER := "cat_1_bars_001_002"
const CAT_MORNING_1 := "cat_1_bars_009_012"
const CAT_MORNING_2_SUSTAIN := "cat_1_bars_018_019"
const CAT_MORNING_2 := "cat_1_bars_026_027"
const CAT_MORNING_EVENT := "cat_1_bars_030_031"
const CAT_NOON_1 := "cat_1_bars_035_038"
const CAT_NOON_2_SUSTAIN := "cat_1_bars_041_042"
const CAT_NOON_2 := "cat_1_bars_050_051"
const CAT_NOON_EVENT := "cat_2_bars_001_002"
const CAT_AFTERNOON_1 := "cat_2_bars_006_007"
const CAT_AFTERNOON_2 := "cat_2_bars_012_015"
const CAT_AFTERNOON_EVENT := "cat_2_bars_018_019"
const CAT_EVENING_1 := "cat_2_bars_032_035"
const CAT_EVENING_2_SUSTAIN := "cat_2_bars_037_040"
const CAT_EVENING_2 := "cat_2_bars_048_051"
const GAMEPLAY_MUSIC_CONDUCTOR_SCRIPT := preload("res://scripts/audio/gameplay_music_conductor.gd")

var failures: Array[String] = []


class FakeMusicController:
	extends RefCounted
	var actions: Array[Dictionary] = []

	func start_dj_track(track_id: String, cue_id: String) -> bool:
		actions.append({"action": "start", "track": track_id, "cue": cue_id})
		return true

	func request_dj_cue(cue_id: String) -> bool:
		actions.append({"action": "request", "cue": cue_id})
		return true

	func release_dj_to_end() -> bool:
		actions.append({"action": "release"})
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_locked_route()
	_test_cat_route()
	await _test_runtime_bridge()
	if failures.is_empty():
		print("GAMEPLAY_MUSIC_SMOKE: PASS selectable-dog-and-cat-authored-routes authoritative-phom-triggers forward-overlap optional-cleanup runtime-dj-bridge")
		quit(0)
		return
	for failure in failures:
		push_error("GAMEPLAY_MUSIC_SMOKE: %s" % failure)
	quit(1)


func _test_locked_route() -> void:
	var fake := FakeMusicController.new()
	var conductor = GAMEPLAY_MUSIC_CONDUCTOR_SCRIPT.new(fake)
	_check(conductor.start_campaign("dog"), "DOG set starts on DOG_2 at the approved starter cue")
	_check(conductor.on_deal_started("morning"), "Morning Phase 1 requests its cue")
	_check(conductor.on_deal_phase_started(2), "Morning Phase 2 requests its cue")
	_check(conductor.on_deal_resolved(), "Morning resolution requests the event sustain")
	_check(conductor.on_deal_started("noon"), "Noon Phase 1 releases through authored audio toward DOG_2 bars 9-12")
	_check(conductor.on_deal_phase_started(2), "Noon Phase 2 requests its hold")
	var before_wrong_phom := fake.actions.size()
	_check(not conductor.on_new_phom(1, 1) and fake.actions.size() == before_wrong_phom, "Phase 1 Phom cannot release the Noon Phase 2 hold")
	_check(conductor.on_new_phom(2, 1), "first Noon Phase 2 Phom arms the optional final cue")
	var before_second_phom := fake.actions.size()
	_check(not conductor.on_new_phom(2, 2) and fake.actions.size() == before_second_phom, "later Phom events cannot retrigger the first-Phom route")
	_check(conductor.on_deal_resolved(), "Noon resolution releases or cancels the optional final hold")
	_check(conductor.on_event_started("noon"), "Noon Event switches to DOG_1 and holds its opening cue")
	_check(conductor.on_deal_started("afternoon"), "Afternoon Phase 1 requests DOG_1 bars 6-9")
	_check(conductor.on_deal_phase_started(2), "Afternoon Phase 2 requests DOG_1 bars 14-21")
	_check(conductor.on_deal_resolved(), "Afternoon resolution preserves the Phase 2 cue until its Event begins")
	var before_afternoon_event := fake.actions.size()
	_check(conductor.on_event_started("afternoon") and fake.actions.size() == before_afternoon_event + 1, "Afternoon Event advances to its separate DOG_1 bars 25-26 hold")
	_check(conductor.on_deal_started("evening"), "Evening Phase 1 requests DOG_1 bars 29-32")
	_check(conductor.on_deal_phase_started(2), "Evening Phase 2 requests DOG_1 bars 35-36")
	_check(conductor.on_new_phom(2, 1), "first Evening Phase 2 Phom releases toward DOG_1 bars 47-50")
	var before_second_boss_phom := fake.actions.size()
	_check(not conductor.on_new_phom(2, 2) and fake.actions.size() == before_second_boss_phom, "later boss Phom events cannot retrigger cleanup")
	_check(conductor.on_deal_resolved(), "boss resolution releases or cancels the cleanup hold")
	var expected := [
		{"action": "start", "track": "dog_2", "cue": STARTER},
		{"action": "request", "cue": MORNING_1},
		{"action": "request", "cue": MORNING_2},
		{"action": "request", "cue": MORNING_EVENT},
		{"action": "request", "cue": NOON_1},
		{"action": "request", "cue": NOON_2},
		{"action": "request", "cue": NOON_FINAL},
		{"action": "release"},
		{"action": "start", "track": "dog_1", "cue": DOG_1_NOON_EVENT},
		{"action": "request", "cue": AFTERNOON_1},
		{"action": "request", "cue": AFTERNOON_2},
		{"action": "request", "cue": AFTERNOON_EVENT},
		{"action": "request", "cue": BOSS_1},
		{"action": "request", "cue": BOSS_2},
		{"action": "request", "cue": BOSS_CLEANUP},
		{"action": "release"},
	]
	_check(fake.actions == expected, "locked DOG_1 and DOG_2 gameplay sequence is exact")
	_check(str(fake.actions).contains(NOON_1), "approved DOG_2 bars 9-12 are routed as the Noon Phase 1 hold")


func _test_cat_route() -> void:
	var fake := FakeMusicController.new()
	var conductor = GAMEPLAY_MUSIC_CONDUCTOR_SCRIPT.new(fake)
	_check(conductor.start_campaign("cat"), "CAT set starts on CAT_1 at the approved starter cue")
	_check(conductor.on_deal_started("morning"), "CAT Morning Phase 1 requests its cue")
	_check(conductor.on_deal_phase_started(2), "CAT Morning Phase 2 catches its sustain cue")
	_check(conductor.on_new_phom(2, 1), "first Morning Phase 2 Phom releases CAT into its later Phase 2 cue")
	_check(not conductor.on_new_phom(2, 2), "later Morning Phom events do not retrigger CAT")
	_check(conductor.on_deal_resolved(), "CAT Morning resolution advances to the Morning Event cue")
	_check(conductor.on_deal_started("noon"), "CAT Noon Phase 1 requests its cue")
	_check(conductor.on_deal_phase_started(2), "CAT Noon Phase 2 catches its sustain cue")
	_check(conductor.on_new_phom(2, 1), "first Noon Phase 2 Phom releases CAT into its later Phase 2 cue")
	_check(conductor.on_deal_resolved(), "CAT Noon resolution releases the authored ending")
	_check(conductor.on_event_started("noon"), "Noon Event switches the CAT set from CAT_1 to CAT_2")
	_check(conductor.on_deal_started("afternoon"), "CAT Afternoon Phase 1 requests its cue")
	_check(conductor.on_deal_phase_started(2), "CAT Afternoon Phase 2 requests its cue")
	_check(conductor.on_deal_resolved(), "CAT Afternoon resolution preserves its cue")
	_check(conductor.on_event_started("afternoon"), "CAT Afternoon Event requests its separate cue")
	_check(conductor.on_deal_started("evening"), "CAT Evening Phase 1 requests its cue")
	_check(conductor.on_deal_phase_started(2), "CAT Evening Phase 2 catches its sustain cue")
	_check(conductor.on_new_phom(2, 1), "first Evening Phase 2 Phom releases CAT into its later Phase 2 cue")
	_check(conductor.on_deal_resolved(), "CAT Evening resolution releases the authored ending")
	var expected := [
		{"action": "start", "track": "cat_1", "cue": CAT_STARTER},
		{"action": "request", "cue": CAT_MORNING_1},
		{"action": "request", "cue": CAT_MORNING_2_SUSTAIN},
		{"action": "request", "cue": CAT_MORNING_2},
		{"action": "request", "cue": CAT_MORNING_EVENT},
		{"action": "request", "cue": CAT_NOON_1},
		{"action": "request", "cue": CAT_NOON_2_SUSTAIN},
		{"action": "request", "cue": CAT_NOON_2},
		{"action": "release"},
		{"action": "start", "track": "cat_2", "cue": CAT_NOON_EVENT},
		{"action": "request", "cue": CAT_AFTERNOON_1},
		{"action": "request", "cue": CAT_AFTERNOON_2},
		{"action": "request", "cue": CAT_AFTERNOON_EVENT},
		{"action": "request", "cue": CAT_EVENING_1},
		{"action": "request", "cue": CAT_EVENING_2_SUSTAIN},
		{"action": "request", "cue": CAT_EVENING_2},
		{"action": "release"},
	]
	_check(fake.actions == expected, "CAT_1 opening half and CAT_2 closing half sequence is exact")


func _test_runtime_bridge() -> void:
	var controller := ReactiveMusicController.new()
	root.add_child(controller)
	await process_frame
	await process_frame
	_check(controller.music_director != null and controller.music_director.catalogs_are_loaded, "reactive controller owns a loaded MusicDirector")
	_check(controller.start_dj_track("dog_2", STARTER), "reactive controller starts DOG_2 first in DJ mode")
	_check(controller.dj_mode, "DJ mode becomes authoritative for campaign playback")
	_check(controller.music_director.current_cue_id == STARTER and controller.music_director.state == MusicDirector.STATE_HOLDING_CUE, "runtime bridge holds the starter cue")
	_check(controller.full_mix_player == controller.music_director.audio_player, "beat presentation observes the DJ player on the Music bus")
	var legacy_stopped := true
	for player in controller.mix_players:
		legacy_stopped = legacy_stopped and not player.playing
	_check(legacy_stopped, "legacy playlist players stop when gameplay DJ mode starts")
	controller.set_music_paused(true)
	_check(controller.music_director.audio_player.stream_paused, "music pause propagates to the DJ player")
	controller.set_music_paused(false)
	_check(controller.request_dj_cue(MORNING_1), "runtime bridge releases toward the next authored cue")
	_check(controller.music_director.pending_cue_id == MORNING_1 and controller.music_director.state == MusicDirector.STATE_TRAVELING_FORWARD, "forward request preserves authored source audio until catch")
	_check(controller.release_dj_to_end(), "runtime bridge can cancel a pending catch and release to the original ending")
	_check(controller.music_director.pending_cue_id.is_empty() and controller.music_director.state == MusicDirector.STATE_RELEASED_TO_END, "release clears the pending optional checkpoint")
	_check(controller.start_dj_track("dog_2", MORNING_1), "runtime bridge can hold DOG_2 Morning Phase 1")
	_check(controller.request_dj_cue(MORNING_2), "DOG_2 Morning Phase 2 routes to bars 5-8")
	_check(controller.music_director.pending_cue_id == MORNING_2 and controller.music_director.state == MusicDirector.STATE_TRAVELING_FORWARD, "DOG_2 Morning Phase 2 cue is armed through authored forward audio")
	_check(controller.start_dj_track("dog_2", MORNING_EVENT), "runtime bridge can hold the shared DOG_2 Morning Phase 2/Event cue before Noon")
	_check(controller.request_dj_cue(NOON_1), "Noon Phase 1 releases toward DOG_2 bars 9-12")
	_check(controller.music_director.pending_cue_id == NOON_1 and controller.music_director.state == MusicDirector.STATE_TRAVELING_FORWARD, "slow Noon Phase 1 play will catch and hold DOG_2 bars 9-12")
	_check(controller.request_dj_cue(NOON_2), "fast Noon Phase 1 play can retarget Phase 2 before bars 9-12 are caught")
	_check(controller.music_director.pending_cue_id == NOON_2 and controller.music_director.state == MusicDirector.STATE_TRAVELING_FORWARD, "fast Phase 2 transition bypasses the pending Noon Phase 1 hold without seeking")
	_check(controller.start_dj_track("dog_2", NOON_1), "runtime bridge can hold DOG_2 Noon Phase 1")
	var noon_1 := controller.music_director.get_candidate("dog_2", NOON_1)
	var noon_2 := controller.music_director.get_candidate("dog_2", NOON_2)
	var before_noon_overlap := controller.music_director.current_playback_position
	_check(controller.request_dj_cue(NOON_2), "DOG_2 Noon Phase 2 extends the overlapping 9-12 loop through bar 14")
	_check(is_equal_approx(controller.music_director.current_playback_position, before_noon_overlap), "Noon overlap changes loop bounds without seeking or restarting")
	_check(controller.music_director.runtime_stream.loop_begin == int(noon_2.get("start_sample", -1)) and controller.music_director.runtime_stream.loop_end == int(noon_2.get("end_sample", -1)), "Noon Phase 2 arms bar 14 as loop end and bar 11 as wrap target")
	_check(int(noon_2.get("start_sample", -1)) < int(noon_1.get("end_sample", -1)) and int(noon_2.get("end_sample", -1)) > int(noon_1.get("end_sample", -1)), "DOG_2 Noon Phase 2 overlaps and extends Phase 1")
	_check(controller.start_dj_track("dog_1", BOSS_1), "runtime bridge starts the DOG_1 Evening Phase 1 cue")
	var boss_2 := controller.music_director.get_candidate("dog_1", BOSS_2)
	var boss_1 := controller.music_director.get_candidate("dog_1", BOSS_1)
	var before_overlap_position := controller.music_director.current_playback_position
	_check(controller.request_dj_cue(BOSS_2), "runtime bridge releases DOG_1 Evening Phase 1 toward Phase 2")
	_check(controller.music_director.state == MusicDirector.STATE_TRAVELING_FORWARD and controller.music_director.pending_cue_id == BOSS_2, "DOG_1 Evening transition keeps authored playback moving forward")
	_check(is_equal_approx(controller.music_director.current_playback_position, before_overlap_position), "Evening transition does not seek or restart the WAV")
	_check(int(boss_2.get("start_sample", -1)) >= int(boss_1.get("end_sample", -1)), "DOG_1 Evening Phase 2 follows Phase 1 chronologically")
	controller.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
