shader_type canvas_item;

uniform float max_desaturation : hint_range(0.0, 2.0) = 1.0;  // Maximum desaturation factor
uniform float max_distance : hint_range(0.0, 1000.0) = 200.0;  // Maximum distance where full desaturation occurs

void light() {
    vec4 base_color = texture(TEXTURE, UV);
    float gray = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
    
    if (LIGHT_IS_DIRECTIONAL) {
        base_color.rgb = mix(base_color.rgb, vec3(gray, gray, gray), max_desaturation);
    }
    
    if (!LIGHT_IS_DIRECTIONAL) {
        float distance = length(LIGHT_POSITION.xyz - FRAGCOORD.xyz);
        float distance_factor = clamp(distance / max_distance, 0.0, 1.0);
        float desaturation = distance_factor * max_desaturation;
        base_color.rgb = mix(base_color.rgb, vec3(gray, gray, gray), desaturation);
    }
    
    base_color.rgb *= LIGHT_COLOR.rgb * LIGHT_ENERGY;
    LIGHT.rgba = vec4(base_color.rgb, 1.0);
}
