shader_type canvas_item;
// Nghiêng 3D giả: xoay 4 đỉnh của lá quanh trục Y (tilt.x) và X (tilt.y) rồi chia phối cảnh.
// Thêm vệt sáng loá chạy theo góc nghiêng để lá trông như giấy bồi có bóng.

uniform vec2 tilt = vec2(0.0);
uniform vec2 size = vec2(100.0, 342.0);
uniform float fov = 900.0;
uniform float sheen = 0.18;

varying vec2 v_local;

void vertex() {
	vec2 c = VERTEX - size * 0.5;
	float cy = cos(tilt.x), sy = sin(tilt.x);
	float cx = cos(tilt.y), sx = sin(tilt.y);
	vec3 p = vec3(c.x * cy, c.y, -c.x * sy);
	p = vec3(p.x, p.y * cx - p.z * sx, p.y * sx + p.z * cx);
	float k = fov / (fov + p.z);
	VERTEX = p.xy * k + size * 0.5;
	v_local = UV;
}

void fragment() {
	// COLOR đã là texture × modulate; nhân thêm texture lần nữa sẽ làm mặt bài tối sẫm.
	float band = dot(v_local - 0.5, normalize(vec2(1.0, 0.35))) + tilt.x * 0.9 - tilt.y * 0.6;
	float glare = smoothstep(0.14, 0.0, abs(band)) * sheen * length(tilt) * 3.0;
	COLOR = vec4(COLOR.rgb + glare, COLOR.a);
}
