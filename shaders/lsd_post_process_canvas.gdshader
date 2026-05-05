shader_type canvas_item;

// Canvas fallback when no Camera3D is current (e.g. pure UI root) — no depth = kaleidoscope over the whole frame.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// CanvasItem analyzers often reject SCREEN_PIXEL_SIZE here; drive from script instead.
uniform vec2 viewport_pixels = vec2(1280.0, 720.0);

uniform float effect_time : hint_range(0.0, 100000.0) = 0.0;

// Excessivly long because why not
const float PHI = 1.6180339887498948482045868343656381177203091798058;

uniform float effect_strength : hint_range(0.0, 1.0) = 0.45;
uniform float wobble_amp : hint_range(0.0, 0.06) = 0.014;
uniform float chroma_amp : hint_range(0.0, 0.024) = 0.0045;
uniform float hue_speed : hint_range(0.0, 3.0) = 0.18;
uniform float hue_time_scale : hint_range(0.12, 1.35) = 0.38;
uniform float hue_amount : hint_range(0.0, 1.0) = 0.7;
uniform float saturation_push : hint_range(1.0, 2.2) = 1.52;
uniform float hue_wobble : hint_range(0.0, 6.283) = 1.45;
uniform float tint_strength : hint_range(0.0, 0.22) = 0.12;

uniform float rainbow_strength : hint_range(0.0, 1.0) = 0.52;
uniform float rainbow_scale : hint_range(0.4, 22.0) = 7.0;
uniform float rainbow_flow : hint_range(0.0, 3.5) = 1.2;
uniform float rainbow_twirl : hint_range(0.0, 2.5) = 0.85;

uniform float kaleido_segments : hint_range(3.0, 14.0) = 7.0;
uniform float kaleido_uv_mix : hint_range(0.0, 1.0) = 0.82;
uniform float kaleido_spin : hint_range(-1.5, 1.5) = 0.095;
uniform float kaleido_radius_warp : hint_range(0.0, 0.35) = 0.08;
uniform float kaleido_pattern_strength : hint_range(0.0, 0.4) = 0.14;
uniform float kaleido_line_freq : hint_range(3.0, 28.0) = 12.0;

vec2 wobble(vec2 uv, float t) {
	uv.x += sin(uv.y * 19.0 + t * 2.05) * wobble_amp;
	uv.y += cos(uv.x * 15.0 + t * 1.65) * wobble_amp;
	return uv;
}

vec3 apply_hue_shift(vec3 rgb, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	mat3 mtx = mat3(
			vec3(0.213 + c * 0.787 - s * 0.213, 0.715 - c * 0.715 - s * 0.715, 0.072 - c * 0.072 + s * 0.928),
			vec3(0.213 - c * 0.213 + s * 0.143, 0.715 + c * 0.285 + s * 0.140, 0.072 - c * 0.072 - s * 0.283),
			vec3(0.213 - c * 0.213 - s * 0.787, 0.715 - c * 0.715 + s * 0.715, 0.072 + c * 0.928 + s * 0.072));
	return mtx * rgb;
}

vec3 push_saturation(vec3 rgb, float amount) {
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
	return clamp(mix(vec3(lum), rgb, amount), 0.0, 1.0);
}

vec3 rainbow_unit(float phase) {
	return 0.5 + 0.5 * cos(TAU * (vec3(0.0, 1.0 / 3.0, 2.0 / 3.0) + phase));
}

vec3 apply_spatial_rainbow(vec3 rgb, vec2 uv_sample, float th, vec2 vp) {
	float aspect_r = vp.x / max(vp.y, 1.0);
	vec2 pn = (uv_sample - 0.5) * vec2(aspect_r, 1.0);
	float ang = atan(pn.y, pn.x);
	float rad = length(pn);
	float phase = th * rainbow_flow
			+ dot(pn, vec2(1.85, 1.05)) * rainbow_scale
			+ rad * rainbow_scale * (1.05 + 0.4 * sin(th * 0.88))
			+ ang * rainbow_twirl
			+ 0.45 * sin(pn.x * rainbow_scale * 2.1 - th * 1.12)
			+ 0.35 * cos(pn.y * rainbow_scale * 1.7 + th * 0.97);
	vec3 rb = rainbow_unit(fract(phase * 0.1618));

	float lu = dot(rgb, vec3(0.299, 0.587, 0.114));
	float screen_gate = smoothstep(0.02, 0.55, lu);

	vec3 scr = 1.0 - (1.0 - clamp(rgb, 0.0, 1.0)) * (1.0 - clamp(rb, 0.0, 1.0));
	vec3 outc = mix(rgb, scr, rainbow_strength * 0.78 * screen_gate);

	float add_amp = rainbow_strength * (0.22 + 0.62 * screen_gate);
	outc = clamp(outc + (rb - vec3(0.5)) * add_amp * 1.65, 0.0, 1.0);

	return outc;
}

