shader_type canvas_item;

// Dark outline and drop shadow of the letters of title.png, so the animated
// characters of the menu look drawn with the title.

uniform vec4 outline_color : source_color = vec4(0.039, 0.055, 0.165, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.129, 0.22, 1.0);
// In texels of the sprite
uniform vec2 shadow_offset = vec2(1.0, 1.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (color.a < 0.5) {
		vec2 tx = vec2(TEXTURE_PIXEL_SIZE.x, 0.0);
		vec2 ty = vec2(0.0, TEXTURE_PIXEL_SIZE.y);
		// Sprite grown by one texel
		float outline = max(max(texture(TEXTURE, UV + tx).a, texture(TEXTURE, UV - tx).a),
				max(texture(TEXTURE, UV + ty).a, texture(TEXTURE, UV - ty).a));
		// Same outlined shape, shifted
		vec2 s = UV - shadow_offset * TEXTURE_PIXEL_SIZE;
		float shadow = max(texture(TEXTURE, s).a,
				max(max(texture(TEXTURE, s + tx).a, texture(TEXTURE, s - tx).a),
				max(texture(TEXTURE, s + ty).a, texture(TEXTURE, s - ty).a)));
		if (outline > 0.5) {
			color = outline_color;
		} else if (shadow > 0.5) {
			color = shadow_color;
		}
	}
	COLOR = color;
}
