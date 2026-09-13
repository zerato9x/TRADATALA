shader_type canvas_item;
render_mode unshaded;

// Permanent printing: liquid ground, gilded cuts, vermilion seal, spectral frame.
// Geometry owns each lane. Combinations are occluded in print order, never added.
uniform vec4 strengths = vec4(0.0); // Making, Set, Extend, Run
uniform float material_amount : hint_range(0.0, 1.0) = 1.0;
uniform float motion_speed : hint_range(0.0, 1.5) = 0.65;
uniform float seal_radius : hint_range(0.18, 0.4) = 0.29;
uniform float frame_width : hint_range(0.035, 0.15) = 0.085;
uniform float cut_width : hint_range(0.018, 0.09) = 0.055;
uniform float liquid_contrast : hint_range(0.0, 1.0) = 1.0;
uniform vec4 vermilion : source_color = vec4(0.86, 0.16, 0.20, 1.0);
uniform vec4 gold : source_color = vec4(1.0, 0.67, 0.15, 1.0);
uniform vec4 jade : source_color = vec4(0.18, 0.84, 0.79, 1.0);
uniform vec4 amethyst : source_color = vec4(0.66, 0.32, 0.88, 1.0);
uniform bool freeze_motion = false;
uniform float sample_time = 0.0;
varying vec4 vertex_tint;

void vertex() { vertex_tint = COLOR; }

