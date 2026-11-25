extends Control
## Bàn chơi prototype (Giai đoạn 3): dựng layout theo mockups/table.html, diễn sự kiện engine thành hoạt cảnh
## (chia, đặt úp, lật, gom), juice kiểu Balatro (lò xo, rung màn hình, hitstop, CRT), cho người chơi chọn/kéo bài.
## Hết ván thì mở ExecutionView (game/execution.gd) cho người lên thớt.
## Chạy tự động để chụp màn: godot --path . -- --shot=<thư mục>

const HUMAN := MatchController.HUMAN
const SEAT_NAMES := ["The House", "Effigy I", "You", "Effigy II"]
const SEAT_ROLES := ["leads the first hand", "bot · never cut", "", "bot · never cut"]
const SLOT_CENTER := [Vector2(960, 330), Vector2(1240, 470), Vector2(960, 590), Vector2(680, 470)]
const STACK_POS := [Vector2(1180, 104), Vector2(1660, 560), Vector2(-500, 900), Vector2(214, 560)]
const PLAQUE_CENTER := [Vector2(930, 160), Vector2(1577, 440), Vector2(371, 900), Vector2(349, 440)]
const DECK_POS := Vector2(910, -400)
const SLOT_SCALE := 0.56
const HAND_Y := 722.0

# Chỉnh trong Inspector: chọn node "Table" trong game/table.tscn, sửa giá trị, F5.
@export_group("Swirl colours")
## 4 màu nền xoáy từ tối tới sáng, lúc đang đánh bài.
@export var palette_table: Array[Color] = [Color("0a0705"), Color("180c08"), Color("2c100b"), Color("42150e")]
## 4 màu nền xoáy khi hết ván / Hành Quyết.
@export var palette_execution: Array[Color] = [Color("100403"), Color("3e0906"), Color("7a140d"), Color("b8261a")]
@export_group("Darkness & CRT")
## Góc màn tối dần (0 = không tối góc).
@export_range(0.0, 1.0, 0.01) var vignette := 0.6
## Độ đậm vạch quét CRT (0 = tắt).
@export_range(0.0, 0.6, 0.01) var scanlines := 0.22
## Độ cong màn CRT (0 = phẳng).
@export_range(0.0, 0.15, 0.005) var screen_curve := 0.045
## Tách kênh màu (chromatic aberration) lúc đánh bài và lúc Hành Quyết.
@export_range(0.0, 6.0, 0.1) var aberration_table := 1.3
@export_range(0.0, 6.0, 0.1) var aberration_execution := 1.9
@export_group("Shake & hitstop")
## Độ rung màn hình khi đập bài (px).
@export_range(0.0, 30.0, 0.5) var shake_strength := 9.0
## Thời gian khựng hình khi đập bài (giây, 0 = tắt).
@export_range(0.0, 0.3, 0.01) var hitstop_seconds := 0.07
## Tách kênh màu bật thêm khi đập bài.
@export_range(0.0, 4.0, 0.1) var aberration_kick := 1.4

const INK := Color("1b1310")
const PAPER := Color("d8c294")
const PAPER_LIGHT := Color("eadcb4")
const SON := Color("b0241a")
const DIEP := Color("f1e9d6")

var match_ctl: MatchController
var world: Control
var card_layer: Control
var crt_mat: ShaderMaterial
var swirl_mat: ShaderMaterial
var hand: Array[CardView] = []
var slots := [[], [], [], []]
var stack_counts := [0, 0, 0, 0]
var stack_labels := {}
var trick_labels := {}
var hud_title: Label
var hud_sub: Label
var tricks_label: Label
var prompt: Label
var call_plaque: Panel
var call_label: Label
var lay_btn: Button
var clear_btn: Button
var result_panel: Panel
var result_label: Label
var execution: ExecutionView
var role_labels := {}
var tremor := false              # mất ngón Trỏ: bài trên tay run
var stains: Array[TextureRect] = []

var queue: Array = []
var busy := false
var shake := 0.0
var ca_base := 0.0
var ca_kick := 0.0
var flash := 0.0
var hand_no := 0
var trick_no := 0
var _trick_leader := -1
var _pending_mine: Array[CardView] = []

