extends RefCounted
## Saturday fixtures reuse the established physical-card and real-Deal helpers.
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
		owner.run_seed = "SNAKE-%d" % index
		if ZodiacCatalog.select(owner.seed_for("zodiac_selection", 5), 5) == id:
			seed_text = owner.run_seed
			break
	owner.start_campaign(true, seed_text)
	owner.current_day_index = 5
	owner.zodiac.begin_day(5, owner.seed_for("zodiac_selection", 5))
	owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	return owner

static func node(owner: CampaignManager, id: String) -> void: SHARED.node(owner, id)
static func terms(owner: CampaignManager, id: String) -> void: SHARED.terms(owner, id)
static func accept(owner: CampaignManager, id: String, ids: Array = []) -> Dictionary: return SHARED.accept(owner, id, ids)
static func cards(pool: Array[CardData], specs: Array) -> Array[CardData]: return SHARED.cards(pool, specs)
static func afternoon(owner: CampaignManager) -> void:
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	owner.zodiac.deal.start_deal(42, false, CardTargetQuery.physical_ids(cards(owner.gieo_que.persistent_deck, OPENING)))
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

static func first(owner: CampaignManager) -> Dictionary: return meld(owner)
static func next(owner: CampaignManager) -> Dictionary: return extension(owner)
static func last(owner: CampaignManager) -> Dictionary:
	return owner.zodiac.deal.create_meld(cards(owner.zodiac.deal.hand, [["7", "Diamonds"], ["7", "Clubs"], ["7", "Spades"]]))

static func cadence(owner: CampaignManager) -> bool: return first(owner).ok and next(owner).ok and last(owner).ok

static func recover_discard(owner: CampaignManager, drink: String = DrinkCatalog.NHAN_TRAN) -> Dictionary:
	var deal := owner.zodiac.deal
	deal.set_current_drink(drink)
	var selected: CardData = cards(deal.hand, [["3", "Hearts"]])[0]
	if not deal.discard_card(selected).ok: return {"ok": false}
	var record: DiscardRecord = deal.discard_history.filter(func(r: DiscardRecord): return r.card.unique_id == selected.unique_id)[0]
	var outgoing: CardData = cards(deal.hand, [["K", "Clubs"]])[0]
	return deal.use_nhan_tran(outgoing, record) if drink == DrinkCatalog.NHAN_TRAN else deal.use_den_da(outgoing, record)

static func recover_meld(owner: CampaignManager, whole: bool = false) -> Dictionary:
	var deal := owner.zodiac.deal
	deal.set_current_drink(DrinkCatalog.NAU_DA if whole else DrinkCatalog.NUOC_VOI)
	var meld: MeldState = deal.melds[0]
	if not whole and meld.cards.size() == 3:
		if not extension(owner, meld.meld_id).ok: return {"ok": false, "error": "fixture_extension_failed"}
	return deal.use_nau_da(meld.meld_id) if whole else deal.use_nuoc_voi(meld.meld_id, meld.cards[0])

static func chosen_deal(owner: CampaignManager, chosen: String) -> void:
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	var selected: CardData = CardTargetQuery.resolve_ids(owner.gieo_que.persistent_deck, [chosen])[0]
	var play: Array[CardData] = []
	for card: CardData in owner.gieo_que.persistent_deck:
		if card.rank == selected.rank and card.unique_id != chosen: play.append(card)
	play.append(selected)
	var ids: Array[String] = CardTargetQuery.physical_ids(play)
	for card: CardData in owner.gieo_que.persistent_deck:
		if ids.size() < 10 and card.unique_id not in ids: ids.append(card.unique_id)
	owner.zodiac.deal.start_deal(43, false, ids)

static func chosen_first(owner: CampaignManager) -> Dictionary:
	return owner.zodiac.deal.create_meld(owner.zodiac.deal.hand.slice(0, 3))

static func chosen_next(owner: CampaignManager, chosen: String) -> Dictionary:
	var deal := owner.zodiac.deal
	return deal.extend_meld(deal.melds[0].meld_id, CardTargetQuery.resolve_ids(deal.hand, [chosen]))
