class_name TamCucGame
## Engine một ván Tam Cúc: thuần logic, deterministic, không dùng Node.
## Mọi thay đổi đi qua apply(action) -> events. Action và Event là Dictionary để gửi thẳng qua RPC.
## Server giữ object này; client chỉ nhận view_for(seat).
##
## Action:
##   {type = "deal"}
##   {type = "lead",   seat = int, cards = [int]}   # người cầm cái đặt úp một bộ hợp lệ
##   {type = "follow", seat = int, cards = [int]}   # người khác đặt úp đúng trick_size lá, theo thứ tự nào cũng được
##   {type = "draw_stick", seat = int, stick = 0..5}   # người lên thớt rút một trong 6 que tre
##   {type = "chop", seat = int, finger = Finger}      # rút trúng que ngắn: chọn ngón để chặt

enum Phase { DEAL, PLAY, EXECUTION, CHOP, HAND_OVER }   # EXECUTION = đang chờ rút que; CHOP = trúng que ngắn, chờ chọn ngón
enum Finger { PINKY, RING, MIDDLE, INDEX, THUMB }

const SEATS := 4
const HAND_SIZE := 8
const STICKS := 6

var rng := RandomNumberGenerator.new()
var phase := Phase.DEAL
var hands: Array = [[], [], [], []]
var leader := 0                         # ván đầu: ghế 0 (Nhà Cái); sau đó: người ăn Kết
var trick_size := 0                     # 0 = người cầm cái chưa đặt
var table: Array = [null, null, null, null]   # bài úp của vòng hiện tại; null = chưa đặt
var tricks_won: Array = [0, 0, 0, 0]
var last_trick := {}                    # {plays, winner, overtaken} của vòng vừa lật; công khai
var last_win: Array = [-1, -1, -1, -1]  # chỉ số vòng gần nhất mỗi ghế ăn; -1 = chưa ăn
var tricks_played := 0
var execution := {}                     # {seat, lethal}: ai lên thớt và số que ngắn (1..5), có khi hết ván
var mortal: Array                       # false = Hình nhân, không bao giờ lên thớt
var players: Array                      # ghế người thật lúc vào Run (ghế 1..3 còn mạng); hết người còn mạng = thua Run
var fingers: Array = []                 # fingers[seat][Finger] = còn ngón đó không
var stage := 1                          # Màn hiện tại; Nhà Cái (ghế 0) mất ngón Cái thì sang Màn sau, Nhà Cái mới đủ 5 ngón
var losses: Array = [0, 0, 0, 0]        # số lần lên thớt: người thật tính cả Run, Nhà Cái tính trong Màn
var _sticks: Array = []                 # bí mật: 6 que, true = que ngắn; không bao giờ vào view
var rig_next_stick = null               # chỉ cho cảnh debug: true/false ép kết quả lần rút tới; không đi qua apply() nên client không chạm được


func _init(seed_value: int, mortal_seats: Array = [true, true, true, true]) -> void:
	rng.seed = seed_value
	mortal = mortal_seats.duplicate()
	players = range(1, SEATS).filter(func(s): return mortal[s])
	for s in SEATS:
		fingers.append([true, true, true, true, true])


func apply(a: Dictionary) -> Array:
	var err := _check(a)
	if err != "":
		return [{type = "rejected", reason = err, action = a}]
	if a.type == "deal":
		return _deal()
	if a.type == "draw_stick":
		return _draw_stick(a)
	if a.type == "chop":
		return _chop(a)
	if a.type == "lead":
		trick_size = a.cards.size()
	return _commit(a.seat, a.cards)


## Thông tin ghế `seat` được phép biết. Không chứa bài tay người khác, bài úp chưa lật, hay RNG.
func view_for(seat: int) -> Dictionary:
	return {
		phase = phase,
		seat = seat,
		leader = leader,
		trick_size = trick_size,
		hand = hands[seat].duplicate(),
		hand_sizes = hands.map(func(h): return h.size()),
		committed = table.map(func(t): return t != null),
		my_play = table[seat].duplicate() if table[seat] != null else null,
		tricks_won = tricks_won.duplicate(),
		last_trick = last_trick.duplicate(true),
		execution = execution.duplicate(),
		fingers = fingers.duplicate(true),
		mortal = mortal.duplicate(),
		stage = stage,
		losses = losses.duplicate(),
	}


