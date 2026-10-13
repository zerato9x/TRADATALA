extends RefCounted
## Thursday fixtures reuse the established physical-card and real-Deal helpers.
const SHARED := preload("res://tests/monkey_dog_test_flow.gd")
const OPENING := SHARED.OPENING

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
		owner.run_seed = "HORSE-GOAT-%d" % index
		if ZodiacCatalog.select(owner.seed_for("zodiac_selection", 3), 3) == id:
			seed_text = owner.run_seed
			break
	owner.start_campaign(true, seed_text)
	owner.current_day_index = 3
	owner.zodiac.begin_day(3, owner.seed_for("zodiac_selection", 3))
	owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	return owner

static func node(owner: CampaignManager, id: String) -> void: SHARED.node(owner, id)
static func terms(owner: CampaignManager, id: String) -> void: SHARED.terms(owner, id)
static func accept(owner: CampaignManager, id: String, ids: Array = []) -> Dictionary: return SHARED.accept(owner, id, ids)
static func cards(pool: Array[CardData], specs: Array) -> Array[CardData]: return SHARED.cards(pool, specs)
static func afternoon(owner: CampaignManager) -> void: SHARED.afternoon(owner)
static func meld(owner: CampaignManager) -> Dictionary: return SHARED.meld(owner)
static func extension(owner: CampaignManager, id: int = -1) -> Dictionary: return SHARED.extension(owner, id)
static func finish(owner: CampaignManager) -> bool: return SHARED.finish(owner)

static func final_window(owner: CampaignManager) -> bool:
	var deal := owner.zodiac.deal
	deal.set_current_drink(DrinkCatalog.BAC_XIU)
	while deal.state == DealState.STATE_ACTIVE:
		var discard: CardData = deal.hand.filter(func(c: CardData): return c.rank != "6" or c.suit != "Hearts")[-1]
		if not deal.discard_card(discard).ok: return false
	return deal.state == DealState.STATE_FINAL_COMMIT_WINDOW

static func phase_two(owner: CampaignManager) -> bool:
	var deal := owner.zodiac.deal
	if not final_window(owner) or not deal.settle_phase().ok: return false
	if not deal.select_sam_dua_preserves(deal.hand).ok: return false
	return deal.choose_phase_two(false).ok and deal.current_phase == 2

static func first(owner: CampaignManager) -> Dictionary:
	return meld(owner) if owner.zodiac.active_id() == "horse" else owner.zodiac.deal.create_meld(cards(owner.zodiac.deal.hand, [["7", "Hearts"], ["7", "Diamonds"], ["7", "Clubs"]]))

static func next(owner: CampaignManager) -> Dictionary:
	return owner.zodiac.deal.create_meld(cards(owner.zodiac.deal.hand, [["7", "Hearts"], ["7", "Diamonds"], ["7", "Clubs"]])) if owner.zodiac.active_id() == "horse" else meld(owner)

static func chosen_deal(owner: CampaignManager, chosen: String, mismatch: bool = false) -> void:
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	var selected: CardData = CardTargetQuery.resolve_ids(owner.gieo_que.persistent_deck, [chosen])[0]
	var play: Array[CardData] = []
	if owner.zodiac.active_id() == "horse" or mismatch:
		for card: CardData in owner.gieo_que.persistent_deck:
			if card.rank == selected.rank and card.unique_id != chosen: play.append(card)
		play.append(selected)
	else:
		var first_rank := mini(selected.rank_index, 11)
		for rank in range(first_rank, first_rank + 3):
			play.append(cards(owner.gieo_que.persistent_deck, [[DeckManager.RANKS[rank - 1], selected.suit]])[0])
	var opening: Array[String] = CardTargetQuery.physical_ids(play)
	for card: CardData in owner.gieo_que.persistent_deck:
		if opening.size() < 10 and card.unique_id not in opening: opening.append(card.unique_id)
	owner.zodiac.deal.start_deal(43, false, opening)

static func chosen_play(owner: CampaignManager, chosen: String) -> bool:
	var deal := owner.zodiac.deal
	if owner.zodiac.active_id() == "horse":
		if not deal.create_meld(deal.hand.slice(0, 3)).ok: return false
		return deal.extend_meld(deal.melds[0].meld_id, CardTargetQuery.resolve_ids(deal.hand, [chosen])).ok
	return deal.create_meld(deal.hand.slice(0, 3)).ok
