class_name Combo
## Kiểm tra bộ bài hợp lệ và so sánh bộ theo luật Tam Cúc.

enum Type { INVALID, SINGLE, PAIR, TRIPLE, FOUR_PAWNS, FIVE_PAWNS }

const _ELEPHANT_ADVISOR_GENERAL := [Card.Rank.ELEPHANT, Card.Rank.ADVISOR, Card.Rank.GENERAL]
const _HORSE_CANNON_CHARIOT := [Card.Rank.HORSE, Card.Rank.CANNON, Card.Rank.CHARIOT]


## Trả về {type, strength}; type là INVALID nếu không phải bộ hợp lệ.
## strength chỉ có nghĩa khi so hai bộ cùng type.
static func classify(cards: Array) -> Dictionary:
	var bad := {type = Type.INVALID, strength = -1}
	var n := cards.size()
	if n == 0 or n > 5:
		return bad
	for c in cards:
		if typeof(c) != TYPE_INT or c < 0 or c >= Card.COUNT or cards.count(c) > 1:
			return bad
	var s0 := Card.suit(cards[0])
	var ranks := []
	for c in cards:
		if Card.suit(c) != s0:
			return bad
		ranks.append(Card.rank(c))
	ranks.sort()
	var red := 1 if s0 == Card.Suit.RED else 0
	var all_pawns := ranks.count(Card.Rank.PAWN) == n
	match n:
		1:
			return {type = Type.SINGLE, strength = ranks[0] * 2 + red}
		2:
			if ranks[0] == ranks[1] and ranks[0] != Card.Rank.GENERAL:
				return {type = Type.PAIR, strength = ranks[0] * 2 + red}
		3:
			if ranks == _ELEPHANT_ADVISOR_GENERAL:
				return {type = Type.TRIPLE, strength = 2 + red}
			if ranks == _HORSE_CANNON_CHARIOT:
				return {type = Type.TRIPLE, strength = red}
		4:
			if all_pawns:
				return {type = Type.FOUR_PAWNS, strength = red}
		5:
			if all_pawns:
				return {type = Type.FIVE_PAWNS, strength = red}
	return bad


## Bộ `challenger` chỉ ăn được bộ đang dẫn khi cùng loại và mạnh hơn hẳn; hòa thì người đặt trước giữ.
static func beats(challenger: Dictionary, best: Dictionary) -> bool:
	return challenger.type != Type.INVALID and challenger.type == best.type and challenger.strength > best.strength
