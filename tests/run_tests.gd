extends SceneTree
## Chạy: godot --headless --path . -s tests/run_tests.gd
## Mọi hàm test_* tự chạy. Exit code 1 nếu có test fail.

const R := Card.Suit.RED
const B := Card.Suit.BLACK
const K := Card.Rank

var _fails := 0
var _checks := 0
var _current := ""


func _init() -> void:
	var count := 0
	for m in get_method_list():
		if m.name.begins_with("test_"):
			_current = m.name
			call(m.name)
			count += 1
	print("%d tests, %d checks, %d failed" % [count, _checks, _fails])
	quit(1 if _fails else 0)


func check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		printerr("FAIL %s: %s" % [_current, msg])


func c(r: int, s: int, nth := 0) -> int:
	return Card.find(r, s, nth)


func pawns(s: int, n: int) -> Array:
	var out := []
	for i in n:
		out.append(c(K.PAWN, s, i))
	return out


func kind(cards: Array) -> int:
	return Combo.classify(cards).type


func wins(a: Array, b: Array) -> bool:
	return Combo.beats(Combo.classify(a), Combo.classify(b))


## Game đã chia bài, sau đó thay bài tay bằng `rigged` (các tay phải cùng số lá và không trùng nhau).
func rigged_game(rigged: Array, lead_seat := 0, mortal := [true, true, true, true]) -> TamCucGame:
	var g := TamCucGame.new(1, mortal)
	g.apply({type = "deal"})
	g.hands = rigged.duplicate(true)
	g.leader = lead_seat
	return g


func play(g: TamCucGame, seat: int, cards: Array) -> Array:
	var t := "lead" if seat == g.leader and g.trick_size == 0 else "follow"
	return g.apply({type = t, seat = seat, cards = cards})


func rejected(events: Array) -> String:
	return events[0].reason if events.size() == 1 and events[0].type == "rejected" else ""


# ---------- Bộ bài ----------

func test_deck_has_32_cards_with_traditional_counts() -> void:
	var counts := {}
	for id in Card.COUNT:
		var key := [Card.rank(id), Card.suit(id)]
		counts[key] = counts.get(key, 0) + 1
	for s in [R, B]:
		check(counts[[K.GENERAL, s]] == 1, "1 Tướng mỗi màu")
		for r in [K.ADVISOR, K.ELEPHANT, K.CHARIOT, K.CANNON, K.HORSE]:
			check(counts[[r, s]] == 2, "2 lá mỗi chức %d màu %d" % [r, s])
		check(counts[[K.PAWN, s]] == 5, "5 Tốt mỗi màu")
	check(c(K.PAWN, R, 5) == -1, "không có Tốt Đỏ thứ 6")
	check(Card.name_of(c(K.GENERAL, R)) == "Tướng Đỏ", "tên lá")


# ---------- Validator ----------

func test_valid_combos() -> void:
	check(kind([c(K.PAWN, B)]) == Combo.Type.SINGLE, "lẻ")
	check(kind([c(K.HORSE, R), c(K.HORSE, R, 1)]) == Combo.Type.PAIR, "đôi Mã Đỏ")
	check(kind([c(K.PAWN, B, 1), c(K.PAWN, B, 4)]) == Combo.Type.PAIR, "đôi Tốt Đen")
	check(kind([c(K.GENERAL, R), c(K.ADVISOR, R), c(K.ELEPHANT, R, 1)]) == Combo.Type.TRIPLE, "Tướng-Sĩ-Tượng")
	check(kind([c(K.CANNON, B), c(K.HORSE, B, 1), c(K.CHARIOT, B)]) == Combo.Type.TRIPLE, "Xe-Pháo-Mã, thứ tự lộn xộn")
	check(kind(pawns(R, 4)) == Combo.Type.FOUR_PAWNS, "Tứ tử")
	check(kind(pawns(B, 5)) == Combo.Type.FIVE_PAWNS, "Ngũ tử")


