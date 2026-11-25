shader_type canvas_item;
// Nền xoáy (port từ mockups/fx.js): tính theo lưới 240×135 rồi phóng to vuông pixel, phân 6 dải màu kiểu poster.
// Bảng màu/tốc độ là uniform để chuyển trạng thái: trầm khi chia bài → đỏ thẫm, xoáy nhanh khi Hành Quyết.

uniform vec3 c0 : source_color = vec3(0.039, 0.027, 0.020);
uniform vec3 c1 : source_color = vec3(0.094, 0.047, 0.031);
uniform vec3 c2 : source_color = vec3(0.173, 0.063, 0.043);
uniform vec3 c3 : source_color = vec3(0.259, 0.082, 0.055);
uniform float twist = 1.6;
uniform float speed = 0.08;
uniform float rings = 8.0;
uniform vec2 grid = vec2(240.0, 135.0);

void fragment() {
	vec2 p = floor(UV * grid) / grid;
	vec2 q = (p - 0.5) * vec2(grid.x / grid.y, 1.0);
	float r = length(q);
	float t = TIME + 3.0;
	float a = atan(q.y, q.x) + twist / (r + 0.3) + t * speed;
	float s = 0.65 * (sin(a * 3.0 + r * rings - t * 0.6) * 0.5 + 0.5) + 0.35 * (sin(a * 5.0 - r * 15.0 + t) * 0.5 + 0.5);
	s = floor(s * 6.0) / 6.0 * max(0.0, 1.0 - r * 0.75);
	float f = s * 3.0;
	vec3 col = f < 1.0 ? mix(c0, c1, f) : (f < 2.0 ? mix(c1, c2, f - 1.0) : mix(c2, c3, f - 2.0));
	COLOR = vec4(col, 1.0);
}
