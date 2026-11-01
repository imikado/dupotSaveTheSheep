shader_type canvas_item;

// 1px outline around the sprite so gameplay elements stand out from the decor.
// The outline adapts to what is behind it: on a dark background it is a light
// halo, on a bright background a dark rim, both tinted by the faction color.
// Edges already drawn with a dark hand-made outline get no extra outline.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Faction tint used on dark backgrounds (light halo)
uniform vec4 light_color : source_color = vec4(0.62, 0.68, 0.85, 1.0);
// Faction tint used on bright backgrounds (dark rim)
uniform vec4 dark_color : source_color = vec4(0.08, 0.06, 0.12, 1.0);
// Opacity of the outline on dark / bright backgrounds
uniform float light_strength : hint_range(0.0, 1.0) = 0.35;
uniform float dark_strength : hint_range(0.0, 1.0) = 0.5;
// Background luminance above which the dark rim is used
uniform float bright_threshold : hint_range(0.0, 1.0) = 0.12;
// Sprite edge pixels darker than this count as a hand-drawn outline
uniform float drawn_outline_luma : hint_range(0.0, 1.0) = 0.1;

// Modulate of the node (COLOR in fragment() already holds modulate * texture)
varying vec4 modulate;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void vertex() {
	modulate = COLOR;
}

void fragment() {
	if (COLOR.a < 0.1) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		vec4 n[4] = vec4[](
			texture(TEXTURE, UV + vec2(px.x, 0.0)),
			texture(TEXTURE, UV - vec2(px.x, 0.0)),
			texture(TEXTURE, UV + vec2(0.0, px.y)),
			texture(TEXTURE, UV - vec2(0.0, px.y)));
		bool opaque = false;
		float brightest = 0.12;
		for (int i = 0; i < 4; i++) {
			if (n[i].a > 0.5) {
				opaque = true;
				brightest = max(brightest, luma(n[i].rgb));
			}
		}
		if (opaque && brightest > drawn_outline_luma) {
			float bg = luma(texture(screen_texture, SCREEN_UV).rgb);
			// Smooth switch so an outline crossing a light/dark edge stays even
			float bright = smoothstep(bright_threshold - 0.05, bright_threshold + 0.05, bg);
			vec3 tint = mix(light_color.rgb, dark_color.rgb, bright);
			float strength = mix(light_strength, dark_strength, bright);
			COLOR = vec4(tint, strength * modulate.a);
		}
	}
}
