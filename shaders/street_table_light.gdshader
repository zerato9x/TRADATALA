shader_type canvas_item;
render_mode unshaded;

// This layer sits behind every card, character and text control. No screen sampling.
uniform float strength : hint_range(0.0, 1.0) = 0.8;
uniform float time_of_day : hint_range(0.0, 3.0) = 0.0;

void fragment() {
	float afternoon = max(0.0, 1.0 - abs(time_of_day - 2.0));
	float night = smoothstep(2.0, 3.0, time_of_day);
	float noon = max(0.0, 1.0 - abs(time_of_day - 1.0));
	vec2 point = UV - vec2(0.5, 0.47);
	float vignette = smoothstep(0.22, 0.74, length(point * vec2(0.92, 1.0)));
	vec2 sun_pos = mix(vec2(0.14, 0.10), vec2(0.84, 0.14), min(time_of_day / 2.0, 1.0));
	vec2 sun_delta = (UV - sun_pos) * vec2(1.1, 0.85);
	float sun = exp(-dot(sun_delta, sun_delta) * 5.5);
	// Broad, slow awning shadows: motion belongs to the street, never the hit targets.
	float drift = sin(TIME * 0.23) * 0.016;
	float bands = smoothstep(0.63, 0.87, sin((UV.x + UV.y * 0.58 + drift) * 23.0));
	float shadow = bands * (1.0 - smoothstep(0.0, 0.85, UV.y)) * (1.0 - night) * 0.09;
	vec2 lamp_delta = (UV - vec2(0.22, 0.27)) * vec2(1.15, 0.85);
	float lamp = exp(-dot(lamp_delta, lamp_delta) * 18.0) * night;
	vec3 warm = mix(vec3(0.94, 0.76, 0.39), vec3(1.0, 0.40, 0.13), afternoon);
	float glow = sun * (0.11 + afternoon * 0.14 - noon * 0.04) * (1.0 - night);
	vec3 tint = mix(vec3(0.015, 0.037, 0.065), warm, min(glow * 4.2 + lamp * 0.68, 1.0));
	float alpha = vignette * (0.36 + night * 0.18) + shadow + glow + night * 0.44;
	COLOR = vec4(tint, clamp(alpha * strength, 0.0, 0.66));
}