vec2 kaleido_fold_uv(vec2 uv, float t, float segs) {
	vec2 p = uv - 0.5;
	float aspect = viewport_pixels.x / max(viewport_pixels.y, 1.0);

	p.x *= aspect;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float segf = max(3.0, min(14.0, round(segs)));
	float wedge = TAU / segf;
	ang += t * kaleido_spin;
	ang = mod(ang, wedge);
	ang = abs(ang - wedge * 0.5);
	ang += sin(r * 21.0 + t * 1.3) * kaleido_radius_warp * kaleido_uv_mix;
	p = vec2(cos(ang), sin(ang)) * r;
	p.x /= aspect;
	return p + 0.5;
}

float kaleido_facets(vec2 uv, float t) {
	vec2 q = (uv - 0.5) * kaleido_line_freq;
	float tri = abs(fract(q.x + q.y * 0.8660254 + t * 0.07) - 0.5);
	float tri2 = abs(fract(q.y * 1.12 - t * 0.05) - 0.5);
	float ring = abs(fract(length(uv - 0.5) * 14.0 - t * 0.11) - 0.5);
	float lines = smoothstep(0.38, 0.5, tri) + smoothstep(0.38, 0.5, tri2) + smoothstep(0.42, 0.5, ring);
	return clamp(lines * 0.38, 0.0, 1.0);
}

void fragment() {
	float t = effect_time;
	vec2 uv_base = SCREEN_UV;
	vec3 baseline = textureLod(screen_texture, uv_base, 0.0).rgb;

	vec2 uv_w = wobble(uv_base, t);
	vec2 uv_fold = kaleido_fold_uv(clamp(uv_w, 0.001, 0.999), t, kaleido_segments);
	vec2 uv_samp = mix(uv_w, uv_fold, kaleido_uv_mix);

	vec2 o = chroma_amp * vec2(cos(t * 1.17 + sin(t * PHI * 0.31)), sin(t * 1.41 + cos(t * 0.58)));

	float r = textureLod(screen_texture, wobble(uv_samp + o, t), 0.0).r;
	float gch = textureLod(screen_texture, wobble(uv_samp, t), 0.0).g;
	float bch = textureLod(screen_texture, wobble(uv_samp - o * 1.08, t), 0.0).b;

	vec3 rgb = vec3(r, gch, bch);

	float facets = kaleido_facets(uv_fold, t);
	vec3 facet_tint = vec3(
			0.62 + 0.38 * sin(t * 1.83 + uv_fold.x * 14.2),
			0.58 + 0.42 * cos(t * 1.29 + uv_fold.y * 11.7),
			0.55 + 0.45 * sin(t * 1.51 + facets * 6.283));
	rgb += facet_tint * facets * kaleido_pattern_strength;

	float th = t * hue_time_scale;

	rgb *= vec3(
			0.93 + tint_strength * sin(th * (3.883 + PHI * 0.11)),
			0.93 + tint_strength * cos(th * PI * PHI * 0.79 + PHI * PHI),
			0.93 + tint_strength * sin(th * 2.119 + cos(th * PHI * 0.517) * 3.417));

	float hue_phi = th * hue_speed
			+ sin(th * PHI * 0.47) * hue_wobble * 0.55
			+ cos(th * 2.983 + PHI) * hue_wobble * 0.38
			+ sin(th * PHI * PHI * 0.21) * hue_wobble * 0.22;

	rgb = push_saturation(rgb, saturation_push);

	vec3 spun = apply_hue_shift(rgb, hue_phi);
	vec3 spun_b = apply_hue_shift(rgb, hue_phi * PHI + th / (7.17 + PHI));
	vec3 prism = mix(spun, spun_b, mix(0.22, 0.48, sin(th * 0.673) * 0.5 + 0.5));

	rgb = mix(rgb, prism, hue_amount);
	rgb = apply_spatial_rainbow(rgb, uv_samp, th, viewport_pixels);

	COLOR.rgb = mix(baseline, rgb, effect_strength);
	COLOR.a = 1.0;
}
