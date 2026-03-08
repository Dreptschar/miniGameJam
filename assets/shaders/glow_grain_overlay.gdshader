shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float grain_strength : hint_range(0.0, 0.4) = 0.09;
uniform float grain_scale : hint_range(20.0, 600.0) = 240.0;
uniform float grain_speed : hint_range(0.0, 8.0) = 1.6;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.58;
uniform float glow_softness : hint_range(0.0, 0.5) = 0.18;
uniform vec3 grain_tint : source_color = vec3(0.90, 0.96, 1.0);

float hash_2d(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 src = textureLod(screen_texture, uv, 0.0);

	float luma = dot(src.rgb, vec3(0.2126, 0.7152, 0.0722));
	float glow_mask = smoothstep(glow_threshold - glow_softness, glow_threshold + glow_softness, luma);

	vec2 noise_uv = floor(uv * grain_scale + vec2(TIME * grain_speed, -TIME * grain_speed * 0.73));
	float grain = hash_2d(noise_uv) * 2.0 - 1.0;
	vec3 grain_rgb = grain_tint * grain * grain_strength * glow_mask;

	COLOR = vec4(clamp(src.rgb + grain_rgb, 0.0, 1.0), src.a);
}
