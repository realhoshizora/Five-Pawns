class_name Card
## Một lá bài là một số nguyên 0..31: 0..15 là Đỏ, 16..31 là Đen.
## Giữ dạng int để state gửi qua mạng và so sánh được trực tiếp.

enum Rank { PAWN, HORSE, CANNON, CHARIOT, ELEPHANT, ADVISOR, GENERAL }
enum Suit { RED, BLACK }

const COUNT := 32
## Chức của 16 lá trong một màu: Tướng×1, Sĩ×2, Tượng×2, Xe×2, Pháo×2, Mã×2, Tốt×5.
const _LAYOUT := [
	Rank.GENERAL, Rank.ADVISOR, Rank.ADVISOR, Rank.ELEPHANT, Rank.ELEPHANT,
	Rank.CHARIOT, Rank.CHARIOT, Rank.CANNON, Rank.CANNON, Rank.HORSE, Rank.HORSE,
	Rank.PAWN, Rank.PAWN, Rank.PAWN, Rank.PAWN, Rank.PAWN,
]
const _NAMES := ["Tốt", "Mã", "Pháo", "Xe", "Tượng", "Sĩ", "Tướng"]


static func rank(id: int) -> int:
	return _LAYOUT[id % 16]


static func suit(id: int) -> int:
	return Suit.RED if id < 16 else Suit.BLACK


static func name_of(id: int) -> String:
	return "%s %s" % [_NAMES[rank(id)], "Đỏ" if suit(id) == Suit.RED else "Đen"]


## Id của lá thứ `nth` (đếm từ 0) có chức và màu cho trước; trả -1 nếu không có lá đó.
static func find(r: int, s: int, nth := 0) -> int:
	for i in 16:
		if _LAYOUT[i] == r:
			if nth == 0:
				return s * 16 + i
			nth -= 1
	return -1
