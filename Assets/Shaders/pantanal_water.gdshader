shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Cores da água pantaneira noturna sob a luz da lua (Pântano Lunar)
uniform vec4 deep_color : source_color = vec4(0.010, 0.032, 0.042, 0.96);
uniform vec4 shallow_color : source_color = vec4(0.024, 0.052, 0.058, 0.85);
uniform vec4 foam_color : source_color = vec4(0.18, 0.25, 0.30, 0.25);

// Propriedades físicas da água: superfície calma e espelhada refletindo o luar
uniform float metallic : hint_range(0.0, 1.0) = 0.02;
uniform float roughness : hint_range(0.0, 1.0) = 0.04;
uniform float specular : hint_range(0.0, 1.0) = 0.98;

// Ondulações suaves da correnteza pantaneira
uniform vec2 flow_direction = vec2(0.2, 0.95);
uniform float flow_speed : hint_range(0.0, 2.0) = 0.18;
uniform float wave_height : hint_range(0.0, 0.12) = 0.010;
uniform float wave_frequency : hint_range(0.1, 8.0) = 1.8;

// Profundidade e transição de margens
uniform float depth_distance : hint_range(0.05, 3.0) = 0.80;
uniform float foam_edge_distance : hint_range(0.005, 0.2) = 0.03;

// Reflexo de Luar e Fresnel (brilho prateado suave nas cristas)
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.8;
uniform vec3 moonlight_tint : source_color = vec3(0.40, 0.65, 0.85);
uniform float moonlight_boost : hint_range(0.0, 2.0) = 0.28;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

float wave(vec2 pos, float time, vec2 dir, float freq, float speed) {
	return sin(dot(pos, dir) * freq + time * speed);
}

float get_wave_height(vec2 world_xz, float time) {
	vec2 fdir = normalize(flow_direction);
	vec2 cross_dir = vec2(-fdir.y, fdir.x);
	
	float w1 = wave(world_xz, time, fdir, wave_frequency, flow_speed * 2.2);
	float w2 = wave(world_xz, time, fdir * 0.85 + cross_dir * 0.15, wave_frequency * 1.6, flow_speed * 2.8);
	float w3 = wave(world_xz, time, fdir * 1.20 - cross_dir * 0.28, wave_frequency * 2.4, flow_speed * 3.4);
	
	return (w1 * 0.60 + w2 * 0.28 + w3 * 0.12) * wave_height;
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
	NORMAL = normalize(MODELVIEW_NORMAL_MATRIX * normal_comp);
}

void fragment() {
	float depth_raw = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	float depth_factor = 1.0;
	float foam_factor = 0.0;
	
	if (depth_raw > 0.0001 && depth_raw < 0.9999) {
		vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
		if (abs(upos.w) > 0.0001) {
			vec3 pixel_pos = upos.xyz / upos.w;
			float scene_depth = -pixel_pos.z;
			float surface_depth = -VERTEX.z;
			float depth_diff = scene_depth - surface_depth;
			if (depth_diff > 0.0) {
				depth_factor = clamp(depth_diff / depth_distance, 0.0, 1.0);
				if (depth_diff < foam_edge_distance) {
					foam_factor = 1.0 - (depth_diff / foam_edge_distance);
					foam_factor = pow(foam_factor, 2.0);
				}
			}
		}
	}
	
	vec4 water_color = mix(shallow_color, deep_color, depth_factor);
	
	// Efeito Fresnel no Albedo (reflexo de superfície, sem glow artificial de emission)
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, fresnel_power);
	vec3 moonlit_water = mix(water_color.rgb, moonlight_tint, fresnel * moonlight_boost);
	vec3 final_albedo = mix(moonlit_water, foam_color.rgb, foam_factor * foam_color.a);
	
	ALBEDO = final_albedo;
	METALLIC = metallic;
	ROUGHNESS = mix(roughness, 0.22, foam_factor);
	SPECULAR = specular;
	ALPHA = water_color.a;
}
