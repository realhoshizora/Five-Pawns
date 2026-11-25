extends "res://game/table.gd"
## Cảnh thử Hành Quyết: vào thẳng màn rút que, không cần đánh Tam Cúc. Mở tests/debug_execution.tscn rồi bấm F6.
## F1 bật/tắt bảng debug (chỉ bản debug). Hết một lần Hành Quyết, bấm nút đi tiếp để mở lần mới với cài đặt hiện tại.
## Tự chơi để chụp màn: godot --path . res://tests/debug_execution.tscn -- --shot=<thư mục>

const DF := TamCucGame.Finger

var victim := HUMAN
var loss_count := 1
var force = null                 # null = ngẫu nhiên, true = ép que ngắn, false = ép que dài
var xray := false
var overlay: PanelContainer
var info: Label
var loss_label: Label
var _driving := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_dir = a.substr(7)
	_build()
	match_ctl = MatchController.new()
	match_ctl.ready_gate = func(): return queue.is_empty() and not busy
	match_ctl.event.connect(_on_event)
	add_child(match_ctl)
	match_ctl.game.apply({type = "deal"})   # chia thẳng trong engine (không diễn) để bảng biên bản có Kết mà ghi
	_set_palette(palette_execution, 2.8, 0.2)
	ca_base = aberration_execution
	if OS.is_debug_build():
		_build_overlay()
	if shot_dir != "":
		get_tree().create_timer(150.0).timeout.connect(get_tree().quit)
	_start()


## Đặt engine vào lúc `victim` vừa thua ván với `loss_count` lần thua, rồi mở cảnh.
func _start() -> void:
	var g := match_ctl.game
	if not g.mortal[victim]:   # vừa bị loại / thua Run: hồi ghế để thử tiếp
		g.mortal[victim] = true
		g.fingers[victim] = [true, true, true, true, true]
	g.phase = TamCucGame.Phase.EXECUTION
	g.losses[victim] = loss_count
	g.execution = {seat = victim, lethal = TamCucGame.compute_short_stick_count({loss_count = loss_count}, {})}
	g._roll_sticks()
	g.rig_next_stick = force
	g.last_trick = {plays = [[0], [9], [17], [25]], winner = 1, overtaken = []}
	var ev := {type = "hand_over", ket_winner = 1, ket_type = Combo.Type.SINGLE, tricks_won = [2, 3, 1, 2], execution = g.execution.duplicate()}
	hand_no += 1
	if execution.visible:
		execution.close()
	execution.open(ev, match_ctl.view(), hand_no)
	execution.xray = g._sticks.duplicate() if xray else []
	match_ctl._schedule_bots()
	_refresh_info()


func _on_execution_finished(_next: String) -> void:
	_start()


func _input(ev: InputEvent) -> void:
	if overlay and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_F1:
		overlay.visible = not overlay.visible


# ---------------------------------------------------------------- bảng debug

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 11   # trên lớp CRT để chữ không bị méo
	add_child(layer)
	overlay = PanelContainer.new()
	overlay.position = Vector2(110, 548)
	overlay.custom_minimum_size = Vector2(410, 0)
	var th := Theme.new()
	th.default_font = font_hud
	th.default_font_size = 24
	overlay.theme = th
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.02, 0.02, 0.88)
	st.border_color = Color(0.4, 0.9, 0.5, 0.7)
	st.set_border_width_all(2)
	st.set_content_margin_all(10)
	overlay.add_theme_stylebox_override("panel", st)
	layer.add_child(overlay)
	var box := VBoxContainer.new()
	overlay.add_child(box)
	var head := Label.new()
	head.text = "DEBUG · F1 to hide"
	head.add_theme_color_override("font_color", Color(0.5, 1, 0.6))
	box.add_child(head)

	var row := _row(box, "Next stick")
	var g1 := ButtonGroup.new()
	for opt in [["Random", null], ["Force Short", true], ["Force Long", false]]:
		var b := _btn(row, opt[0], func(): force = opt[1]; match_ctl.game.rig_next_stick = force; _refresh_info())
		b.toggle_mode = true
		b.button_group = g1
		b.button_pressed = opt[1] == null

	row = _row(box, "loss_count")
	_btn(row, "-", func(): _set_loss(loss_count - 1))
	loss_label = Label.new()
	row.add_child(loss_label)
	_btn(row, "+", func(): _set_loss(loss_count + 1))

	row = _row(box, "Victim")
	var g2 := ButtonGroup.new()
	for opt in [["Player", HUMAN], ["The House", 0]]:
		var b := _btn(row, opt[0], func(): victim = opt[1]; _start())
		b.toggle_mode = true
		b.button_group = g2
		b.button_pressed = opt[1] == HUMAN

	row = _row(box, "Fingers")
	_btn(row, "Reset All", func(): _set_fingers([true, true, true, true, true]))
	_btn(row, "Thumb Only", func(): _set_fingers([false, false, false, false, true]))

	var xr := CheckButton.new()
	xr.text = "X-Ray Sticks"
	xr.toggled.connect(func(on): xray = on; execution.xray = match_ctl.game._sticks.duplicate() if on else [])
	box.add_child(xr)
	info = Label.new()
	info.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75))
	box.add_child(info)


