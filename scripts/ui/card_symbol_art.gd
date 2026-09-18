class_name CardSymbolArt
extends RefCounted

const SUIT_TEXTURES := {
	"Spades": preload("res://cards/symbol_spade.png"),
	"Hearts": preload("res://cards/symbol_heart.png"),
	"Diamonds": preload("res://cards/symbol_diamond.png"),
	"Clubs": preload("res://cards/symbol_club.png"),
}
const MELD_TEXTURE := preload("res://cards/symbol_meld.png")
const TINT_SHADER_CODE := """
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(tint.rgb, source.a * tint.a);
}
"""


static func texture_for_suit(suit: String) -> Texture2D:
	return SUIT_TEXTURES.get(suit, null) as Texture2D


static func create_suit_icon(suit: String, size: Vector2 = Vector2(12, 12), tint: Color = Color.WHITE) -> TextureRect:
	return _create_icon(texture_for_suit(suit), size, tint, "SuitSymbol")


static func create_meld_icon(size: Vector2 = Vector2(16, 16), tint: Color = Color.WHITE) -> TextureRect:
	return _create_icon(MELD_TEXTURE, size, tint, "MeldSymbol")


static func tint_icon(icon: TextureRect, tint: Color) -> void:
	if icon == null:
		return
	var shader := Shader.new()
	shader.code = TINT_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", tint)
	icon.material = material


static func _create_icon(texture: Texture2D, size: Vector2, tint: Color, node_name: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = node_name
	icon.custom_minimum_size = size
	icon.size = size
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint_icon(icon, tint)
	return icon
