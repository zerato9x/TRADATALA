shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(1.0, 0.78, 0.38, 1.0);
uniform float rim_strength = 0.38;

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	vec2 reach = max(TEXTURE_PIXEL_SIZE * 5.0, vec2(0.003));
	float near_alpha = max(texture(TEXTURE, UV + vec2(reach.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(reach.x, 0.0)).a);
	near_alpha = max(near_alpha, texture(TEXTURE, UV + vec2(0.0, reach.y)).a);
	near_alpha = max(near_alpha, texture(TEXTURE, UV - vec2(0.0, reach.y)).a);
	float edge = max(near_alpha - art.a, 0.0);
	float pulse = 0.78 + 0.22 * sin(TIME * 1.8);
	COLOR = vec4(art.rgb * (0.97 + 0.05 * pulse) + rim_color.rgb * edge * rim_strength,
		max(art.a, edge * rim_strength * pulse));
}