var font_carved: Font = preload("res://assets/fonts/Bevan-Regular.ttf")
var font_hud: Font = preload("res://assets/fonts/VT323-Regular.ttf")

var shot_dir := ""
var _auto_busy := false
var _shots := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_dir = a.substr(7)
	_build()
	match_ctl = MatchController.new()
	match_ctl.ready_gate = func(): return queue.is_empty() and not busy
	match_ctl.event.connect(_on_event)
	add_child(match_ctl)
	if shot_dir != "":
		get_tree().create_timer(300.0).timeout.connect(get_tree().quit)
	match_ctl.submit({type = "deal"})


# ---------------------------------------------------------------- dựng giao diện

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # không nuốt click: cảnh Hành Quyết cần click rơi xuống Area2D của ngón tay
	world = Control.new()
	world.size = Vector2(1920, 1080)
	world.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(world)

	var bg := ColorRect.new()
	bg.size = world.size
	swirl_mat = ShaderMaterial.new()
	swirl_mat.shader = preload("res://shaders/swirl.gdshader")
	_set_palette(palette_table, 1.6, 0.08)
	bg.material = swirl_mat
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(bg)

	var table := Panel.new()
	table.position = Vector2(150, 66)
	table.size = Vector2(1620, 946)
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color("2a170d")
	ts.set_corner_radius_all(40)
	ts.set_border_width_all(16)
	ts.border_color = Color("120a07")
	ts.shadow_color = Color(0, 0, 0, 0.8)
	ts.shadow_size = 40
	ts.shadow_offset = Vector2(0, 30)
	table.add_theme_stylebox_override("panel", ts)
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(table)

	hud_title = _label("STAGE I · HAND 1", font_carved, 34, DIEP, Vector2(206, 96))
	hud_sub = _label("Trick 1", font_hud, 30, Color("b9a98e"), Vector2(206, 140))

	var tp := _panel(Vector2(1414, 100), Vector2(300, 250), Color(0.04, 0.02, 0.015, 0.7), Color(PAPER, 0.4))
	_label("TRICKS TAKEN", font_carved, 20, PAPER, Vector2(18, 12), tp)
	_label("fewest → the Block\nFinal winner safe", font_hud, 24, PAPER_LIGHT, Vector2(18, 40), tp)
	tricks_label = _label("", font_hud, 28, DIEP, Vector2(18, 98), tp)

	for s in [0, 1, 3, HUMAN]:
		var pos: Vector2 = PLAQUE_CENTER[s] - Vector2(150, 60)
		var p := _panel(pos, Vector2(300, 120), PAPER, INK)
		_label(SEAT_NAMES[s].to_upper(), font_carved, 28, INK, Vector2(18, 12), p)
		role_labels[s] = _label(SEAT_ROLES[s], font_hud, 24, Color("4b3b2c"), Vector2(18, 50), p)
		trick_labels[s] = _label("0 tricks", font_hud, 24, Color("4b3b2c"), Vector2(18, 80), p)
		if s != HUMAN:
			var back := TextureRect.new()
			back.texture = CardView.BACK
			back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			back.stretch_mode = TextureRect.STRETCH_SCALE
			back.size = Vector2(44, 150)
			back.position = STACK_POS[s]
			back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			world.add_child(back)
			stack_labels[s] = _label("×8", font_hud, 30, DIEP, STACK_POS[s] + Vector2(52, 112))

	call_plaque = _panel(Vector2(900, 430), Vector2(120, 76), PAPER, INK)
	call_plaque.rotation = deg_to_rad(-2)
	_label("CALLS", font_carved, 20, INK, Vector2(22, 4), call_plaque)
	call_label = _label("2", font_carved, 36, SON, Vector2(46, 26), call_plaque)
	call_plaque.visible = false

	# dòng hướng dẫn đặt cạnh cụm nút thao tác, không bị tay bài hay ô bài giữa bàn che
	prompt = _label("", font_hud, 30, DIEP, Vector2(1330, 724))
	prompt.size = Vector2(400, 70)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD

	card_layer = Control.new()
	card_layer.size = world.size
	card_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	world.add_child(card_layer)

	clear_btn = _button("Clear", false, Vector2(1300, 900), Vector2(120, 52))
	clear_btn.pressed.connect(_clear_selection)
	lay_btn = _button("Lay down", true, Vector2(1440, 870), Vector2(290, 92))
	lay_btn.pressed.connect(_lay)

	result_panel = _panel(Vector2(660, 330), Vector2(600, 330), PAPER, INK)
	result_label = _label("", font_hud, 32, INK, Vector2(30, 24), result_panel)
	result_label.size = Vector2(540, 200)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	var next := _button("Next hand", true, Vector2(150, 222), Vector2(300, 80), result_panel)
	next.pressed.connect(_next_hand)
	result_panel.visible = false
	result_panel.z_index = 100

	execution = ExecutionView.new(self)
	execution.finished.connect(_on_execution_finished)
	world.add_child(execution)

	var crt_layer := CanvasLayer.new()
	crt_layer.layer = 10
	add_child(crt_layer)
	var crt := ColorRect.new()
	crt.size = Vector2(1920, 1080)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_mat = ShaderMaterial.new()
	crt_mat.shader = preload("res://shaders/crt.gdshader")
	crt_mat.set_shader_parameter("vignette", vignette)
	crt_mat.set_shader_parameter("scan", scanlines)
	crt_mat.set_shader_parameter("curve", screen_curve)
	crt.material = crt_mat
	crt_layer.add_child(crt)


