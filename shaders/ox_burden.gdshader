shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.5;
void fragment() {
	vec4 tint = COLOR;
	vec2 p = UV * vec2(86.0, 119.0);
	float sides = (1.0 - smoothstep(3.0, 8.0, min(p.x, 86.0 - p.x)));
	float links = pow(abs(sin((p.y + TIME * 3.0) * 0.24)), 8.0);
	float weight = (1.0 - smoothstep(0.0, 8.0, 119.0 - p.y)) * 0.25;
	COLOR = vec4(mix(vec3(0.7, 0.42, 0.18), vec3(1.0, 0.73, 0.3), strength), (sides * links * 0.65 + weight) * tint.a);
}
