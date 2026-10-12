shader_type canvas_item;
render_mode unshaded;
uniform vec4 ownership_color : source_color = vec4(0.20, 0.60, 1.0, 1.0);
void fragment() {
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float rim = 1.0 - smoothstep(0.015, 0.065, edge);
	float stitch = 0.55 + 0.45 * step(0.5, fract((UV.x + UV.y) * 18.0 - TIME * 0.65));
	float sweep = pow(max(0.0, 1.0 - abs(fract(UV.y - UV.x * 0.35 - TIME * 0.2) - 0.5) * 9.0), 3.0);
	COLOR = vec4(ownership_color.rgb, rim * stitch * 0.88 + sweep * 0.16);
}
