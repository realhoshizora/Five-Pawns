# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

> Ghi chú: sản phẩm thật là game PC (Godot 4). "web" ở đây chỉ là chất liệu làm mockup: các màn HTML tĩnh chụp ra PNG để chốt hướng hình ảnh. Khung chuẩn là 1920×1080, 16:9, điều khiển bằng chuột.

## Stack

- Game: Godot 4.7 + GDScript. Engine logic thuần nằm ở `core/`, xem `docs/GDD.md`.
- Mockup: HTML/CSS tĩnh trong `mockups/`, dùng xong bỏ. Giai đoạn 3 dựng lại bằng scene và shader Godot.

## Users

Người chơi PC/Steam thích game bài roguelike và tabletop u tối, chơi một mình với bot hoặc co-op 2–4 người với bạn bè.
- Người Việt đã quen Tam Cúc: không cần giải thích luật, đọc được chữ trên mặt bài.
- Người chơi quốc tế chưa biết Tam Cúc: cần nhận ra chức của quân bài và luật đè bài mà không phải đọc hướng dẫn dài.
Luật và giao diện trong game **toàn bộ bằng tiếng Anh**. Mặt bài giữ chữ Hán gốc của bộ Tam Cúc 32 lá, cộng vạch chức để ai cũng đọc được. Thuật ngữ xem `docs/GDD.md` mục 0.

## Product Purpose

Five Pawns là game bài chiến thuật kinh dị tâm lý, dựa trên Tam Cúc truyền thống (32 lá, 2 màu Đỏ/Đen). Cuối mỗi ván, người thua nặng nhất phải lên thớt **Chặt Ngũ Chỉ**: lưỡi đại đao treo bằng 6 sợi dây gai, trong đó có X Dây Tử, và người đó phải tự cắt một sợi (Russian Roulette kiểu cổ phong). Tên game có hai nghĩa: 5 quân Tốt và 5 ngón tay. Game thành công khi mỗi lần lật bài đều căng thẳng, vì đến cuối ván nó biến thành số Dây Tử trên thớt.

## Positioning

Đây là game bài roguelike duy nhất dùng bộ Tam Cúc 32 lá thật và luật thật: đặt úp, đè bài, ván Kết, Tứ tử/Ngũ tử. Kết quả ván bài quyết định trực tiếp số đạn nạp vào ổ. Co-op PvE chống Nhà Cái, đồng đội có thể gánh đạn thay nhau.

## Operating Context

- Bàn 4 ghế: Nhà Cái (AI) ở ghế 0, người chơi ở ghế 1–3, ghế trống có Hình nhân (bot) ngồi.
- Mỗi người 8 lá. Người cầm cái đặt úp 1–5 lá, những người khác úp đúng số lá đó, sau đó lật cùng lúc.
- Cuối ván, đúng một người lên thớt: người ăn ít vòng nhất, trừ người ăn Kết. Số Dây Tử: 1 mặc định, 2 nếu bị đè ở Kết, 3 nếu Kết bằng đôi/bộ ba, 4 Tứ tử, 5 Ngũ tử.
- Ai cũng có 5 ngón (kể cả Nhà Cái). Mỗi ngón mất kèm một debuff vĩnh viễn; mất ngón Cái là bị loại. Đồng đội có thể "Take the Blade" nhận thay khi người lên thớt còn 1–2 ngón.
- Mất ngón: vết máu và sẹo ở lại trên thớt/bàn trong suốt phiên chơi; bàn tay ở các ván sau hiện ngón đã mất quấn băng.

## Capabilities and Constraints

- Bộ bài: mỗi màu có Tướng×1, Sĩ×2, Tượng×2, Xe×2, Pháo×2, Mã×2, Tốt×5. Thứ tự Tướng > Sĩ > Tượng > Xe > Pháo > Mã > Tốt; cùng chức thì Đỏ ăn Đen.
- Engine luật đã xong và có unit test (Giai đoạn 2). Chưa có hình ảnh, âm thanh hay mạng.
- Mạng: 5 ngón cho mọi ghế còn mạng. 6 dây, Dây Tử 1–5.
- Chưa quyết: danh sách Bùa, cân bằng Dây Tử, cách relay khi chơi online. Debuff mất ngón cần có sẵn các tính năng ô Bùa, tự xếp bài, lịch sử lá đã đánh, ping.

## Brand Commitments

Hướng hình ảnh do người dùng chốt trong brief, đây là ràng buộc:
- Chất liệu bài Tam Cúc dân gian và tranh khắc gỗ Đông Hồ, bảng màu tối: đỏ son, đen mực, vàng giấy dó cũ.
- Hậu kỳ màn hình CRT: scanline nhẹ, cong viền, chromatic aberration tăng theo độ căng thẳng.
- Nền shader xoáy đổi màu theo trạng thái: trầm khi chia bài, đỏ thẫm khi vào Hành Quyết, tốc độ xoáy tỷ lệ với số Dây Tử.
- Bàn tay và khung đao vẽ kiểu pixel / tranh khắc gỗ dân gian. Tuyệt đối không dùng 3D tả thực.
- Máu kiểu pixel/retro có kiểm soát thẩm mỹ, vết máu và sẹo lưu lại trên thớt và mặt bàn gỗ.
- Hình ảnh phải tự vẽ. Lấy cảm hứng từ thể loại, nhưng không sao chép tên, nhân vật, art hay giao diện của bất kỳ game nào đã có.

## Evidence on Hand

- `docs/GDD.md`: luật, state machine, kiến trúc.
- `core/`, `tests/`: engine luật và test.
- Chưa có art, logo, font, âm thanh hay ảnh chụp game. Mockup không được bịa review, giải thưởng hay số liệu người chơi.

## Product Principles

1. Luật Tam Cúc thật là xương sống. Không đổi bộ bài hay thứ tự quân cho dễ.
2. Lá bài nào cũng phải thấy được hậu quả: số đạn luôn hiển thị và gắn với kết quả ván.
3. Thông tin úp là thông tin úp: giao diện không bao giờ để lộ bài người khác trước khi lật.
4. Người nước ngoài phải đọc được chức quân bài chỉ bằng hình, không cần biết chữ.
