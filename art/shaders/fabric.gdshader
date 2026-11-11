shader_type canvas_item;
// Fabric patterns for softie blankets, drawn in the softie's own local space
// so the pattern travels and turns with it.

uniform vec4 base : source_color = vec4(0.95, 0.65, 0.63, 1.0);
uniform int pattern = 0;      // 0 gingham, 1 dots, 2 stripes, 3 fleece
uniform float unit = 150.0;   // one grid cell, in local pixels

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 c = base.rgb;
	vec3 light = mix(c, vec3(1.0), 0.42);
	vec3 dark = c * 0.86;
	vec2 p = lp / unit;
	float aa = 1.5 / unit;

	if (pattern == 0) {
		vec2 f = fract(p * 3.0);
		vec2 g = smoothstep(0.5 - aa * 3.0, 0.5 + aa * 3.0, f) * (1.0 - smoothstep(1.0 - aa * 3.0, 1.0, f));
		c = mix(light, dark, (g.x + g.y) * 0.5);
	} else if (pattern == 1) {
		vec2 q = p * 3.2;
		q.x += mod(floor(q.y), 2.0) * 0.5;
		float d = length(fract(q) - 0.5);
		c = mix(light, c, smoothstep(0.21, 0.21 + aa * 4.0, d));
	} else if (pattern == 2) {
		float s = fract((p.x + p.y) * 2.4);
		float band = smoothstep(0.5, 0.5 + aa * 4.0, s) * (1.0 - smoothstep(1.0 - aa * 4.0, 1.0, s));
		c = mix(c, light, band);
	} else {
		float fine = hash(floor(lp / 4.0));
		float tuft = hash(floor(lp / 13.0 + 7.0));
		c = mix(c, light, fine * 0.22 + tuft * 0.2);
	}
	COLOR = vec4(c, base.a * COLOR.a);
}