# Biên tin cậy: action có thể đến từ client gian lận, nên kiểm tra mọi trường trước khi động vào state.
func _check(a: Dictionary) -> String:
	var t = a.get("type")
	if t == "deal":
		if players.all(func(s): return not mortal[s]):
			return "run_over"
		return "" if phase == Phase.DEAL or phase == Phase.HAND_OVER else "wrong_phase"
	if t == "draw_stick" or t == "chop":
		return _check_execution(a)
	if t != "lead" and t != "follow":
		return "bad_type"
	if phase != Phase.PLAY:
		return "wrong_phase"
	var seat = a.get("seat")
	if typeof(seat) != TYPE_INT or seat < 0 or seat >= SEATS:
		return "bad_seat"
	var cards = a.get("cards")
	if typeof(cards) != TYPE_ARRAY:
		return "bad_cards"
	for c in cards:
		if typeof(c) != TYPE_INT or not hands[seat].has(c) or cards.count(c) > 1:
			return "not_in_hand"
	if table[seat] != null:
		return "already_played"
	if t == "lead":
		if seat != leader:
			return "not_leader"
		if Combo.classify(cards).type == Combo.Type.INVALID:
			return "invalid_combo"
	else:
		if seat == leader or trick_size == 0:
			return "not_your_turn"
		if cards.size() != trick_size:
			return "wrong_count"
	return ""


func _check_execution(a: Dictionary) -> String:
	if phase != (Phase.EXECUTION if a.type == "draw_stick" else Phase.CHOP):
		return "wrong_phase"
	var seat = a.get("seat")
	if typeof(seat) != TYPE_INT or seat != execution.seat:
		return "not_on_block"
	if a.type == "draw_stick":
		var stick = a.get("stick")
		return "" if typeof(stick) == TYPE_INT and stick >= 0 and stick < STICKS else "bad_stick"
	var f = a.get("finger")
	if typeof(f) != TYPE_INT or f < 0 or f > Finger.THUMB or not fingers[seat][f]:
		return "finger_gone"
	if f == Finger.THUMB and fingers[seat].count(true) > 1:
		return "thumb_last"
	return ""


## Số que ngắn trong 6 que. Tách riêng để chỉnh công thức (vd. cộng hệ số Kết từ hand_result {ket_type, overtaken}).
static func compute_short_stick_count(victim_state: Dictionary, _hand_result: Dictionary) -> int:
	return clampi(victim_state.loss_count, 1, 5)


## Xáo 6 que cho người đang lên thớt theo execution.lethal.
func _roll_sticks() -> void:
	_sticks = []
	for i in STICKS:
		_sticks.append(i < execution.lethal)
	_shuffle(_sticks)


# Fisher-Yates bằng rng có seed; Array.shuffle() dùng RNG toàn cục nên không replay được.
func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _deal() -> Array:
	var deck := range(Card.COUNT)
	_shuffle(deck)
	for s in SEATS:
		hands[s] = deck.slice(s * HAND_SIZE, (s + 1) * HAND_SIZE)
		hands[s].sort()
	table = [null, null, null, null]
	tricks_won = [0, 0, 0, 0]
	last_win = [-1, -1, -1, -1]
	tricks_played = 0
	execution = {}
	last_trick = {}
	trick_size = 0
	phase = Phase.PLAY
	return [{type = "dealt", leader = leader}]


func _commit(seat: int, cards: Array) -> Array:
	for c in cards:
		hands[seat].erase(c)
	table[seat] = cards.duplicate()
	var events := [{type = "committed", seat = seat, count = cards.size()}]
	if table.has(null):
		return events
	return events + _resolve()


