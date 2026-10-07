class_name DrinkPresentation
extends RefCounted
## Read-only artwork selection shared by the table, shop and collection.
## All production PNGs share a 700 x 900 canvas and contact point (280, 776).

const FULL := "full"
const HALF := "half"
const EMPTY := "empty"
const CANVAS_SIZE := Vector2(700, 900)
const CONTACT_POINT := Vector2(280, 776)

static var _textures: Dictionary = {}


static func texture(drink_id: String, fill: String = FULL) -> Texture2D:
	if drink_id == DrinkCatalog.NONE or not DrinkCatalog.is_known(drink_id):
		return null
	assert(fill in [FULL, HALF, EMPTY])
	var path := "res://assets/drinks/%s_%s.png" % [drink_id, fill]
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path] as Texture2D


static func tint(_drink_id: String) -> Color:
	return Color.WHITE


static func fill_for(deal: DealState, spent: bool) -> String:
	# A temporarily blocked action is not consumption. Read the actual usage
	# flags from MatchUI's existing cadence logic, never current_drink_has_charge.
	if deal.state == DealState.STATE_DEAL_OVER:
		return EMPTY
	if not spent:
		return FULL
	if deal.current_drink_id in [DrinkCatalog.C2_ICED_TEA, DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU]:
		return EMPTY
	if deal.current_phase == 2 and deal.current_drink_id in [DrinkCatalog.NUOC_VOI, DrinkCatalog.NAU_DA, DrinkCatalog.STING]:
		return EMPTY
	return HALF
