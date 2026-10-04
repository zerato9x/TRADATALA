shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.8;
void fragment() {
	vec4 tint = COLOR;
	vec2 p = UV - vec2(0.5);
	float edge = max(abs(p.x) / 0.48, abs(p.y) / 0.48);
	float coil = exp(-abs(edge - 1.0 + sin(atan(p.y, p.x) * 7.0 - TIME * 2.0) * 0.018) * 75.0);
	COLOR = vec4(0.55, 0.96, 0.34, coil * strength * tint.a);
}
