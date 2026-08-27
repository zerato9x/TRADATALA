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
const NUOC_MIA := "nuoc_mia"
const MIA_TAC := "mia_tac"
const MIA_SAU_RIENG := "mia_sau_rieng"

const CATEGORY_BASIC := "basic"
const CATEGORY_CAFFEINE := "caffeine"
const CATEGORY_ENERGY := "energy"
const CATEGORY_SUGAR := "sugar"

const DEFINITIONS := {
	TRA_DA: {"name": "Trà đá", "category": CATEGORY_BASIC, "implemented": true},
	NUOC_VOI: {"name": "Nước vối", "category": CATEGORY_BASIC, "implemented": true},
	NHAN_TRAN: {"name": "Nhân trần", "category": CATEGORY_BASIC, "implemented": true},
	SAM_DUA: {"name": "Sâm dứa", "category": CATEGORY_BASIC, "implemented": true},
	DEN_DA: {"name": "Đen đá", "category": CATEGORY_CAFFEINE, "implemented": false},
	NAU_DA: {"name": "Nâu đá", "category": CATEGORY_CAFFEINE, "implemented": false},
	BAC_XIU: {"name": "Bạc xỉu", "category": CATEGORY_CAFFEINE, "implemented": false},
	STING: {"name": "Sting", "category": CATEGORY_ENERGY, "implemented": false},
	BO_HUC: {"name": "Bò Húc", "category": CATEGORY_ENERGY, "implemented": false},
	C2_ICED_TEA: {"name": "C2 Iced Tea", "category": CATEGORY_SUGAR, "implemented": false},
	NUOC_MIA: {"name": "Nước mía", "category": CATEGORY_SUGAR, "implemented": false},
	MIA_TAC: {"name": "Mía tắc", "category": CATEGORY_SUGAR, "implemented": false},
	MIA_SAU_RIENG: {"name": "Mía sầu riêng", "category": CATEGORY_SUGAR, "implemented": false},
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
	return DEFINITIONS.get(drink_id, {}).get("implemented", false)


static func basic_ids() -> Array[String]:
	return [TRA_DA, NUOC_VOI, NHAN_TRAN, SAM_DUA]
