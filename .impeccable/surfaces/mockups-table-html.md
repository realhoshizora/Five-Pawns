---
version: 1
slug: "mockups-table-html"
primary_target: "mockups/table.html"
related_targets: ["mockups/title.html","mockups/execution.html"]
---

## Scope

Ba mockup tĩnh 1920×1080 cho Five Pawns: màn tiêu đề (`mockups/title.html`), bàn chơi (`mockups/table.html`), pha Hành Quyết Chặt Ngũ Chỉ (`mockups/execution.html`). Mode: Experience. Mockup dùng để chốt hướng hình ảnh, sau đó bỏ; Giai đoạn 3 dựng lại bằng Godot.

Người xem: chính người dùng (dev). Câu hỏi họ cần trả lời: hướng hình ảnh này có đúng là game mình muốn làm không?

Ràng buộc: hướng hình ảnh do người dùng chốt trong brief (xem PRODUCT.md, Brand Commitments). **Chữ trong game bằng tiếng Anh.** Mặt bài theo art direction người dùng đưa (ảnh 7 lá Tam Cúc kinh dị, chép ở `assets/ref/tamcuc_horror_ref.webp`) và spec của họ: khổ 120×410 (người dùng duyệt khổ B thay cho 120×360), vùng chữ Hán trên/dưới mỗi vùng 78, chữ đáy xoay 180°, ô tranh 96×238 viền đôi mực, bảng màu khoá 11 màu. Ruột tranh do vtracer vẽ lại từ ảnh tham chiếu (người dùng chọn hướng A). Chữ Hán dùng LXGW WenKai TC (khải thư bút lông) để gần nét chữ trong ảnh tham chiếu, cỡ ngang hoa thị. PNG là định dạng phát hành duy nhất; nguồn gốc ghi ở `assets/cards/PROVENANCE.md`. Không còn vạch chức; tên tiếng Anh hiện khi rê chuột. Asset: `assets/cards/` (SVG) và `assets/cards/png/` (PNG 3×), dựng bằng `tools/build_card.py`. Lá bài không bao giờ lộ mặt khi đang úp. Không có gì trên màn để lộ sợi nào là Dây Tử. Mọi tên người chơi và số liệu ván là dữ liệu minh họa.

Thích nghi có chủ ý: GDD 3.5 muốn bàn tay cầm bài ở các ván sau hiện ngón đã mất quấn băng. Mockup chỉ thể hiện điều này qua icon bàn tay trên bảng tên. Bàn tay cầm bài thật dựng ở Giai đoạn 3 (Godot).

## Direction contract

THESIS: Bàn Tam Cúc là một bàn thờ xét xử sơn mài. Lá bài chính là một tờ tranh khắc gỗ Đông Hồ in trên giấy dó, ánh sáng duy nhất là màn CRT. Hướng này không dùng bàn nỉ xanh casino và không dùng UI neon.

OWN-WORLD: nền đen than tre (#0e0a07) có xoáy đỏ son trầm. Mặt bàn gỗ mít sẫm. Lá bài theo bài Tam Cúc thật: giấy dó cũ #CBB793 với mép cháy #7A6648 và mốc #2E3529; chữ Hán mực #14110F ở trên, tranh dân gian ở giữa, chữ lộn ngược ở dưới; hai màu dùng chung bộ chữ 將士象車馬砲卒, bộ Đỏ có hoa cúc 8 cánh nét đôi son #9E2622 sau chữ, bộ Đen không hoa và ngả tro lạnh. Tranh kinh dị: Tướng, Sĩ, Tốt là xác đầu lâu; ngựa thối; máu chảy từ mép ô tranh và loang dưới chân (#8E1414 / #4A0A0A). Lưng bài màu son với hoa văn đồng tiền khắc. Mạng là icon bàn tay 5 ngón, ngón mất là mỏm quấn băng thấm máu. Hành Quyết là khung gỗ, lưỡi đại đao treo bằng 6 dây gai xoắn, thớt gỗ cắt ngang thớ có sẹo. Tất cả vẽ kiểu in khắc gỗ: nét mực đen dày, màu phẳng, đường khắc trắng, không gradient. Chữ: Bevan khắc slab cho tiêu đề, VT323 cho HUD CRT, LXGW WenKai TC 700 cho chữ Hán trên bài (đã nướng vào PNG); Noto Serif TC 900 chỉ còn cho chữ 五 ở lưng bài, ấn 莊 và phụ đề 五子. Hậu kỳ: scanline, vignette cong, chromatic aberration.

STORY: người xem nhận ra ngay đây là bài Tam Cúc thật. Họ thấy lưỡi đao và số Dây Tử treo trên mỗi ván, và tin rằng chất dân gian cùng chất kinh dị là một thế giới chứ không phải lớp trang trí.

FIRST VIEWPORT: màn tiêu đề gồm năm lá Tốt Đỏ xòe hình quạt ở giữa, là vật thể chính. Chữ "FIVE PAWNS" khắc lớn đè lên, kèm "五子". Menu dọc bên trái dưới, mục chính là "Play offline". Bàn chơi nhìn từ trên xuống: The House ở trên, bạn ở dưới với tay 8 lá xòe, vòng bài úp ở giữa. Execution: lưỡi đao trên thớt ở giữa, 6 dây đánh số I–VI, ngón tay của bạn trên thớt, nút "Cut rope".

FORM: thế giới khắc gỗ Đông Hồ × bàn bài CRT, do brief ghim nguyên. seed: none (pinned): "Kết hợp chất liệu bài Tam Cúc dân gian / tranh khắc gỗ Đông Hồ với bảng màu tối u ám (đỏ son, đen mực, vàng giấy dó cũ) và hậu kỳ Balatro-style"; experience pinned by "Background shader xoáy động đổi màu theo trạng thái (trầm mặc khi chia bài -> đỏ thẫm …)", the user's ask "cho mình xem một vài hình ảnh về giao diện và ingame", and the replacement ending "Chặt Ngũ Chỉ … lưỡi đại đao treo bởi 6 sợi dây gai … background shader xoáy … tăng tốc độ xoáy tỷ lệ thuận với số Dây Tử".

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

Signature interaction: lá bài được chọn nhấc lên và nghiêng 3D về phía con trỏ. Rê chuột vào dây thì dây rung, chromatic aberration và vignette tăng. Bài chưa lật là lưng son úp. Chromatic aberration tăng dần từ màn tiêu đề tới Hành Quyết.
