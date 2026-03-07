shader_type canvas_item;

// The color of the gleam (we will change this from code)
uniform vec4 gleam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Controls the position of the gleam. Tween this from -0.5 to 1.5 to sweep across.
uniform float progress : hint_range(-0.5, 1.5) = -0.5;

// How wide the gleam is
uniform float width : hint_range(0.0, 1.0) = 0.2;

// The angle of the gleam line
uniform float angle : hint_range(0.0, 90.0) = 45.0;

void fragment() {
	// 1. Get the original texture color
	vec4 tex_color = texture(TEXTURE, UV);

	// 2. Calculate the angled coordinates
	float rad = radians(angle);
	float x = UV.x * cos(rad) - UV.y * sin(rad);

	// 3. Calculate how close the current pixel is to the 'progress' line
	float dist = abs(x - progress);

	// 4. Create a smooth gradient for the gleam band
	float gleam_intensity = smoothstep(width, 0.0, dist);

	// 5. Add the gleam to the original color, multiplied by the original alpha
	// to ensure it skips transparent pixels smoothly!
	COLOR.rgb = tex_color.rgb + (gleam_color.rgb * gleam_intensity * gleam_color.a);
	COLOR.a = tex_color.a;
}