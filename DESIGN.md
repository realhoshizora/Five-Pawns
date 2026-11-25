---
name: Five Pawns
description: Bàn Tam Cúc khắc gỗ Đông Hồ trên giấy dó, nhìn qua một màn CRT đang nóng dần lên.
colors:
  than: "#0e0a07"
  muc: "#1b1310"
  son: "#b0241a"
  son-sau: "#6e150f"
  son-xin: "#6e2a22"
  do: "#d8c294"
  do-sang: "#eadcb4"
  diep: "#f1e9d6"
  dong: "#c49a45"
  go: "#2a170d"
  go-khung: "#4a2a16"
  go-thot: "#6b4424"
  gai: "#9a7843"
  gai-toi: "#3c2a14"
  thep: "#2b2622"
  luoi: "#cfc6b6"
  da: "#e0c497"
  tro-sang: "#b9a98e"
  muc-nhat: "#4b3b2c"
  mau-kho: "#3a0503"
  mau: "#6a0f0a"
  mau-sau: "#530a07"
  mau-tuoi: "#9b2216"
  mau-bang: "#7a120c"
  card-paper: "#CBB793"
  card-burn: "#7A6648"
  card-mould: "#2E3529"
  card-ink: "#14110F"
  card-green: "#4A6648"
  card-green-dk: "#2B3D2A"
  card-ochre: "#BFA038"
  card-ochre-dk: "#856B22"
  card-seal: "#9E2622"
  card-blood: "#8E1414"
  card-blood-dk: "#4A0A0A"
typography:
  display:
	fontFamily: "Bevan, serif"
	fontSize: "178px"
	fontWeight: 400
	lineHeight: 1
	letterSpacing: "0.01em"
  headline:
	fontFamily: "Bevan, serif"
	fontSize: "58px"
	fontWeight: 400
	lineHeight: 1
	letterSpacing: "0.02em"
  title:
	fontFamily: "Bevan, serif"
	fontSize: "30px"
	fontWeight: 400
	lineHeight: 1
	letterSpacing: "0.03em"
  body:
	fontFamily: "VT323, monospace"
	fontSize: "30px"
	fontWeight: 400
	lineHeight: 1.1
	letterSpacing: "0.04em"
  label:
	fontFamily: "VT323, monospace"
	fontSize: "24px"
	fontWeight: 400
	lineHeight: 1.1
	letterSpacing: "0.02em"
  han:
	fontFamily: "Noto Serif TC, serif"
	fontWeight: 900
	lineHeight: 1
  card-han:
	fontFamily: "LXGW WenKai TC, Noto Serif TC, serif"
	fontSize: "68px"
	fontWeight: 700
	lineHeight: 1
rounded:
  chip: "3px"
  card: "4px"
  plaque: "4px"
  seal: "6px"
  screen: "34px"
  table: "40px"
spacing:
  hud-gap: "8px"
  stack: "18px"
  safe-edge: "206px"
  card-han-zone: "78px"
components:
  card-face:
	backgroundColor: "{colors.card-paper}"
	textColor: "{colors.card-ink}"
	typography: "{typography.card-han}"
	rounded: "{rounded.card}"
	width: "120px"
	height: "410px"
  card-face-black:
	backgroundColor: "{colors.card-paper}"
	textColor: "{colors.card-ink}"
	typography: "{typography.card-han}"
	rounded: "{rounded.card}"
	width: "120px"
	height: "410px"
  card-panel:
	backgroundColor: "{colors.card-paper}"
	width: "96px"
	height: "238px"
  card-back:
	backgroundColor: "{colors.son-sau}"
	textColor: "{colors.do}"
	rounded: "{rounded.card}"
  plaque:
	backgroundColor: "{colors.do}"
	textColor: "{colors.muc}"
	rounded: "{rounded.plaque}"
	padding: "12px 18px 14px"
  seal-button:
	backgroundColor: "{colors.son}"
	textColor: "{colors.do-sang}"
	typography: "{typography.title}"
	rounded: "{rounded.seal}"
	padding: "22px 40px 24px"
  seal-button-disabled:
	backgroundColor: "{colors.son-xin}"
	textColor: "{colors.do}"
	rounded: "{rounded.seal}"
  ghost-button:
	backgroundColor: "{colors.than}"
	textColor: "{colors.diep}"
	typography: "{typography.body}"
	rounded: "{rounded.plaque}"
	padding: "10px 22px"
  chip:
	backgroundColor: "{colors.son}"
	textColor: "{colors.do-sang}"
	typography: "{typography.label}"
	rounded: "{rounded.chip}"
	padding: "1px 9px 2px"
  hand-icon:
	backgroundColor: "{colors.da}"
	textColor: "{colors.muc}"
	width: "64px"
  lacquer-table:
	backgroundColor: "{colors.go}"
	rounded: "{rounded.table}"
