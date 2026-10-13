extends RefCounted
## Shared real-deal fixtures for the Tuesday persuasion pair.
const OPENING := [["3", "Hearts"], ["4", "Hearts"], ["5", "Hearts"], ["6", "Hearts"],
	["7", "Hearts"], ["7", "Diamonds"], ["7", "Clubs"], ["7", "Spades"], ["9", "Hearts"], ["K", "Clubs"]]

static func campaign(id: String, familiar: bool = true, start: bool = true, files: MetaSaveFiles = null) -> CampaignManager:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var owner := CampaignManager.new(deal.wallet, events)
	owner.zodiac.bind(owner, deal)
	owner.relic_shop.runtime = deal.relics
	owner.zodiac.progress = ZodiacProgress.new("")
	if files != null: files.attach(owner)
	if not start: return owner
	if familiar: owner.zodiac.progress.record_disposition(id, "fixture:familiar:" + id, "PLEASED")
	var seed_text := ""
	for index in 100:
		owner.run_seed = "MONKEY-DOG-%d" % index
		if ZodiacCatalog.select(owner.seed_for("zodiac_selection", 1), 1) == id:
			seed_text = owner.run_seed
			break
	owner.start_campaign(true, seed_text)
	owner.current_day_index = 1
	owner.zodiac.begin_day(1, owner.seed_for("zodiac_selection", 1))
	owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	return owner

static func node(owner: CampaignManager, id: String) -> void:
	var engine := owner.zodiac.persuasion
	for content: Dictionary in ZodiacCatalog.persuasion_nodes(owner.zodiac.active_id()):
		if content.id != id: continue
		engine.state().plan = [content]
		engine.state().cursor = 0
		engine._open_node()
		return

static func terms(owner: CampaignManager, id: String) -> void:
	node(owner, id)
	owner.zodiac.answer_question("B")
	owner.zodiac.continue_conversation()

static func accept(owner: CampaignManager, id: String, ids: Array = []) -> Dictionary:
	terms(owner, id)
	owner.zodiac.respond("ACCEPT", ids)
	owner.zodiac.continue_conversation()
	return owner.zodiac.daily.promises[-1]

static func cards(pool: Array[CardData], specs: Array) -> Array[CardData]:
	var found: Array[CardData] = []
	for spec: Array in specs:
		for card: CardData in pool:
			if card.rank == spec[0] and card.suit == spec[1]:
				found.append(card)
				break
	return found

static func afternoon(owner: CampaignManager) -> void:
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	var opening: Array[String] = []
	for card: CardData in cards(owner.gieo_que.persistent_deck, OPENING): opening.append(card.unique_id)
	owner.zodiac.deal.start_deal(42, false, opening)

static func meld(owner: CampaignManager) -> Dictionary:
	return owner.zodiac.deal.create_meld(cards(owner.zodiac.deal.hand, OPENING.slice(0, 3)))

static func extension(owner: CampaignManager, id: int = -1) -> Dictionary:
	var deal := owner.zodiac.deal
	return deal.extend_meld(deal.melds[0].meld_id if id < 0 else id, cards(deal.hand, [["6", "Hearts"]]))

static func finish(owner: CampaignManager) -> bool:
	var deal := owner.zodiac.deal
	for _step in 24:
		match deal.state:
			DealState.STATE_ACTIVE: deal.discard_card(deal.hand[-1])
			DealState.STATE_FINAL_COMMIT_WINDOW: deal.settle_phase()
			DealState.STATE_PHASE_CHOICE: deal.choose_phase_two(false)
			DealState.STATE_DEAL_OVER: break
	return deal.state == DealState.STATE_DEAL_OVER and deal.physical_card_accounting_is_valid() and owner.complete_deal()
