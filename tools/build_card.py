"""Dựng một lá bài Tam Cúc SVG (120×360) từ ảnh art direction.

Ruột tranh: cắt ô tranh trong ảnh tham chiếu → phóng to → ép về bảng màu khoá → vtracer → SVG.
Khung, chữ Hán, hoa thị, giấy dó, vết máu: SVG viết tay trong <defs> dùng chung.

Chạy: python -P tools/build_card.py all          # 14 lá khổ 120×410 (khổ đã duyệt)
      python -P tools/build_card.py general red 410
"""
import re
import sys
from pathlib import Path

import vtracer
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
REF = ROOT / "assets/ref/tamcuc_horror_ref.webp"
OUT = ROOT / "assets/cards"

# Bảng màu khoá (art direction). Ruột tranh bị ép về đúng các màu này.
PALETTE = {
	"paper": "#CBB793", "burn": "#7A6648", "mold": "#2E3529", "ink": "#14110F",
	"green": "#4A6648", "green_dk": "#2B3D2A", "ochre": "#BFA038", "ochre_dk": "#856B22",
	"seal": "#9E2622", "blood": "#8E1414", "blood_dk": "#4A0A0A",
}

# Ô tranh (phía trong viền) của từng lá trong ảnh tham chiếu 1024×572: (x0, y0, x1, y1).
PANELS = {
	"general": (42, 156, 140, 406),
	"advisor": (183, 157, 281, 409),
	"elephant": (324, 158, 423, 409),
	"chariot": (466, 159, 565, 411),
	"horse": (607, 158, 706, 411),
	"cannon": (748, 157, 847, 411),
	"pawn": (891, 158, 990, 412),
}
HAN = {"general": "將", "advisor": "士", "elephant": "象", "chariot": "車", "horse": "馬", "cannon": "砲", "pawn": "卒"}


def hex_rgb(h):
	return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


# Bộ Đen: tranh ngả lạnh và tối bằng cách đổi màu trong chính bảng khoá; máu và mực giữ nguyên.
BLACK_REMAP = {"ochre": "green", "ochre_dk": "burn", "burn": "mold"}   # giữ một bậc sáng (green) để hình còn khối


def quantize_to_palette(img, suit="red"):
	pal_img = Image.new("P", (1, 1))
	flat = [c for h in PALETTE.values() for c in hex_rgb(h)]
	pal_img.putpalette(flat + flat[:3] * (256 - len(PALETTE)))
	q = img.quantize(palette=pal_img, dither=Image.Dither.NONE)
	if suit == "black":
		out = [c for k in PALETTE for c in hex_rgb(PALETTE[BLACK_REMAP.get(k, k)])]
		q.putpalette(out + out[:3] * (256 - len(PALETTE)))
	return q.convert("RGB")


def trace_panel(name, work, suit="red"):
	box = PANELS[name]
	panel = Image.open(REF).convert("RGB").crop(box)
	panel = panel.resize((panel.width * 4, panel.height * 4), Image.LANCZOS).filter(ImageFilter.MedianFilter(5))
	panel = quantize_to_palette(panel, suit).filter(ImageFilter.ModeFilter(5))  # gom điểm lẻ để mảng màu phẳng như bản khắc
	src = work / f"{suit}_{name}_panel.png"
	traced = work / f"{suit}_{name}_panel.svg"
	panel.save(src)
	# shortcut: vtracer 0.6.15 trên Python 3.14 segfault khi truyền keyword, nên truyền theo vị trí.
	# Thứ tự: colormode, hierarchical, mode, filter_speckle, color_precision, layer_difference,
	#         corner_threshold, length_threshold, max_iterations, splice_threshold, path_precision
	vtracer.convert_image_to_svg_py(str(src), str(traced), "color", "stacked", "spline", 12, 6, 16, 60, 4.0, 10, 45, 2)
	svg = traced.read_text(encoding="utf-8")
	w, h = (int(v) for v in re.search(r'width="(\d+)" height="(\d+)"', svg).groups())
	body = svg[svg.index(">", svg.index("<svg")) + 1: svg.rindex("</svg>")]
	assert "<path" in body, "vtracer không ra path nào"
	return w, h, body.strip()


