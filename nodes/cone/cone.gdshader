shader_type canvas_item;

uniform float cone_angle_deg : hint_range(0.0, 180.); // Control the angle of the cone
uniform float falloff_distance : hint_range(0.0, 2.0); // Control the falloff intensity
uniform vec4 base_color : source_color; // Color for the cone texture

void fragment() {
    vec2 start = vec2(0.0, 0.5);
    
    float cone_angle_rad = radians(cone_angle_deg);
    // Calculate angle of the cone in the X and Y axes
    vec2 relative_pos = UV - start;
    float angle = atan(relative_pos.y, relative_pos.x);
    
    // Normalize the distance from the center
    float dist = length(relative_pos);

    // Apply a falloff effect based on distance and angle, reverse smoothstep range
    float alpha = smoothstep(falloff_distance, 0.0, dist) * (1.0 - abs(angle) / cone_angle_rad);
    
    // Set the final color based on the base color and falloff
    COLOR = base_color * alpha;
}
