shader_type canvas_item;
render_mode unshaded;

// A protective green perimeter belongs to the whole loyal Meld.
// No card-face tint, smoke, or replacement of interaction outlines.
uniform vec2 surface_size = vec2(178.0, 136.0);

void fragment() {
	vec4 inherited_tint = COLOR;
	vec2 edge = min(UV, vec2(1.0) - UV) * surface_size;
	float distance_to_edge = min(edge.x, edge.y);
	float guard = exp(-abs(distance_to_edge - 4.0) * 0.6);
	float halo = exp(-distance_to_edge * 0.16) * 0.2;
	float path = (UV.x + UV.y) * 18.0 - TIME * 1.5;
	float sparks = pow(max(sin(path), 0.0), 16.0);
	float breathe = 0.75 + 0.15 * sin(TIME * 2.0);
	vec3 green = mix(vec3(0.12, 0.85, 0.38), vec3(0.67, 1.0, 0.72), sparks);
	COLOR = vec4(green, (guard * (0.5 + sparks * 0.35) + halo) * breathe) * inherited_tint;
}
