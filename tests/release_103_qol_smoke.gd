extends SceneTree
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var conversation := load("res://scenes/ui/npc_conversation.tscn").instantiate() as NpcConversation
	root.add_child(conversation)
	conversation.say("Vendor", "A long explanation about the selected drink and its effect.")
	await create_timer(0.15).timeout
	var reveal := conversation._reveal
	var revealed := conversation.speech.visible_characters
	conversation.say("Vendor", "A long explanation about the selected drink and its effect.")
	check(conversation._reveal == reveal and conversation.speech.visible_characters >= revealed, "identical speech keeps its current reveal")
	conversation.speech.visible_characters = -1
	conversation.say("Vendor", "A long explanation about the selected drink and its effect.")
	check(conversation.speech.visible_characters == -1, "repeated speech does not restart a completed line")
	conversation.say("Vendor", "Changed explanation")
	check(conversation._reveal != reveal, "changed speech starts a new reveal")
	var manager := DrinkManager.new()
	manager.progress = DrinkProgress.new("")
	var shop := load("res://scenes/ui/drink_shop.tscn").instantiate() as DrinkShop
	root.add_child(shop)
	shop.configure(manager, false)
	var inspected := [0]
	shop.drink_inspected.connect(func(_id): inspected[0] += 1)
	shop.inspect_drink(DrinkCatalog.TRA_DA)
	shop.inspect_drink(DrinkCatalog.TRA_DA)
	check(inspected[0] == 1, "reclicking the selected drink emits no repeated inspection")
	check(shop._buttons[DrinkCatalog.TRA_DA].button_pressed, "reclick keeps selection highlighted")
	shop.inspect_drink("unknown")
	check(shop.selected_id == DrinkCatalog.TRA_DA, "invalid drink does not clear selection or crash")
	shop.inspect_drink(DrinkCatalog.STING)
	check(shop.confirm.disabled and shop.confirm.text == TranslationServer.translate("DRINK_LOCKED"), "locked drinks have a disabled Locked action")
	shop._completed = true
	shop.inspect_drink(DrinkCatalog.TRA_DA)
	check(shop.confirm.disabled and shop.confirm.text == TranslationServer.translate("EVENT_INTERACT_DONE"), "completed shop keeps Done while inspecting")
	var destination := TextureRect.new()
	destination.texture = load("res://assets/drinks/tra_da_full.png")
	destination.size = Vector2(80, 120)
	destination.position = Vector2(700, 200)
	root.add_child(destination)
	var arrival = load("res://scripts/ui/debt_collector_arrival.gd").new()
	root.add_child(arrival)
	arrival.play(destination)
	arrival._motion.pause()
	await create_timer(0.05).timeout
	check(arrival._engine.playing and arrival._engine.get_playback_position() >= 1.25, "engine starts at the audible rev")
	check(arrival._engine.bus == &"Sound", "collector respects Sound volume")
	arrival._motion.custom_step(0.9)
	check(arrival._engine.playing, "fade plays after docking instead of stopping in parallel")
	arrival._motion.custom_step(0.3)
	check(not arrival._engine.playing and not arrival.visible and destination.modulate.a == 1.0, "arrival finishes and restores portrait")
	arrival.play(destination)
	arrival.stop()
	check(not arrival._engine.playing and destination.modulate.a == 1.0, "interruption cancels audio and restores portrait")
	arrival.queue_free()
	destination.queue_free()
	shop.queue_free()
	conversation.queue_free()
	await create_timer(0.2).timeout
	print("RELEASE_103_QOL checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)