float stripe(float distance, float width, float aa) {
 return 1.0 - smoothstep(width - aa, width + aa, abs(distance));
}
vec3 spectral(float phase) {
 float a = 0.5 + 0.5 * sin(phase);
 float b = 0.5 + 0.5 * sin(phase + 2.1);
 return mix(mix(jade.rgb, amethyst.rgb, a), vec3(0.98, 0.74, 0.48), b * b * 0.45);
}
void fragment() {
 vec4 art = texture(TEXTURE, UV);
 vec4 w = clamp(strengths, vec4(0.0), vec4(1.0));
 float t = (freeze_motion ? sample_time : TIME) * motion_speed;
 vec2 p = (UV - 0.5) * vec2(1.0, 1.386);
 float aa = max(fwidth(p.x), 0.002);
 float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y) * 1.386);
 float interior = smoothstep(0.025, 0.075, edge);
 vec3 paper = vec3(1.0);

 // RUN: a broad, liquid foil ground. The palette rolls through curved reflection cells.
 float river = p.x * 5.0 + p.y * 3.0 + 0.85 * sin(p.y * 5.5 - t * 0.7) + t * 1.1;
 float ripple = sin(river + 0.4 * sin(p.x * 8.0 + t * 0.55));
 float caustic = pow(0.5 + 0.5 * sin(river * 1.65 - t * 0.45), 9.0);
 vec3 liquid = mix(vec3(0.96, 0.98, 1.0), spectral(river * 0.6 + t * 0.3), 0.57 + 0.34 * ripple);
 liquid = mix(liquid, vec3(1.0, 0.97, 0.86), caustic * 0.65);
 paper = mix(paper, liquid, w.w * liquid_contrast * interior);

 // EXTEND: two permanent diagonal incisions; specular light runs ALONG each cut.
 float diagonal = p.x + p.y * 0.52;
 float cuts = max(stripe(diagonal + 0.19, cut_width, aa), stripe(diagonal - 0.20, cut_width, aa));
 float cut_core = max(stripe(diagonal + 0.19, cut_width * 0.32, aa), stripe(diagonal - 0.20, cut_width * 0.32, aa));
 float cut_light = pow(0.5 + 0.5 * sin(p.y * 8.0 - t * 3.4), 3.0);
 vec3 metal = mix(gold.rgb * vec3(0.79, 0.60, 0.43), gold.rgb, 0.45 + 0.5 * cut_light);
 metal = mix(metal, vec3(1.0, 0.98, 0.77), cut_core * (0.55 + 0.45 * cut_light));
 paper = mix(paper, metal, cuts * w.z * interior);

 // MAKING: a vermilion seal with a gilded double rim and turning engraved spokes.
 float radius = length(p);
 float angle = atan(p.y, p.x + 0.00001);
 float seal = 1.0 - smoothstep(seal_radius - aa, seal_radius + aa, radius);
 float rim = max(stripe(radius - seal_radius + 0.018, 0.009, aa), stripe(radius - seal_radius + 0.057, 0.007, aa));
 float rays = pow(0.5 + 0.5 * cos(angle * 12.0), 7.0);
 float rays_region = smoothstep(seal_radius * 0.60, seal_radius * 0.73, radius);
 float seal_glint = 0.5 + 0.5 * cos(angle - t * 1.5);
 float seal_band = smoothstep(seal_radius * 0.67 - aa, seal_radius * 0.67 + aa, radius);
 float engraved = stripe(radius - seal_radius * 0.43, 0.006, aa);
 vec3 seal_ink = mix(vec3(1.0, 0.91, 0.65), vermilion.rgb, seal_band);
 seal_ink = mix(seal_ink, gold.rgb, rays * rays_region * 0.65);
 seal_ink = mix(seal_ink, vermilion.rgb, engraved * 0.65);
 seal_ink = mix(seal_ink, mix(gold.rgb, vec3(1.0, 0.96, 0.72), seal_glint), rim);
 paper = mix(paper, seal_ink, seal * w.x);

 // SET: a cut-gem foil frame, with faceted reflections chasing its perimeter.
 float frame = (1.0 - smoothstep(frame_width - aa, frame_width + aa, edge)) * smoothstep(0.018, 0.035, edge);
 float perimeter = angle * 2.0 + t * 1.45;
 float facet = 0.5 + 0.5 * sin(angle * 14.0 + edge * 44.0);
 float frame_glint = pow(0.5 + 0.5 * sin(perimeter), 5.0);
 vec3 gemstone = spectral(angle * 1.7 - t * 0.65) * (0.62 + 0.38 * facet);
 gemstone = mix(gemstone, vec3(0.97, 1.0, 0.97), frame_glint * 0.8);
 float bevel = stripe(edge - frame_width + 0.007, 0.005, aa);
 gemstone = mix(gemstone, vec3(0.93, 0.90, 1.0), bevel * 0.65);
 paper = mix(paper, gemstone, frame * w.y);

 // A simple seal hallmark survives busy court-card art in the quiet upper-right.
 vec2 mark_p = (UV - vec2(0.79, 0.14)) * vec2(1.0, 1.386);
 float mark_r = length(mark_p);
 float mark = 1.0 - smoothstep(0.074 - aa, 0.074 + aa, mark_r);
 float mark_ring = stripe(mark_r - 0.055, 0.008, aa);
 float mark_center = 1.0 - smoothstep(0.031, 0.039, mark_r);
 vec3 mark_ink = mix(mix(vermilion.rgb, gold.rgb, mark_ring), vec3(1.0, 0.94, 0.70), mark_center);
 paper = mix(paper, mark_ink, mark * w.x);

 // Reserve BOTH rank corners. Never displace or recolor printed ink.
 float corner_a = (1.0 - smoothstep(0.16, 0.27, UV.x)) * (1.0 - smoothstep(0.23, 0.35, UV.y));
 float corner_b = smoothstep(0.73, 0.84, UV.x) * smoothstep(0.65, 0.77, UV.y);
 paper = mix(paper, vec3(1.0), max(corner_a, corner_b));
 float blank_paper = smoothstep(0.68, 0.92, min(art.r, min(art.g, art.b)));
 // A narrow light keyline keeps dark/red print readable even over saturated foil.
 vec3 n1 = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb;
 vec3 n2 = texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb;
 vec3 n3 = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb;
 vec3 n4 = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb;
 vec3 nearest_ink = min(min(n1, n2), min(n3, n4));
 float keyline = 1.0 - smoothstep(0.60, 0.85, min(nearest_ink.r, min(nearest_ink.g, nearest_ink.b)));
 paper = mix(paper, vec3(1.0, 0.98, 0.93), keyline * 0.72);
 float enabled = step(0.5, dot(w, vec4(1.0)));
 vec3 result = mix(art.rgb, art.rgb * clamp(paper, vec3(0.0), vec3(1.0)), blank_paper * material_amount * enabled);
 COLOR = vec4(result, art.a) * vertex_tint;
}
