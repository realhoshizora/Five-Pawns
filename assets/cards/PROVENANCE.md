# Nguồn gốc asset lá bài

| Mục | Giá trị |
|---|---|
| Nguồn ruột tranh | `assets/ref/tamcuc_horror_ref.webp` — ảnh art direction 7 lá Tam Cúc kinh dị do người dùng cung cấp (1024×572). |
| Cắt | Toạ độ ô tranh từng lá trong `PANELS` của `tools/build_card.py`. |
| Xử lý | Phóng to 4× (Lanczos) → lọc trung vị → ép về bảng màu khoá 11 màu (bộ Đen đổi màu trong bảng khoá qua `BLACK_REMAP`, máu giữ nguyên) → lọc mode. |
| Vector hoá | vtracer 0.6.15 (color, stacked, spline, filter_speckle 12, color_precision 6, layer_difference 16). |
| Khung | SVG viết tay trong `tools/build_card.py`: giấy dó, vệt ố, mốc, mép cháy rách, hoa thị 8 cánh, viền đôi, máu theo seed. |
| Chữ Hán | LXGW WenKai TC 700 (khải thư bút lông, gần nét chữ trong ảnh tham chiếu), tải qua Google Fonts `@import`. |
| Định dạng phát hành | **Chỉ PNG** (`assets/cards/png/*.png`, 360×1230, nền trong suốt) là file dùng trong game. SVG là nguồn dựng: chữ phụ thuộc font web và filter không chạy trong Godot (ThorVG). |
| Dựng lại | `python -P tools/build_card.py all`, rồi xuất PNG bằng Edge headless mở `assets/cards/bake.html?card=<suit>_<name>`. Xuất lại PNG sẽ mất metadata nguồn gốc: chạy lại `impeccable embed-prompt <png> --prompt "Origin: …"` cho từng file (kiểm tra bằng `embed-prompt --scan assets/cards/png`). |
