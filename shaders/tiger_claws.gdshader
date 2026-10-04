shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 tint = COLOR;
	float slash = 0.0;
	for (int i = 0; i < 3; i++) {
		float line = UV.x + UV.y * 0.45 - 0.42 - float(i) * 0.12;
		slash += exp(-abs(line) * 150.0) * smoothstep(0.04, 0.2, UV.y) * (1.0 - smoothstep(0.36, 0.67, UV.y));
	}
	COLOR = vec4(1.0, 0.43, 0.1, slash * (0.6 + 0.15 * sin(TIME * 2.0)) * tint.a);
}
