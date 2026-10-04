shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
void fragment() {
	vec4 tint = COLOR;
	float filled = step(UV.x, progress);
	vec3 scales = mix(vec3(0.26, 0.8, 0.9), vec3(0.8, 0.58, 1.0), 0.5 + 0.5 * sin(UV.x * 30.0 - TIME * 1.8));
	COLOR = vec4(mix(vec3(0.16, 0.25, 0.32), scales, filled), mix(0.3, 0.95, filled) * tint.a);
}
