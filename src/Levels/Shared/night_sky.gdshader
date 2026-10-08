shader_type canvas_item;

// Night sky: vertical gradient, sparse twinkling pixel stars and a moon.
// Everything is computed in screen space (in game pixels) so it stays behind the parallax.

uniform vec4 top_color : source_color = vec4(0.02, 0.03, 0.10, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.12, 0.10, 0.24, 1.0);
// Virtual resolution of the screen, in game pixels
uniform vec2 virtual_size = vec2(480.0, 270.0);
// Size of the grid cell holding at most one star, in game pixels
uniform float star_cell = 8.0;
// Probability that a cell holds a star
uniform float star_density : hint_range(0.0, 1.0) = 0.12;
uniform vec4 star_color : source_color = vec4(0.85, 0.90, 1.0, 1.0);
uniform bool show_moon = true;
uniform vec2 moon_position = vec2(0.82, 0.16);
uniform float moon_radius = 9.0;
uniform vec4 moon_color : source_color = vec4(0.98, 0.95, 0.80, 1.0);

// Sin-free hash: stable on every GPU
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	// Position in game pixels, snapped to the pixel grid
	vec2 px = floor(uv * virtual_size);

	// Banded gradient keeps the pixel-art look
	float t = floor(uv.y * 16.0) / 16.0;
	vec3 color = mix(top_color.rgb, horizon_color.rgb, t * t);

	// Stars: at most one per cell, at a random spot inside it
	vec2 cell = floor(px / star_cell);
	float h = hash12(cell + 17.0);
	if (h < star_density) {
		vec2 star_px = floor(hash22(cell) * (star_cell - 1.0));
		vec2 local = px - cell * star_cell;
		float brightness = hash12(cell + 91.0);
		float twinkle = 0.65 + 0.35 * sin(TIME * (1.0 + brightness * 3.0) + h * 600.0);
		float fade = clamp(1.2 - uv.y * 1.3, 0.0, 1.0);
		float star = 0.0;
		if (local == star_px) {
			star = 0.35 + 0.65 * brightness;
		} else if (brightness > 0.85 && abs(local.x - star_px.x) + abs(local.y - star_px.y) == 1.0) {
			// Small cross around the brightest stars
			star = 0.3;
		}
		color = mix(color, star_color.rgb, star * twinkle * fade);
	}

	// Moon with a soft halo
	if (show_moon) {
		vec2 to_moon = px - floor(moon_position * virtual_size);
		float dist = length(to_moon);
		float halo = 1.0 - smoothstep(moon_radius, moon_radius * 3.0, dist);
		color += moon_color.rgb * halo * 0.08;
		if (dist < moon_radius) {
			// Darker craters
			float crater = step(0.8, hash12(floor(to_moon / 3.0) + 7.0));
			color = mix(moon_color.rgb, moon_color.rgb * 0.82, crater);
		}
	}

	COLOR = vec4(color, 1.0);
}
