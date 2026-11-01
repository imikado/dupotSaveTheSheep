shader_type canvas_item;

// Desert sunset: banded gradient, big striped sun low on the horizon and the
// first stars at the top. Computed in screen space (in game pixels) so it stays
// behind the parallax.

uniform vec4 top_color : source_color = vec4(0.16, 0.09, 0.28, 1.0);
uniform vec4 middle_color : source_color = vec4(0.55, 0.22, 0.42, 1.0);
uniform vec4 horizon_color : source_color = vec4(1.0, 0.56, 0.32, 1.0);
// Height (0 top, 1 bottom) where the middle color is reached
uniform float middle_height : hint_range(0.0, 1.0) = 0.45;
// Virtual resolution of the screen, in game pixels
uniform vec2 virtual_size = vec2(480.0, 270.0);
uniform vec2 sun_position = vec2(0.68, 0.60);
uniform float sun_radius = 34.0;
uniform vec4 sun_top_color : source_color = vec4(1.0, 0.93, 0.55, 1.0);
uniform vec4 sun_bottom_color : source_color = vec4(1.0, 0.45, 0.35, 1.0);
uniform float star_cell = 9.0;
uniform float star_density : hint_range(0.0, 1.0) = 0.10;
uniform vec4 star_color : source_color = vec4(1.0, 0.92, 0.85, 1.0);

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
	vec2 px = floor(uv * virtual_size);

	// Banded gradient keeps the pixel-art look
	float t = floor(uv.y * 20.0) / 20.0;
	vec3 color;
	if (t < middle_height) {
		color = mix(top_color.rgb, middle_color.rgb, t / middle_height);
	} else {
		color = mix(middle_color.rgb, horizon_color.rgb, (t - middle_height) / (1.0 - middle_height));
	}

	// Stars, only in the darker top part
	vec2 cell = floor(px / star_cell);
	float h = hash12(cell + 17.0);
	float fade = clamp(1.0 - uv.y * 2.2, 0.0, 1.0);
	if (h < star_density && fade > 0.0) {
		vec2 star_px = floor(hash22(cell) * (star_cell - 1.0));
		float brightness = hash12(cell + 91.0);
		float twinkle = 0.6 + 0.4 * sin(TIME * (1.0 + brightness * 3.0) + h * 600.0);
		if (px - cell * star_cell == star_px) {
			color = mix(color, star_color.rgb, (0.3 + 0.7 * brightness) * twinkle * fade);
		}
	}

	// Sun: glow, then a disc cut by stripes that get thicker towards the bottom
	vec2 sun_center = floor(sun_position * virtual_size);
	vec2 to_sun = px - sun_center;
	float dist = length(to_sun);
	float glow = 1.0 - smoothstep(sun_radius, sun_radius * 2.6, dist);
	color += sun_top_color.rgb * floor(glow * 4.0) / 4.0 * 0.12;
	if (dist < sun_radius) {
		float k = (to_sun.y / sun_radius + 1.0) * 0.5;
		vec3 sun = mix(sun_top_color.rgb, sun_bottom_color.rgb, floor(k * 6.0) / 6.0);
		bool stripe = false;
		if (to_sun.y > 0.0) {
			float period = 7.0;
			float gap = 1.0 + floor(to_sun.y / sun_radius * 4.0);
			stripe = mod(to_sun.y, period) < gap;
		}
		if (!stripe) {
			color = sun;
		}
	}

	COLOR = vec4(color, 1.0);
}