---

# Design System: Five Pawns

## Overview

**Creative North Star: "Bàn thờ xét xử sơn mài"**

Bàn Tam Cúc là một bàn thờ xét xử: mặt gỗ mít sơn mài, lá bài là tờ tranh dân gian kinh dị in khắc trên giấy dó cũ đã ố mốc và cháy mép, và ánh sáng duy nhất đến từ một màn CRT. Mọi vật thể trên màn đều là vật thật có chất liệu (giấy, mực, son, gỗ, dây gai, thép, da, máu); giao diện không có tấm kính, không có thẻ phẳng, không có gradient trang trí. Chữ khắc slab nói giọng của bản án, chữ CRT nói giọng của máy, chữ Hán nói giọng của lá bài và của ấn. Mọi chữ trong game là tiếng Anh, theo thuật ngữ ở GDD §0 (The House, the Block, the Blade, Death Rope, Effigy).

Độ căng thẳng là một trục được đo bằng hình: nền xoáy đổi bảng màu và quay nhanh theo số Death Rope, chromatic aberration tăng hệ số, khung cảnh nghiêng dần từ màn tiêu đề tới Execution. Dân gian và kinh dị là một thế giới: máu chảy trên tranh lá bài, bộ khung đao Chặt Ngũ Chỉ in cùng nét khắc, và mỗi ngón mất để lại một vết máu trên bàn và một vết sẹo trên thớt suốt phiên chơi.

Mặt lá bài là asset đã duyệt, dựng từ art direction người dùng đưa (`assets/ref/tamcuc_horror_ref.webp`) bằng `tools/build_card.py`, nguồn gốc ở `assets/cards/PROVENANCE.md`; nó không được vẽ lại bằng CSS hay code. Mockup HTML là chất liệu tạm cho phần còn lại; hệ thống này được ghi theo vai trò để dựng lại bằng scene, StyleBox, NinePatch và shader trong Godot 4. Khung chuẩn 1920×1080, chuột.

**Key Characteristics:**
- Bảng màu UI tối ba chất: đen than, đỏ son, vàng giấy dó. Gỗ, gai, thép, da và máu là chất liệu phụ, không phải màu UI.
- Lá bài có bảng màu khoá 11 màu riêng, tách khỏi bảng màu UI.
- Mọi bề mặt UI sáng là giấy dó có sợi, viền khắc kép (mực, giấy, mực).
- Ba giọng chữ cố định: Bevan khắc, VT323 CRT, chữ Hán (LXGW WenKai TC 700 trên mặt bài, Noto Serif TC 900 trên lưng bài và ấn).
- Vật minh họa (bàn tay, bộ khung đao, tranh lá bài) vẽ kiểu in khắc gỗ: màu phẳng, nét mực dày, mép nét sần.
- Hậu kỳ CRT phủ toàn khung; cường độ đi theo trạng thái game.
- Pixel thô cho nền xoáy và máu trên bàn, nét khắc cho bài, chữ và vật.

## Colors

Ba chất màu dân gian trên nền đen than cho UI; lá bài mang bảng màu khoá riêng của tờ tranh cũ; mọi màu khác là chất liệu vật thể hoặc sắc độ của máu.

### Primary
- **Đỏ son** (`son`): chất màu chính của UI. Nút con dấu, chip trạng thái, ô nhãn dây đang trỏ, tổng Death Rope trên biên bản, số đếm ngược, ấn 莊 The House. Đỏ son là màu của hành động và hậu quả.
- **Son trầm** (`son-sau`): lưng bài, viền đỏ quanh mép bàn, chuôi dao găm con trỏ. Đỏ đã khô, không bao giờ dùng cho chữ.
- **Son xỉn** (`son-xin`): mặt nút con dấu khi bị khóa. Chỉ mặt nút xỉn đi; dòng phụ vẫn đủ tương phản.

### Secondary
- **Đồng thau** (`dong`): kim loại hiếm. Chỉ viền mảnh trong lòng bàn (55% độ phủ) và chắn tay dao găm con trỏ.

### Neutral
- **Đen than tre** (`than`): nền màn hình, nền ghost button (55%).
- **Mực in** (`muc`): chữ trên giấy dó UI, mọi vòng viền khắc của UI, nét keyline của bàn tay và khung đao.
- **Giấy dó cũ** (`do`): mặt bảng tên, ô nhãn dây, vòng giấy trên lưng bài, đường khắc trên gỗ và thép, chữ menu chưa chọn.
- **Giấy dó sáng** (`do-sang`): vòng giấy trong viền kép, chữ trên nền son, băng quấn ngón mất, viền sáng dây khi rê chuột, focus ring.
- **Trắng điệp** (`diep`): chữ sáng trên nền tối, tiêu đề khắc lớn, HUD.
- **Tro sáng** (`tro-sang`): dòng phụ HUD trên nền tối, dòng "an toàn" (Effigy, never cut).
- **Mực nhạt** (`muc-nhat`): dòng phụ trên giấy (vai trò, đếm vòng ăn).

