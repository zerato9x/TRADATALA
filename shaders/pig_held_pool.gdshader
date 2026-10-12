shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform float display_progress = 0.0;
uniform float unlocked = 0.0;
void fragment() {
	vec4 tint = COLOR;
	float shown = min(display_progress, progress);
	float filled = step(UV.x, shown);
	float rim = step(UV.y, 0.16) + step(0.84, UV.y);
	float divisions = 1.0 - smoothstep(0.018, 0.04, abs(fract(UV.x * 4.0) - 0.5));
	float sweep = pow(0.5 + 0.5 * sin(UV.x * 20.0 - TIME * 2.5), 7.0);
	vec3 money = mix(vec3(1.0, 0.67, 0.42), vec3(0.61, 0.89, 0.67), unlocked);
	vec3 color = mix(vec3(0.24, 0.15, 0.2), money + vec3(sweep * 0.13), filled);
	color = mix(color, vec3(1.0, 0.84, 0.65), min(rim * 0.4 + divisions * 0.3, 0.65));
	COLOR = vec4(color, mix(0.55, 0.94, filled) * tint.a);
}
