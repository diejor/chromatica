shader_type canvas_item;

// 1. How far you're willing to push desaturation where the mask is dark.
//    0.0 = never desaturate, 1.0 = full to grayscale, >1.0 = extra push.
uniform float max_desaturation : hint_range(0.0, 2.0) = 1.0;

// Optional shaping: <1.0 makes the mask brighten (less desat overall),
// >1.0 makes the mask darker (more desat where it's not white).
uniform float mask_contrast : hint_range(0.1, 4.0) = 1.0;

float luma(vec3 c) {
    // Perceptual luminance for desaturation target and mask readback
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void light() {
    vec4 base = texture(TEXTURE, UV);

    // What "full desaturation" would look like at this pixel
    float base_gray = luma(base.rgb);

    // Use the light's color as a mask (includes any Light2D texture/attenuation the engine gives us).
    // Black -> 0.0, White -> 1.0 (after contrast shaping).
    float mask = clamp(luma(LIGHT_COLOR.rgb), 0.0, 1.0);
    mask = pow(mask, mask_contrast);

    // Where mask is 0 → desat = max; where mask is 1 → desat = 0
    float desat = (1.0 - mask) * max_desaturation;

    vec3 out_rgb = mix(base.rgb, vec3(base_gray), desat);

    // Important: we do NOT multiply by LIGHT_COLOR or LIGHT_ENERGY.
    LIGHT = vec4(out_rgb, base.a);
}
