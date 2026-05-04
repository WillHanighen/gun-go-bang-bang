shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float effect_time : hint_range(0.0, 100000.0) = 0.0;

const float PHI = 1.61803398875;

// How strongly the distorted pass replaces the raw frame (lower = more readable).
uniform float effect_strength : hint_range(0.0, 1.0) = 0.45;

uniform float wobble_amp : hint_range(0.0, 0.06) = 0.014;
uniform float chroma_amp : hint_range(0.0, 0.024) = 0.0045;

uniform float hue_speed : hint_range(0.0, 3.0) = 0.18;

// Scales ALL hue-phase motion (overall drift feels ~1 / value). Lower = lazier rainbow crawl.
uniform float hue_time_scale : hint_range(0.12, 1.35) = 0.38;
uniform float hue_amount : hint_range(0.0, 1.0) = 0.7;

uniform float saturation_push : hint_range(1.0, 2.2) = 1.52;

// Extra hue jitter in radians (time only — no radial/UV swirl).
uniform float hue_wobble : hint_range(0.0, 6.283) = 1.45;

uniform float tint_strength : hint_range(0.0, 0.22) = 0.12;

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

void fragment() {
	float t = effect_time;
	vec2 uv_base = SCREEN_UV;
	vec3 baseline = textureLod(screen_texture, uv_base, 0.0).rgb;

	vec2 o = chroma_amp * vec2(cos(t * 1.17 + sin(t * PHI * 0.31)), sin(t * 1.41 + cos(t * 0.58)));

	float r = textureLod(screen_texture, wobble(uv_base + o, t), 0.0).r;
	float gch = textureLod(screen_texture, wobble(uv_base, t), 0.0).g;
	float bch = textureLod(screen_texture, wobble(uv_base - o * 1.08, t), 0.0).b;

	vec3 rgb = vec3(r, gch, bch);

	// Time-only tint phases — extra spectrum without UV/radial swirls.
	float th = t * hue_time_scale;

	// Tint follows same slower clock so punchy hues do not sprint past.
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

	COLOR.rgb = mix(baseline, rgb, effect_strength);
	COLOR.a = 1.0;
}
