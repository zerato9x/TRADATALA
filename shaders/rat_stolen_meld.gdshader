shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 tint = COLOR;
	float rim = exp(-min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)) * 90.0);
	float stitches = step(0.35, fract((UV.x + UV.y) * 30.0 - TIME * 0.8));
	COLOR = vec4(0.73, 0.64, 0.94, rim * stitches * 0.8 * tint.a);
}