func test_invalid_combos() -> void:
	var bad := Combo.Type.INVALID
	check(kind([]) == bad, "rỗng")
	check(kind([c(K.HORSE, R), c(K.HORSE, B)]) == bad, "đôi khác màu")
	check(kind([c(K.HORSE, R), c(K.CANNON, R)]) == bad, "đôi khác chức")
	check(kind([c(K.GENERAL, R), c(K.GENERAL, B)]) == bad, "Tướng không có đôi")
	check(kind([c(K.GENERAL, R), c(K.ADVISOR, R), c(K.ELEPHANT, B)]) == bad, "bộ ba lẫn màu")
	check(kind([c(K.GENERAL, R), c(K.ADVISOR, R), c(K.CHARIOT, R)]) == bad, "Tướng-Sĩ-Xe không phải bộ ba")
	check(kind(pawns(R, 3)) == bad, "3 Tốt không phải bộ")
	check(kind(pawns(R, 3) + [c(K.PAWN, B)]) == bad, "Tứ tử lẫn màu")
	check(kind(pawns(R, 4) + [c(K.HORSE, R)]) == bad, "4 Tốt + Mã")
	check(kind(pawns(R, 5) + [c(K.PAWN, B)]) == bad, "6 lá")
	check(kind([3, 3]) == bad, "trùng id")
	check(kind([3.0]) == bad, "id không phải int")
	check(kind([32]) == bad, "id ngoài bộ")


func test_comparisons() -> void:
	check(wins([c(K.GENERAL, B)], [c(K.ADVISOR, R)]), "Tướng Đen > Sĩ Đỏ")
	check(wins([c(K.HORSE, B)], [c(K.PAWN, R)]), "Mã Đen > Tốt Đỏ")
	check(wins([c(K.PAWN, R)], [c(K.PAWN, B)]), "Đỏ ăn Đen cùng chức")
	check(not wins([c(K.PAWN, B)], [c(K.PAWN, R)]), "Đen không ăn Đỏ")
	check(not wins([c(K.ADVISOR, R, 1)], [c(K.ADVISOR, R)]), "hòa thì không ăn")
	check(wins([c(K.CHARIOT, R), c(K.CHARIOT, R, 1)], [c(K.CHARIOT, B), c(K.CHARIOT, B, 1)]), "đôi Xe Đỏ > đôi Xe Đen")
	check(wins([c(K.ELEPHANT, B), c(K.ELEPHANT, B, 1)], [c(K.CHARIOT, R), c(K.CHARIOT, R, 1)]), "đôi Tượng Đen > đôi Xe Đỏ")
	check(wins([c(K.GENERAL, B), c(K.ADVISOR, B), c(K.ELEPHANT, B)], [c(K.CHARIOT, R), c(K.CANNON, R), c(K.HORSE, R)]), "TST Đen > XPM Đỏ")
	check(wins([c(K.CHARIOT, R), c(K.CANNON, R), c(K.HORSE, R)], [c(K.CHARIOT, B), c(K.CANNON, B), c(K.HORSE, B)]), "XPM Đỏ > XPM Đen")
	check(wins(pawns(R, 4), pawns(B, 4)), "Tứ tử Đỏ > Tứ tử Đen")
	check(wins(pawns(R, 5), pawns(B, 5)), "Ngũ tử Đỏ > Ngũ tử Đen")
	check(not wins([c(K.GENERAL, R)], [c(K.PAWN, B), c(K.PAWN, B, 1)]), "khác loại không ăn")
	check(not wins([c(K.GENERAL, R), c(K.ADVISOR, R)], [c(K.PAWN, B), c(K.PAWN, B, 1)]), "rác 2 lá không ăn đôi")
	check(not wins(pawns(R, 4), pawns(B, 5)), "Tứ tử không ăn Ngũ tử")


# ---------- Engine ----------

func test_deal_is_deterministic_and_complete() -> void:
	var a := TamCucGame.new(42)
	var b := TamCucGame.new(42)
	a.apply({type = "deal"})
	b.apply({type = "deal"})
	check(a.hands == b.hands, "cùng seed cùng bài")
	var all := []
	for h in a.hands:
		check(h.size() == 8, "mỗi người 8 lá")
		all += h
	all.sort()
	check(all == range(32), "chia đủ 32 lá, không trùng")
	var other := TamCucGame.new(43)
	other.apply({type = "deal"})
	check(other.hands != a.hands, "khác seed khác bài")


