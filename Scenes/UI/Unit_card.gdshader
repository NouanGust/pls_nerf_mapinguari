shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    vec2 uv = UV - 0.5;
    vec2 abs_uv = abs(uv);
    vec2 q = abs_uv - 0.5 + radius;
    float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    
    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(tex.rgb, tex.a * smoothstep(0.01, 0.0, dist));
}