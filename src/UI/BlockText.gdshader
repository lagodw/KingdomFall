shader_type canvas_item;

// The texture to use for the text fill
uniform sampler2D text_texture : source_color;
// Tiling scale for the texture
uniform float texture_scale = 1.0;

void fragment() {
    // Current fragment's UV coordinates for the text object
    vec2 uv = UV;
    
    // Scale the UV for tiling the texture
    uv *= texture_scale;

    // Get the color of the background (the text that's about to be drawn)
    // The COLOR variable holds the color that the control node (Label) is trying to draw.
    // When drawing text, the built-in fragment() function's COLOR.a will contain the
    // alpha of the text shape, and COLOR.rgb will contain the font's color.
    vec4 text_color = COLOR;
    
    // Sample the texture at the modified UV
    vec4 texture_color = texture(text_texture, uv);

    // Use the texture color's RGB and the text color's Alpha
    // This essentially masks the texture with the shape of the rendered text.
    // If the text has high alpha (it's part of the letter), the texture color shows.
    // If the text has zero alpha (it's background), nothing shows.
    COLOR.rgb = texture_color.rgb;
    COLOR.a = text_color.a;

    // Optional: Add the text's original color as a tint for more control
    // COLOR.rgb *= text_color.rgb;
}