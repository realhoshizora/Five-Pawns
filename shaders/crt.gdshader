shader_type canvas_item;
// Hậu kỳ CRT: cong viền, tách kênh màu (ca tăng theo độ căng), scanline, vignette, flash 1 khung, nhiễu glitch.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float ca = 1.0;
uniform float curve = 0.045;
uniform float vignette = 0.6;
uniform float scan = 0.22;
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.92, 0.86, 1.0);
uniform float glitch = 0.0;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void fragment() {
	vec2 c = SCREEN_UV * 2.0 - 1.0;
	c *= 1.0 + curve * dot(c, c);
	vec2 uv = c * 0.5 + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		float row = floor(uv.y * 160.0);
		uv.x += glitch * 0.03 * step(0.9, hash(row + floor(TIME * 30.0))) * (hash(row) - 0.5);
		vec2 off = vec2(ca * 1.6 / 1920.0, 0.0) * (0.5 + length(c));
		vec3 col = vec3(texture(screen_tex, uv + off).r, texture(screen_tex, uv).g, texture(screen_tex, uv - off).b);
		col *= 1.0 - scan * (0.5 + 0.5 * sin(uv.y * 1080.0 * 1.5708));
		col *= mix(1.0, smoothstep(1.3, 0.4, length(c)), vignette);
		col = mix(col, flash_color.rgb, flash);
		COLOR = vec4(col, 1.0);
	}
}
