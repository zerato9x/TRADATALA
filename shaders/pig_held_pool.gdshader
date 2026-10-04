shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
void fragment() {
	vec4 tint = COLOR;
	float filled = step(UV.x, progress);
	float coins = smoothstep(0.15, 0.35, fract(UV.x * 28.0 - TIME * 0.2));
	COLOR = vec4(mix(vec3(0.32, 0.2, 0.24), vec3(1.0, 0.72 + coins * 0.18, 0.46), filled), mix(0.3, 0.9, filled) * tint.a);
}
