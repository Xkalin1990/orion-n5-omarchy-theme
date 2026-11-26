#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 color = texture(tex, v_texcoord);
    vec2 texel = 1.0 / vec2(textureSize(tex, 0));

    // Low-intensity two-ring phosphor bloom tuned for Orion N5
    vec3 innerBloom = vec3(0.0);
    vec2 innerOffsets[8] = vec2[8](
        vec2(-2.0,  0.0), vec2( 2.0,  0.0),
        vec2( 0.0, -2.0), vec2( 0.0,  2.0),
        vec2(-3.5, -3.5), vec2( 3.5, -3.5),
        vec2(-3.5,  3.5), vec2( 3.5,  3.5)
    );

    vec3 outerBloom = vec3(0.0);
    vec2 outerOffsets[8] = vec2[8](
        vec2(-6.5,  0.0), vec2( 6.5,  0.0),
        vec2( 0.0, -6.5), vec2( 0.0,  6.5),
        vec2(-8.5, -8.5), vec2( 8.5, -8.5),
        vec2(-8.5,  8.5), vec2( 8.5,  8.5)
    );

    for (int i = 0; i < 8; i++) {
        vec3 s1 = texture(tex, v_texcoord + innerOffsets[i] * texel).rgb;
        float e1 = dot(s1, vec3(0.299, 0.587, 0.114));
        innerBloom += s1 * smoothstep(0.18, 0.55, e1);

        vec3 s2 = texture(tex, v_texcoord + outerOffsets[i] * texel).rgb;
        float e2 = dot(s2, vec3(0.299, 0.587, 0.114));
        outerBloom += s2 * smoothstep(0.18, 0.55, e2);
    }
    vec3 bloom = (innerBloom / 8.0) * 0.65 + (outerBloom / 8.0) * 0.35;

    // Subtle cool sage-mint halo (#c4ddd0) at very low intensity
    vec3 sageTint = vec3(0.77, 0.90, 0.84);
    color.rgb += bloom * sageTint * 0.10;

    // Very subtle horizontal scanlines (~3% modulation)
    float scanline = 0.985 + 0.015 * sin(gl_FragCoord.y * 3.14159265);
    color.rgb *= scanline;

    // Very light edge vignette
    vec2 uv = v_texcoord * (1.0 - v_texcoord.yx);
    float vignette = clamp(pow(uv.x * uv.y * 16.0, 0.06), 0.95, 1.0);
    color.rgb *= vignette;

    fragColor = color;
}