DEFS = """
<defs>
	<style>
		@import url("https://fonts.googleapis.com/css2?family=LXGW+WenKai+TC:wght@700&amp;family=Noto+Serif+TC:wght@900&amp;display=block");
		.han { font-family: "LXGW WenKai TC", "Noto Serif TC", serif; font-weight: 700; font-size: 68px; fill: #14110F; stroke: #14110F; stroke-width: 2.4; stroke-linejoin: round; paint-order: stroke; text-anchor: middle; dominant-baseline: central; }
	</style>

	<!-- Mép nét sần như ván khắc in tay -->
	<filter id="woodcut-ink" x="-10%" y="-10%" width="120%" height="120%">
		<feTurbulence type="fractalNoise" baseFrequency="0.06" numOctaves="3" seed="7" result="n"/>
		<feDisplacementMap in="SourceGraphic" in2="n" scale="2.5" xChannelSelector="R" yChannelSelector="G"/>
	</filter>

	<!-- Giấy dó: sợi giấy + 2–3 mảng ẩm mốc xanh rêu -->
	<filter id="do-paper-mold" x="0" y="0" width="100%" height="100%">
		<feTurbulence type="fractalNoise" baseFrequency="0.9 0.05" numOctaves="2" seed="3" result="fiber"/>
		<feColorMatrix in="fiber" values="0 0 0 0 0.48  0 0 0 0 0.40  0 0 0 0 0.28  0 0 0 0.7 -0.25" result="fiberC"/>
		<feTurbulence type="fractalNoise" baseFrequency="0.018" numOctaves="3" seed="11" result="blot"/>
		<feColorMatrix in="blot" values="0 0 0 0 0.18  0 0 0 0 0.21  0 0 0 0 0.16  0 0 0 -16 8.4" result="mold"/>
		<feGaussianBlur in="mold" stdDeviation=".6" result="moldSoft"/>
		<feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="fiberC"/></feMerge>
		<feComposite in2="SourceAlpha" operator="in"/>
	</filter>

	<!-- Giấy cũ: vệt ố loang màu cháy, mốc xanh rêu lốm đốm (seed đổi theo lá) -->
	<filter id="stain" x="0" y="0" width="100%" height="100%">
		<feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="4" seed="SEED_A"/>
		<feColorMatrix values="0 0 0 0 0.478  0 0 0 0 0.4  0 0 0 0 0.282  3.4 0 0 0 -1.5"/>
	</filter>
	<filter id="mould" x="0" y="0" width="100%" height="100%">
		<feTurbulence type="fractalNoise" baseFrequency="0.06" numOctaves="3" seed="SEED_B"/>
		<feColorMatrix values="0 0 0 0 0.18  0 0 0 0 0.21  0 0 0 0 0.16  4.4 0 0 0 -2.5"/>
		<feGaussianBlur stdDeviation=".7"/>
	</filter>
	<filter id="ragged" x="-5%" y="-5%" width="110%" height="110%">
		<feTurbulence type="fractalNoise" baseFrequency="0.09" numOctaves="3" seed="SEED_A"/>
		<feDisplacementMap in="SourceGraphic" scale="9" xChannelSelector="R" yChannelSelector="G"/>
	</filter>
	<radialGradient id="edge-fade" cx="50%" cy="50%" r="70%">
		<stop offset="0.45" stop-color="#000"/><stop offset="1" stop-color="#fff"/>
	</radialGradient>

	<!-- Góc tối, mép cháy -->
	<radialGradient id="burn-vignette" cx="50%" cy="50%" r="75%">
		<stop offset="0.5" stop-color="#7A6648" stop-opacity="0.08"/>
		<stop offset="0.84" stop-color="#7A6648" stop-opacity="0.7"/>
		<stop offset="1" stop-color="#2E3529" stop-opacity="0.95"/>
	</radialGradient>

	<!-- Khắc gỗ: gạch ngắn bất quy tắc -->
	<pattern id="hatch-dark" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(-35)">
		<path d="M0 1 h6 M3 4.5 h5 M0 8 h4" stroke="#14110F" stroke-width="0.9" stroke-linecap="round"/>
	</pattern>
	<pattern id="hatch-cross" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(20)">
		<path d="M0 0 l7 7 M7 0 l-7 7" stroke="#14110F" stroke-width="0.6"/>
	</pattern>
	<pattern id="gouge-light" width="10" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(-12)">
		<path d="M1 2 q2 -1 4 0 M5 6 q2 -1 3 0" stroke="#CBB793" stroke-width="0.8" fill="none" stroke-linecap="round"/>
	</pattern>

	<!-- Hoa cúc 8 cánh nét đôi, đỏ son ấn triện (chỉ bộ Đỏ) -->
	<g id="red-seal-ring" fill="none" stroke="#9E2622">
		<g stroke-width="2.8">
			<circle cx="27" cy="0" r="12"/><circle cx="19.1" cy="19.1" r="12"/><circle cx="0" cy="27" r="12"/><circle cx="-19.1" cy="19.1" r="12"/>
			<circle cx="-27" cy="0" r="12"/><circle cx="-19.1" cy="-19.1" r="12"/><circle cx="0" cy="-27" r="12"/><circle cx="19.1" cy="-19.1" r="12"/>
		</g>
		<g stroke-width="1.4">
			<circle cx="27" cy="0" r="8.5"/><circle cx="19.1" cy="19.1" r="8.5"/><circle cx="0" cy="27" r="8.5"/><circle cx="-19.1" cy="19.1" r="8.5"/>
			<circle cx="-27" cy="0" r="8.5"/><circle cx="-19.1" cy="-19.1" r="8.5"/><circle cx="0" cy="-27" r="8.5"/><circle cx="19.1" cy="-19.1" r="8.5"/>
		</g>
		<circle r="25" fill="#CBB793" stroke="none"/>
		<circle r="24" stroke-width="2.6"/><circle r="20" stroke-width="1.3"/>
	</g>

	<!-- Vết máu: bắn tóe + vệt chảy dọc -->
	<g id="blood-splatter-1">
		<path d="M0 0 h14 q1 3 -1 4 q-2 1 -2 9 q0 4 -2 4 q-2 0 -2 -4 q0 -5 -2 -6 q-1 7 -3 7 q-2 0 -1 -6 q0 -4 -2 -5 q-1 -1 1 -3 z" fill="#8E1414"/>
		<path d="M3 3 q2 6 1 12" stroke="#4A0A0A" stroke-width="0.8" fill="none"/>
	</g>
	<g id="blood-splatter-2">
		<path d="M0 0 q6 -4 11 0 q5 4 1 8 q-4 5 -10 2 q-6 -3 -2 -10 z" fill="#8E1414"/>
		<circle cx="15" cy="-3" r="1.6" fill="#8E1414"/><circle cx="18" cy="4" r="1" fill="#8E1414"/><circle cx="-5" cy="7" r="1.2" fill="#8E1414"/><circle cx="9" cy="14" r=".9" fill="#4A0A0A"/>
		<path d="M3 3 q3 2 6 0" stroke="#4A0A0A" stroke-width="1" fill="none"/>
	</g>
	<g id="blood-splatter-3">
		<path d="M0 0 q2 0 2 3 q0 10 1 22 q0 3 -2 3 q-2 0 -2 -3 q1 -12 1 -25 z" fill="#8E1414"/>
		<ellipse cx="1.5" cy="27" rx="2.2" ry="2.6" fill="#8E1414"/>
		<path d="M5 2 q1 0 1 2 q0 5 .5 9 q0 1.5 -1 1.5 q-1 0 -1 -1.5 q.3 -5 .5 -11 z" fill="#4A0A0A"/>
	</g>
</defs>"""


