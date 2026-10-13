extends RefCounted
## Wednesday fixtures reuse the established physical-card and real-Deal helpers.
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
		owner.run_seed = "PIG-OX-%d" % index
		if ZodiacCatalog.select(owner.seed_for("zodiac_selection", 2), 2) == id:
			seed_text = owner.run_seed
			break
	owner.start_campaign(true, seed_text)
	owner.current_day_index = 2
	owner.zodiac.begin_day(2, owner.seed_for("zodiac_selection", 2))
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