### Bảng màu lá bài (khoá, chỉ sống trong asset lá bài)
Mười một màu do art direction chốt, định nghĩa ở `PALETTE` trong `tools/build_card.py`. Ruột tranh bị ép về đúng các màu này (không dither); khung, chữ, hoa thị và máu chỉ dùng chúng.
- **Giấy lá bài** (`card-paper`): nền giấy dó cũ của lá, nền trong hoa thị.
- **Mép cháy** (`card-burn`): vệt ố loang, mép cháy rách, góc tối.
- **Mốc** (`card-mould`): mốc lốm đốm dồn về mép, vành ngoài cùng của mép cháy.
- **Mực lá bài** (`card-ink`): chữ Hán và nét viền chữ, viền đôi ô tranh, nét gạch khắc.
- **Xanh rêu** (`card-green`) và **Xanh rêu sẫm** (`card-green-dk`): mảng màu trong tranh.
- **Hoàng thổ** (`card-ochre`) và **Hoàng thổ sẫm** (`card-ochre-dk`): mảng màu ấm trong tranh bộ Đỏ.
- **Son ấn** (`card-seal`): hoa thị 8 cánh nét đôi sau chữ Hán bộ Đỏ.
- **Máu lá bài** (`card-blood`) và **Máu khô lá bài** (`card-blood-dk`): máu chảy, máu tràn, vệt máu khô.

Bảng màu này gần nhưng khác bảng màu UI ở mọi chỗ trùng vai trò: giấy lá bài `#CBB793` tối và xám hơn giấy dó UI `do`; mực lá bài `#14110F` khác `muc`; son ấn `#9E2622` trầm hơn `son`; máu lá bài `#8E1414` / `#4A0A0A` không thuộc dải máu pixel trên bàn (`mau-*`). Hai bảng không thay thế cho nhau.

### Chất liệu vật thể (chỉ cho vật minh họa, không dùng cho UI)
- **Gỗ mít sẫm** (`go`): mặt bàn sơn mài, thân thớt.
- **Gỗ khung** (`go-khung`): cột khung đao (xà ngang sáng hơn một bậc, `#5a331b`).
- **Gỗ thớt** (`go-thot`): mặt thớt cắt ngang thớ, vòng tuổi khắc `#e6d3a8`.
- **Gai** (`gai`) và **Gai tối** (`gai-toi`): sọc chéo xoắn của dây gai; khi rê chuột dây sáng lên `#d8b46e` / `#5a3e1c`.
- **Thép** (`thep`) và **Lưỡi** (`luoi`): thân đại đao và mép lưỡi đã mài; lưỡi dao găm con trỏ cũng dùng `luoi`.
- **Da** (`da`): bàn tay trên thớt; icon bàn tay dùng sắc sáng hơn một chút `#e3cc9c`.

### Blood (chỉ dùng cho vết máu và vết thương ngoài lá bài)
- **Máu khô** (`mau-kho`) viền vũng; **Máu** (`mau`) và **Máu sẫm** (`mau-sau`) thân vũng, trộn ngẫu nhiên khoảng 50/50; **Máu tươi** (`mau-tuoi`) đốm sáng khoảng 6% số pixel.
- **Máu thấm băng** (`mau-bang`): đỉnh băng quấn ngón mất, trên icon và trên bàn tay ở thớt. Vết máu khô trên thớt sẫm hơn (`#4a0806`).

### Named Rules
**The Đồng Thau Hiếm Rule.** Đồng thau chỉ là chỉ kim loại mảnh (viền trong lòng bàn, chắn tay dao). Không dùng đồng cho nút, chữ, tiêu đề hay viền bảng.

**The Ba Chất Rule.** Mọi màu UI phải là sắc độ của than, son hoặc giấy dó; vật minh họa thêm gỗ, gai, thép, da và máu. Không có màu xanh, tím hay neon nào trong UI, trừ hai vệt đỏ/lam của chromatic aberration. Xanh rêu và mốc chỉ tồn tại bên trong tranh lá bài, như vết thời gian trên giấy cũ.

