@tool
extends McpTestSuite

const MUSIC_ANTI_FATIGUE_SCRIPT := preload("res://scripts/audio/music_anti_fatigue.gd")


func suite_name() -> String:
	return "music_anti_fatigue"


func test_first_two_completed_passes_are_full_and_variation_starts_after_pass_two() -> void:
	var anti := _new_anti_fatigue()
	anti.cue_started("short_loop")
	assert_eq(anti.loop_pass_count, 0)
	assert_eq(anti.current_state, MusicAntiFatigue.STATE_FULL)

	anti.loop_completed("short_loop")
	assert_eq(anti.loop_pass_count, 1)
	assert_eq(anti.current_state, MusicAntiFatigue.STATE_FULL)
	anti.loop_completed("short_loop")
	assert_eq(anti.loop_pass_count, 2)
	assert_ne(anti.current_state, MusicAntiFatigue.STATE_FULL)
	anti.free()


func test_variation_never_repeats_the_current_state() -> void:
	var anti := _new_anti_fatigue()
	anti.state_rng.seed = 17
	anti.cue_started("held_loop")
	anti.loop_completed("held_loop")
	anti.loop_completed("held_loop")
	var previous := anti.current_state
	for _pass in range(12):
		anti.loop_completed("held_loop")
		assert_ne(anti.current_state, previous)
		previous = anti.current_state
	anti.free()


func test_cue_change_resets_counter_and_state() -> void:
	var anti := _new_anti_fatigue()
	anti.cue_started("cue_a")
	anti.loop_completed("cue_a")
	anti.loop_completed("cue_a")
	assert_ne(anti.current_state, MusicAntiFatigue.STATE_FULL)
	anti.prepare_for_cue_change()
	anti.cue_started("cue_b")
	assert_eq(anti.current_cue_id, "cue_b")
	assert_eq(anti.loop_pass_count, 0)
	assert_eq(anti.current_state, MusicAntiFatigue.STATE_FULL)
	anti.free()


func test_release_resets_state_and_non_looping_output_does_not_advance_it() -> void:
	var anti := _new_anti_fatigue()
	anti.cue_started("held_loop")
	anti.loop_completed("held_loop")
	anti.loop_completed("held_loop")
	assert_ne(anti.current_state, MusicAntiFatigue.STATE_FULL)
	anti.reset_variation(false)
	assert_eq(anti.current_cue_id, "")
	assert_eq(anti.loop_pass_count, 0)
	assert_eq(anti.current_state, MusicAntiFatigue.STATE_FULL)
	anti.loop_completed("album_track")
	assert_eq(anti.loop_pass_count, 0)
	assert_eq(anti.current_state, MusicAntiFatigue.STATE_FULL)
	anti.free()


func test_music_director_wrap_signal_condition_requires_a_held_forward_loop() -> void:
	var director := MusicDirector.new()
	director.current_cue_id = "held_loop"
	director.state = MusicDirector.STATE_HOLDING_CUE
	director.runtime_stream = AudioStreamWAV.new()
	director.runtime_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	director._last_playback_position = 4.0
	director.current_playback_position = 0.5
	assert_true(director._did_hold_cue_wrap())
	director.current_playback_position = 4.5
	assert_false(director._did_hold_cue_wrap())
	director.current_playback_position = 0.5
	director.state = MusicDirector.STATE_TRAVELING_FORWARD
	assert_false(director._did_hold_cue_wrap())
	director.free()


func _new_anti_fatigue() -> MusicAntiFatigue:
	var anti: MusicAntiFatigue = MUSIC_ANTI_FATIGUE_SCRIPT.new()
	anti.enabled = true
	anti.transition_seconds = 0.0
	return anti