func test_rejects_illegal_actions() -> void:
	var g := TamCucGame.new(7)
	check(rejected(g.apply({type = "lead", seat = 0, cards = []})) == "wrong_phase", "chưa chia")
	g.apply({type = "deal"})
	var h0: Array = g.hands[0].duplicate()
	var h1: Array = g.hands[1].duplicate()
	check(rejected(g.apply({type = "deal"})) == "wrong_phase", "chia giữa ván")
	check(rejected(g.apply({type = "cheat"})) == "bad_type", "type lạ")
	check(rejected(g.apply({type = "lead", seat = 9, cards = [h0[0]]})) == "bad_seat", "ghế lạ")
	check(rejected(g.apply({type = "lead", seat = 1, cards = [h1[0]]})) == "not_leader", "không phải cái")
	check(rejected(g.apply({type = "follow", seat = 1, cards = [h1[0]]})) == "not_your_turn", "theo trước khi cái đặt")
	check(rejected(g.apply({type = "lead", seat = 0, cards = [h1[0]]})) == "not_in_hand", "lá của người khác")
	check(rejected(g.apply({type = "lead", seat = 0, cards = [h0[0], h0[0]]})) == "not_in_hand", "nhân đôi một lá")
	check(rejected(g.apply({type = "lead", seat = 0, cards = [float(h0[0])]})) == "not_in_hand", "id float")
	check(rejected(g.apply({type = "lead", seat = 0, cards = "x"})) == "bad_cards", "cards không phải mảng")
	check(rejected(g.apply({type = "lead", seat = 0, cards = h0.slice(0, 6)})) == "invalid_combo", "6 lá")
	check(g.hands[0] == h0, "bị từ chối thì state không đổi")
	g.apply({type = "lead", seat = 0, cards = [h0[0]]})
	check(rejected(g.apply({type = "follow", seat = 0, cards = [h0[1]]})) == "already_played", "cái đặt hai lần")
	check(rejected(g.apply({type = "follow", seat = 1, cards = h1.slice(0, 2)})) == "wrong_count", "sai số lá")
	check(g.apply({type = "follow", seat = 1, cards = [h1[0]]})[0].type == "committed", "theo hợp lệ")
	check(rejected(g.apply({type = "follow", seat = 1, cards = [h1[1]]})) == "already_played", "theo hai lần")


func test_follower_beats_leader_and_takes_lead() -> void:
	var g := rigged_game([
		[c(K.HORSE, B)], [c(K.PAWN, R)], [c(K.GENERAL, R)], [c(K.ADVISOR, R)],
	])
	play(g, 0, [c(K.HORSE, B)])
	play(g, 3, [c(K.ADVISOR, R)])   # theo không cần đúng thứ tự
	play(g, 1, [c(K.PAWN, R)])
	var ev := play(g, 2, [c(K.GENERAL, R)])
	check(ev[1].type == "revealed" and ev[1].winner == 2, "Tướng Đỏ ăn vòng")
	check(g.leader == 2, "người ăn cầm cái")
	check(g.phase == TamCucGame.Phase.EXECUTION, "hết bài thì vào Hành Quyết")


func test_tie_goes_to_earlier_seat_clockwise() -> void:
	# Cái là ghế 2, thứ tự lật 2→3→0→1. Ghế 3 và ghế 1 cùng có đôi Tốt Đỏ: ghế 3 đặt trước nên thắng.
	var g := rigged_game([
		[c(K.HORSE, B), c(K.CANNON, B)],
		[c(K.PAWN, R), c(K.PAWN, R, 1)],
		[c(K.PAWN, B), c(K.PAWN, B, 1)],
		[c(K.PAWN, R, 2), c(K.PAWN, R, 3)],
	], 2)
	play(g, 2, [c(K.PAWN, B), c(K.PAWN, B, 1)])
	play(g, 1, [c(K.PAWN, R), c(K.PAWN, R, 1)])
	play(g, 0, [c(K.HORSE, B), c(K.CANNON, B)])
	var ev := play(g, 3, [c(K.PAWN, R, 2), c(K.PAWN, R, 3)])
	check(ev[1].winner == 3, "hòa: ghế đặt trước (3) giữ")


func test_ket_with_five_pawns_sends_next_seat_to_block() -> void:
	var junk := func(s, start): return [c(K.HORSE, s, start), c(K.CANNON, s, start), c(K.CHARIOT, s, start), c(K.ELEPHANT, s, start), c(K.ADVISOR, s, start)]
	var g := rigged_game([pawns(R, 5), junk.call(B, 0), junk.call(R, 1), junk.call(B, 1)], 0, [true, true, false, true])
	play(g, 0, pawns(R, 5))
	play(g, 1, g.hands[1].duplicate())
	play(g, 2, g.hands[2].duplicate())
	var ev := play(g, 3, g.hands[3].duplicate())
	var over: Dictionary = ev[-1]
	check(over.type == "hand_over" and over.ket_type == Combo.Type.FIVE_PAWNS, "Kết bằng Ngũ tử")
	# Ghế 1, 3 cùng 0 vòng (ghế 2 là Hình nhân): hòa thì chọn ghế 1, ngồi sát sau người ăn Kết.
	check(over.execution == {seat = 1, lethal = 1}, "Kết Ngũ tử: ghế 1 lên thớt, lần thua đầu = 1 que ngắn: %s" % [over.execution])