# Các lá mà ảnh tham chiếu cho máu tràn qua mép dưới ô tranh xuống vùng chữ dưới.
SPILL = {"general", "elephant", "chariot", "cannon"}


def card_svg(name, suit, art, H=410):
	aw, ah, art_body = art
	han = HAN[name]
	k = list(HAN).index(name) + (7 if suit == "black" else 0)   # seed theo lá: vết máu, ố, mốc khác nhau
	dx1, dx2, dy = 18 + k * 7 % 30, 64 + k * 11 % 32, k * 13 % 40
	ph = H - 172                      # ô tranh: H trừ 2 vùng chữ 78 và lề
	py = 86 + ph                      # mép dưới ô tranh
	by = py + 2                       # đỉnh vùng chữ dưới
	defs = DEFS.replace("SEED_A", str(3 + k * 5)).replace("SEED_B", str(11 + k * 3))
	seal = '<use href="#red-seal-ring" transform="translate(60 45)" filter="url(#woodcut-ink)"/>' if suit == "red" else ""
	# Bộ Đen phủ mốc dày hơn để ngả lạnh, vẫn bằng màu khoá.
	mould_op = ".85" if suit == "black" else ".6"
	side = k % 2                      # vệt máu khô bám mép trái hay phải
	sx, sdir = (1, 1) if side == 0 else (119, -1)
	smear_y = H - 70 - k * 9 % 60
	spill = ""
	if name in SPILL:
		x1, x2 = 30 + k * 13 % 40, 62 + k * 7 % 34
		spill = f"""
	<g filter="url(#woodcut-ink)">
		<path d="M{x1 - 6} {py - 6} q6 -3 14 0 q3 2 1 4 q-2 1 -2 10 q0 18 -3 26 q-1 3 -3 0 q-2 -10 -2 -20 q0 -6 -3 -8 q-4 -3 -2 -12 z" fill="#8E1414"/>
		<ellipse cx="{x1 + 1}" cy="{py + 34}" rx="3" ry="3.6" fill="#8E1414"/>
		<use href="#blood-splatter-3" transform="translate({x2} {py - 2})"/>
		<path d="M{x2 - 4} {py + 2} q8 4 14 0" stroke="#4A0A0A" stroke-width="1.6" fill="none"/>
	</g>"""
	return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 {H}" width="120" height="{H}">
{defs}
	<clipPath id="card-shape"><rect x="0.5" y="0.5" width="119" height="{H - 1}" rx="4"/></clipPath>
	<mask id="edge-mask"><rect width="120" height="{H}" fill="url(#edge-fade)"/></mask>

	<g clip-path="url(#card-shape)">
		<!-- giấy dó: sợi giấy, vệt ố loang, mốc lốm đốm dồn về mép, mép cháy rách -->
		<rect width="120" height="{H}" fill="#CBB793" filter="url(#do-paper-mold)"/>
		<rect width="120" height="{H}" filter="url(#stain)" opacity=".85"/>
		<rect width="120" height="{H}" filter="url(#mould)" mask="url(#edge-mask)" opacity="{mould_op}"/>
		<rect width="120" height="{H}" fill="url(#burn-vignette)"/>
		<g filter="url(#ragged)" fill="none">
			<rect x="0" y="0" width="120" height="{H}" stroke="#7A6648" stroke-width="12" opacity=".75"/>
			<rect x="0" y="0" width="120" height="{H}" stroke="#2E3529" stroke-width="5"/>
		</g>
	</g>

	<!-- vùng chữ trên (78) -->
	<g>{seal}<text class="han" x="60" y="46" filter="url(#woodcut-ink)">{han}</text></g>

	<!-- ô tranh 96×{ph}, viền đôi mực -->
	<svg x="12" y="86" width="96" height="{ph}" viewBox="0 0 {aw} {ah}" preserveAspectRatio="xMidYMid slice">{art_body}</svg>
	<g fill="none" stroke="#14110F" filter="url(#woodcut-ink)">
		<rect x="12" y="86" width="96" height="{ph}" stroke-width="2.6"/>
		<rect x="15" y="89" width="90" height="{ph - 6}" stroke-width="1"/>
	</g>

	<!-- vùng chữ dưới (78), xoay 180° -->
	<g transform="rotate(180 60 {by + 39})"><g transform="translate(0 {by - 6})">{seal}<text class="han" x="60" y="46" filter="url(#woodcut-ink)">{han}</text></g></g>

	<!-- máu: chảy từ mép trên ô tranh, tràn mép dưới (một số lá), vệt khô dọc mép bài; vị trí theo seed -->
	<use href="#blood-splatter-1" transform="translate({dx1} 86)"/>
	<use href="#blood-splatter-3" transform="translate({dx2} 86)"/>
	<use href="#blood-splatter-3" transform="translate({112 if side == 0 else 4} {2 + dy}) scale(.8)"/>{spill}
	<g filter="url(#woodcut-ink)" clip-path="url(#card-shape)">
		<path d="M{sx} {smear_y} q{5 * sdir} 6 {3 * sdir} 18 q{-2 * sdir} 10 {4 * sdir} 20 q{4 * sdir} 8 {1 * sdir} 16 q{-2 * sdir} 8 {4 * sdir} 14 L{sx} {smear_y + 76} Z" fill="#4A0A0A" opacity=".8"/>
		<path d="M{sx + sdir} {smear_y + 10} q{3 * sdir} 8 {1 * sdir} 16 q{-1 * sdir} 8 {3 * sdir} 14" fill="none" stroke="#8E1414" stroke-width="1.6"/>
	</g>
</svg>
"""


def main():
	work = OUT / "_work"
	work.mkdir(parents=True, exist_ok=True)
	if sys.argv[1] == "all":
		jobs = [(n, su, 410) for n in HAN for su in ("red", "black")]
	else:
		jobs = [(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 410)]
	for name, suit, H in jobs:
		art = trace_panel(name, work, suit)   # bộ Đen đổi màu ở bước ép bảng màu nên phải trace riêng
		out = OUT / f"{suit}_{name}.svg"
		out.write_text(card_svg(name, suit, art, H), encoding="utf-8")
		print(out.name, f"{out.stat().st_size // 1024} KB")


if __name__ == "__main__":
	main()
