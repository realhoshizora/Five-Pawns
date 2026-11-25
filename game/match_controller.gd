class_name MatchController
extends Node
## Cầu nối giữa engine (core/) và màn hình. Offline: giữ TamCucGame và cho bot đánh ở các ghế không phải người.
## Màn hình chỉ gọi submit(action) và nghe signal `event` + đọc view(); Giai đoạn 5 thay bằng bản mạng cùng giao diện.

signal event(ev: Dictionary)

const HUMAN := 2                 # ghế người chơi (dưới); 0 = Nhà Cái (trên), 1 và 3 = Hình nhân
const MORTAL := [true, false, true, false]
const BOT_DELAY := Vector2(0.45, 0.95)
const EXEC_DELAY := 0.8           # Nhà Cái ngập ngừng trước khi rút que / chọn ngón

var game: TamCucGame
var _rng := RandomNumberGenerator.new()
var _pending := {}               # ghế bot đã hẹn giờ đánh, tránh hẹn trùng
var ready_gate: Callable         # màn hình trả true khi đã diễn xong hoạt cảnh; bot chờ để không đánh dồn


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		seed_value = int(Time.get_unix_time_from_system())
	game = TamCucGame.new(seed_value, MORTAL)
	_rng.seed = seed_value + 1


func view() -> Dictionary:
	return game.view_for(HUMAN)


func submit(action: Dictionary) -> Array:
	var evs := game.apply(action)
	for ev in evs:
		event.emit(ev)
	if evs[0].type != "rejected":
		_schedule_bots()
	return evs


func _schedule_bots() -> void:
	if (game.phase == TamCucGame.Phase.EXECUTION or game.phase == TamCucGame.Phase.CHOP) and game.execution.seat != HUMAN:
		_bot_execution(game.execution.seat, game.phase)
	if game.phase != TamCucGame.Phase.PLAY:
		return
	for s in TamCucGame.SEATS:
		if s == HUMAN or game.table[s] != null:
			continue
		var leading := game.trick_size == 0
		if leading and s != game.leader:
			continue
		if not leading and s == game.leader:
			continue
		if _pending.has(s):
			continue
		_pending[s] = true
		_bot_after_delay(s, game.leader)
		if leading:
			return   # người theo chỉ được đặt sau khi cái đã gọi số lá


func _bot_after_delay(seat: int, leader_at_schedule: int) -> void:
	while ready_gate.is_valid() and not ready_gate.call():
		await get_tree().process_frame
	await get_tree().create_timer(_rng.randf_range(BOT_DELAY.x, BOT_DELAY.y)).timeout
	_pending.erase(seat)
	if game.phase != TamCucGame.Phase.PLAY or game.table[seat] != null or game.leader != leader_at_schedule:
		return
	if game.trick_size == 0 and seat != game.leader:
		return
	submit(BotBasic.choose(game.view_for(seat)))


## Nhà Cái lên thớt: chờ màn hình diễn xong, ngập ngừng một lúc rồi mới rút que (hoặc chọn ngón).
func _bot_execution(seat: int, phase: int) -> void:
	while ready_gate.is_valid() and not ready_gate.call():
		await get_tree().process_frame
	await get_tree().create_timer(EXEC_DELAY).timeout
	if game.phase == phase and game.execution.seat == seat:
		submit(BotBasic.choose(game.view_for(seat)))
