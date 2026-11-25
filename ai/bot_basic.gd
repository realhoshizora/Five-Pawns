class_name BotBasic
## Bot tạm cho Giai đoạn 3 (bot thật ở Giai đoạn 5). Chỉ đọc view_for(seat), không bao giờ thấy bài úp của người khác.
## Cầm cái: ra bộ mạnh nhất. Theo: có bộ cùng số lá thì ra bộ mạnh nhất, không thì đổ những lá yếu nhất.


static func choose(view: Dictionary) -> Dictionary:
	if view.phase == TamCucGame.Phase.EXECUTION:   # que chọn bừa
		return {type = "draw_stick", seat = view.seat, stick = randi() % TamCucGame.STICKS}
	if view.phase == TamCucGame.Phase.CHOP:        # hy sinh ngón Út trước, giữ ngón Cái tới cuối
		return {type = "chop", seat = view.seat, finger = view.fingers[view.seat].find(true)}
	var hand: Array = view.hand
	if view.trick_size == 0:
		return {type = "lead", seat = view.seat, cards = _strongest(hand, [1, 2, 3, 4, 5])}
	var n: int = view.trick_size
	var best := _strongest(hand, [n])
	if best.is_empty():
		var weak := hand.duplicate()
		weak.sort_custom(func(a, b): return _value(a) < _value(b))
		best = weak.slice(0, n)
	return {type = "follow", seat = view.seat, cards = best}


## Bộ hợp lệ mạnh nhất có số lá thuộc `sizes` (ưu tiên bộ nhiều lá hơn); [] nếu không có.
static func _strongest(hand: Array, sizes: Array) -> Array:
	var best := []
	var best_key := -1
	for mask in range(1, 1 << hand.size()):
		var pick := []
		for i in hand.size():
			if mask & (1 << i):
				pick.append(hand[i])
		if not sizes.has(pick.size()):
			continue
		var c := Combo.classify(pick)
		if c.type == Combo.Type.INVALID:
			continue
		var key: int = pick.size() * 100 + c.strength
		if key > best_key:
			best_key = key
			best = pick
	return best


static func _value(card: int) -> int:
	return Card.rank(card) * 2 + (1 if Card.suit(card) == Card.Suit.RED else 0)