func test_red_five_pawns_overturns_black_five_pawns() -> void:
	var g := rigged_game([pawns(B, 5), pawns(R, 5),
		[c(K.HORSE, R), c(K.HORSE, R, 1), c(K.CANNON, R), c(K.CANNON, R, 1), c(K.GENERAL, R)],
		[c(K.HORSE, B), c(K.HORSE, B, 1), c(K.CANNON, B), c(K.CANNON, B, 1), c(K.GENERAL, B)]])
	play(g, 0, pawns(B, 5))
	play(g, 1, pawns(R, 5))
	play(g, 2, g.hands[2].duplicate())
	var ev := play(g, 3, g.hands[3].duplicate())
	check(ev[-1].ket_winner == 1, "Ngũ tử Đỏ lật kèo")
	check(ev[-1].execution == {seat = 2, lethal = 1}, "lên thớt: ghế 2, ngồi sát sau người ăn Kết: %s" % [ev[-1].execution])


func test_ket_by_single_and_pair_pick_loser() -> void:
	# Vòng 1: đôi, ghế 1 ăn. Vòng 2 (Kết): lẻ, ghế 1 ăn.
	var g := rigged_game([
		[c(K.PAWN, B), c(K.PAWN, B, 1), c(K.PAWN, B, 2)],
		[c(K.CHARIOT, R), c(K.CHARIOT, R, 1), c(K.GENERAL, R)],
		[c(K.HORSE, R), c(K.HORSE, R, 1), c(K.ADVISOR, R)],
		[c(K.PAWN, R), c(K.CANNON, B), c(K.PAWN, B, 3)],
	])
	play(g, 0, [c(K.PAWN, B), c(K.PAWN, B, 1)])
	play(g, 1, [c(K.CHARIOT, R), c(K.CHARIOT, R, 1)])
	play(g, 2, [c(K.HORSE, R), c(K.HORSE, R, 1)])
	play(g, 3, [c(K.PAWN, R), c(K.CANNON, B)])
	check(g.leader == 1 and g.tricks_won == [0, 1, 0, 0], "đôi Xe Đỏ ăn vòng 1")
	play(g, 1, [c(K.GENERAL, R)])
	play(g, 0, [c(K.PAWN, B, 2)])
	play(g, 2, [c(K.ADVISOR, R)])
	var ev := play(g, 3, [c(K.PAWN, B, 3)])
	check(ev[-1].ket_type == Combo.Type.SINGLE and ev[-1].execution == {seat = 2, lethal = 1}, "Kết lẻ: ghế 2 lên thớt: %s" % [ev[-1].execution])

	# Cùng tay bài nhưng Kết bằng đôi.
	g = rigged_game([
		[c(K.PAWN, B), c(K.PAWN, B, 1), c(K.HORSE, B)],
		[c(K.GENERAL, R), c(K.CHARIOT, R), c(K.CHARIOT, R, 1)],
		[c(K.ADVISOR, R), c(K.HORSE, R), c(K.HORSE, R, 1)],
		[c(K.PAWN, R), c(K.CANNON, B), c(K.PAWN, B, 3)],
	])
	play(g, 0, [c(K.HORSE, B)])
	play(g, 1, [c(K.CHARIOT, R)])
	play(g, 2, [c(K.ADVISOR, R)])
	play(g, 3, [c(K.PAWN, R)])
	check(g.leader == 2, "Sĩ Đỏ ăn vòng 1")
	play(g, 2, [c(K.HORSE, R), c(K.HORSE, R, 1)])
	play(g, 0, [c(K.PAWN, B), c(K.PAWN, B, 1)])
	play(g, 1, [c(K.GENERAL, R), c(K.CHARIOT, R, 1)])
	ev = play(g, 3, [c(K.CANNON, B), c(K.PAWN, B, 3)])
	check(ev[-1].ket_type == Combo.Type.PAIR and ev[-1].execution == {seat = 3, lethal = 1}, "Kết đôi: ghế 3 lên thớt: %s" % [ev[-1].execution])


