shader_type canvas_item;
render_mode unshaded;
// One engraved Vietnamese drum motif, shared by both Fortune pigments.
uniform float fortune : hint_range(-6.0, 6.0) = 0.0;
uniform float liquid_amount : hint_range(0.0, 1.0) = 0.0;
uniform float negative_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D deck_atlas : filter_nearest, repeat_disable;
uniform sampler2D index_print : filter_nearest, repeat_disable;
uniform float identity_phase = 0.0;
uniform bool polished = false;
uniform float motion_speed : hint_range(0.0, 1.5) = 0.65;
uniform float liquid_contrast : hint_range(0.0, 1.0) = 1.0;
uniform bool freeze_motion = false;
uniform float sample_time = 0.0;
uniform float transformation : hint_range(0.0, 1.0) = 1.0;
uniform float previous_fortune : hint_range(-6.0, 6.0) = 0.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
float line(float distance, float width, float aa) {
 return 1.0 - smoothstep(width - aa, width + aa, abs(distance));
}
float segment(vec2 p, vec2 a, vec2 b, float width, float aa) {
 vec2 v = b - a;
 return 1.0 - smoothstep(width - aa, width + aa, length(p - a - v * clamp(dot(p-a,v)/dot(v,v),0.0,1.0)));
}
float paper(vec3 art) { return smoothstep(0.65, 0.93, min(art.r, min(art.g, art.b))); }
vec3 spectral(float phase) {
 float a = 0.5+0.5*sin(phase);
 float b = 0.5+0.5*sin(phase+2.1);
 return mix(mix(vec3(0.18,0.84,0.79),vec3(0.66,0.32,0.88),a),vec3(0.98,0.74,0.48),b*b*0.45);
}
vec3 liquid_reflection(vec2 p, float t) {
 // Liquid and Negative share the same moving rivers, ripples and caustics.
 float river = p.x*5.0+p.y*3.0+0.85*sin(p.y*5.5-t*0.7)+t*1.1;
 float ripple = sin(river+0.4*sin(p.x*8.0+t*0.55));
 float caustic = pow(0.5+0.5*sin(river*1.65-t*0.45),9.0);
 vec3 liquid = mix(vec3(0.96,0.98,1.0),spectral(river*0.6+t*0.3),0.57+0.34*ripple);
 return mix(liquid,vec3(1.0,0.97,0.86),caustic*0.65);
}
vec3 ground_print(vec3 art, vec2 p, float t) {
 float strength = max(liquid_amount,negative_amount)*liquid_contrast;
 vec3 flowing = mix(art,art*liquid_reflection(p,t),paper(art)*strength);
 vec3 inverted = vec3(0.93,0.97,1.0)-flowing*0.92;
 return mix(flowing,inverted,negative_amount*(1.0-liquid_amount*negative_amount*0.78));
}
vec3 reflected_pigment(vec3 pigment, vec2 p, float t) {
 vec3 wash = liquid_reflection(p,t);
 wash = mix(wash,vec3(0.93,0.97,1.0)-wash*0.92,negative_amount*(1.0-liquid_amount));
 vec3 reflected = pigment*(vec3(0.72)+wash*0.65)+wash*0.055;
 return mix(pigment,reflected,max(liquid_amount,negative_amount)*liquid_contrast*0.70);
}
vec4 identity(float index, vec2 uv) {
 float tile = mod(index,52.0);
 vec2 cell = vec2(mod(tile,13.0),floor(tile/13.0));
 return texture(deck_atlas,(cell+clamp(uv,vec2(0.006),vec2(0.994)))/vec2(13.0,4.0));
}
vec4 visible_face(vec4 original, vec2 uv, float cycle, float t, float glitch) {
 if (glitch < 0.5) { return original; }
 // Seven torn bands drift through actual deck faces, with fluid RGB separation.
 float edge = min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y)*1.386);
 float interior = smoothstep(0.025,0.065,edge);
 float slice = floor(uv.y*7.0);
 float tear = sin(slice*8.1+floor(t*6.0))*0.022*interior;
 vec2 warp = uv+vec2(tear+sin(uv.y*18.0+t*3.0)*0.014,sin(t+uv.x*8.0)*0.007);
 float index = floor(cycle)+slice*7.0;
 vec4 morph = mix(identity(index,warp),identity(index+1.0,warp),smoothstep(0.12,0.86,fract(cycle)));
 vec3 split = vec3(identity(index,warp+vec2(0.009,0.0)).r,morph.g,identity(index+1.0,warp-vec2(0.009,0.0)).b);
 morph.rgb = mix(morph.rgb,split,0.28);
 // The paper around the true indices receives the same material as the whole face.
 morph.rgb = mix(morph.rgb,vec3(1.0),texture(index_print,uv).a);
 return mix(original,morph,glitch);
}
float lotus_petal(vec2 p, float aa) {
 float lens = max(length(p-vec2(0.027,0.0)),length(p+vec2(0.027,0.0)))-0.073;
 return line(lens,0.0045,aa);
}
float tattoo(vec2 p, vec2 uv, float magnitude, float aa) {
 float r = length(p);
 float a = atan(p.y,p.x+0.00001);
 // The old double sun ring remains the anchor at every magnitude.
 float marks = max(line(r-0.222,0.0065,aa),line(r-0.252,0.0051,aa));
 float rays = pow(0.5+0.5*cos(a*12.0),8.0) * line(r-0.237,0.0175,aa);
 marks = max(marks,rays);
 float edge = min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y)*1.386);
 marks = max(marks,line(edge-0.056,0.0045,aa)*0.72);
 float triangle = abs(fract(a*12.0/6.283185)-0.5)*2.0;
 float drum = max(line(r-0.291-triangle*0.023,0.0051,aa),line(r-0.326,0.0045,aa));
 marks = max(marks,drum*smoothstep(1.0,2.0,magnitude));
 // Four long-wing Lac birds occupy a single clear ornamental lane.
 float sector = mod(a+0.785398,1.570796)-0.785398;
 vec2 b = vec2(sector*0.383,r-0.383);
 float bird = segment(b,vec2(-0.076,0.057),vec2(0.003,0.018),0.0063,aa);
 bird = max(bird,segment(b,vec2(0.003,0.018),vec2(-0.077,-0.020),0.0063,aa));
 bird = max(bird,segment(b,vec2(-0.077,-0.020),vec2(0.050,-0.007),0.0063,aa));
 bird = max(bird,segment(b,vec2(0.050,-0.007),vec2(0.062,0.046),0.0063,aa));
 bird = max(bird,segment(b,vec2(0.062,0.046),vec2(0.105,0.046),0.0063,aa));
 marks = max(marks,bird*smoothstep(2.0,3.0,magnitude));
 float frame = line(edge-0.080,0.0045,aa);
 marks = max(marks,frame*smoothstep(3.0,4.0,magnitude));
 // Paired lotus terminals complete the engraving, leaving open paper between motifs.
 vec2 flower = vec2(p.x,abs(p.y)-0.526);
 float petals = lotus_petal(flower,aa);
 vec2 left = mat2(vec2(0.82,-0.57),vec2(0.57,0.82))*(flower+vec2(0.040,0.016));
 vec2 right = mat2(vec2(0.82,0.57),vec2(-0.57,0.82))*(flower-vec2(0.040,-0.016));
 petals = max(petals,max(lotus_petal(left,aa),lotus_petal(right,aa)));
 marks = max(marks,petals*smoothstep(4.0,5.0,magnitude));
 return clamp(marks,0.0,1.0);
}
vec3 material_print(vec3 ground, vec3 art, vec2 p, vec2 uv, float value, float aa, float t, float interior, float guard) {
 float magnitude = abs(value);
 float active = smoothstep(0.0,0.7,magnitude);
 float blank = paper(art);
 float safe = blank;
 float marks = tattoo(p,uv,magnitude,aa);
 float wave = 0.5+0.5*sin(p.x*6.0+p.y*2.3-t*0.85);
 float glint = pow(wave,5.0);
 vec3 metal = mix(vec3(0.64,0.39,0.10),vec3(0.95,0.77,0.36),0.38+wave*0.52);
 metal = mix(metal,vec3(1.0,0.93,0.69),glint*0.42);
 float negative = negative_amount*(1.0-liquid_amount);
 vec3 ink = mix(vec3(0.055,0.075,0.077),vec3(0.43,0.53,0.48),negative);
 vec3 pigment = reflected_pigment(value > 0.0 ? metal : ink,p,t);
 vec3 result = mix(ground,pigment,marks*safe*guard*active);
 // The same engraved figure grows into its substrate instead of adding a mesh.
 float coat = (1.0-smoothstep((magnitude-3.0)*0.30-0.035,(magnitude-3.0)*0.30+0.035,length(p))) * step(3.001,magnitude);
 vec3 field = value > 0.0 ? metal : vec3(0.045,0.062,0.064);
 vec3 incision = value > 0.0 ? metal*0.45 : vec3(0.34,0.42,0.37);
 field = mix(field,incision,marks*guard*0.8);
 field = reflected_pigment(field,p,t);
 result = mix(result,field,safe*coat);
 // One paper-width clearance keeps every original pip and court figure legible.
 vec3 clearance = value > 0.0 ? vec3(1.0,0.95,0.78) : vec3(0.86,0.89,0.83);
 result = mix(result,clearance,(1.0-guard)*safe*coat*0.83);
 // Inverted ink on mature Gold gets the same dark contrast as ordinary printing.
 if (value > 0.0) {
  result = mix(result,(vec3(1.0)-art)*0.23+vec3(0.035,0.045,0.04),(1.0-blank)*coat*negative);
 }
 return result;
}
void fragment() {
 float time = freeze_motion ? sample_time : TIME;
 float t = time*motion_speed;
 float glitch = liquid_amount*negative_amount;
 float cycle = t*4.5+identity_phase;
 vec4 original = texture(TEXTURE,UV);
 vec4 art = visible_face(original,UV,cycle,t,glitch);
 vec2 p = (UV-0.5)*vec2(1.0,1.386);
 float aa = max(fwidth(UV.x)*0.45,0.0012);
 float edge = min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y)*1.386);
 float interior = smoothstep(0.025,0.065,edge);
 vec2 dx = vec2(TEXTURE_PIXEL_SIZE.x,0.0);
 vec2 dy = vec2(0.0,TEXTURE_PIXEL_SIZE.y);
 vec3 n1 = visible_face(texture(TEXTURE,UV+dx),UV+dx,cycle,t,glitch).rgb;
 vec3 n2 = visible_face(texture(TEXTURE,UV-dx),UV-dx,cycle,t,glitch).rgb;
 vec3 n3 = visible_face(texture(TEXTURE,UV+dy),UV+dy,cycle,t,glitch).rgb;
 vec3 n4 = visible_face(texture(TEXTURE,UV-dy),UV-dy,cycle,t,glitch).rgb;
 float guard = min(min(paper(n1),paper(n2)),min(paper(n3),paper(n4)));
 vec3 ground = ground_print(art.rgb,p,t);
 vec3 before = material_print(ground,art.rgb,p,UV,previous_fortune,aa,t,interior,guard);
 vec3 after = material_print(ground,art.rgb,p,UV,fortune,aa,t,interior,guard);
 float front = length(p)+sin(p.x*13.0+p.y*11.0)*0.008;
 float infection = 1.0-smoothstep(transformation*0.96-0.055,transformation*0.96+0.055,front);
 infection *= smoothstep(0.0,0.035,transformation);
 infection = mix(infection,1.0,step(0.999,transformation));
 vec3 result = mix(before,after,infection);
 if (glitch > 0.0) {
  float seam = line(fract(UV.y*7.0+t*0.23)-0.5,0.012,aa)*interior;
  result = mix(result,spectral(t+UV.y*9.0),seam*glitch*0.36);
 }
 if (polished) {
  float sweep = line(UV.x+UV.y*0.38-(mod(time*0.34,1.9)-0.25),0.075,0.07);
  vec3 silver = fortune > 0.0 ? vec3(0.94,0.90,0.68) : vec3(0.52,0.79,0.85);
  float blank = paper(art.rgb);
  result = mix(result,silver,line(edge-0.026,0.011,aa)*blank*0.85);
  vec3 reflection = fortune > 0.0 ? vec3(0.96,0.84,0.55) : vec3(0.60,0.82,0.90);
  result = mix(result,reflection,sweep*blank*0.34);
 }
 // A single quiet edge follows the infection; no extra stripe crosses the artwork.
 float seal = line(front-transformation*0.96,0.009,0.008)*smoothstep(0.0,0.12,transformation)*(1.0-smoothstep(0.82,1.0,transformation));
 vec3 seal_color = fortune >= 0.0 ? vec3(0.94,0.78,0.37) : vec3(0.35,0.46,0.40);
 result = mix(result,seal_color,seal*paper(art.rgb)*guard*interior*0.55);
 // Reprint only the real rank/suit glyphs with a one-texel contrasting keyline.
 // The material continues between the strokes, with no reserved corner panel.
 vec4 indices = texture(index_print,UV);
 float modified = max(smoothstep(0.0,0.7,abs(fortune)),max(liquid_amount,negative_amount));
 if (indices.g > 0.0 && modified > 0.0) {
  vec2 index_uv = UV.y < 0.5 ? vec2(0.12,0.16) : vec2(0.88,0.84);
  vec2 index_p = (index_uv-0.5)*vec2(1.0,1.386);
  vec3 index_ground = ground_print(vec3(1.0),index_p,t);
  vec3 index_before = material_print(index_ground,vec3(1.0),index_p,index_uv,previous_fortune,aa,t,1.0,1.0);
  vec3 index_after = material_print(index_ground,vec3(1.0),index_p,index_uv,fortune,aa,t,1.0,1.0);
  float index_front = length(index_p)+sin(index_p.x*13.0+index_p.y*11.0)*0.008;
  float index_infection = 1.0-smoothstep(transformation*0.96-0.055,transformation*0.96+0.055,index_front);
  index_infection *= smoothstep(0.0,0.035,transformation);
  index_infection = mix(index_infection,1.0,step(0.999,transformation));
  vec3 backdrop = mix(index_before,index_after,index_infection);
  float light_ink = 1.0-smoothstep(0.27,0.42,dot(backdrop,vec3(0.2126,0.7152,0.0722)));
  vec3 dark_print = mix(vec3(0.025,0.035,0.04),vec3(0.61,0.015,0.045),indices.b);
  vec3 light_print = mix(vec3(0.98,0.95,0.85),vec3(1.0,0.47,0.49),indices.b);
  vec3 glyph = mix(dark_print,light_print,light_ink);
  vec3 keyline = mix(vec3(1.0,0.97,0.85),vec3(0.015,0.025,0.035),light_ink);
  result = mix(result,keyline,indices.g*(1.0-indices.r)*modified*0.88);
  result = mix(result,glyph,indices.r*modified);
 }
 COLOR = vec4(clamp(result,vec3(0.0),vec3(1.0)),original.a)*vertex_tint;
}