**The Bảng Màu Khoá Rule.** Mặt lá bài chỉ dùng 11 màu `card-*`. Bộ Đen không thêm màu: nó đổi màu trong chính bảng khoá (hoàng thổ thành xanh rêu, hoàng thổ sẫm và xanh rêu thành xanh rêu sẫm, mép cháy thành mốc), máu và mực giữ nguyên. Không lấy màu `card-*` làm màu UI, không lấy màu UI vẽ lên lá.

## Typography

**Display Font:** Bevan (với serif)
**Body Font:** VT323 (với monospace)
**Han Font (mặt bài):** LXGW WenKai TC 700 (với Noto Serif TC, serif)
**Han Font (UI):** Noto Serif TC 900 (với serif)

**Character:** Bevan là chữ slab đậm như khắc dao trên ván gỗ, luôn viết hoa; VT323 là chữ phosphor của máy CRT, dùng cho mọi con số và trạng thái; chữ Hán trên mặt bài là khải thư bút lông LXGW WenKai TC có viền mực, gần nét chữ trong ảnh tham chiếu; chữ Hán 900 Noto Serif TC là con dấu, sống trên lưng bài (五), ấn The House (莊) và phụ đề 五子.

### Hierarchy
- **Display** (Bevan 400, 178px, 1): "FIVE PAWNS" trên màn tiêu đề, phủ woodcut và chromatic aberration.
- **Headline** (Bevan 400, 58px, 1): tên pha lớn ("Execution"), phủ woodcut và CA.
- **Title** (Bevan 400, 20–44px, 1, viết hoa): tên trên bảng, tiêu đề bảng, chữ nút con dấu (34–44px), mục menu (30px), nhãn số La Mã của dây (22px).
- **Body** (VT323 400, 27–32px, 1.1–1.25): HUD, dòng biên bản, nhãn ghost button.
- **Label** (VT323 400, 22–24px): vai trò dưới tên, chip, dòng phụ dưới nút con dấu.
- **Card Han** (LXGW WenKai TC 700, 68px trên khổ 120, nét viền mực 2.4 vẽ dưới chữ): chữ Hán trong vùng chữ trên và dưới của lá, cỡ ngang hoa thị. Đã nướng vào PNG; game không cần font này lúc chạy.
- **Han** (Noto Serif TC 900): ấn 五 trên lưng bài (34% bề rộng lá), ấn 莊 The House (72px), phụ đề 五子.

### Named Rules
**The Ba Giọng Rule.** Mỗi chữ thuộc đúng một giọng: Bevan cho tên và phán quyết, VT323 cho số và trạng thái, chữ Hán cho bài và ấn. Không trộn giọng trong một dòng.

**The Số Là Máy Rule.** Mọi số liệu ván (Death Rope, phần trăm, ngón, vòng ăn) viết bằng VT323. Riêng tổng Death Rope trên biên bản ("3 of 6") và số đếm ngược Take the Blade được lên Bevan son, vì đó là phán quyết.

**The Mặt Bài Gốc Rule.** Mặt bài chỉ có chữ Hán gốc (trên và lộn ngược dưới) và tranh; không in tên chữ Latin, số hay vạch lên lá. Tên tiếng Anh ("Red Chariot") chỉ sống trong tooltip và nhãn trợ năng (`alt`).

## Layout

Khung cố định 1920×1080, bo góc 34px như mặt kính CRT. Lớp xếp từ dưới lên: nền xoáy, bàn gỗ, vết máu, bộ khung đao (Execution), bài úp, bảng tên, vòng bài, tay bài, nút, HUD, lớp vignette căng thẳng, hậu kỳ CRT (luôn trên cùng, không bắt chuột).

Bàn chơi nhìn từ trên xuống: The House giữa trên, đồng đội trái, Effigy phải, bạn dưới trái với tay 8 lá xòe hình quạt ở giữa đáy (bước ngang 96px, xoay ±1.8° mỗi lá, lá ngoài cùng ±12.6° và hạ 29px). Vòng bài đặt úp theo chữ thập quanh tâm bàn. Lề an toàn trong bàn là 206px từ mép khung. Nút hành động gom góc dưới phải trên bàn chơi.

Màn tiêu đề: quạt năm lá Red Pawn xoay −32° / −16° / 0 / 16° / 32° quanh gốc dưới lá, nửa dưới các lá được che dần (mask 70% → 78% chiều cao) để chìm sau chữ "FIVE PAWNS".

Execution: bộ khung đao chiếm giữa khung (cột x 568–1352, xà y 86). Sáu dây cách đều 104px, đánh số I–VI trên xà. Thớt và bàn tay nằm dưới lưỡi đao, bàn gỗ chỉ lộ ở đáy. Biên bản trái, bảng ngón phải, bảng Take the Blade góc dưới trái, nút con dấu góc dưới phải. Khoảng cách: 8px giữa thành phần HUD, 6px giữa chip, 10px giữa lá trong vòng, 18px giữa các nút xếp chồng.