func test_overtaken_in_final_seat_choice() -> void:
	# Ván một vòng: cái (ghế 0) dẫn bằng Mã Đen, ghế 2 đè bằng Xe Đen, ghế 3 đè tiếp bằng Tướng Đỏ.
	# Ai cũng 0 vòng; ghế 0 ngồi sát sau người ăn Kết nên lên thớt.
	var g := rigged_game([[c(K.HORSE, B)], [c(K.PAWN, R)], [c(K.CHARIOT, B)], [c(K.GENERAL, R)]])
	play(g, 0, [c(K.HORSE, B)])
	play(g, 1, [c(K.PAWN, R)])
	play(g, 2, [c(K.CHARIOT, B)])
	var ev := play(g, 3, [c(K.GENERAL, R)])
	check(ev[1].overtaken == [0, 2], "thứ tự bị đè: %s" % [ev[1].overtaken])
	check(ev[-1].execution == {seat = 0, lethal = 1}, "bị đè ở Kết: ghế 0 lên thớt: %s" % [ev[-1].execution])
	# Ghế 0 là Hình nhân: ghế 1 lên thớt.
	g = rigged_game([[c(K.HORSE, B)], [c(K.PAWN, R)], [c(K.CHARIOT, B)], [c(K.GENERAL, R)]], 0, [false, true, true, true])
	play(g, 0, [c(K.HORSE, B)])
	play(g, 1, [c(K.PAWN, R)])
	play(g, 2, [c(K.CHARIOT, B)])
	ev = play(g, 3, [c(K.GENERAL, R)])
	check(ev[-1].execution == {seat = 1, lethal = 1}, "Hình nhân không lên thớt: %s" % [ev[-1].execution])


func test_tie_on_tricks_goes_to_oldest_last_win() -> void:
	# Ghế 1 ăn vòng 0, ghế 2 ăn vòng 1, ghế 3 ăn Kết (vòng 2). Ghế 0 là Hình nhân.
	# Ghế 1 và 2 cùng 1 vòng; ghế 1 ăn từ lâu hơn nên lên thớt.
	var g := rigged_game([
		[c(K.PAWN, B), c(K.PAWN, B, 1), c(K.PAWN, B, 2)],
		[c(K.GENERAL, R), c(K.HORSE, B), c(K.PAWN, B, 3)],
		[c(K.CANNON, B), c(K.ADVISOR, R), c(K.PAWN, B, 4)],
		[c(K.HORSE, R), c(K.CANNON, R), c(K.GENERAL, B)],
	], 0, [false, true, true, true])
	play(g, 0, [c(K.PAWN, B)]); play(g, 1, [c(K.GENERAL, R)]); play(g, 2, [c(K.CANNON, B)]); play(g, 3, [c(K.HORSE, R)])
	check(g.leader == 1, "ghế 1 ăn vòng 0")
	play(g, 1, [c(K.HORSE, B)]); play(g, 2, [c(K.ADVISOR, R)]); play(g, 3, [c(K.CANNON, R)]); play(g, 0, [c(K.PAWN, B, 1)])
	check(g.leader == 2, "ghế 2 ăn vòng 1")
	play(g, 2, [c(K.PAWN, B, 4)]); play(g, 3, [c(K.GENERAL, B)]); play(g, 0, [c(K.PAWN, B, 2)])
	var ev := play(g, 1, [c(K.PAWN, B, 3)])
	check(ev[-1].ket_winner == 3, "ghế 3 ăn Kết")
	check(ev[-1].execution.seat == 1, "hòa số vòng: người ăn vòng cuối lâu nhất lên thớt: %s" % [ev[-1].execution])


func test_view_hides_private_information() -> void:
	var g := TamCucGame.new(5)
	g.apply({type = "deal"})
	var lead_cards := [g.hands[0][0]]
	g.apply({type = "lead", seat = 0, cards = lead_cards})
	var v := g.view_for(1)
	check(v.hand == g.hands[1], "thấy bài mình")
	check(v.committed == [true, false, false, false] and v.trick_size == 1, "biết ai đã úp và úp mấy lá")
	check(v.my_play == null, "không thấy bài úp của cái")
	var dump := var_to_str(v)
	for s in [0, 2, 3]:
		for card in g.hands[s]:
			check(not (card in v.hand), "không lẫn bài ghế %d" % s)
	check(not dump.contains("seed") and not v.has("hands") and not v.has("table"), "không lộ seed/hands/table")
	check(g.view_for(0).my_play == lead_cards, "cái thấy bài mình đã úp")


