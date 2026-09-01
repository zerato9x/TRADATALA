extends SceneTree

const SCENE_PATH := "res://debug/MusicLoopAudition.tscn"

var failures: Array[String] = []
var scene: Control
var player: MusicLoopPlayer


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_check(packed != null, "audition scene loads")
	if packed == null:
		_finish()
		return
	scene = packed.instantiate() as Control
	root.add_child(scene)
	await process_frame
	await process_frame
	player = scene.get_node("MusicLoopPlayer") as MusicLoopPlayer
	_check(player != null and player.catalog_is_loaded, "fresh player loads catalog")
	_check(player.get_track_ids().size() == 26, "tester exposes exactly 26 tracks")
	_check(not player.get_track_ids().has("pig_3"), "tester excludes V2")
	_check(scene.selected_track_id == "dog_1", "tester defaults to dog_1 for current QA")
	var distinct := player.get_candidates("dog_1", true)
	var all := player.get_candidates("dog_1", false)
	_check(not distinct.is_empty(), "dog_1 has distinct audition candidates")
	_check(all.size() > distinct.size(), "dog_1 can expose every overlapping candidate")
	if not distinct.is_empty():
		var candidate: Dictionary = distinct[0]
		var candidate_id := String(candidate.get("candidate_id", ""))
		_check(player.audition_candidate("dog_1", candidate_id), "candidate audition starts")
		_check(player.runtime_stream != null and player.runtime_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "audition configures forward loop")
		_check(player.runtime_stream.loop_begin == int(candidate.get("start_sample", -1)), "audition uses exact begin sample")
		_check(player.runtime_stream.loop_end == int(candidate.get("end_sample", -1)), "audition uses exact end sample")
		_check(player.release_loop(), "active audition loop releases")
		_check(player.runtime_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "release restores forward source playback")
	_check(player.play_track_from_start("dog_2"), "whole dog_2 source can play without looping")
	_check(player.runtime_stream != null and player.runtime_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "source playback has no automatic loop")
	player.stop()
	scene.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	scene = null
	player = null
	_finish()


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _finish() -> void:
	if failures.is_empty():
		print("MUSIC_LOOP_PLAYER_SMOKE: PASS tracks=26 exhaustive-audition=true")
		quit(0)
		return
	for failure in failures:
		print("MUSIC_LOOP_PLAYER_SMOKE_FAIL: %s" % failure)
	quit(1)
