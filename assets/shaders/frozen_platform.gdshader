shader_type canvas_item;

uniform vec4 freeze_tint : source_color = vec4(0.35, 0.35, 0.38, 1.0);
uniform float freeze_amount : hint_range(0.0, 1.0) = 0.0;
uniform float darken_strength : hint_range(0.0, 1.0) = 0.28;
uniform float desaturate_strength : hint_range(0.0, 1.0) = 0.22;
uniform float accent_strength : hint_range(0.0, 1.0) = 0.18;
uniform int stripe_color_count = 1;
uniform vec4 stripe_colors[4];
uniform float stripe_frozen[4];

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	int safe_color_count = max(stripe_color_count, 1);
	float stripe_index_float = floor(clamp(UV.x, 0.0, 0.9999) * float(safe_color_count));
	int stripe_index = int(clamp(stripe_index_float, 0.0, float(safe_color_count - 1)));
	vec3 stripe_color = stripe_colors[stripe_index].rgb;
	float local_freeze_amount = freeze_amount * stripe_frozen[stripe_index];
	vec3 base_color = tex.rgb * stripe_color * COLOR.rgb;
	float alpha = tex.a * COLOR.a;
	float luminance = dot(base_color, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = vec3(luminance);
	vec3 desaturated = mix(base_color, grayscale, local_freeze_amount * desaturate_strength);
	vec3 frozen = mix(desaturated, freeze_tint.rgb, local_freeze_amount * accent_strength);
	frozen *= 1.0 - local_freeze_amount * darken_strength;

	COLOR = vec4(frozen, alpha);
}
