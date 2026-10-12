shader_type canvas_item;
render_mode unshaded;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	float cuts = 0.0;
	float glow = 0.0;
	for (int i = 0; i < 3; i++) {
		float line = UV.x + UV.y * 0.64 - 0.54 - float(i) * 0.13;
		float reveal = smoothstep(UV.y - 0.12, UV.y + 0.05, progress * 1.6);
		float taper = smoothstep(0.08, 0.3, UV.y) * (1.0 - smoothstep(0.7, 0.95, UV.y));
		cuts += exp(-abs(line) * 180.0) * reveal * taper;
		glow += exp(-abs(line) * 32.0) * reveal * taper;
	}
	float fade = (1.0 - smoothstep(0.65, 1.0, progress)) * step(0.01, progress);
	COLOR = vec4(mix(vec3(1.0, 0.22, 0.04), vec3(1.0, 0.94, 0.72), clamp(cuts, 0.0, 1.0)), clamp(cuts + glow * 0.38, 0.0, 1.0) * fade);
}
