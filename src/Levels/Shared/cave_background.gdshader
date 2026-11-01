shader_type canvas_item;

// Cave background: irregular rocks lit from above, darker deep zones and a few
// glowing crystal clusters.
// Uses the rect UV so the texture scrolls with the level.

uniform vec2 rect_size = vec2(6883.0, 3296.0);
uniform vec4 base_color : source_color = vec4(0.03, 0.05, 0.07, 1.0);
uniform vec4 rock_color : source_color = vec4(0.08, 0.13, 0.17, 1.0);
uniform vec4 rock_light_color : source_color = vec4(0.13, 0.21, 0.26, 1.0);
// Muted violets: blue is kept for gameplay (water bottles, spiders)
uniform vec4 crystal_color : source_color = vec4(0.55, 0.45, 0.75, 1.0);
uniform vec4 crystal_alt_color : source_color = vec4(0.62, 0.48, 0.72, 1.0);
// How dark the gaps between rocks are, so the background stays calmer than the ground
uniform float edge_darkness : hint_range(0.0, 1.0) = 0.45;
// Average size of a rock, in game pixels
uniform float rock_size = 18.0;
// Size of the grid cell holding at most one crystal cluster
uniform float crystal_cell = 72.0;
uniform float crystal_density : hint_range(0.0, 1.0) = 0.16;

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

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Voronoi: distance to the nearest and second nearest rock centers, and the
// id of the nearest rock
vec2 rocks(vec2 p, out vec2 id) {
	vec2 cell = floor(p);
	float d1 = 8.0;
	float d2 = 8.0;
	id = cell;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = cell + vec2(float(x), float(y));
			// Rocks are wider than tall, like strata
			vec2 center = c + 0.15 + hash22(c) * 0.7;
			vec2 delta = (center - p) * vec2(1.0, 1.5);
			float d = dot(delta, delta);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = c;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec2(sqrt(d1), sqrt(d2));
}

void fragment() {
	vec2 pos = floor(UV * rect_size);

	// Large dark and light zones give the wall some depth
	float depth = value_noise(pos / 160.0) * 0.65 + value_noise(pos / 47.0) * 0.35;
	depth = floor(depth * 5.0) / 5.0;

	vec2 rock_id;
	vec2 r = rocks(pos / rock_size, rock_id);
	float edge = (r.y - r.x) * rock_size;
	float shade = hash12(rock_id + 5.0);
	vec3 color = mix(rock_color.rgb, rock_light_color.rgb, floor(shade * 3.0) / 3.0 * 0.6);

	// Light from above: lighter top of the rock, darker bottom
	vec2 above;
	rocks((pos - vec2(0.0, 2.0)) / rock_size, above);
	vec2 below;
	rocks((pos + vec2(0.0, 2.0)) / rock_size, below);
	if (above != rock_id) {
		color = mix(color, rock_light_color.rgb * 1.15, 0.6);
	} else if (below != rock_id) {
		color = mix(color, base_color.rgb, 0.35);
	}

	// Dark gaps between rocks
	if (edge < 1.2) {
		color = mix(color, base_color.rgb, edge_darkness);
	}

	color *= 0.55 + depth * 0.65;

	// Crystal clusters: a few pixel shards with a soft halo, slowly pulsing
	vec2 cell = floor(pos / crystal_cell);
	float h = hash12(cell + 23.0);
	if (h < crystal_density) {
		vec2 center = cell * crystal_cell + floor(8.0 + hash22(cell + 3.0) * (crystal_cell - 16.0));
		vec2 to_c = pos - center;
		vec3 c_color = hash12(cell + 61.0) < 0.7 ? crystal_color.rgb : crystal_alt_color.rgb;
		float pulse = 0.65 + 0.35 * sin(TIME * 1.5 + h * 400.0);
		float halo = 1.0 - smoothstep(2.0, 22.0, length(to_c + vec2(0.0, 4.0)));
		color += c_color * floor(halo * 4.0) / 4.0 * 0.12 * pulse;
		// Three shards growing up from the base, middle one taller
		for (int i = -1; i <= 1; i++) {
			float fi = float(i);
			float height = (i == 0 ? 9.0 : 4.0 + hash12(cell + fi) * 3.0);
			vec2 local = to_c - vec2(fi * 3.0, 0.0);
			float half_width = local.y > -height + 1.0 ? 1.0 : 0.0;
			if (local.y <= 0.0 && local.y > -height && abs(local.x) <= half_width) {
				float lit = local.x < 0.0 ? 1.0 : 0.7;
				color = mix(color, c_color * lit, 0.5 + 0.3 * pulse);
			}
		}
	}

	COLOR = vec4(color, 1.0);
}