func _label(text: String, font: Font, size_px: int, color: Color, pos: Vector2, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else world).add_child(l)
	return l


func _panel(pos: Vector2, sz: Vector2, bg: Color, border: Color, parent: Node = null) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = sz
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.set_border_width_all(3)
	st.border_color = border
	st.set_corner_radius_all(4)
	st.shadow_color = Color(0, 0, 0, 0.6)
	st.shadow_size = 14
	st.shadow_offset = Vector2(0, 8)
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else world).add_child(p)
	return p


func _button(text: String, seal: bool, pos: Vector2, sz: Vector2, parent: Node = null) -> Button:
	var b := Button.new()
	b.text = text.to_upper() if seal else text
	b.position = pos
	b.size = sz
	b.add_theme_font_override("font", font_carved if seal else font_hud)
	b.add_theme_font_size_override("font_size", 34 if seal else 30)
	var states := {"normal": SON, "hover": Color("c8352a"), "pressed": Color("8c1a12"), "disabled": Color("6e2a22"), "focus": SON}
	for k in states:
		var st := StyleBoxFlat.new()
		st.bg_color = states[k] if seal else Color(0.05, 0.03, 0.02, 0.6)
		st.set_border_width_all(4 if seal else 2)
		st.border_color = PAPER_LIGHT if seal else Color(PAPER, 0.55)
		st.set_corner_radius_all(6)
		if k == "focus":
			st.draw_center = false
			st.border_color = PAPER_LIGHT
		b.add_theme_stylebox_override(k, st)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, PAPER_LIGHT if seal else DIEP)
	b.add_theme_color_override("font_disabled_color", Color("b49f8a"))
	(parent if parent else world).add_child(b)
	return b


# ---------------------------------------------------------------- hàng đợi sự kiện

func _on_event(ev: Dictionary) -> void:
	queue.append(ev)
	if not busy:
		_drain()


func _drain() -> void:
	busy = true
	_update_controls()
	while not queue.is_empty():
		await _play(queue.pop_front())
	busy = false
	_update_controls()


func _play(ev: Dictionary) -> void:
	match ev.type:
		"dealt":
			await _play_deal()
		"committed":
			await _play_commit(ev.seat, ev.count)
		"revealed":
			await _play_reveal(ev.plays, ev.winner)
		"hand_over":
			await _play_hand_over(ev)
		"stick_drawn":
			await execution.play_draw(ev)
		"chopped":
			await execution.play_chop(ev)
			_refresh_hud()
		"eliminated", "stage_cleared", "run_over":
			execution.note(ev)
			_refresh_hud()
		"rejected":
			prompt.text = "Not allowed: %s" % ev.reason
			shake = 5.0


