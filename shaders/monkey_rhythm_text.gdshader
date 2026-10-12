shader_type canvas_item;
render_mode unshaded;

// Only the glyphs dance. This never paints a panel behind the text.
uniform float urgency = 0.0;
void vertex() {
	VERTEX.y += sin(TIME * 4.0 + VERTEX.x * 0.045) * (0.6 + urgency * 0.4);
}
void fragment() {
	vec4 glyph = texture(TEXTURE, UV) * COLOR;
	float beat = 0.5 + 0.5 * sin(TIME * 5.0 + UV.x * 8.0);
	glyph.rgb = mix(glyph.rgb, mix(vec3(1.0, 0.9, 0.42), vec3(1.0, 0.43, 0.19), urgency), beat * 0.28);
	COLOR = glyph;
}
