shader_type canvas_item;
// Literal clear polish, independent of permanent Gieo printing.
uniform bool polished = false;
render_mode unshaded;

// Permanent printing: legendary liquid ground and six conditional gold engravings.
// Geometry owns each lane. Combinations are occluded in print order, never added.
uniform vec4 strengths = vec4(0.0); // Gold: Making, Set, Extend, Run
uniform vec3 accents = vec3(0.0); // Gold: Big, Last Call; legendary Liquid
uniform float material_amount : hint_range(0.0, 1.0) = 1.0;
uniform float motion_speed : hint_range(0.0, 1.5) = 0.65;
uniform float liquid_contrast : hint_range(0.0, 1.0) = 1.0;
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
 paper = mix(paper, liquid, accents.z * liquid_contrast * interior);

 // One metal family; independent geometric lanes prevent additive shader soup.
 float radius = length(p);
 float angle = atan(p.y, p.x + 0.00001);
 float gleam = pow(0.5 + 0.5 * sin(p.x * 8.0 + p.y * 5.0 - t * 2.3), 4.0);
 vec3 metal = mix(vec3(0.64, 0.34, 0.065), gold.rgb, 0.5 + 0.5 * gleam);
 metal = mix(metal, vec3(1.0, 0.97, 0.73), gleam * 0.7);
 // MAKING: double sun-ring, engraved spokes. Open centre preserves the art.
 float ring = max(stripe(radius - 0.245, 0.008, aa), stripe(radius - 0.275, 0.005, aa));
 float spokes = pow(0.5 + 0.5 * cos(angle * 16.0), 12.0) * stripe(radius - 0.26, 0.035, aa);
 float making = max(ring, spokes);
 // SET: linked square facets inside a rectangular frame.
 float frame = stripe(edge - 0.055, 0.009, aa);
 float facet = stripe(abs(fract((UV.x + UV.y) * 18.0) - 0.5) - 0.23, 0.10, aa);
 float set_mark = max(frame, stripe(edge - 0.08, 0.009, aa) * facet);
 // EXTEND: two ascending, segmented diagonal gold cuts.
 float diagonal = p.x + p.y * 0.52;
 float cuts = max(stripe(diagonal + 0.20, 0.014, aa), stripe(diagonal - 0.20, 0.014, aa));
 float extend_mark = cuts * (0.55 + 0.45 * smoothstep(-0.5, 0.7, sin(p.y * 32.0 - t * 2.0)));
 // RUN: parallel flowing rails, thin and gold; distinct from Liquid's broad ground.
 float wave = sin(p.y * 10.0 - t * 1.2) * 0.023;
 float run_mark = max(stripe(abs(p.x) - 0.32 - wave, 0.009, aa), stripe(abs(p.x) - 0.35 - wave, 0.005, aa));
 // BIG: four nested angular brackets pointing toward the expanded centre.
 vec2 q = abs(p);
 float bracket = max(stripe(q.x - 0.395, 0.011, aa) * step(0.34, q.y) * step(q.y, 0.49), stripe(q.y - 0.49, 0.011, aa) * step(0.27, q.x) * step(q.x, 0.395));
 // LAST CALL: hourglass lattice in the upper/lower interior, with travelling sparks.
 vec2 h = vec2(p.x, abs(p.y) - 0.51);
 float hourglass = stripe(abs(h.x) - abs(h.y) * 0.9, 0.009, aa) * step(abs(h.y), 0.085);
 hourglass = max(hourglass, stripe(abs(h.y) - 0.085, 0.008, aa) * step(abs(h.x), 0.077));
 float gold_mask = max(max(making * w.x, set_mark * w.y), max(extend_mark * w.z, run_mark * w.w));
 gold_mask = max(gold_mask, max(bracket * accents.x, hourglass * accents.y)) * interior;
 paper = mix(paper, metal, gold_mask);
 // Six fixed hallmark positions in the quiet upper-right identify stacked properties.
 // Each enabled mark has its own silhouette; no colour coding required.
 for (int i = 0; i < 6; i++) {
  float active = i < 4 ? w[i] : accents[i - 4];
  vec2 m = (UV - vec2(0.73 + float(i % 2) * 0.12, 0.105 + float(i / 2) * 0.072)) * vec2(1.0, 1.386);
  float mark = 0.0;
  if (i == 0) mark = stripe(length(m) - 0.022, 0.006, aa);
  if (i == 1) mark = stripe(max(abs(m.x), abs(m.y)) - 0.021, 0.006, aa);
  if (i == 2) mark = stripe(m.x + m.y * 0.7, 0.007, aa) * step(abs(m.y), 0.026);
  if (i == 3) mark = stripe(m.x - sin(m.y * 90.0) * 0.015, 0.006, aa) * step(abs(m.y), 0.028);
  if (i == 4) mark = stripe(abs(m.x) + abs(m.y) - 0.029, 0.006, aa);
  if (i == 5) mark = stripe(abs(m.x) - abs(m.y) * 0.8, 0.006, aa) * step(abs(m.y), 0.028);
  paper = mix(paper, metal, mark * active);
 }

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
 float enabled = step(0.5, dot(w, vec4(1.0)) + dot(accents, vec3(1.0)));
 vec3 result = mix(art.rgb, art.rgb * clamp(paper, vec3(0.0), vec3(1.0)), blank_paper * material_amount * enabled);
 if (polished) {
  float polish_time = freeze_motion ? sample_time : TIME;
  float sweep_position = mod(polish_time * 0.48, 1.9) - 0.25;
  float sweep = stripe(UV.x + UV.y * 0.38 - sweep_position, 0.065, 0.055);
  // Persistent cool-silver rim reads even between sweeps, including small hand cards.
  float rim = stripe(edge - 0.034, 0.018, aa);
  vec3 silver = mix(vec3(0.30, 0.65, 0.78), vec3(0.78, 0.93, 1.0), 0.5 + 0.5 * sin(polish_time * 2.0));
  float protected_paper = blank_paper * (1.0 - max(corner_a, corner_b));
  result = mix(result, silver, rim * blank_paper * 0.85);
  // A tinted reflection remains visible on white paper without washing out printed ink.
  result = mix(result, vec3(0.58, 0.83, 0.95), sweep * protected_paper * 0.55);
  result = mix(result, vec3(1.0), stripe(UV.x + UV.y * 0.38 - sweep_position + 0.055, 0.012, aa) * protected_paper * 0.75);
  for (int i = 0; i < 2; i++) {
   vec2 anchor = i == 0 ? vec2(0.86, 0.16) : vec2(0.15, 0.83);
   vec2 sparkle_uv = (UV - anchor) * vec2(1.0, 1.386);
   float sparkle = max(stripe(sparkle_uv.x, 0.008, aa) * (1.0 - smoothstep(0.0, 0.065, abs(sparkle_uv.y))),
                       stripe(sparkle_uv.y, 0.008, aa) * (1.0 - smoothstep(0.0, 0.050, abs(sparkle_uv.x))));
   result = mix(result, vec3(0.18, 0.52, 0.68), sparkle * blank_paper * (0.8 + 0.2 * sin(polish_time * 2.5 + float(i) * 2.0)));
  }
 }
 COLOR = vec4(result, art.a) * vertex_tint;
}
