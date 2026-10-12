shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
void fragment() {
	vec4 tint = COLOR;
	float gap = step(0.012, abs(UV.x - 0.5));
	float paid = step(UV.x, progress);
	float gallop = pow(0.5 + 0.5 * sin(TIME * (3.0 + progress * 2.0) - UV.x * 22.0), 4.0);
	float rim = step(UV.y, 0.15) + step(0.85, UV.y);
	vec3 ink = mix(vec3(0.1, 0.21, 0.3), vec3(0.4, 0.8, 1.0) + gallop * 0.15, paid);
	ink = mix(ink, vec3(0.71, 0.92, 1.0), rim * 0.25);
	COLOR = vec4(ink, gap * mix(0.5, 0.88, paid) * tint.a);
}