Vật trên giấy được dán lệch, không thẳng hàng: nút con dấu −1.5°, biên bản −2.2°, bảng ngón +1.6°, bảng Take the Blade +1.2°, bảng "Calls" −2°. Trong Godot: đặt `rotation` của Control tương ứng, giữ pivot ở tâm.

## Elevation & Depth

Chiều sâu có hai chế độ. UI giấy (bài, bảng, nút) là vật nằm trên bàn dưới một nguồn sáng: bóng đổ mềm, rơi thẳng xuống. Vật minh họa in khắc (bàn tay, khung đao, thớt, tranh lá bài) không có bóng mềm: chiều sâu chỉ bằng mảng mực phẳng (bóng đao trên thớt là một mảng mực 55%, không blur).

### Shadow Vocabulary
- **Lá trên bàn** (`drop-shadow(0 10px 14px rgba(0,0,0,.65))`): bóng của mặt lá, đi theo mép cháy rách trong suốt của PNG chứ không theo hình chữ nhật. Trong Godot: bóng nướng sẵn hoặc một `TextureRect` bản sao tô đen, lệch 10px, làm mờ.
- **Vật trên bàn** (`0 10px 22px rgba(0,0,0,.6)`): lưng bài, bảng tên (26px blur), nút con dấu (28px, .7).
- **Lá được nhấc** (`0 34px 40px rgba(0,0,0,.7)`): lá đang chọn, nhấc 40px.
- **Bàn trên nền** (`0 40px 90px rgba(0,0,0,.8)`): bàn sơn mài trên nền xoáy.

### CRT post-process (mọi màn)
Scanline đen 28% mỗi 4px, lưới RGB rất nhẹ (3–3.5%), vignette cong (trong suốt tới 58%, đen 92% ở mép), bóng trong 120px, vệt sáng kính góc trên trái 7%. Trong Godot: một `CanvasLayer` trên cùng với `ColorRect` shader đọc `SCREEN_TEXTURE`, nhận tham số `ca`.

**Chromatic aberration theo trạng thái** (hệ số `ca`, lệch đỏ −2px×ca, lam +2px×ca trên chữ sáng):
- Tiêu đề: 1.0
- Bàn chơi: 1.3
- Execution: 2.6, lên 3.2 khi rê chuột hoặc focus vào một dây.

**Vignette căng thẳng** (chỉ Execution): một lớp ellipse đỏ đen (trong suốt tới 55%, `rgba(30,0,0,.7)` ở mép) dưới lớp CRT, hiện ra trong 0.3s khi rê chuột vào dây. Trong Godot: `ColorRect` shader, tham số `tension` tween 0→1.

### Nền xoáy theo trạng thái
Tính trên lưới 240×135 rồi phóng to không lọc (nearest), phân dải 6 bậc kiểu poster, tối dần ra mép. Bốn điểm màu RGB từ tối tới sáng:
- **calm** (tiêu đề): 12,8,6 → 30,15,10 → 58,19,13 → 92,27,17; xoắn 1.3, tốc 0.06, 7 vòng.
- **table** (chia bài): 10,7,5 → 24,12,8 → 44,16,11 → 66,21,14; xoắn 1.6, tốc 0.08, 8 vòng.
- **blood** (Execution): 16,4,3 → 62,9,6 → 122,20,13 → 184,38,26; xoắn 2.8, tốc gốc 0.12, 11 vòng; cả khung cảnh nghiêng −0.6° và phóng 1.02.

Tốc độ xoáy tỉ lệ với số Death Rope X: `tốc = tốc gốc × (1 + 0.35·X)`. Trong Godot: `SubViewport` 240×135 với shader canvas_item nhận uniform `death_ropes`, `TextureRect` hiển thị với `texture_filter = NEAREST`. Tắt chuyển động khi người chơi bật giảm chuyển động; giữ khung tĩnh.

### Named Rules
**The Một Nguồn Sáng Rule.** Bóng của UI giấy luôn rơi thẳng xuống, mềm, đen; độ cao càng lớn bóng càng dài và mờ. Không có bóng màu, không có glow.

**The Căng Thẳng Là Tham Số Rule.** Độ căng thẳng chỉ được nâng bằng bốn núm: bảng màu và tốc độ xoáy, hệ số `ca`, vignette căng thẳng, độ nghiêng khung. Không thêm hiệu ứng mới để báo nguy.

## Shapes

Góc bo nhỏ như giấy cắt tay (chip 3px, lá bài và bảng 4px, nút con dấu 6px); chỉ khung CRT (34px) và bàn (40px) bo lớn. Mép mặt lá bài không thẳng: giấy bị cháy rách (dịch chuyển nhiễu 9px), nên hình bao thật của lá là mép rách trong suốt của PNG.

