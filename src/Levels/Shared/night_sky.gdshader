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
// Top of the camera, in game pixels (set by the level every frame)
uniform float camera_y = 0.0;
// Below this camera position the moon rises with the parallax layers,
// so the buildings scrolling up never pass in front of it
uniform float camera_rest_y = 0.0;
uniform float moon_parallax = 0.0;

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
	// Screen size in game pixels, with square pixels whatever the viewport aspect
	vec2 screen = virtual_size.x * SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE;
	// Position in game pixels, snapped to the pixel grid
	vec2 px = floor(uv * screen);

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

	// Moon: round disc with stepped halo rings, like the sun of the bonus level
	if (show_moon) {
		// Pixel centres so the disc is symmetric
		vec2 moon_px = floor(moon_position * screen);
		moon_px.y -= floor(moon_parallax * max(camera_y - camera_rest_y, 0.0));
		vec2 to_moon = px + 0.5 - moon_px;
		float dist = length(to_moon);
		if (dist < moon_radius * 2.4) {
			color += moon_color.rgb * 0.05;
		}
		if (dist < moon_radius * 1.6) {
			color += moon_color.rgb * 0.06;
		}
		if (dist < moon_radius) {
			vec2 n = to_moon / moon_radius;
			// Shadowed lower-left rim, in two bands
			float shade = dot(n, normalize(vec2(-0.6, 0.8)));
			color = moon_color.rgb * (shade > 0.55 ? 0.84 : (shade > 0.25 ? 0.93 : 1.0));
			// A few round craters, placed relative to the radius
			if (length(n - vec2(-0.30, -0.25)) < 0.22
					|| length(n - vec2(0.35, 0.20)) < 0.15
					|| length(n - vec2(-0.05, 0.45)) < 0.12) {
				color *= 0.86;
			}
		}
	}

	COLOR = vec4(color, 1.0);
}
