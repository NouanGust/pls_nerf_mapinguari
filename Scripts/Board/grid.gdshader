shader_type spatial;

uniform vec3 background_color : source_color = vec3(0.1,0.1,0.1);
uniform vec3 grid_color : source_color = vec3(0.5,0.5,0.5);
uniform vec3 player_zone_color : source_color = vec3(0.1,0.3,0.6);
uniform vec3 enemy_zone_color : source_color = vec3(0.6,0.1,0.1);
uniform vec2 hover_pos = vec2(-1.0, -1.0);

uniform float line_thickness : hint_range(0.01, 0.1) = 0.03;
uniform float grid_size = 2.2;
uniform vec2 board_dimensions;
uniform float player_rows;

varying vec3 world_position;


void vertex() {
	// Called for every vertex the material is visible on.
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Called for every pixel the material is visible on.
	// Localizar as posições do board
	vec2 pos = world_position.xz + (board_dimensions * grid_size * 0.5);
	vec2 grid = abs(fract(pos/grid_size -0.5) -0.5) / fwidth(pos/grid_size);
	float line = min(grid.x, grid.y);
	float grid_line = 1.0 - smoothstep(0.0, line_thickness, line);
	
	// Definir cores
	float current_row = floor(pos.y/grid_size);
	vec3 zone_color = (current_row < (board_dimensions.y - player_rows)) ? enemy_zone_color : player_zone_color;
	
	// Mix de fundo + cor suave
	vec3 final_color = mix(background_color, zone_color, 0.15);
	final_color = mix(final_color, grid_color, grid_line * 0.5);
	
	// Hover 
	vec2 current_cell = floor(pos/grid_size);
	if (current_cell == hover_pos){
		ALBEDO += vec3(0.3, 0.3, 0.1); // Destaque amarelado suave
        EMISSION = vec3(0.2, 0.2, 0.0);
	}
	
	ALBEDO = final_color;
	ALPHA = 0.9;
	
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