Hình dạng nhận diện của UI là **viền khắc kép**: ba vòng lồng nhau mực, giấy sáng, mực (3 / 7 / 9px trên lưng bài, vòng giữa là `do`; 2 / 5 / 6px trên bảng tên; 4 / 8 / 10px trên nút con dấu, đảo màu thành giấy, son, giấy). Ô trống trong vòng bài là khung đứt nét giấy dó 45%. Trong Godot: viền kép dựng bằng `NinePatchRect` từ một texture giấy có sẵn viền, không dùng StyleBoxFlat nhiều lớp.

Mặt lá bài có hình học riêng: **viền đôi mực** quanh ô tranh (nét ngoài 2.6, nét trong 1, cách 3) và **hoa thị 8 cánh nét đôi** của bộ Đỏ (8 vòng r12 nét 2.8 và r8.5 nét 1.4 quanh tâm, đĩa giấy r25, hai vòng r24 / r20).

Hình dạng nhận diện của vật minh họa là **bản in khắc gỗ**: màu phẳng, keyline mực dày (6–7px trên khung, thớt, lưỡi; 1.6–1.8px trên icon bàn tay 64px), đường khắc màu giấy 2–2.4px ở 50–85% độ phủ chạy theo thớ gỗ, vòng tuổi hay song song lưỡi. Không gradient, không blur.

Chất liệu bề mặt giấy UI là nhiễu sợi kéo dài theo chiều ngang (fractal noise tần số 0.035×0.9) đè lên gradient giấy 170°. Bộ lọc **woodcut** (nhiễu tần số 1.1 cắt ngưỡng làm mòn nét mực, dịch chuyển 2.4px) phủ lên tiêu đề khắc lớn, ấn The House, ấn 五 trên lưng bài và toàn bộ bộ khung đao; không phủ lên VT323 và nhãn số dây. Mặt lá bài mang bộ lọc mép nét sần của riêng nó (nhiễu 0.06, dịch chuyển 2.5) đã nướng sẵn trên chữ, hoa thị, viền ô tranh và máu; không phủ thêm woodcut lên PNG. Trong Godot: một shader canvas_item `woodcut` dùng chung, gán bằng `material` cho node cha.

## Components

### Lá bài (signature)
Tờ tranh Tam Cúc kinh dị trên giấy dó cũ, khổ hẹp dài 120×410 (≈1:3.42, người dùng duyệt thay cho 120×360). Định dạng phát hành duy nhất là PNG 3× (`assets/cards/png/<suit>_<name>.png`, 360×1230, nền trong suốt); SVG trong `assets/cards/` chỉ là nguồn dựng. Các khổ hiển thị: mặc định 110×376, tay bài 100×342, vòng bài 56×191, bài úp đối thủ 44×150, quạt tiêu đề 150×513. Mọi khổ giữ đúng tỉ lệ 120:410.
- **Bố cục (theo khổ 120×410):** vùng chữ trên cao 78, ô tranh 96×238 tại (12, 86) viền đôi mực, vùng chữ dưới cao 78 xoay 180° để lá đọc được từ cả hai đầu.
- **Hai bộ dùng chung bảy chữ:** 將 士 象 車 馬 砲 卒 (General, Advisor, Elephant, Chariot, Horse, Cannon, Pawn). Bộ Đỏ có hoa thị son ấn sau chữ Hán; bộ Đen không hoa thị, tranh đổi màu trong bảng khoá cho ngả lạnh và phủ mốc dày hơn (85% so với 60%). Hai bộ phân biệt bằng hoa thị và nhiệt màu, không bằng màu chữ.
- **Giấy:** sợi giấy, vệt ố loang theo seed, mốc lốm đốm chỉ dồn về mép (mask tỏa từ giữa), góc tối cháy, mép cháy rách hai lớp (mép cháy 12, mốc 5).
- **Ruột tranh:** cắt từ ảnh art direction, phóng 4×, ép về bảng màu khoá, gom điểm lẻ cho mảng phẳng, vector hoá bằng vtracer. Không vẽ tay lại.
- **Máu (seed theo lá):** hai vệt chảy từ mép trên ô tranh, một giọt nhỏ gần mép trên, một vệt máu khô dọc một mép bài (trái hoặc phải theo seed). General, Elephant, Chariot, Cannon có máu tràn qua mép dưới ô tranh xuống vùng chữ dưới.
- **Không có trên mặt lá:** tên Latin, số, vạch chức. Tên tiếng Anh nằm ở `title` (tooltip) và `alt`.
- **Lưng:** son trầm, hoa văn đồng tiền khắc lặp mỗi 22px (so le 11px), ấn tròn chữ 五 giữa lá trong viền giấy kép, viền khắc kép mực/giấy/mực. Bài chưa lật luôn là lưng.
- **Chọn:** nhấc 40px, bóng dài ra; nghiêng 3D theo con trỏ tối đa ±9° trục X, ±11° trục Y; chuyển động 0.35s ease-out mạnh (`cubic-bezier(.16,1,.3,1)`).
- **Dựng lại:** `python -P tools/build_card.py all`, xuất PNG qua `assets/cards/bake.html`, rồi ghi lại metadata nguồn gốc (xem PROVENANCE.md).
- **Godot:** `TextureRect` nạp PNG, `expand_mode` giữ tỉ lệ, filter linear có mipmap (bản 3× thu nhỏ về 100–150px); `tooltip_text` mang tên tiếng Anh. Không dùng SVG trong Godot: font web và filter không chạy qua ThorVG. Lưng bài vẫn là `TextureRect` NinePatch giấy son.

