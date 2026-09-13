class_name DrinkCatalog
extends RefCounted

const NONE := "none"

const TRA_DA := "tra_da"
const NUOC_VOI := "nuoc_voi"
const NHAN_TRAN := "nhan_tran"
const SAM_DUA := "sam_dua"

const DEN_DA := "den_da"
const NAU_DA := "nau_da"
const BAC_XIU := "bac_xiu"
const STING := "sting"
const BO_HUC := "bo_huc"
const C2_ICED_TEA := "c2_iced_tea"
const MIA_TAC := "mia_tac"
const MIA_SAU_RIENG := "mia_sau_rieng"

const CATEGORY_BASIC := "basic"
const CATEGORY_CAFFEINE := "caffeine"
const CATEGORY_ENERGY := "energy"
const CATEGORY_SUGAR := "sugar"

const DEFINITIONS := {
	TRA_DA: {"tier": 0, "charge_scope": "PASSIVE", "targeting_mode": "discard", "active": false, "name": "Trà đá", "category": CATEGORY_BASIC, "implemented": true, "cue_trigger": "extra_discard_pending"},
	NUOC_VOI: {"tier": 1, "charge_scope": "PHASE", "targeting_mode": "meld_card", "active": true, "name": "Nước vối", "category": CATEGORY_BASIC, "implemented": true, "cue_trigger": "removable_meld_card"},
	NHAN_TRAN: {"tier": 1, "charge_scope": "TURN", "targeting_mode": "discard_swap", "active": true, "name": "Nhân trần", "category": CATEGORY_BASIC, "implemented": true, "cue_trigger": "discard_completes_meld"},
	SAM_DUA: {"tier": 1, "charge_scope": "TRANSITION", "targeting_mode": "preserve", "active": true, "name": "Sâm dứa", "category": CATEGORY_BASIC, "implemented": true, "cue_trigger": "phase_one_redraw_preserve"},
	DEN_DA: {"tier": 2, "charge_scope": "TURN", "targeting_mode": "discard_swap", "active": true, "name": "Đen đá", "category": CATEGORY_CAFFEINE, "implemented": true},
	NAU_DA: {"tier": 2, "charge_scope": "PHASE", "targeting_mode": "whole_meld", "active": true, "name": "Nâu đá", "category": CATEGORY_CAFFEINE, "implemented": true},
	BAC_XIU: {"tier": 2, "charge_scope": "TRANSITION", "targeting_mode": "preserve", "active": true, "name": "Bạc xỉu", "category": CATEGORY_CAFFEINE, "implemented": true},
	STING: {"tier": 2, "charge_scope": "PHASE", "targeting_mode": "pair", "active": true, "name": "Sting", "category": CATEGORY_ENERGY, "implemented": true},
	BO_HUC: {"tier": 3, "charge_scope": "TURN", "targeting_mode": "pair", "active": true, "name": "Bò Húc", "category": CATEGORY_ENERGY, "implemented": true},
	C2_ICED_TEA: {"tier": 2, "charge_scope": "DEAL", "targeting_mode": "run", "active": true, "name": "C2", "category": CATEGORY_SUGAR, "implemented": true},
	MIA_TAC: {"tier": 3, "charge_scope": "PASSIVE", "targeting_mode": "red_run", "active": false, "name": "Nước Mía Quất", "category": CATEGORY_SUGAR, "implemented": true},
	MIA_SAU_RIENG: {"tier": 3, "charge_scope": "PASSIVE", "targeting_mode": "black_run", "active": false, "name": "Nước Mía Sầu Riêng", "category": CATEGORY_SUGAR, "implemented": true},
}


static func is_known(drink_id: String) -> bool:
	return drink_id == NONE or DEFINITIONS.has(drink_id)


static func display_name(drink_id: String) -> String:
	if drink_id == NONE:
		return "Không có"
	return DEFINITIONS.get(drink_id, {}).get("name", drink_id)


static func category(drink_id: String) -> String:
	return DEFINITIONS.get(drink_id, {}).get("category", "")


static func is_effect_implemented(drink_id: String) -> bool:
	return DEFINITIONS.has(drink_id)


static func cue_trigger(drink_id: String) -> String:
	return String(DEFINITIONS.get(drink_id, {}).get("cue_trigger", ""))


static func basic_ids() -> Array[String]:
	return [TRA_DA, NUOC_VOI, NHAN_TRAN, SAM_DUA]


static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(DEFINITIONS.keys())
	return ids


static func effect_text(drink_id: String) -> String:
	return TranslationServer.translate("DRINK_EFFECT_" + drink_id.to_upper())
