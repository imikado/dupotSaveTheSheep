shader_type canvas_item;

// Cave background: dark rocky blocks with a few glowing crystals.
// Uses the rect UV so the texture scrolls with the level.

uniform vec2 rect_size = vec2(6883.0, 3296.0);
uniform vec4 base_color : source_color = vec4(0.05, 0.07, 0.09, 1.0);
uniform vec4 rock_color : source_color = vec4(0.09, 0.12, 0.15, 1.0);
uniform vec4 crystal_color : source_color = vec4(0.35, 0.75, 0.95, 1.0);
uniform float block_size = 16.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 pos = floor(UV * rect_size);
	// Offset every other row like a brick/rock wall
	vec2 block_pos = pos / block_size;
	block_pos.x += step(1.0, mod(floor(block_pos.y), 2.0)) * 0.5;
	vec2 block = floor(block_pos);
	vec2 inner = fract(block_pos) * block_size;

	float shade = hash(block);
	vec3 color = mix(base_color.rgb, rock_color.rgb, shade * 0.8);

	// Dark seams between rocks
	if (inner.x < 1.0 || inner.y < 1.0) {
		color = base_color.rgb * 0.6;
	}

	// Rare crystals, slowly pulsing
	float c = hash(floor(pos / 2.0) + 3.0);
	if (c > 0.9994) {
		float pulse = 0.5 + 0.5 * sin(TIME * 2.0 + c * 500.0);
		color = mix(color, crystal_color.rgb, 0.4 + 0.6 * pulse);
	}

	COLOR = vec4(color, 1.0);
}
