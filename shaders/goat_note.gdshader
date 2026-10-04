shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.6;
void fragment() {
	vec4 tint = COLOR;
	float bottom = exp(-abs(UV.y - 0.94) * 65.0);
	float bars = step(0.56, fract(UV.x * 10.0)) * (0.65 + 0.3 * sin(TIME * 2.0 + UV.x * 12.0));
	float sides = exp(-min(UV.x, 1.0 - UV.x) * 90.0) * 0.28;
	COLOR = vec4(0.55, 0.96, 0.85, (bottom * bars + sides) * strength * tint.a);
}