func _resolve() -> Array:
	var best_seat := leader
	var best := Combo.classify(table[leader])
	var overtaken := []         # những ghế từng dẫn vòng này rồi bị đè
	for i in range(1, SEATS):   # duyệt theo chiều kim đồng hồ: hòa thì người đặt trước giữ
		var s := (leader + i) % SEATS
		var c := Combo.classify(table[s])
		if Combo.beats(c, best):
			overtaken.append(best_seat)
			best = c
			best_seat = s
	tricks_won[best_seat] += 1
	last_win[best_seat] = tricks_played
	tricks_played += 1
	last_trick = {plays = table.duplicate(true), winner = best_seat, overtaken = overtaken}
	var events := [{type = "revealed", plays = table.duplicate(true), winner = best_seat, overtaken = overtaken.duplicate()}]
	table = [null, null, null, null]
	trick_size = 0
	leader = best_seat
	if hands[0].is_empty():   # mọi người luôn ra cùng số lá, nên hết bài cùng lúc
		events.append(_score(best.type))
	return events


## Người lên thớt: trong các ghế còn mạng, trừ người ăn Kết, chọn người ăn ít vòng nhất.
## Hòa thì chọn người ăn vòng cuối cách đây lâu nhất (chưa ăn vòng nào xếp đầu), vẫn hòa thì chọn người ngồi sát sau người ăn Kết.
## Số que ngắn: compute_short_stick_count() theo số lần người đó đã lên thớt (tính cả lần này).
func _score(ket_type: int) -> Dictionary:
	var loser := -1
	for i in range(1, SEATS):
		var s := (leader + i) % SEATS
		if not mortal[s]:
			continue
		if loser == -1 or tricks_won[s] < tricks_won[loser] 				or (tricks_won[s] == tricks_won[loser] and last_win[s] < last_win[loser]):
			loser = s
	execution = {}
	if loser != -1:
		losses[loser] += 1
		var lethal := compute_short_stick_count({loss_count = losses[loser], fingers = fingers[loser]},
			{ket_type = ket_type, overtaken = last_trick.overtaken.has(loser)})
		execution = {seat = loser, lethal = lethal}
		_roll_sticks()
	phase = Phase.EXECUTION if loser != -1 else Phase.HAND_OVER
	return {type = "hand_over", ket_winner = leader, ket_type = ket_type,
		tricks_won = tricks_won.duplicate(), execution = execution.duplicate()}


## Rút que: que dài thì tha, xong Hành Quyết; que ngắn thì sang CHOP chờ chọn ngón.
func _draw_stick(a: Dictionary) -> Array:
	var k: int = a.stick
	if rig_next_stick != null and _sticks[k] != rig_next_stick:   # đổi chỗ với một que đúng loại, giữ nguyên số que ngắn
		var j := _sticks.find(rig_next_stick)
		_sticks[j] = _sticks[k]
		_sticks[k] = rig_next_stick
	rig_next_stick = null
	var short: bool = _sticks[k]
	var events := [{type = "stick_drawn", seat = a.seat, stick = k, short = short, sticks = _sticks.duplicate()}]
	_sticks = []
	phase = Phase.CHOP if short else Phase.HAND_OVER
	return events


## Chặt ngón: mất ngón Cái là bị loại (ghế thành Hình nhân).
## Nhà Cái bị loại thì sang Màn sau với Nhà Cái mới; mọi người thật bị loại thì thua Run.
func _chop(a: Dictionary) -> Array:
	var seat: int = a.seat
	var events := [{type = "chopped", seat = seat, finger = a.finger}]
	phase = Phase.HAND_OVER
	fingers[seat][a.finger] = false
	if a.finger != Finger.THUMB:
		return events
	mortal[seat] = false
	events.append({type = "eliminated", seat = seat})
	if seat == 0:
		stage += 1
		fingers[0] = [true, true, true, true, true]
		mortal[0] = true
		losses[0] = 0
		leader = 0   # Nhà Cái mới cầm cái ván đầu của Màn
		events.append({type = "stage_cleared", stage = stage})
	elif players.all(func(s): return not mortal[s]):
		events.append({type = "run_over"})
	return events
