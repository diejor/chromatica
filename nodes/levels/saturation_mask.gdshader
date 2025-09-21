shader_type canvas_item;

// SubViewport texture (bind from GDScript)
uniform sampler2D mask_tex;

// Size of the mask texture in pixels (Vector2); set from GDScript
uniform vec2 mask_tex_size = vec2(1.0, 1.0);

// How strong to desaturate where the mask is "off"
uniform float desat_strength : hint_range(0.0, 1.0) = 1.0;

// Read alpha (true) or red channel (false)
uniform bool mask_uses_alpha = true;

// Transition window (center/width within 0..1 mask space)
uniform float thresh_center : hint_range(0.0, 1.0) = 0.5;
uniform float thresh_width  : hint_range(0.0, 1.0) = 0.2;

// Blend between hard and soft edges
uniform float hard_soft_mix : hint_range(0.0, 1.0) = 1.0;

// Curve response
uniform float gamma : hint_range(0.2, 5.0) = 1.0;

// Extra screen-space feathering (in pixels)
uniform float edge_softness_px : hint_range(0.0, 4.0) = 1.0;

float read_mask(vec2 suv) {
    vec4 c = texture(mask_tex, suv);
    return mask_uses_alpha ? c.a : c.r; // 1 = keep color, 0 = desat
}

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    float gray = dot(base.rgb, vec3(0.299, 0.587, 0.114));

    // Map pixel coords directly to mask texture UVs
    // FRAGCOORD.xy is in pixels of the current viewport/backbuffer.
    vec2 suv = FRAGCOORD.xy / mask_tex_size;

    float a = clamp(read_mask(suv), 0.0, 1.0);

    // Transition window
    float halfw = max(1e-5, thresh_width * 0.5);
    float lo = clamp(thresh_center - halfw, 0.0, 1.0);
    float hi = clamp(thresh_center + halfw, 0.0, 1.0);

    // Hard edge (binary)
    float m_hard = step((lo + hi) * 0.5, a);

    // Soft edge with derivative-based feather (in pixels)
    float pxw = fwidth(a) * edge_softness_px;
    float m_soft = smoothstep(lo - pxw, hi + pxw, a);

    // Blend hard/soft, then curve
    float m = mix(m_hard, m_soft, hard_soft_mix);
    m = pow(clamp(m, 0.0, 1.0), gamma);

    // m=1 → keep color; m=0 → desaturate by desat_strength
    float keep = m + (1.0 - m) * (1.0 - desat_strength);
    vec3 final_rgb = mix(vec3(gray), base.rgb, keep);

    COLOR = vec4(final_rgb, base.a);
}
