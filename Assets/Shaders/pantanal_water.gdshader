shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Cores da água de baía/corixo do Pantanal ao crepúsculo
uniform vec4 deep_color : source_color = vec4(0.02, 0.08, 0.10, 0.92);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.18, 0.16, 0.78);
uniform vec4 foam_color : source_color = vec4(0.55, 0.52, 0.42, 0.55);

// Propriedades físicas da superfície da água
uniform float metallic : hint_range(0.0, 1.0) = 0.05;
uniform float roughness : hint_range(0.0, 1.0) = 0.06; // Superfície espelhada de baía calma
uniform float specular : hint_range(0.0, 1.0) = 0.96;

// Fluxo suave de meandro pantaneiro
uniform vec2 flow_direction = vec2(0.2, 0.95);
uniform float flow_speed : hint_range(0.0, 2.0) = 0.25;
uniform float wave_height : hint_range(0.0, 0.12) = 0.016;
uniform float wave_frequency : hint_range(0.1, 8.0) = 2.0;

// Profundidade e transição de margens
uniform float depth_distance : hint_range(0.05, 3.0) = 0.85;
uniform float foam_edge_distance : hint_range(0.01, 0.5) = 0.12;

// Reflexo crepuscular (brilho dourado/rosado do poente)
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.2;
uniform vec3 sunset_tint : source_color = vec3(0.96, 0.54, 0.26);
uniform float sunset_reflection_strength : hint_range(0.0, 2.0) = 0.55;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Ondulações procedurais analíticas
float wave(vec2 pos, float time, vec2 dir, float freq, float speed) {
	return sin(dot(pos, dir) * freq + time * speed);
}

float get_wave_height(vec2 world_xz, float time) {
	vec2 fdir = normalize(flow_direction);
	vec2 cross_dir = vec2(-fdir.y, fdir.x);
	
	float w1 = wave(world_xz, time, fdir, wave_frequency, flow_speed * 2.6);
	float w2 = wave(world_xz, time, fdir * 0.85 + cross_dir * 0.15, wave_frequency * 1.6, flow_speed * 3.2);
	float w3 = wave(world_xz, time, fdir * 1.20 - cross_dir * 0.28, wave_frequency * 2.7, flow_speed * 4.0);
	
	return (w1 * 0.55 + w2 * 0.30 + w3 * 0.15) * wave_height;
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = get_wave_height(world_pos.xz, TIME);
	VERTEX.y += h;
	
	float delta = 0.04;
	float h_x = get_wave_height(world_pos.xz + vec2(delta, 0.0), TIME);
	float h_z = get_wave_height(world_pos.xz + vec2(0.0, delta), TIME);
	
	vec3 tangent_x = vec3(delta, h_x - h, 0.0);
	vec3 tangent_z = vec3(0.0, h_z - h, delta);
	vec3 normal_comp = normalize(cross(tangent_z, tangent_x));
	NORMAL = normalize((MODEL_NORMAL_MATRIX * normal_comp));
}

void fragment() {
	// 1. Cálculo de profundidade linear na câmera
	float depth_raw = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
	vec3 pixel_pos = upos.xyz / upos.w;
	float scene_depth = -pixel_pos.z;
	float surface_depth = -VERTEX.z;
	float depth_diff = max(0.0, scene_depth - surface_depth);
	
	// 2. Transição pela profundidade
	float depth_factor = clamp(depth_diff / depth_distance, 0.0, 1.0);
	vec4 water_color = mix(shallow_color, deep_color, depth_factor);
	
	// 3. Efeito Fresnel refletindo o horizonte poente
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, fresnel_power);
	
	// 4. Espuma suave e lodo orgânico nas margens
	float foam_factor = 1.0 - clamp(depth_diff / foam_edge_distance, 0.0, 1.0);
	foam_factor = pow(foam_factor, 1.7);
	
	vec3 world_coords = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float ripple = sin(world_coords.x * 9.0 + TIME * 2.2) * cos(world_coords.z * 7.5 + TIME * 1.8);
	foam_factor = clamp(foam_factor + ripple * 0.10 * foam_factor, 0.0, 1.0);
	
	vec3 final_albedo = mix(water_color.rgb, foam_color.rgb, foam_factor * foam_color.a);
	// Tinge a água em ângulo rasante com o reflexo quente do pôr do sol
	final_albedo = mix(final_albedo, sunset_tint, fresnel * sunset_reflection_strength);
	
	ALBEDO = final_albedo;
	// Toque suave de reflexo especular emitido na crista das ondas
	EMISSION = sunset_tint * fresnel * 0.10;
	METALLIC = metallic;
	ROUGHNESS = mix(roughness, 0.45, foam_factor);
	SPECULAR = specular;
	ALPHA = mix(water_color.a, 0.98, foam_factor);
}
