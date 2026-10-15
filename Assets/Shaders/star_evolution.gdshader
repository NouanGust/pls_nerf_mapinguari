shader_type spatial;
render_mode depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.58, 0.72, 0.9, 1.0);
uniform vec4 burst_color : source_color = vec4(1.0, 0.82, 0.38, 1.0);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform float shimmer_speed : hint_range(0.0, 20.0) = 8.0;

void fragment() {
	float shimmer = 0.5 + 0.5 * sin(UV.y * 18.0 - TIME * shimmer_speed + UV.x * 7.0);
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.0);
	float light_band = clamp((0.25 + shimmer * 0.45 + rim * 0.35) * flash_strength, 0.0, 1.0);

	ALBEDO = mix(base_color.rgb, burst_color.rgb, light_band);
	METALLIC = 0.2 + 0.35 * flash_strength;
	ROUGHNESS = 0.38 - 0.16 * flash_strength;
	EMISSION = burst_color.rgb * flash_strength * (0.4 + rim * 1.6);
}