func test_random_full_hands_keep_invariants() -> void:
	# 300 ván với bot ngẫu nhiên (biết ra cả Tứ/Ngũ tử) để bắt crash và lỗi bất biến.
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var seen_types := {}
	var g := TamCucGame.new(2026)
	var runs := 1
	for hand_no in 300:
		if rejected(g.apply({type = "deal"})) == "run_over":
			runs += 1
			g = TamCucGame.new(2026 + runs)
			g.apply({type = "deal"})
		var tricks := 0
		var ev := []
		while g.phase == TamCucGame.Phase.PLAY:
			var combos := valid_leads(g.hands[g.leader])
			var lead: Array = combos[rng.randi_range(0, combos.size() - 1)]
			var lead_seat := g.leader
			ev = g.apply({type = "lead", seat = lead_seat, cards = lead})
			check(ev[0].type == "committed", "lead hợp lệ bị từ chối")
			for i in range(1, 4):
				var s := (lead_seat + i) % 4
				var h: Array = g.hands[s].duplicate()
				for k in range(h.size() - 1, 0, -1):
					var j := rng.randi_range(0, k)
					var tmp = h[k]; h[k] = h[j]; h[j] = tmp
				ev = g.apply({type = "follow", seat = s, cards = h.slice(0, lead.size())})
			tricks += 1
			check(tricks <= 8, "quá 8 vòng")
		var over: Dictionary = ev[-1]
		seen_types[over.ket_type] = true
		check(g.tricks_won.reduce(func(a, b): return a + b) == tricks, "tổng vòng ăn = số vòng")
		check(g.hands.all(func(h): return h.is_empty()), "hết bài")
		var ex: Dictionary = over.execution
		check(ex.seat != over.ket_winner and ex.lethal >= 1 and ex.lethal <= 5, "người lên thớt hợp lệ: %s" % [ex])
		var fewest := 99
		for s in 4:
			if s != over.ket_winner and g.mortal[s]:
				fewest = mini(fewest, g.tricks_won[s])
		check(g.tricks_won[ex.seat] == fewest, "người lên thớt ăn ít vòng nhất")
		check(ex.lethal == clampi(g.losses[ex.seat], 1, 5), "số que ngắn theo số lần thua")
		check(g.phase == TamCucGame.Phase.EXECUTION and g._sticks.size() == 6 and g._sticks.count(true) == ex.lethal, "6 que, đúng X que ngắn")
		var before: int = g.fingers[ex.seat].count(true)
		var drawn := g.apply({type = "draw_stick", seat = ex.seat, stick = rng.randi_range(0, 5)})
		check(drawn[0].type == "stick_drawn", "rút que: %s" % [drawn[0]])
		var chopped := []
		if drawn[0].short:
			check(g.phase == TamCucGame.Phase.CHOP, "que ngắn: chờ chọn ngón")
			chopped = g.apply({type = "chop", seat = ex.seat, finger = g.fingers[ex.seat].find(true)})
		check(g.phase == TamCucGame.Phase.HAND_OVER, "xong Hành Quyết")
		var lost: int = before - g.fingers[ex.seat].count(true)
		check(lost == (1 if drawn[0].short else 0) or chopped.any(func(e): return e.type == "stage_cleared"), "mất đúng 0 hoặc 1 ngón")
	# Bot ngẫu nhiên hầu như chỉ Kết bằng lẻ/đôi; Kết bằng bộ ba/Tứ/Ngũ tử đã có test riêng ở trên.
	check(seen_types.has(Combo.Type.SINGLE) and seen_types.has(Combo.Type.PAIR), "fuzz phủ Kết lẻ và đôi: %s" % [seen_types.keys()])
	check(runs > 1 or g.stage > 1, "fuzz đi tới thua Run hoặc qua Màn")


# ---------- Hành Quyết ----------

## Game đang chờ `seat` rút que; que ngắn ở các vị trí `short`.
func on_block(seat: int, short: Array, mortal := [true, false, true, false]) -> TamCucGame:
	var g := TamCucGame.new(1, mortal)
	g.apply({type = "deal"})
	g.phase = TamCucGame.Phase.EXECUTION
	g.execution = {seat = seat, lethal = short.size()}
	g._sticks = range(6).map(func(i): return short.has(i))
	return g