func _play_deal() -> void:
	hand_no += 1
	trick_no = 1
	_trick_leader = -1
	result_panel.visible = false
	_set_palette(palette_table, 1.6, 0.08)
	ca_base = aberration_table
	for c in hand:
		c.queue_free()
	hand.clear()
	for s in 4:
		for c in slots[s]:
			c.queue_free()
		slots[s] = []
		stack_counts[s] = 8
	_refresh_hud()
	var v := match_ctl.view()
	var ids: Array = v.hand.duplicate()
	if v.fingers[HUMAN][TamCucGame.Finger.RING]:
		ids.sort_custom(func(a, b): return Card.rank(a) * 2 - Card.suit(a) < Card.rank(b) * 2 - Card.suit(b))
	else:
		ids.shuffle()   # mất ngón Áp út: không tự xếp bài
	for id in ids:
		var c := CardView.new(id, false)
		c.snap(DECK_POS, -0.3, 1.0)
		c.clicked.connect(_on_card_clicked)
		c.drag_released.connect(_on_card_dropped)
		card_layer.add_child(c)
		hand.append(c)
		_layout_hand()
		await get_tree().create_timer(0.06).timeout
	await get_tree().create_timer(0.35).timeout
	for c in hand:
		c.flip_to(c.card_id)
		await get_tree().create_timer(0.04).timeout
	await get_tree().create_timer(0.25).timeout


func _play_commit(seat: int, count: int) -> void:
	if _trick_leader == -1:
		_trick_leader = seat
		call_label.text = str(count)
		call_plaque.visible = true
	var cards: Array[CardView] = []
	if seat == HUMAN:
		cards = _pending_mine.duplicate()
		_pending_mine.clear()
		for c in cards:
			hand.erase(c)
			c.selected = false
			c.lift = 0.0
			c.set_interactive(false)
			c.flip_to(-1, 0.16)
		_layout_hand()
	else:
		for i in count:
			var c := CardView.new(-1, false)
			c.snap(STACK_POS[seat] - CardView.SIZE * 0.5 + Vector2(22, 75), 0.0, 0.44)
			card_layer.add_child(c)
			cards.append(c)
		stack_counts[seat] -= count
		_refresh_stacks()
	slots[seat] = cards
	_layout_slot(seat)
	await get_tree().create_timer(0.24).timeout
	_slam(0.7)
	await get_tree().create_timer(0.12).timeout


func _play_reveal(plays: Array, winner: int) -> void:
	call_plaque.visible = false
	for i in 4:
		var s := (_trick_leader + i) % 4
		for j in slots[s].size():
			slots[s][j].flip_to(plays[s][j], 0.2)
			await get_tree().create_timer(0.07).timeout
	await get_tree().create_timer(0.35).timeout
	for c in slots[winner]:
		c.home_scale = 0.68
		c.lift = 26.0
		c.z_index = 20
	prompt.text = "%s takes the trick" % SEAT_NAMES[winner]
	_slam(0.5)
	if shot_dir != "" and not _shots.has("reveal"):
		_shots["reveal"] = true
		await _shot("reveal.png")
	await get_tree().create_timer(0.9).timeout
	for s in 4:
		for c in slots[s]:
			c.home = PLAQUE_CENTER[winner] - CardView.SIZE * 0.5
			c.home_scale = 0.18
			var t: Tween = c.create_tween()
			t.tween_interval(0.18)
			t.tween_property(c, "modulate:a", 0.0, 0.2)
			t.tween_callback(c.queue_free)
		slots[s] = []
	_trick_leader = -1
	trick_no += 1
	_refresh_hud()
	await get_tree().create_timer(0.4).timeout


func _play_hand_over(ev: Dictionary) -> void:
	_set_palette(palette_execution, 2.8, 0.12 * (1.0 + 0.35 * (ev.execution.get("lethal", 1))))
	ca_base = aberration_execution
	flash = 0.6
	_slam(1.0)
	if not ev.execution.is_empty():
		prompt.text = "%s %s to the Block" % [SEAT_NAMES[ev.execution.seat], "go" if ev.execution.seat == HUMAN else "goes"]
		await get_tree().create_timer(1.1).timeout
		execution.open(ev, match_ctl.view(), hand_no)
		return
	var final_name: String = CardNames.TYPE.get(ev.ket_type, "?")
	result_label.text = "THE FINAL · %s, taken by %s.\n\nNo one goes to the Block." % [final_name, SEAT_NAMES[ev.ket_winner]]
	result_panel.visible = true


