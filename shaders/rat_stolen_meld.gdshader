shader_type canvas_item;
render_mode unshaded;
uniform vec4 ownership_color : source_color = vec4(0.20, 0.60, 1.0, 1.0);
void fragment() {
	vec4 tint = COLOR;
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float rim = 1.0 - smoothstep(0.003, 0.025, edge);
	float stitches = 0.55 + 0.45 * step(0.35, fract((UV.x + UV.y) * 30.0 - TIME * 0.8));
	float glint = pow(max(0.0, 1.0 - abs(fract(UV.x * 0.25 + UV.y - TIME * 0.13) - 0.5) * 8.0), 3.0);
	COLOR = vec4(ownership_color.rgb, (rim * stitches * 0.8 + glint * 0.07) * tint.a);
}
