shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 surface_size = vec2(150.0, 56.0);
void fragment() {
	vec4 inherited_tint = COLOR;
	vec2 p = (UV - vec2(0.5)) * surface_size;
	float ink = 0.0;
	for (int i = 0; i < 12; i++) {
		float angle = float(i) * 6.283185 / 12.0;
		vec2 ray = vec2(cos(angle), sin(angle));
		vec2 origin = ray * vec2(surface_size.x * 0.26, 8.0);
		vec2 spark = origin + ray * progress * 23.0;
		vec2 d = abs(p - spark);
		ink += (1.0 - smoothstep(0.7, 2.3, min(d.x + d.y * 0.25, d.y + d.x * 0.25)))
			* (1.0 - smoothstep(2.0, 5.0, max(d.x, d.y)));
	}
	COLOR = vec4(1.0, 0.78 + progress * 0.18, 0.28, min(ink, 1.0) * (1.0 - progress)) * inherited_tint;
}
