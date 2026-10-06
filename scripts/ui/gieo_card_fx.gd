class_name GieoCardFX
extends RefCounted
## One material on the existing card face. Fortune and Jackpot channels coexist.
const SHADER := preload("res://shaders/gieo_card.gdshader")
static var _atlas: Texture2D
static var _index_prints: Dictionary = {}

static func attach_texture(face: TextureRect, card: CardData) -> void:
	face.set_meta("physical_id", card.unique_id)
	apply_state(face, card.fortune, card.liquid, card.negative, card.shiny)

static func apply_snapshot(face: TextureRect, state: Dictionary) -> void:
	var card := CardData.from_permanent_snapshot(state)
	face.set_meta("physical_id", String(state.get("unique_id", state.get("card_id", ""))))
	apply_state(face, card.fortune, card.liquid, card.negative, bool(state.get("shiny", false)))

static func apply_state(face: TextureRect, fortune: int, liquid: bool, negative: bool, shiny: bool = false, force_material: bool = false) -> void:
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if fortune == 0 and not liquid and not negative and not shiny and not force_material:
		if face.has_meta("gieo_material"):
			face.material = face.get_meta("gieo_original_material") if face.has_meta("gieo_original_material") else null
		return
	var mat: ShaderMaterial
	if face.has_meta("gieo_material"): mat = face.get_meta("gieo_material")
	else:
		if face.material != null: face.set_meta("gieo_original_material", face.material)
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		face.set_meta("gieo_material", mat)
	mat.set_shader_parameter("fortune", float(fortune))
	mat.set_shader_parameter("liquid_amount", 1.0 if liquid else 0.0)
	mat.set_shader_parameter("negative_amount", 1.0 if negative else 0.0)
	mat.set_shader_parameter("previous_fortune", float(fortune))
	mat.set_shader_parameter("transformation", 1.0)
	mat.set_shader_parameter("polished", shiny)
	if face.texture != null: mat.set_shader_parameter("index_print", index_print(face.texture))
	mat.set_shader_parameter("identity_phase", float(absi(String(face.get_meta("physical_id", "")).hash()) % 52))
	if liquid and negative: mat.set_shader_parameter("deck_atlas", deck_atlas())
	face.material = mat

# Copy only the existing rank/suit ink, never the paper rectangle around it.
# Connected components exclude the frame, nearby pips and court artwork.
static func index_print(texture: Texture2D) -> Texture2D:
	if _index_prints.has(texture): return _index_prints[texture]
	var source := texture.get_image()
	if source.is_compressed(): source.decompress()
	var dimensions := source.get_size()
	var mask := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	mask.fill(Color(0, 0, 0, 0))
	var top := Rect2i(Vector2i(2, 3), Vector2i(12, 21))
	top.position = Vector2i(Vector2(top.position) * Vector2(dimensions) / Vector2(57, 79))
	top.size = Vector2i(Vector2(top.size) * Vector2(dimensions) / Vector2(57, 79))
	var bottom := Rect2i(dimensions - top.end, top.size)
	var visited := PackedByteArray()
	visited.resize(dimensions.x * dimensions.y)
	var glyphs: Array[Vector2i] = []
	for y in dimensions.y:
		for x in dimensions.x:
			var point := Vector2i(x, y)
			if visited[y * dimensions.x + x] or not _printed_pixel(source.get_pixelv(point)): continue
			var component: Array[Vector2i] = [point]
			visited[y * dimensions.x + x] = 1
			var cursor := 0
			var minimum := point
			var maximum := point
			while cursor < component.size():
				var pixel := component[cursor]
				cursor += 1
				minimum = minimum.min(pixel)
				maximum = maximum.max(pixel)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = pixel + offset
					if next.x < 0 or next.y < 0 or next.x >= dimensions.x or next.y >= dimensions.y: continue
					var index := next.y * dimensions.x + next.x
					if visited[index] or not _printed_pixel(source.get_pixelv(next)): continue
					visited[index] = 1
					component.append(next)
			if (top.has_point(minimum) and top.has_point(maximum)) or (bottom.has_point(minimum) and bottom.has_point(maximum)):
				glyphs.append_array(component)
	var top_bounds := Rect2i()
	var bottom_bounds := Rect2i()
	for point in glyphs:
		if top.has_point(point): top_bounds = _include_pixel(top_bounds, point)
		else: bottom_bounds = _include_pixel(bottom_bounds, point)
	# Glitch clears alternate index artwork before applying the full-card material.
	# These tight windows contain no final colour or backing plate.
	for bounds in [top_bounds, bottom_bounds]:
		if bounds.has_area(): mask.fill_rect(bounds.grow(1), Color(0, 0, 0, 1))
	for point in glyphs:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var halo := point + Vector2i(dx, dy)
				if halo.x < 0 or halo.y < 0 or halo.x >= dimensions.x or halo.y >= dimensions.y: continue
				var color := mask.get_pixelv(halo)
				color.g = 1.0
				mask.set_pixelv(halo, color)
	for point in glyphs:
		var original := source.get_pixelv(point)
		var red := 1.0 if original.r > original.g + 0.2 and original.r > original.b + 0.2 else 0.0
		mask.set_pixelv(point, Color(1, 1, red, 1))
	var result := ImageTexture.create_from_image(mask)
	_index_prints[texture] = result
	return result

static func _printed_pixel(color: Color) -> bool:
	return color.a > 0.5 and minf(color.r, minf(color.g, color.b)) < 0.65

static func _include_pixel(bounds: Rect2i, point: Vector2i) -> Rect2i:
	if not bounds.has_area(): return Rect2i(point, Vector2i.ONE)
	var minimum := bounds.position.min(point)
	var maximum := (bounds.end - Vector2i.ONE).max(point)
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)

# Built once from the actual 52 existing faces. Glitch samples real identities.
static func deck_atlas() -> Texture2D:
	if _atlas != null: return _atlas
	const TILE := Vector2i(96, 133)
	var atlas := Image.create(TILE.x * 13, TILE.y * 4, false, Image.FORMAT_RGBA8)
	for suit_index in 4:
		for rank_index in 13:
			var card := CardData.new("atlas", DeckManager.RANKS[rank_index], rank_index + 1, DeckManager.SUITS[suit_index], rank_index + 1)
			var source := (load(card.texture_path()) as Texture2D).get_image()
			if source.is_compressed(): source.decompress()
			source.convert(Image.FORMAT_RGBA8)
			source.resize(TILE.x, TILE.y, Image.INTERPOLATE_NEAREST)
			atlas.blit_rect(source, Rect2i(Vector2i.ZERO, TILE), Vector2i(rank_index * TILE.x, suit_index * TILE.y))
	_atlas = ImageTexture.create_from_image(atlas)
	return _atlas