### Bảng tên (plaque)
Tấm giấy dó dán lên bàn. Tên Bevan 30px, vai trò VT323 24px mực nhạt, hàng dưới gồm icon bàn tay và "N tricks". Dưới cùng là hàng chip debuff của mỗi ngón đã mất (−1 charm slot / no auto-sort / no history). Cùng chất liệu này làm biên bản, bảng ngón, bảng "Calls" và bảng Take the Blade (padding 16–26px, xoay lệch). Ấn The House là chữ 莊 72px son có woodcut.

### Nút con dấu (seal button)
Con dấu son đóng lệch −1.5°. Chữ Bevan giấy sáng 34–44px, dòng phụ VT323 24px. Viền kép đảo màu. Hover: nhấc 3px, phóng 1.02, sáng 1.1, 0.25s. Focus: viền giấy sáng 3px cách 6px. **Khóa:** mặt nút chuyển son xỉn, chữ giấy tối `#d9c3ae`, con trỏ not-allowed, dòng phụ giữ nguyên để giải thích vì sao ("after Tú decides · 4s"). Mỗi màn chỉ một nút con dấu, là hành động chính. Mục menu đang chọn trên màn tiêu đề dùng cùng chất liệu (lệch −1.2°).

### Ghost button
Hành động phụ. Nền than 55%, viền giấy dó 55% 2px, chữ VT323 30px trắng điệp. Hover: viền lên giấy sáng. Focus: viền giấy sáng 3px cách 4px.

### Chip
Nhãn trạng thái nhỏ son/giấy sáng, VT323 22px, bo 3px. Dùng cho debuff ngón mất trên bảng tên.

### Bảng trạng thái (status plaque)
Khi một quyết định thuộc về người khác (Take the Blade trên màn của người đang lên thớt), cửa sổ đó là bảng giấy `role="status"` không bấm được: tên và vai trò người quyết định, số đếm ngược Bevan son 44px bên phải. Không bao giờ vẽ nó như nút.

### Bàn sơn mài
Gỗ mít sẫm có vân kéo dài, gradient tỏa từ giữa. Mép: vành đen 16px, chỉ son trầm 2px, vành đen ngoài; trong lòng chỉ đồng mảnh. Một vệt bóng sơn mài chéo 115° (tối đa 11% sáng). Bảng HUD đặt trên bàn dùng nền than 62% và viền giấy dó 40%.

### Mạng: icon bàn tay
Mỗi người chơi có năm ngón; icon là bàn tay khắc gỗ 5 ngón, mặc định 64px (72px trên bảng ngón ở Execution), màu da phẳng, keyline mực. Ngón mất là mỏm cụt quấn băng giấy sáng, đỉnh băng thấm máu (`mau-bang`). Thứ tự mất: út, áp út, giữa, trỏ, cái cuối cùng. `aria-label` đọc "N of 5 fingers, lost: …". Effigy không có icon (không bao giờ bị chặt). Trong Godot: `TextureRect` từ atlas 6 trạng thái (0–5 ngón mất), hoặc `Control._draw()` với cùng hình học.

