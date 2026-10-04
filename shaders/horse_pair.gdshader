shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
void fragment() {
	vec4 tint = COLOR;
	float gap = step(0.02, abs(UV.x - 0.5));
	float paid = step(UV.x, progress);
	float gallop = 0.72 + 0.22 * sin(TIME * 4.0 - UV.x * 10.0);
	COLOR = vec4(mix(vec3(0.18, 0.3, 0.4), vec3(0.38, 0.78, 1.0), paid), gap * mix(0.3, gallop, paid) * tint.a);
}
