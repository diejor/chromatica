shader_type canvas_item;

// ===== mask input =====
uniform sampler2D mask_tex;
uniform bool mask_flip_y = false; // flip if your SubViewport is upside-down

// ===== desat controls =====
uniform float desat_strength : hint_range(0.0, 1.0) = 1.0;
uniform bool  mask_uses_alpha = true;
uniform float thresh_center : hint_range(0.0, 1.0) = 0.5;
uniform float thresh_width  : hint_range(0.0, 1.0) = 0.2;
uniform float hard_soft_mix : hint_range(0.0, 1.0) = 1.0;
uniform float gamma         : hint_range(0.2, 5.0) = 1.0;
uniform float edge_softness_px : hint_range(0.0, 4.0) = 1.0;

// ===== new: modulation policy =====
// If true: apply TileMap/CanvasItem modulate ONLY where we desaturate;
//          where we keep color, ignore modulate (use bare texture).
// If false: behave normally (always include modulate via COLOR).
uniform bool modulate_only_when_desat = true;

float read_mask(vec2 uv) {
    vec4 c = texture(mask_tex, uv);
    return mask_uses_alpha ? c.a : c.r; // 1 = keep color, 0 = desat
}

void fragment() {
    // --- sample the default texture and the modulated color ---
    vec4 tex  = texture(TEXTURE, UV); // bare texture (no modulate)
    vec4 col_in = COLOR;              // includes TileMap/CanvasItem modulate * tex

    // --- mask sampling in SubViewport (screen) space ---
    vec2 mask_sz = vec2(textureSize(mask_tex, 0));
    vec2 mask_uv = FRAGCOORD.xy / mask_sz;
    if (mask_flip_y) mask_uv.y = 1.0 - mask_uv.y;
    float a = clamp(read_mask(mask_uv), 0.0, 1.0);

    // --- threshold window & edge shaping ---
    float halfw = max(1e-5, thresh_width * 0.5);
    float lo = clamp(thresh_center - halfw, 0.0, 1.0);
    float hi = clamp(thresh_center + halfw, 0.0, 1.0);
    float m_hard = step((lo + hi) * 0.5, a);
    float pxw    = fwidth(a) * edge_softness_px;
    float m_soft = smoothstep(lo - pxw, hi + pxw, a);
    float m = mix(m_hard, m_soft, hard_soft_mix);   // m ~ 1 => keep color, m ~ 0 => desat
    m = pow(clamp(m, 0.0, 1.0), gamma);

    // --- choose the base color according to the modulation policy ---
    // apply_mod is how strongly we use the *modulated* color; the complement uses bare texture.
    float apply_mod = modulate_only_when_desat ? (1.0 - m) : 1.0;
    vec4 base = mix(tex, col_in, apply_mod);

    // --- luminance & desaturation mix ---
    float gray = dot(base.rgb, vec3(0.299, 0.587, 0.114));
    // "keep" is the effective color-retention after desat_strength
    float keep = m + (1.0 - m) * (1.0 - desat_strength);
    vec3 final_rgb = mix(vec3(gray), base.rgb, keep);

    COLOR = vec4(final_rgb, base.a);
}
