"""Biến tranh gốc trong assets/execution/raw/ thành các lớp PNG nền trong suốt cho cảnh Hành Quyết.
Chạy: python tools/execution_art.py   (cần Pillow + numpy)

- Xoá nền xám: vùng xám trung tính nối với mép ảnh là nền. Chỗ tối hơn nền (bóng đổ) giữ lại thành
  lớp đen bán trong suốt; nét mực đậm (tối hơn 42% độ sáng nền) không bao giờ bị coi là nền.
- Watermark sáng ở góc dưới phải nằm trong vùng nền nên bị xoá luôn.
- block: cắt theo đường tròn khớp với mép thớt (khói tối phía dưới không lọt vào).
- stick_sheets: tách nửa trái (que dài) / nửa phải (que ngắn đẫm máu), cùng tỉ lệ thu nhỏ.
- hand_*_player: hand_palm.png (bàn tay đã bỏ 5 ngón) + finger_<ngón>.png / finger_<ngón>_bandaged.png,
  mọi lớp cùng khung ảnh nên chồng đúng toạ độ; hand_layout.json ghi đa giác vùng bấm, gốc ngón, đầu ngón.
  Đa giác ngón (FINGER_POLYS) vẽ tay theo tranh này; đổi tranh tay thì chỉnh lại.
"""
import json, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, '..', 'assets', 'execution', 'raw')
OUT = os.path.join(HERE, '..', 'assets', 'execution')
INK = np.array([27, 19, 16], np.float32)


def box_blur(a, r):
    """Trung bình hộp (2r+1)² bằng ảnh tích phân."""
    p = np.pad(a, r + 1, mode='edge').cumsum(0).cumsum(1)
    k = 2 * r + 1
    return (p[k:, k:] - p[:-k, k:] - p[k:, :-k] + p[:-k, :-k])[:a.shape[0], :a.shape[1]] / (k * k)


def flood(seed, cand):
    """Lan seed trong cand theo 4 hướng: lan dọc từng đoạn liền theo hàng rồi theo cột cho tới khi đứng yên."""
    seed = seed & cand
    while True:
        before = seed.sum()
        for t in (False, True):
            s, c = (seed.T, cand.T) if t else (seed, cand)
            flat_c = np.concatenate([c, np.zeros((c.shape[0], 1), bool)], 1).ravel()
            flat_s = np.concatenate([s, np.zeros((s.shape[0], 1), bool)], 1).ravel()
            starts = flat_c & ~np.concatenate([[False], flat_c[:-1]])
            run = np.cumsum(starts) * flat_c
            hit = np.bincount(run, weights=flat_s, minlength=run.max() + 1) > 0
            hit[0] = False
            out = hit[run].reshape(c.shape[0], -1)[:, :-1]
            seed = out.T if t else out
        if seed.sum() == before:
            return seed


