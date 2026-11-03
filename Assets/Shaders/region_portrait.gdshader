shader_type canvas_item;

uniform vec4 ring_color : source_color = vec4(0.85, 0.72, 0.47, 1.0);

void fragment() {
	vec4 portrait = texture(TEXTURE, UV);
	float radius = length(UV - vec2(0.5));
	float mask = 1.0 - smoothstep(0.485, 0.495, radius);
	float ring = smoothstep(0.465, 0.475, radius);
	COLOR = vec4(mix(portrait.rgb, ring_color.rgb, ring), mask * COLOR.a);
}
