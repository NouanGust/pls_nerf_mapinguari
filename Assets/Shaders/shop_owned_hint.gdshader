shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(0.24, 0.82, 0.95, 0.85);
uniform vec2 card_size = vec2(110.0, 230.0);
uniform float speed : hint_range(0.1, 3.0) = 0.5;

void fragment() {
	float inherited_alpha = COLOR.a;
	vec2 edge_px = min(UV, vec2(1.0) - UV) * max(card_size, vec2(1.0));
	float edge_distance = min(edge_px.x, edge_px.y);
	
	// Borda fina luminosa nas extremidades da carta
	float rim = 1.0 - smoothstep(1.0, 3.2, edge_distance);
	float halo = exp(-edge_distance * 0.26);
	
	// Pulso suave
	float pulse = 0.70 + 0.30 * sin(TIME * 2.2);
	
	// Efeito de brilho percorrendo a borda e cantos
	float corner_dist = length(min(UV, vec2(1.0) - UV));
	float corner_glow = exp(-corner_dist * 8.0) * 0.4;
	
	// Varredura diagonal suave
	float sweep_pos = fract(TIME * speed) * 1.8 - 0.4;
	float sweep = 1.0 - smoothstep(0.0, 0.05, abs(UV.y + UV.x * 0.35 - sweep_pos));
	
	float alpha = rim * (0.55 + 0.30 * pulse) + halo * 0.25 + corner_glow + sweep * 0.12;
	vec3 tint = mix(glow_color.rgb, vec3(1.0), sweep * 0.45);
	
	COLOR = vec4(tint, clamp(alpha, 0.0, 0.90) * glow_color.a * inherited_alpha);
}