### Bộ khung đao Execution (signature)
Khung gỗ hai cột và một xà, đường khắc thớ màu giấy. Đại đao treo bằng 6 dây gai xoắn; mỗi dây là bốn nét chồng: vùng bắt chuột trong suốt 34px, keyline mực 15px, viền sáng 19px (chỉ hiện khi rê chuột), sợi gai 10px tô bằng pattern sọc chéo 32° (gai / gai tối). Đầu dây có khuy thép viền giấy. Thân đao thép, mép lưỡi đã mài, ba đường khắc song song lưỡi, một vệt máu khô. Dưới đao là thớt cắt ngang thớ (vòng tuổi khắc) và bàn tay của người lên thớt, các ngón đã mất quấn băng. Nhãn số La Mã I–VI trên xà là ô giấy viền mực; dây đang trỏ đổi ô son viền giấy sáng.
- **Rê chuột / focus dây:** dây rung kiểu bước (`steps(2)`, ±2.5px, ±0.5°, 0.09s), sợi gai sáng lên, `ca` lên 3.2, vignette căng thẳng hiện. Giảm chuyển động: tắt rung, giữ sáng và vignette.
- **Không có gì trên màn để lộ sợi nào là Death Rope.**
- **Godot:** khung, thớt, lưỡi là `Polygon2D` màu phẳng với `Line2D` keyline; dây là `Line2D` với texture sọc chéo, `texture_mode = TILE`; rung bằng `AnimationPlayer` track rời rạc; cả nhóm dùng chung material `woodcut`.

### Vết máu và sẹo phiên chơi
Vết máu vẽ trên lưới thấp (vd 44×34) rồi phóng 6–8 lần không lọc. Vũng là 9 đĩa gộp lại, quanh đó 30 giọt văng nhỏ dần ra xa; viền 1px máu khô, thân trộn hai sắc máu, đốm máu tươi thưa. Độ mờ 92% (vết cũ 70–85%). **Một vết cho mỗi ngón mất trong phiên** (của mọi người chơi), seed và vị trí cố định, ở lại trên bàn qua mọi màn. Trên thớt, mỗi ngón mất là một vết chém khắc (nét mực 7px, đường khắc giấy) kèm một vệt máu khô: số sẹo trên thớt luôn bằng số vết máu trên bàn. Trong Godot: sinh `Image` theo seed, `ImageTexture` với filter NEAREST; sẹo thớt là decal `Sprite2D` thêm vào theo danh sách ngón mất. Máu pixel trên bàn và máu khắc trên lá bài là hai chất liệu khác nhau, không trộn.

## Do's and Don'ts

### Do:
- **Do** dựng mọi bề mặt UI sáng bằng giấy dó có sợi và viền khắc kép mực/giấy/mực.
- **Do** dùng mặt lá bài từ PNG đã duyệt (`assets/cards/png`), giữ tỉ lệ 120:410; đổi mặt bài bằng cách sửa `tools/build_card.py` và dựng lại, không vẽ đè bằng CSS hay shader.
- **Do** giữ mặt lá trong 11 màu khoá; bộ Đen đổi màu trong bảng khoá, máu và mực không đổi.
- **Do** vẽ vật minh họa (bàn tay, khung đao, thớt) như bản in khắc gỗ: màu phẳng, keyline mực dày, đường khắc màu giấy, phủ woodcut.
- **Do** giữ hệ số chromatic aberration 1.0 / 1.3 / 2.6 cho tiêu đề / bàn chơi / Execution, 3.2 khi rê chuột vào dây.
- **Do** đổi bảng màu nền xoáy theo trạng thái (calm, table, blood) và tăng tốc theo số Death Rope, thay vì thêm hiệu ứng báo nguy mới.
- **Do** viết mọi chữ trong game bằng tiếng Anh theo thuật ngữ GDD §0; tên lá bài ở tooltip và `alt`, không in trên lá.
- **Do** để mỗi ngón mất lại một vết máu trên bàn và một vết sẹo trên thớt, cố định suốt phiên.
- **Do** phóng to nền xoáy và máu trên bàn bằng nearest-neighbor; giữ pixel vuông.

### Don't:
- **Don't** dùng bàn nỉ xanh casino, UI neon, kính mờ hay thẻ phẳng bo tròn lớn.
- **Don't** dùng đồng thau cho nút, chữ, tiêu đề hay viền bảng.
- **Don't** để lộ mặt lá đang úp, hay để lộ sợi nào là Death Rope, kể cả khi hover hay trong hiệu ứng.
- **Don't** in tên Latin, số hay vạch chức lên mặt bài.
- **Don't** dùng màu `card-*` (xanh rêu, mốc, hoàng thổ) cho UI, hay màu UI lên mặt lá.
- **Don't** đưa SVG lá bài vào Godot; chỉ PNG.
- **Don't** phủ woodcut lên chữ VT323 hay lên PNG lá bài, hay làm mượt pixel của nền xoáy và máu trên bàn.
- **Don't** dùng gradient hay blur trên vật minh họa in khắc; bóng của chúng là mảng mực phẳng.
- **Don't** đặt bóng cứng lệch hay bóng màu dưới UI giấy; bóng luôn mềm, đen, rơi thẳng xuống.
- **Don't** vẽ một cửa sổ chỉ người khác bấm được thành nút; dùng bảng trạng thái có đếm ngược.
