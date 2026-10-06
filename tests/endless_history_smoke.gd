extends SceneTree

var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var deal := DealState.new()
	var suite := preload("res://tests/test_run_progression.gd").new()
	var campaign: CampaignManager = suite.make_campaign(deal)
	deal.start_tutorial_deal()
	var cards: Array[CardData] = []
	for card in deal.hand:
		if card.rank_index == 9:
			cards.append(card)
	deal.create_meld(cards)
	var details := deal.accounting_report()
	# 300 completed days: preserve all per-card passes, properties and transactions.
	for index in 900:
		campaign.deal_reports.append({"day_id": "endless_%d" % (index / 3), "details": details.duplicate(true)})
		deal.wallet.apply_vnd(index, "fixture")
	var save := RunSave.new("user://endless_history_test.save")
	var snapshot := save.capture(campaign, deal)
	var start := Time.get_ticks_usec()
	# A non-root prefix selects the original recursive v1 encoding everywhere.
	var legacy_root: Variant = save._encode(snapshot, "legacy")
	var legacy_bytes := var_to_bytes({"root": legacy_root, "objects": save._records})
	var legacy_usec := Time.get_ticks_usec() - start
	var file := FileAccess.open(save.path, FileAccess.WRITE)
	file.store_var({"version": 1, "payload": legacy_bytes, "sha256": RunSave.payload_digest(legacy_bytes)}, false)
	file.close()
	var old := save.load_run()
	check(not old.is_empty(), "v1 saves still load")
	check(old.campaign.deal_reports == campaign.deal_reports, "legacy archive survives load")
	save._ids.clear()
	save._records.clear()
	start = Time.get_ticks_usec()
	var compact_root: Variant = save._encode(snapshot)
	var compact_bytes := var_to_bytes({"root": compact_root, "objects": save._records})
	var compact_usec := Time.get_ticks_usec() - start
	start = Time.get_ticks_usec()
	check(save.save_run(campaign, deal), "long-run save succeeds")
	var write_usec := Time.get_ticks_usec() - start
	var loaded := save.load_run()
	check(not loaded.is_empty(), "v2 save loads")
	check(loaded.campaign.deal_reports == campaign.deal_reports, "all completed deal records survive v2")
	check(loaded.deal.wallet_journal == deal.wallet.journal, "entire wallet journal survives v2")
	var restored := DealState.new()
	var restored_campaign: CampaignManager = suite.make_campaign(restored)
	check(save.restore(loaded, restored_campaign, restored), "long-run snapshot restores")
	check(restored_campaign.deal_reports == campaign.deal_reports, "restored history remains available to future modifiers")
	check(restored.wallet.balance_vnd == deal.wallet.balance_vnd, "balance is unchanged")
	check(restored.deck.draw_pile.map(func(card): return card.unique_id) == deal.deck.draw_pile.map(func(card): return card.unique_id), "next draw order is unchanged")
	print("HISTORY_BENCHMARK deals=900 legacy_encode_ms=%.2f compact_encode_ms=%.2f save_ms=%.2f legacy_bytes=%d compact_bytes=%d" % [legacy_usec / 1000.0, compact_usec / 1000.0, write_usec / 1000.0, legacy_bytes.size(), compact_bytes.size()])
	for failure in failures:
		push_error(failure)
	print("ENDLESS_HISTORY_SMOKE: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
