extends SceneTree

var scene: MatchUI
var failures: Array[String] = []
var hits_seen := 0
var beats_seen := 0
var last_receipt := ""
var sort_presses := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func gameplay_bytes() -> PackedByteArray:
	var codec := RunSave.new()
	var encoded: Variant = codec._encode(codec.capture(scene.campaign, scene.deal))
	check(codec.error.is_empty(), "gameplay encodes")
	return var_to_bytes({"root": encoded, "objects": codec._records})

func observe_receipts() -> void:
	if not is_instance_valid(scene) or not scene.money_presentation.presentation_active \
			or not scene.money_presentation.title_label.text.contains("PACE FIXTURE"):
		return
	var receipt := scene.money_presentation.payout_label.text
	if not receipt.is_empty() and receipt != last_receipt:
		beats_seen += 1
		last_receipt = receipt

func scoring_event(count: int, start: int) -> Dictionary:
	var hits: Array[Dictionary] = []
	for index in count:
		hits.append({"kind": "relic", "label": "PACE FIXTURE", "action_points": 1,
			"rate_bonus_vnd": 1_000, "amount_vnd": 1_000})
	return {"hits": hits, "start_wallet_vnd": start, "target_wallet_vnd": start + count * 1_000,
		"title": "MONEY PACING", "queue_elapsed_seconds": 99.0}

func wait_active() -> void:
	var deadline := Time.get_ticks_msec() + 2_000
	while not scene.money_presentation.presentation_active and Time.get_ticks_msec() < deadline:
		await process_frame
	check(scene.money_presentation.presentation_active, "money presentation starts")

func drain(seconds: float = 2.0) -> void:
	var deadline := Time.get_ticks_msec() + roundi(seconds * 1_000)
	while scene.money_queue_running and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not scene.money_queue_running, "requested fast queue completes within deadline")
	check(not scene.money_presentation.fast_forward_enabled, "speed resets after the queue")

func press(kind: String) -> void:
	var point := scene.sort_button.get_global_transform_with_canvas() * (scene.sort_button.size * 0.5)
	for down in [true, false]:
		var event: InputEvent
		match kind:
			"mouse":
				var mouse := InputEventMouseButton.new()
				mouse.position = point
				mouse.button_index = MOUSE_BUTTON_LEFT
				mouse.pressed = down
				event = mouse
			"keyboard":
				var key := InputEventKey.new()
				key.keycode = KEY_SPACE
				key.pressed = down
				event = key
			"controller":
				var button := InputEventJoypadButton.new()
				button.button_index = JOY_BUTTON_A
				button.pressed = down
				event = button
			"touch":
				var touch := InputEventScreenTouch.new()
				touch.position = point
				touch.pressed = down
				event = touch
		root.push_input(event, true)
	check(scene.money_presentation.fast_forward_enabled, kind + " requests fast animation")
	check(sort_presses == 0, kind + " press never activates the button underneath")

func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/money-2026-09-29/%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameSettings").set_music_system("playing_tracks")
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("TitleScreen").queue_free()
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.hide()
	scene.deal.start_tutorial_deal()
	scene.interaction_locked = false
	scene._sync_all()
	await process_frame
	scene.sort_button.grab_focus()
	scene.sort_button.pressed.connect(func(): sort_presses += 1)
	scene.money_presentation.impact_requested.connect(func(_intensity, _positive): hits_seen += 1)
	process_frame.connect(observe_receipts)
	var before := gameplay_bytes()
	var opening := scene.deal.wallet.balance_vnd
	scene.money_queue_wallet_vnd = opening + 22_000
	scene._enqueue_money_job("scoring", scoring_event(20, opening))
	scene._enqueue_money_job("scoring", scoring_event(2, opening + 20_000))
	await wait_active()
	var deadline := Time.get_ticks_msec() + 4_150
	while Time.get_ticks_msec() < deadline:
		await process_frame
	check(scene.money_queue_running and not scene.money_presentation.fast_forward_enabled, "old pacing persists beyond four seconds and ignores backlog age")
	check(hits_seen >= 6 and hits_seen <= 8, "normal relic beats remain individually readable")
	await capture("normal-money")
	press("mouse")
	await capture("fast-money")
	await drain()
	check(beats_seen == 22, "fast mode presents every hit, including the next queued job")
	check(scene.displayed_wallet_vnd == opening + 22_000, "fast queue lands on the exact display total")
	for kind in ["keyboard", "controller", "touch"]:
		hits_seen = 0
		beats_seen = 0
		last_receipt = ""
		scene._enqueue_money_job("scoring", scoring_event(8, opening))
		await wait_active()
		check(not scene.money_presentation.fast_forward_enabled, "new queue starts at old speed")
		press(kind)
		await drain()
		check(beats_seen == 8, kind + " retains every scoring receipt")
	# Gains, losses, phase settlement and jackpot-style bursts share the request.
	for kind in ["gain", "loss", "phase", "u"]:
		var target := opening - 12_000 if kind in ["loss", "phase"] else opening + 12_000
		var event := {"title": "TRANSFER FIXTURE", "direction": "loss" if kind == "loss" else "gain",
			"reason": kind, "amount_vnd": 12_000, "steps": ["12", "× 1"], "payout": "12.000 VNĐ",
			"start_wallet_vnd": opening, "target_wallet_vnd": target,
			"mom": true, "deadwood_value_sum": 12, "deadwood_multiplier": 1, "deadwood_vnd": 12_000}
		scene._enqueue_money_job("phase" if kind == "phase" else "transaction", event)
		await wait_active()
		press("keyboard")
		await drain(1.0)
		check(scene.displayed_wallet_vnd == target, kind + " transfer keeps its exact final total")
	check(before == gameplay_bytes(), "speed input never changes rules, cards, wallet, history or RNG")
	check(scene.money_presentation.bill_layer.get_child_count() == 0, "fast flights leave no bill ghosts")
	# Motion, releases, wheel scrolling, held-key echoes and menu interaction do
	# not turn normal pacing into fast pacing. Cancellation resets the latch too.
	scene._enqueue_money_job("scoring", scoring_event(20, opening))
	await wait_active()
	var echo := InputEventKey.new()
	echo.keycode = KEY_SPACE
	echo.pressed = true
	echo.echo = true
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	check(not scene._try_fast_forward_money(echo) and not scene._try_fast_forward_money(wheel)
		and not scene._try_fast_forward_money(InputEventMouseMotion.new())
		and not scene._try_fast_forward_money(InputEventKey.new()), "incidental input does not accelerate money")
	scene.menu_layer.show()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_SPACE
	check(not scene._try_fast_forward_money(key), "menu input keeps its normal meaning")
	scene.menu_layer.hide()
	press("keyboard")
	scene.money_presentation.hide_ceremony()
	scene._reset_tutorial_ui_state()
	await process_frame
	check(not scene.money_queue_running and not scene.money_presentation.fast_forward_enabled, "cancellation clears speed and queue")
	scene.queue_free()
	await create_timer(0.25).timeout
	for failure in failures:
		push_error(failure)
	print("MONEY_FAST_FORWARD_SMOKE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
