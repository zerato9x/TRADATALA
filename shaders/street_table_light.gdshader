shader_type canvas_item;
render_mode unshaded;

// A transparent light layer. It never samples or blurs the cards or UI.
uniform float strength : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	vec2 point = UV - vec2(0.5, 0.47);
	float vignette = smoothstep(0.24, 0.72, length(point * vec2(0.92, 1.0)));
	float lamp = exp(-dot((UV - vec2(0.19, 0.12)) * vec2(1.4, 1.0), (UV - vec2(0.19, 0.12)) * vec2(1.4, 1.0)) * 11.0);
	vec3 tint = mix(vec3(0.018, 0.035, 0.05), vec3(0.86, 0.55, 0.22), lamp);
	COLOR = vec4(tint, (vignette * 0.52 + lamp * 0.13) * strength);
}