func draw(g: TamCucGame, seat: int, stick: int) -> Array:
	return g.apply({type = "draw_stick", seat = seat, stick = stick})


func chop(g: TamCucGame, seat: int, finger: int) -> Array:
	return g.apply({type = "chop", seat = seat, finger = finger})


func test_short_stick_count_follows_losses() -> void:
	var want := {0: 1, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 5, 9: 5}
	for n in want:
		var k := TamCucGame.compute_short_stick_count({loss_count = n}, {})
		check(k == want[n], "loss_count %d → %d que ngắn (được %d)" % [n, want[n], k])
		var g := on_block(2, [])
		g.execution.lethal = k
		g._roll_sticks()
		check(g._sticks.size() == 6 and g._sticks.count(true) == k and g._sticks.count(false) == 6 - k, "6 que: %d ngắn, %d dài" % [k, 6 - k])
	# 600 lần xáo với 2 que ngắn: mỗi vị trí phải trúng que ngắn khoảng 1/3 số lần
	var g := on_block(2, [])
	g.execution.lethal = 2
	var hits := [0, 0, 0, 0, 0, 0]
	for i in 600:
		g._roll_sticks()
		for k in 6:
			hits[k] += 1 if g._sticks[k] else 0
	check(hits.all(func(h): return h > 140 and h < 260), "que ngắn rải đều 6 vị trí: %s" % [hits])


func test_losses_count_up_and_reset_for_new_house() -> void:
	var g := TamCucGame.new(3, [true, false, true, false])
	for i in 3:
		g.apply({type = "deal"})
		while g.phase == TamCucGame.Phase.PLAY:
			var leading := g.trick_size == 0
			var s := g.leader
			if not leading:
				for k in range(1, 4):
					if g.table[(g.leader + k) % 4] == null:
						s = (g.leader + k) % 4
						break
			g.apply({type = "lead" if leading else "follow", seat = s, cards = g.hands[s].slice(0, 1 if leading else g.trick_size)})
		var seat: int = g.execution.seat
		var total: int = g.losses.reduce(func(a, b): return a + b)
		check(g.execution.lethal == clampi(g.losses[seat], 1, 5) and total == i + 1, "ván %d: losses %s" % [i, g.losses])
		g.rig_next_stick = false
		draw(g, seat, 0)
	var h := on_block(0, [0])
	h.losses[0] = 4
	h.fingers[0] = [false, false, false, false, true]
	draw(h, 0, 0)
	chop(h, 0, TamCucGame.Finger.THUMB)
	check(h.losses[0] == 0, "Nhà Cái mới: losses về 0")


func test_execution_rejects_bad_actions() -> void:
	var F := TamCucGame.Finger
	var g := on_block(2, [3])
	check(rejected(draw(g, 0, 0)) == "not_on_block", "người khác rút thay")
	check(rejected(draw(g, 2, 6)) == "bad_stick", "que ngoài 0..5")
	check(rejected(g.apply({type = "draw_stick", seat = 2, stick = "x"})) == "bad_stick", "que sai kiểu")
	check(rejected(chop(g, 2, F.PINKY)) == "wrong_phase", "chưa rút que đã chặt")
	check(rejected(g.apply({type = "deal"})) == "wrong_phase", "chưa rút que đã chia ván mới")
	draw(g, 2, 3)
	check(g.phase == TamCucGame.Phase.CHOP, "que ngắn: khoá sang chọn ngón")
	check(rejected(draw(g, 2, 1)) == "wrong_phase", "rút hai lần")
	check(rejected(g.apply({type = "deal"})) == "wrong_phase", "chưa chặt đã chia ván mới")
	check(rejected(chop(g, 0, F.PINKY)) == "not_on_block", "người khác chặt thay")
	check(rejected(g.apply({type = "chop", seat = 2, finger = "x"})) == "finger_gone", "ngón sai kiểu")
	check(rejected(chop(g, 2, 5)) == "finger_gone", "ngón ngoài 0..4")
	check(rejected(chop(g, 2, F.THUMB)) == "thumb_last", "cấm ngón Cái khi còn ngón khác")
	g.fingers[2][F.RING] = false
	check(rejected(chop(g, 2, F.RING)) == "finger_gone", "ngón đã mất")
	g.fingers[2] = [false, false, false, false, true]
	check(chop(g, 2, F.THUMB)[0].type == "chopped", "chỉ còn ngón Cái thì được chặt")


