extends SceneTree
const PATH := "user://fortune_resume.save"
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _run() -> void:
	var deal := DealState.new()
	var campaign := CampaignManager.new(deal.wallet)
	var save := RunSave.new(PATH)
	if "--resume-only" in OS.get_cmdline_user_args():
		var data := save.load_run()
		check(not data.is_empty(),save.error)
		check(save.restore(data,campaign,deal),save.error)
		var service := campaign.gieo_que
		check(service.persistent_deck.size()==53,"expanded deck")
		check(service.state==GieoQueService.STATE_TRANSFORM,"resume applied presentation")
		check(service.free_cast_used_today and service.paid_cast_count_today==1,"price state")
		check(service.current_pull_cost()==20_000,"next price")
		for index in 3:
			var card := service.persistent_deck[index]
			check(card.fortune==[-6,6,0][index],"Fortune "+str(index))
			check(card.is_glitch(),"both jackpot flags "+str(index))
			check(card.rank=="K" and card.suit=="Hearts","actual identity "+str(index))
		check(service.resolved_targets[0]==service.last_transformations[0].card,"shared physical reference")
		var before: Dictionary = service.resolved_targets[0].permanent_snapshot()
		check(service.finish_transformation().ok,"finish receipt")
		check(before==service.resolved_targets[0].permanent_snapshot(),"resume must not apply twice")
		print("FORTUNE_FRESH_PROCESS_READ: ", "PASS" if failures.is_empty() else str(failures))
	else:
		campaign.start_campaign(false,"fortune-resume")
		deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
		deal.start_deal(991)
		var service := campaign.gieo_que
		service.wallet.reset(100_000)
		var lines: Array[String] = ["P","P","N","P","P","N"]
		service.cast(lines)
		service.reroll(lines)
		service.accept()
		service.apply_resolved_targets()
		for index in 3:
			var card := service.persistent_deck[index]
			card.apply_rank("K",13)
			card.apply_suit("Hearts")
			card.fortune=[-6,6,0][index]
			card.liquid=true
			card.negative=true
		var extra := CardData.new("fortune_expanded","K",13,"Hearts",13)
		extra.fortune=6
		extra.liquid=true
		extra.negative=true
		service.persistent_deck.append(extra)
		check(save.save_run(campaign,deal),save.error)
		print("FORTUNE_FRESH_PROCESS_WRITE: ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