# ---------------------------------------------------------------- bố cục

func _layout_hand() -> void:
	var n := hand.size()
	for i in n:
		var k := i - (n - 1) / 2.0
		var c := hand[i]
		c.home = Vector2(960 + k * 96, HAND_Y + k * k * 2.4) - CardView.SIZE * 0.5 + Vector2(0, CardView.SIZE.y * 0.5)
		c.home_rot = k * 0.063
		c.home_scale = 1.0
		c.lift = 40.0 if c.selected else 0.0
		c.base_z = i
		c.z_index = i


func _layout_slot(seat: int) -> void:
	var cards: Array = slots[seat]
	var n := cards.size()
	for j in n:
		var c: CardView = cards[j]
		var center: Vector2 = SLOT_CENTER[seat] + Vector2((j - (n - 1) / 2.0) * 64, 0)
		c.home = center - CardView.SIZE * 0.5
		c.home_rot = randf_range(-0.05, 0.05)
		c.home_scale = SLOT_SCALE
		c.z_index = 10 + j


# ---------------------------------------------------------------- người chơi

func _my_turn() -> String:
	var v := match_ctl.view()
	if v.phase != TamCucGame.Phase.PLAY or v.committed[HUMAN] or busy or not _pending_mine.is_empty():
		return ""
	if v.trick_size == 0 and v.leader == HUMAN:
		return "lead"
	if v.trick_size > 0 and v.leader != HUMAN:
		return "follow"
	return ""


func _selected_ids() -> Array:
	var ids := []
	for c in hand:
		if c.selected:
			ids.append(c.card_id)
	return ids


func _update_controls() -> void:
	var turn := _my_turn()
	for c in hand:
		c.set_interactive(turn != "")
	var ids := _selected_ids()
	var combo_name := CardNames.combo(ids) if not ids.is_empty() else ""
	var ok := false
	if turn == "lead":
		ok = combo_name != ""
		prompt.text = "Your lead: pick a set" if ids.is_empty() else (combo_name if ok else "Not a valid set")
	elif turn == "follow":
		var n: int = match_ctl.view().trick_size
		ok = ids.size() == n
		prompt.text = "Lay %d card%s face down" % [n, "" if n == 1 else "s"] if ids.is_empty() else (
			(combo_name if combo_name != "" else "%d card%s · no set" % [ids.size(), "" if ids.size() == 1 else "s"]))
	elif not busy and match_ctl.game.phase == TamCucGame.Phase.PLAY:
		prompt.text = "Waiting…"
	lay_btn.disabled = not ok
	lay_btn.text = ("LAY %d DOWN" % ids.size()) if ok else "LAY DOWN"
	clear_btn.disabled = ids.is_empty()
	if shot_dir != "" and turn != "" and not _auto_busy:
		_autoplay()


func _on_card_clicked(c: CardView) -> void:
	c.selected = not c.selected
	_layout_hand()
	_update_controls()


func _on_card_dropped(c: CardView, at: Vector2) -> void:
	# Thả lá lên mặt bàn (phía trên tay bài) = đặt úp các lá đang chọn.
	if at.y < HAND_Y - 60:
		if not c.selected:
			c.selected = true
		_update_controls()
		if not lay_btn.disabled:
			_lay()
			return
		shake = 4.0
	_layout_hand()


func _clear_selection() -> void:
	for c in hand:
		c.selected = false
	_layout_hand()
	_update_controls()


func _lay() -> void:
	var turn := _my_turn()
	if turn == "" or lay_btn.disabled:
		return
	_pending_mine.clear()
	for c in hand:
		if c.selected:
			_pending_mine.append(c)
	var evs := match_ctl.submit({type = turn, seat = HUMAN, cards = _selected_ids()})
	if evs[0].type == "rejected":
		_pending_mine.clear()


func _next_hand() -> void:
	match_ctl.submit({type = "deal"})


func _on_execution_finished(next: String) -> void:
	if next == "title":
		get_tree().change_scene_to_file("res://game/title.tscn")
		return
	execution.close()
	_set_palette(palette_table, 1.6, 0.08)
	ca_base = aberration_table
	_next_hand()