func test_long_stick_spares_every_finger() -> void:
	var g := on_block(2, [3])
	var ev := draw(g, 2, 1)
	check(ev.size() == 1 and ev[0].type == "stick_drawn" and not ev[0].short, "que dài: tha")
	check(ev[0].sticks == [false, false, false, true, false, false], "lật cả 6 que sau khi rút")
	check(g.fingers[2].count(true) == 5 and g.phase == TamCucGame.Phase.HAND_OVER, "không mất ngón, không debuff, xong Hành Quyết")
	check(rejected(chop(g, 2, 0)) == "wrong_phase", "que dài thì không có pha chọn ngón")
	check(g.apply({type = "deal"})[0].type == "dealt", "rút xong thì chia ván mới")


func test_short_stick_chop_takes_exactly_that_finger() -> void:
	var F := TamCucGame.Finger
	for f in [F.PINKY, F.RING, F.MIDDLE, F.INDEX]:
		var g := on_block(2, [0, 4])
		check(draw(g, 2, 4)[0].short, "que ngắn")
		var ev := chop(g, 2, f)
		var want := [true, true, true, true, true]
		want[f] = false
		check(ev == [{type = "chopped", seat = 2, finger = f}] and g.fingers[2] == want, "chặt đúng ngón %d (debuff ngón đó): %s" % [f, g.fingers[2]])
		check(g.phase == TamCucGame.Phase.HAND_OVER and g.mortal[2], "mất ngón thường vẫn còn mạng")


func test_rigged_stick_keeps_short_count() -> void:
	for want in [true, false]:
		for k in 6:
			var g := on_block(2, [2, 5])
			g.rig_next_stick = want
			var ev := draw(g, 2, k)
			check(ev[0].short == want and ev[0].sticks.count(true) == 2 and g.rig_next_stick == null, "ép que %s ở vị trí %d" % [want, k])


func test_losing_thumb_eliminates_and_ends_run() -> void:
	var g := on_block(2, [0, 1, 2, 3, 4])
	g.fingers[2] = [false, false, false, false, true]
	draw(g, 2, 0)
	var ev := chop(g, 2, TamCucGame.Finger.THUMB)
	check(ev.map(func(e): return e.type) == ["chopped", "eliminated", "run_over"], "mất ngón Cái: bị loại, hết người: %s" % [ev])
	check(not g.mortal[2], "ghế bị loại thành Hình nhân")
	check(rejected(g.apply({type = "deal"})) == "run_over", "thua Run thì không chia nữa")
	var coop := on_block(2, [0], [true, true, true, false])
	coop.fingers[2] = [false, false, false, false, true]
	draw(coop, 2, 0)
	ev = chop(coop, 2, TamCucGame.Finger.THUMB)
	check(ev.map(func(e): return e.type) == ["chopped", "eliminated"], "co-op: còn đồng đội thì chơi tiếp")


func test_house_losing_thumb_clears_stage() -> void:
	var g := on_block(0, [0])
	g.fingers[0] = [false, false, false, false, true]
	g.leader = 2
	draw(g, 0, 0)
	var ev := chop(g, 0, TamCucGame.Finger.THUMB)
	check(ev[-1] == {type = "stage_cleared", stage = 2}, "Nhà Cái mất ngón Cái: sang Màn 2: %s" % [ev])
	check(g.fingers[0].count(true) == 5 and g.mortal[0] and g.leader == 0, "Nhà Cái mới đủ 5 ngón, cầm cái")


func test_view_never_shows_sticks() -> void:
	var g := on_block(2, [1, 4])
	var dump := var_to_str(g.view_for(2)) + var_to_str(g.view_for(0))
	check(not dump.contains("stick") and not dump.contains("rig"), "view không lộ que")
	check(g.view_for(2).fingers == g.fingers and g.view_for(2).stage == 1, "ngón và Màn là công khai")


## Mọi bộ hợp lệ có thể đánh từ một tay bài (tối đa C(8,1..5) = 218 tổ hợp).
func valid_leads(hand: Array) -> Array:
	var out := []
	var n := hand.size()
	for mask in range(1, 1 << n):
		var pick := []
		for i in n:
			if mask & (1 << i):
				pick.append(hand[i])
		if pick.size() <= 5 and kind(pick) != Combo.Type.INVALID:
			out.append(pick)
	return out
