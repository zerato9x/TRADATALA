extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var receipt = load("res://scripts/ui/resolve_receipt.gd").new()
	root.add_child(receipt)
	var deal := DealState.new()
	deal.start_tutorial_deal()
	var cards: Array[CardData] = []
	for card in deal.hand:
		if card.rank_index == 9:
			cards.append(card)
	deal.create_meld(cards)
	var report := deal.accounting_report()
	var before := deal.wallet.balance_vnd
	receipt.show_report(report, "deal", "TEST", "CONTINUE")
	receipt._show_page("cards")
	var faces: Array = receipt.rows.find_children("*", "TextureRect", true, false)
	check(faces.size() == 3, "pass snapshots supply real cards")
	# Switching during the deal-in animation must not leave tweens on freed faces.
	for i in 8:
		receipt._show_page("cards" if i % 2 == 0 else "ledger")
	await create_timer(0.7).timeout
	check(receipt.net_label.text == VndWallet.format_vnd(int(report.net_vnd), true), "animated number lands on exact authoritative total")
	check(deal.wallet.balance_vnd == before, "presentation leaves wallet unchanged")
	var signals := [0]
	receipt.continued.connect(func(): signals[0] += 1)
	receipt._continue()
	receipt._continue()
	await create_timer(0.2).timeout
	check(signals[0] == 1, "double activation emits one continuation")
	# Negative totals, zero entries, shortfall, and repeat openings are independent.
	var loss := {"net_vnd": -100, "opening_vnd": 100, "closing_vnd": 0, "income_vnd": 0, "expense_vnd": 100, "entries": [], "categories": {}, "due_vnd": 500, "shortfall_vnd": 500}
	receipt.show_report(loss, "collection", "SHORTFALL", "END RUN")
	check(receipt._collector_arrival.visible, "collection starts bike entrance")
	check(receipt._collector_arrival._engine.playing, "collection starts supplied engine sound")
	check(receipt._collector_arrival._engine.bus == "Sound", "engine obeys sound settings")
	await create_timer(0.7).timeout
	check(receipt.net_label.text == VndWallet.format_vnd(-100, true), "negative count finishes exactly")
	check(receipt._collector_arrival.visible, "entrance remains active while riding in")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/collector-arrival.png")
	check(receipt.portrait.visible, "collector restored after repeated report")
	check(not receipt.primary.disabled, "new report restores continue")
	receipt._show_page("cards")
	check(not receipt._collector_arrival.visible and not receipt._collector_arrival._engine.playing, "tab interrupts entrance and sound cleanly")
	check(receipt.rows.find_children("*", "TextureRect", true, false).is_empty(), "no stale card evidence on empty report")
	receipt._show_page("overview")
	await process_frame
	check(receipt.primary.get_global_rect().end.y <= root.size.y, "shortfall action remains within viewport")
	receipt.show_report(loss, "collection", "SHORTFALL", "END RUN")
	await create_timer(2.6).timeout
	check(not receipt._collector_arrival.visible and not receipt._collector_arrival._engine.playing, "entrance finishes and engine stops")
	check(receipt.portrait.modulate.a == 1.0, "docking restores receipt portrait")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/collector-arrived.png")
	receipt.show_report(loss, "collection", "SHORTFALL", "END RUN")
	receipt.hide()
	check(not receipt._collector_arrival._engine.playing, "hidden receipt stops engine immediately")
	receipt.queue_free()
	await create_timer(0.2).timeout
	for failure in failures:
		push_error(failure)
	print("RESOLVE_PRESENTATION_SMOKE: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
