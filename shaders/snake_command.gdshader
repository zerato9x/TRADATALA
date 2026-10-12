shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.8;
uniform float strike = 0.0;
uniform bool meld_surface = false;
void fragment() {
	vec4 tint = COLOR;
	vec2 p = UV - vec2(0.5);
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float curl = sin(atan(p.y, p.x) * 5.0 - TIME * 2.2);
	float coil = exp(-abs(edge - 0.026 - curl * 0.009) * 90.0);
	vec2 cells = UV * vec2(8.0, 12.0);
	cells.x += mod(floor(cells.y), 2.0) * 0.5;
	float scales = exp(-abs(length((fract(cells) - 0.5) * vec2(1.0, 1.45)) - 0.43) * 40.0);
	float ribbon = exp(-abs(UV.x - 0.5 - sin(UV.y * 8.0 - TIME * 1.5) * 0.25) * 13.0);
	float pulse = sin(TIME * 2.0 + UV.y * 5.0) * 0.5 + 0.5;
	// Keep rank/suit corners legible while green ink moves across the card face.
	float index_corner = (1.0 - smoothstep(0.16, 0.27, UV.x)) * (1.0 - smoothstep(0.17, 0.31, UV.y));
	index_corner += smoothstep(0.73, 0.84, UV.x) * smoothstep(0.69, 0.83, UV.y);
	float face_ink = (0.23 + pulse * 0.04 + ribbon * 0.18 + scales * 0.075) * (1.0 - index_corner * 0.82);
	float panel_ink = 0.045 + ribbon * 0.055 + scales * 0.025;
	float alpha = coil * 0.75 + (meld_surface ? panel_ink : face_ink) + strike * 0.16;
	vec3 venom = mix(vec3(0.06, 0.76, 0.24), vec3(0.57, 1.0, 0.29), coil);
	COLOR = vec4(venom, min(alpha, 0.82) * strength * tint.a);
}