## Vết máu pixel ở lại trên mặt bàn suốt phiên chơi, nằm dưới lớp bài.
func add_stain() -> void:
	var t := TextureRect.new()
	t.texture = ExecutionView.blood_blob(randi(), randi_range(18, 40), randi_range(12, 26))
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.size = t.texture.get_size() * 6
	t.position = Vector2(randf_range(220, 1560), randf_range(660, 900))
	t.modulate.a = randf_range(0.7, 0.9)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(t)
	world.move_child(t, card_layer.get_index())
	stains.append(t)


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_accept"):
		_lay()
	elif ev.is_action_pressed("ui_cancel"):
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://game/title.tscn")
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		_clear_selection()


# ---------------------------------------------------------------- juice

func _process(delta: float) -> void:
	world.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	shake = move_toward(shake, 0.0, delta * 38.0)
	ca_kick = move_toward(ca_kick, 0.0, delta * 4.0)
	flash = move_toward(flash, 0.0, delta * 6.0)
	crt_mat.set_shader_parameter("ca", ca_base + ca_kick)
	crt_mat.set_shader_parameter("flash", flash)
	if tremor:
		for c in hand:
			c.position += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 1.8


## Đập bài xuống bàn: rung màn hình, hitstop ngắn, đẩy chromatic aberration.
func _slam(power: float) -> void:
	shake = maxf(shake, shake_strength * power)
	ca_kick = aberration_kick * power
	Engine.time_scale = 0.05
	await get_tree().create_timer(hitstop_seconds * power, true, false, true).timeout
	Engine.time_scale = 1.0


func _set_palette(p: Array, twist: float, speed: float) -> void:
	if swirl_mat.get_shader_parameter("c0") == null:
		for i in 4:
			swirl_mat.set_shader_parameter("c%d" % i, p[i])
	else:
		var t := create_tween().set_parallel()
		for i in 4:
			t.tween_property(swirl_mat, "shader_parameter/c%d" % i, p[i], 1.2)
	swirl_mat.set_shader_parameter("twist", twist)
	swirl_mat.set_shader_parameter("speed", speed)


func _refresh_hud() -> void:
	var v := match_ctl.view()
	hud_title.text = "STAGE %s · HAND %d" % [ExecutionView._roman(v.stage), hand_no]
	hud_sub.text = "Trick %d" % trick_no
	tremor = not v.fingers[HUMAN][TamCucGame.Finger.INDEX]
	for s in [0, HUMAN]:
		var n: int = v.fingers[s].count(true)
		role_labels[s].text = "%d of 5 fingers" % n if v.mortal[s] else "eliminated"
	var lines := []
	for s in [HUMAN, 0, 1, 3]:
		lines.append("%-10s %d" % [SEAT_NAMES[s], v.tricks_won[s]])
		trick_labels[s].text = "%d trick%s" % [v.tricks_won[s], "" if v.tricks_won[s] == 1 else "s"]
	tricks_label.text = "\n".join(lines)
	_refresh_stacks()


func _refresh_stacks() -> void:
	for s in stack_labels:
		stack_labels[s].text = "×%d" % stack_counts[s]


# ---------------------------------------------------------------- tự chơi để chụp màn

func _autoplay() -> void:
	_auto_busy = true
	await get_tree().create_timer(0.7).timeout
	var pick: Array = BotBasic.choose(match_ctl.view()).cards
	for c in hand:
		c.selected = pick.has(c.card_id)
	_layout_hand()
	_update_controls()
	await get_tree().create_timer(0.6).timeout
	if not _shots.has("select"):
		_shots["select"] = true
		await _shot("select.png")
	_auto_busy = false
	_lay()


## Chế độ chụp màn: execution.open() gọi khi mở cảnh Hành Quyết. Bàn chơi chỉ chụp rồi thoát;
## tests/debug_execution.gd ghi đè hàm này để tự chơi cả hai nhánh que.
func _shot_exec() -> void:
	await get_tree().create_timer(1.5).timeout
	await _shot("execution.png")
	get_tree().quit()


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot_dir.path_join(file))
