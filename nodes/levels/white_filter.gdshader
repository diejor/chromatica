shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	//COLOR = vec4(c.x, 0.0, 0., 1.);
	COLOR = vec4(0.0, c.y, 0., 1.);
	COLOR = vec4(0.0, 0.0, c.z, 1.);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
