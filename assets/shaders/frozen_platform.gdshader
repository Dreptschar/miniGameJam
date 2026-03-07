shader_type canvas_item;

uniform vec4 freeze_tint : source_color = vec4(0.35, 0.35, 0.38, 1.0);
uniform float freeze_amount : hint_range(0.0, 1.0) = 0.0;
uniform float darken_strength : hint_range(0.0, 1.0) = 0.28;
uniform float desaturate_strength : hint_range(0.0, 1.0) = 0.22;
uniform float accent_strength : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = vec3(luminance);
	vec3 desaturated = mix(tex.rgb, grayscale, freeze_amount * desaturate_strength);
	vec3 frozen = mix(desaturated, freeze_tint.rgb, freeze_amount * accent_strength);
	frozen *= 1.0 - freeze_amount * darken_strength;

	COLOR = vec4(frozen, tex.a);
}
