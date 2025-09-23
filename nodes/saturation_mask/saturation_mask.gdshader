shader_type canvas_item;

// ===== mask input =====
uniform sampler2D mask_tex;
uniform bool mask_flip_y = false;

// ===== desat controls =====
uniform float desat_strength : hint_range(0.0, 2.0) = 1.0;
uniform bool  mask_uses_alpha = true;
uniform float thresh_center : hint_range(0.0, 1.0) = 0.5;
uniform float thresh_width  : hint_range(0.0, 1.0) = 0.2;
uniform float hard_soft_mix : hint_range(0.0, 1.0) = 1.0;
uniform float gamma         : hint_range(0.2, 5.0) = 1.0;
uniform float edge_softness_px : hint_range(0.0, 4.0) = 1.0;

// Inside the mask, optionally ignore modulate (and force opaque)
uniform bool keep_ignore_modulate = false;

// Only invert where modulate applies; desaturation still applies outside the (non-inverted) mask
uniform bool invert_mask = false;

float read_mask(vec2 uv) {
    vec4 c = texture(mask_tex, uv);
    return mask_uses_alpha ? c.a : c.r; // 1 = inside, 0 = outside
}

float mask_factor_from_screen_uv(vec2 fragcoord_xy) {
    vec2 mask_sz = vec2(textureSize(mask_tex, 0));
    vec2 mask_uv = fragcoord_xy / mask_sz;
    if (mask_flip_y) mask_uv.y = 1.0 - mask_uv.y;

    float a = clamp(read_mask(mask_uv), 0.0, 1.0);

    float halfw = max(1e-5, thresh_width * 0.5);
    float lo = clamp(thresh_center - halfw, 0.0, 1.0);
    float hi = clamp(thresh_center + halfw, 0.0, 1.0);

    float m_hard = step((lo + hi) * 0.5, a);
    float pxw    = fwidth(a) * edge_softness_px;
    float m_soft = smoothstep(lo - pxw, hi + pxw, a);

    float m = mix(m_hard, m_soft, hard_soft_mix);
    return pow(clamp(m, 0.0, 1.0), gamma); // 1 = inside, 0 = outside
}

void fragment() {
    vec4 tex    = texture(TEXTURE, UV);
    vec4 modcol = COLOR;

    float m = mask_factor_from_screen_uv(FRAGCOORD.xy);      // for desaturation (outside gets desat)
    float m_mod = invert_mask ? (1.0 - m) : m;               // where modulate rule applies

    vec4 base = modcol;
    if (keep_ignore_modulate) {
        vec4 unmod = vec4(tex.rgb, 1.0);
        base = mix(modcol, unmod, m_mod);                   // ignore modulate where m_mod=1
    }

    float gray = dot(base.rgb, vec3(0.299, 0.587, 0.114));
    float keep_amt = m + (1.0 - m) * (1.0 - desat_strength);
    vec3 final_rgb = mix(vec3(gray), base.rgb, keep_amt);

    COLOR = vec4(final_rgb, base.a);
}

void light() {
    float m = mask_factor_from_screen_uv(FRAGCOORD.xy);      // desaturation region unchanged
    vec3 neutral_white = vec3(1.0);
    vec3 effective_light_rgb = mix(neutral_white, LIGHT_COLOR.rgb, m);
    LIGHT = vec4(effective_light_rgb * COLOR.rgb * LIGHT_ENERGY, LIGHT_COLOR.a);
}
