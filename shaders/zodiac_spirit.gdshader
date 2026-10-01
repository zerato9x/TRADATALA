shader_type canvas_item;

uniform float shimmer_speed = 1.3;

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float halo = 0.0;
	vec2 texel = max(TEXTURE_PIXEL_SIZE * 12.0, vec2(0.01));
	halo = max(halo, texture(TEXTURE, UV + vec2(texel.x, 0.0)).a);
	halo = max(halo, texture(TEXTURE, UV - vec2(texel.x, 0.0)).a);
	halo = max(halo, texture(TEXTURE, UV + vec2(0.0, texel.y)).a);
	halo = max(halo, texture(TEXTURE, UV - vec2(0.0, texel.y)).a);
	float edge = max(halo - ink.a, 0.0);
	float breath = 0.5 + 0.5 * sin(TIME * shimmer_speed + UV.y * 9.0);
	vec3 glow = mix(vec3(0.35, 0.78, 0.96), vec3(1.0, 0.80, 0.43), breath);
	COLOR = vec4(ink.rgb * (0.92 + 0.15 * breath) + glow * edge, max(ink.a, edge * (0.48 + 0.32 * breath)));
}