func _row(box: Node, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = title
	l.custom_minimum_size.x = 110
	row.add_child(l)
	box.add_child(row)
	return row


func _btn(row: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE   # giữ focus bàn phím cho cảnh Hành Quyết
	b.pressed.connect(cb)
	row.add_child(b)
	return b


func _set_loss(n: int) -> void:
	loss_count = clampi(n, 1, 5)
	_start()


func _set_fingers(f: Array) -> void:
	match_ctl.game.mortal[victim] = true
	match_ctl.game.fingers[victim] = f.duplicate()
	_start()


func _refresh_info() -> void:
	if info == null:
		return
	var k: int = match_ctl.game.execution.lethal
	loss_label.text = " %d " % loss_count
	info.text = "%d short / %d long · %d%% · next: %s" % [k, 6 - k, roundi(k * 100.0 / 6.0),
		"random" if force == null else ("SHORT" if force else "LONG")]


# ---------------------------------------------------------------- tự chơi để chụp màn

func _shot_exec() -> void:
	if _driving:
		return
	_driving = true
	var ex := execution
	await _wait(0.8)
	# 1) Người chơi, que ngắn: chọn que bằng click thật, kéo bằng chuột thật cho tới khi tự chốt
	force = true
	match_ctl.game.rig_next_stick = true
	await _click(ex.stick_btns[2].get_global_rect().get_center())
	_report(ex.stick_sel == 2, "click chọn que III")
	await _wait(0.3)
	await _shot("dbg_1_draw.png")
	var at: Vector2 = ex.stick_btns[4].get_global_rect().get_center()
	await _mouse(at, true)
	for k in 10:
		await _move(at + Vector2(0, 12 * (k + 1)))
	await _mouse(at + Vector2(0, 120), false)
	_report(ex.stick_sel == 4 and ex.step >= ExecutionView.Step.REVEAL, "kéo que V xuống thì tự chốt rút")
	await _until(func(): return ex.step == ExecutionView.Step.SELECT)
	await _wait(0.3)
	await _click(_finger_point(DF.THUMB))
	_report(ex.finger_sel == -1, "click ngón Cái khi còn ngón khác: bị từ chối")
	await _wait(0.15)
	await _shot("dbg_2_thumb_denied.png")
	await _move(_finger_point(DF.MIDDLE))
	await _click(_finger_point(DF.MIDDLE))
	_report(ex.finger_sel == DF.MIDDLE, "click thẳng lên ngón Giữa (Area2D) thì chọn ngón đó")
	await _wait(0.3)
	await _shot("dbg_3_select.png")
	ex._on_main_btn()
	await _until(func(): return ex.step == ExecutionView.Step.DONE and ex.main_btn.visible)
	_report(not match_ctl.game.fingers[HUMAN][DF.MIDDLE], "engine: mất ngón Giữa")
	await _shot("dbg_4_chopped.png")
	# 2) Người chơi, que dài
	force = false
	ex._on_main_btn()
	await _wait(0.8)
	ex._pick_stick(1)
	ex._on_main_btn()
	await _until(func(): return ex.step == ExecutionView.Step.SURVIVE and ex.main_btn.visible)
	await _wait(0.4)
	_report(match_ctl.game.fingers[HUMAN].count(true) == 4, "que dài: không mất thêm ngón")
	await _shot("dbg_5_spared.png")
	# 3) Nhà Cái, que ngắn, X-Ray bật
	victim = 0
	force = true
	xray = true
	loss_count = 3
	_start()
	await _wait(0.5)
	await _shot("dbg_6_house_draw_xray.png")
	xray = false
	await _until(func(): return ex.finger_hover >= 0 or ex.step >= ExecutionView.Step.CHOP)
	await _wait(0.3)
	await _shot("dbg_7_house_select.png")
	await _until(func(): return ex.step == ExecutionView.Step.DONE and ex.main_btn.visible)
	_report(not match_ctl.game.fingers[0][DF.PINKY], "Nhà Cái hy sinh ngón Út trước")
	# 4) Chỉ còn ngón Cái: que ngắn → mất ngón Cái → thua Run
	victim = HUMAN
	loss_count = 5
	match_ctl.game.fingers[HUMAN] = [false, false, false, false, true]
	_start()
	await _wait(0.6)
	ex._pick_stick(0)
	ex._on_main_btn()
	await _until(func(): return ex.step == ExecutionView.Step.SELECT)
	_report(ex.finger_sel == DF.THUMB, "chỉ còn ngón Cái thì tự chọn")
	ex._on_main_btn()
	await _until(func(): return ex._after == "title")
	await _wait(0.5)
	await _shot("dbg_8_run_over.png")
	print("DEBUG SHOTS DONE")
	get_tree().quit()


func _report(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _until(cond: Callable, limit := 12.0) -> void:
	var end := Time.get_ticks_msec() + int(limit * 1000)
	while not cond.call():
		if Time.get_ticks_msec() > end:
			_report(false, "hết giờ chờ (bước trước không xảy ra)")
			return
		await get_tree().process_frame


## Đầu ngón (toạ độ màn) để click thử Area2D.
func _finger_point(f: int) -> Vector2:
	var ex := execution
	return ex.hand.get_global_transform() * ex.finger_base[f].lerp(ex.finger_tip[f], 0.7)


func _move(p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if _held else 0
	get_viewport().push_input(m, true)
	await get_tree().physics_frame
	await get_tree().process_frame


var _held := false


func _mouse(p: Vector2, down: bool) -> void:
	_held = down
	var b := InputEventMouseButton.new()
	b.position = p
	b.global_position = p
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = down
	get_viewport().push_input(b, true)
	await get_tree().physics_frame
	await get_tree().process_frame


func _click(p: Vector2) -> void:
	await _move(p)
	await _mouse(p, true)
	await _mouse(p, false)
