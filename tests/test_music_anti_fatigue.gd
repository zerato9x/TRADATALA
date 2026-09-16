@tool
extends McpTestSuite

func suite_name() -> String:
	return "music_anti_fatigue"

func test_four_full_loops_then_continuous_dark_descent() -> void:
	var anti := MusicAntiFatigue.new()
	anti.cue_started("held")
	for index in 3:
		anti.loop_completed("held")
		anti._process(20.0)
		assert_eq(anti.current_state, MusicAntiFatigue.STATE_FULL)
		assert_eq(anti._current_low_pass_hz, 20000.0)
	anti.loop_completed("wrong")
	assert_eq(anti.loop_pass_count, 3)
	anti.loop_completed("held")
	assert_eq(anti.current_state, MusicAntiFatigue.STATE_DARK)
	assert_eq(anti._current_low_pass_hz, 20000.0)
	var previous := anti._current_low_pass_hz
	for index in 16:
		anti._process(1.0)
		assert_true(anti._current_low_pass_hz < previous)
		previous = anti._current_low_pass_hz
		anti.loop_completed("held")
	assert_eq(anti._current_low_pass_hz, 4000.0)
	assert_eq(anti._current_high_pass_hz, 20.0)
	anti.free()

func test_release_ascends_without_cutoff_jump_or_transport_changes() -> void:
	var anti := MusicAntiFatigue.new()
	anti.cue_started("held")
	for index in 4:
		anti.loop_completed("held")
	anti._process(8.0)
	var dark := anti._current_low_pass_hz
	anti.reset_variation(true)
	assert_eq(anti._current_low_pass_hz, dark)
	anti._process(8.0)
	assert_true(anti._current_low_pass_hz > dark)
	assert_true(anti._current_low_pass_hz < 20000.0)
	# A new cue must not snap the recovery to full brightness.
	var recovering := anti._current_low_pass_hz
	anti.cue_started("next")
	assert_eq(anti._current_low_pass_hz, recovering)
	assert_eq(anti.loop_pass_count, 0)
	anti._process(16.0)
	assert_eq(anti._current_low_pass_hz, 20000.0)
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