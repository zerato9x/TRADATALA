shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.6;
void fragment() {
	vec4 tint = COLOR;
	float bottom = exp(-abs(UV.y - 0.94) * 65.0);
	vec2 p = UV * vec2(86.0, 119.0);
	float notes = 0.0;
	for (int i = 0; i < 4; i++) {
		vec2 head = vec2(13.0 + float(i) * 20.0, 113.0 + sin(TIME * 2.0 + float(i)));
		vec2 d = p - head;
		float dot_ink = 1.0 - smoothstep(1.0, 2.6, length(d));
		float stem = (1.0 - smoothstep(0.5, 1.2, abs(d.x - 1.7))) * step(-7.0, d.y) * step(d.y, 0.0);
		notes += dot_ink + stem;
	}
	float sides = exp(-min(UV.x, 1.0 - UV.x) * 90.0) * 0.28;
	COLOR = vec4(0.55, 0.96, 0.85, (bottom * 0.25 + min(notes, 1.0) + sides) * strength * tint.a);
}