def cutout(img):
    """RGBA nền trong suốt. Trả về (mảng RGBA float, mặt nạ nền)."""
    a = np.asarray(img.convert('RGB')).astype(np.float32)
    L = a.mean(-1)
    C = a.max(-1) - a.min(-1)
    border = np.zeros(L.shape, bool)
    border[:4], border[-4:], border[:, :4], border[:, -4:] = True, True, True, True
    ref = np.median(L[border & (C < 14)])
    m = ((C < 14) & (np.abs(L - ref) < 40)).astype(np.float32)   # điểm trông như nền, để dựng độ sáng nền B(x, y)
    r = max(8, L.shape[0] // 20)
    B = box_blur(L * m, r) / np.maximum(box_blur(m, r), 1e-3)
    B = np.where(box_blur(m, r) > 0.02, B, ref)
    cand = (C < 18) & (L > 0.42 * B)
    bg = flood(border & cand, cand)
    h, w = L.shape
    bg[int(h * 0.9):, int(w * 0.88):] |= cand[int(h * 0.9):, int(w * 0.88):]   # góc watermark
    shade = np.clip((1 - L / B - 0.05) / 0.9, 0, 1)
    rgba = np.zeros((h, w, 4), np.float32)
    rgba[..., :3] = np.where(bg[..., None], INK, a)
    rgba[..., 3] = np.where(bg, shade * 255, 255)
    return rgba, bg


def crop_save(rgba, name, width=None, height=None, box=None):
    img = Image.fromarray(rgba.clip(0, 255).astype(np.uint8), 'RGBA')
    box = box or img.getchannel('A').point(lambda v: 255 if v > 10 else 0).getbbox()
    img = img.crop(box)
    s = (width / img.width) if width else (height / img.height)
    img = img.resize((max(1, round(img.width * s)), max(1, round(img.height * s))), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print('wrote %s %s' % (name, img.size))
    return img, box, s


def raw(name):
    return Image.open(os.path.join(RAW, name))


def block():
    rgba, bg = cutout(raw('block.png'))
    h, w = bg.shape
    pts = []
    for y in range(int(h * 0.08), int(h * 0.55), 6):   # mép thớt ở nửa trên, nơi nền còn sạch
        xs = np.where(~bg[y])[0]
        if xs.size:
            pts += [(xs[0], y), (xs[-1], y)]
    p = np.array(pts, np.float64)
    A = np.c_[2 * p, np.ones(len(p))]
    cx, cy, k = np.linalg.lstsq(A, (p ** 2).sum(1), rcond=None)[0]
    rad = np.sqrt(k + cx * cx + cy * cy)
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    rgba[..., 3] = np.minimum(rgba[..., 3], np.clip(rad + 1.5 - d, 0, 1) * 255)   # trong vòng tròn vẫn bỏ nền lọt ở mép méo
    crop_save(rgba, 'block.png', width=860, box=(int(cx - rad - 2), int(cy - rad - 2), int(cx + rad + 3), int(cy + rad + 3)))


def simple(src, dst, **size):
    rgba, _ = cutout(raw(src))
    return crop_save(rgba, dst, **size)


def sticks():
    rgba, _ = cutout(raw('stick_sheets.png'))
    alpha = rgba[..., 3] > 10
    cols = np.where(alpha.any(0))[0]
    gap = cols[np.argmax(np.diff(cols))]   # cột cuối của que bên trái
    left, right = rgba.copy(), rgba.copy()
    left[:, gap + 1:, 3] = 0
    right[:, :gap + 1, 3] = 0
    # cùng một tỉ lệ cho cả hai que: que ngắn dài SHORT_PX
    SHORT_PX = 340
    rb = Image.fromarray(right[..., 3].astype(np.uint8)).point(lambda v: 255 if v > 10 else 0).getbbox()
    s = SHORT_PX / (rb[3] - rb[1])
    lb = Image.fromarray(left[..., 3].astype(np.uint8)).point(lambda v: 255 if v > 10 else 0).getbbox()
    crop_save(left, 'stick_long.png', height=round((lb[3] - lb[1]) * s))
    crop_save(right, 'stick_short_blood.png', height=SHORT_PX)


# Vùng từng ngón trên tranh gốc 1792×2400 (px): nêm từ đường nối kẽ ngón lên trên, bao cả ngón lành lẫn dải băng thò ra.
# base = giữa gốc ngón, tip = đầu ngón (bản lành). Các lớp chồng khít nên ranh giới chỉ cần nằm trong khe giữa hai ngón.
FINGERS = {
    'pinky':  dict(poly=[(1218, 1017), (1340, 1170), (1420, 1350), (1792, 1350), (1792, 0), (1400, 0), (1370, 600)],
                   base=(1290, 1080), tip=(1533, 683)),
    'ring':   dict(poly=[(1018, 917), (1218, 1017), (1370, 600), (1400, 0), (1070, 0), (1062, 700)],
                   base=(1112, 960), tip=(1278, 383)),
    'middle': dict(poly=[(815, 917), (1018, 917), (1062, 700), (1070, 0), (818, 0)],
                   base=(917, 930), tip=(944, 239)),
    'index':  dict(poly=[(470, 950), (555, 1228), (815, 917), (818, 0), (420, 0)],
                   base=(680, 1060), tip=(611, 350)),
    'thumb':  dict(poly=[(0, 790), (460, 800), (470, 950), (555, 1228), (560, 1300), (470, 1600), (0, 1600)],
                   base=(530, 1290), tip=(189, 994)),
}
HAND_SCALE = 0.38


def hand():
    intact, _ = cutout(raw('hand_intact_player.png'))
    band, _ = cutout(raw('hand_bandaged_player.png'))
    h, w = intact.shape[:2]
    a = Image.fromarray(np.maximum(intact[..., 3], band[..., 3]).astype(np.uint8)).point(lambda v: 255 if v > 10 else 0)
    x0, y0, x1, y1 = a.getbbox()
    box = (max(0, x0 - 8), max(0, y0 - 8), min(w, x1 + 8), min(h, y1 + 8))
    rest = np.ones((h, w), np.float32)
    layout = {'scale': HAND_SCALE, 'fingers': {}}
    def px(p): return [round((p[0] - box[0]) * HAND_SCALE, 1), round((p[1] - box[1]) * HAND_SCALE, 1)]
    for name, f in FINGERS.items():
        m = Image.new('L', (w, h), 0)
        ImageDraw.Draw(m).polygon(f['poly'], fill=255)
        rest -= np.asarray(m).astype(np.float32) / 255
        m = np.asarray(m.filter(ImageFilter.MaxFilter(9))).astype(np.float32) / 255   # lấn sang lòng bàn tay vài px để không hở đường nối khi thu nhỏ
        for src, suffix in [(intact, ''), (band, '_bandaged')]:
            layer = src.copy()
            layer[..., 3] *= m
            crop_save(layer, 'finger_%s%s.png' % (name, suffix), width=round((box[2] - box[0]) * HAND_SCALE), box=box)
        layout['fingers'][name] = {'poly': [px(p) for p in f['poly']], 'base': px(f['base']), 'tip': px(f['tip'])}
    palm = intact.copy()
    palm[..., 3] *= np.clip(rest, 0, 1)
    img, _, _ = crop_save(palm, 'hand_palm.png', width=round((box[2] - box[0]) * HAND_SCALE), box=box)
    layout['size'] = list(img.size)
    with open(os.path.join(OUT, 'hand_layout.json'), 'w') as fp:
        json.dump(layout, fp, indent=1)
    print('wrote hand_layout.json')


os.makedirs(OUT, exist_ok=True)
if __name__ == '__main__':
    import sys
    only = sys.argv[1:]
    def want(k): return not only or k in only
    if want('block'): block()
    if want('fist'): simple('puppet_fist.png', 'puppet_fist.png', width=440)
    if want('sticks'): sticks()
    if want('cleaver'): simple('cleaver.png', 'cleaver.png', height=560)
    if want('hand'): hand()
