shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.76, 0.25, 1.0);
uniform vec2 card_size = vec2(110.0, 230.0);
uniform float speed : hint_range(0.1, 3.0) = 0.65;

void fragment() {
	float inherited_alpha = COLOR.a;
	vec2 edge_px = min(UV, vec2(1.0) - UV) * max(card_size, vec2(1.0));
	float edge_distance = min(edge_px.x, edge_px.y);
	float rim = 1.0 - smoothstep(1.0, 3.5, edge_distance);
	float halo = exp(-edge_distance * 0.22);
	float pulse = 0.65 + 0.35 * sin(TIME * 2.8);
	float orbit = pow(0.5 + 0.5 * sin((UV.x + UV.y) * 9.0 - TIME * 4.0), 6.0);
	float sweep_pos = fract(TIME * speed) * 1.8 - 0.4;
	float sweep = 1.0 - smoothstep(0.0, 0.065, abs(UV.y + UV.x * 0.25 - sweep_pos));
	float alpha = rim * (0.5 + 0.35 * pulse) + halo * orbit * 0.35 + sweep * 0.1;
	vec3 tint = mix(glow_color.rgb, vec3(1.0), orbit * 0.35);
	COLOR = vec4(tint, clamp(alpha, 0.0, 0.95) * glow_color.a * inherited_alpha);
}
