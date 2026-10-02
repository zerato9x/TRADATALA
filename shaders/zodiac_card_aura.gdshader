shader_type canvas_item;
render_mode unshaded;

// Drawn on a separate, padded surface: card printing and action outlines survive.
uniform vec4 aura_color : source_color = vec4(0.67, 0.32, 1.0, 1.0);
uniform float seed = 0.0;
uniform float intensity = 1.0;
uniform float speed = 0.7;
uniform vec2 card_half_size = vec2(0.35, 0.39);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec4 inherited_tint = COLOR;
	vec2 p = UV - vec2(0.5);
	vec2 q = abs(p) - card_half_size + vec2(0.025);
	float distance_to_card = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - 0.025;
	float time = TIME * speed;
	vec2 flow = UV * vec2(9.0, 12.0) + vec2(seed, -time * 1.4);
	float curl = noise(flow * 0.47 + vec2(time * 0.3, 0.0));
	float smoke = noise(flow + vec2(curl * 2.5, curl)) * 0.65 + noise(flow * 1.9) * 0.35;
	float outside = smoothstep(-0.025, 0.01, distance_to_card);
	float falloff = 1.0 - smoothstep(0.01, 0.15, distance_to_card);
	float wisps = smoothstep(0.3, 0.78, smoke) * outside * falloff;
	float rim = exp(-abs(distance_to_card) * 100.0) * (0.25 + smoke * 0.5);
	float bounds = smoothstep(0.0, 0.06, UV.x) * smoothstep(0.0, 0.06, 1.0 - UV.x)
		* smoothstep(0.0, 0.06, UV.y) * smoothstep(0.0, 0.06, 1.0 - UV.y);
	vec3 tint = mix(aura_color.rgb * 0.65, min(aura_color.rgb + vec3(0.2), vec3(1.0)), smoke);
	COLOR = vec4(tint, min(wisps * 0.75 + rim * 0.65, 0.8) * bounds * intensity * aura_color.a) * inherited_tint;
}
