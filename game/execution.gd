class_name ExecutionView
extends Control
## Pha Hành Quyết (theo mockups/execution_sticks_ref.png): người lên thớt rút 1 trong 6 que tre từ nắm tay gỗ của Nhà Cái.
## Que dài thì được tha. Que ngắn thì chọn một ngón đặt lên thớt, dao phay chặt xuống.
## Các bước: ENTER → DRAW → REVEAL → que dài: SURVIVE | que ngắn: SELECT → CHOP → DONE.
## (Take the Blade của co-op chờ Giai đoạn 5, khi có co-op.)
## Kết quả do engine quyết; table.gd gọi play_draw() / play_chop() / note() khi nhận sự kiện.
## Hình là các lớp Sprite2D đọc PNG trong assets/execution/, do tools/execution_art.py cắt từ tranh gốc ở assets/execution/raw/.
## Bàn tay: hand_palm + 5 lớp ngón (lành / băng) cùng khung ảnh, chồng khít; hand_layout.json cho đa giác vùng bấm và gốc ngón.
## Nhà Cái tạm dùng tay người phủ màu xám cho tới khi có tranh tay rối.

signal finished(next: String)   # "next" = chia ván mới, "title" = về màn tiêu đề

enum Step { ENTER, DRAW, REVEAL, SURVIVE, SELECT, CHOP, DONE }

const F := TamCucGame.Finger
const FINGER_NAMES := ["Pinky", "Ring", "Middle", "Index", "Thumb"]
const FINGER_NOUNS := ["pinky", "ring finger", "middle finger", "index finger", "thumb"]
const FINGER_FILES := ["pinky", "ring", "middle", "index", "thumb"]
const DEBUFFS := ["-1 charm slot", "no auto-sort", "no history", "tremor, no pings", "eliminated"]
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
const RULE := "The thumb goes on the Block last."
const ART := "res://assets/execution/%s.png"

# Mốc neo (toạ độ màn 1920×1080).
const BLOCK_C := Vector2(960, 640)
const HAND_TOP := 430.0                    # mép trên khung ảnh bàn tay; khung căn giữa theo x
const CHOP_AT := 0.22                      # dao chặt cách gốc ngón 22% chiều dài ngón
const FIST_AT := Vector2(960, 300)         # chỗ que ló ra khỏi nắm tay gỗ (mép dưới các ngón gỗ)
const FIST_GRIP := Vector2(0.41, 0.92)     # chỗ đó trên ảnh puppet_fist (tỉ lệ theo rộng/cao ảnh)
const STICK_X := [-140.0, -84.0, -28.0, 28.0, 84.0, 140.0]
const SHOWN := 300.0                       # phần que lộ ra dưới nắm tay, như nhau cho mọi que
const DRAG_GESTURE := 120.0                # rê chuột chừng này px thì que trượt hết phần que ngắn giấu trong nắm tay
const DRAG_COMMIT := 0.65
const CLEAVER_REST := Vector2(1205, 450)   # giữa mép lưỡi dao lúc nằm nghỉ
const CLEAVER_EDGE := 0.3                  # giữa mép lưỡi nằm ở 30% chiều cao ảnh cleaver

const INK := Color("1b1310")
const PAPER := Color("d8c294")
const PAPER_LIGHT := Color("eadcb4")
const SON := Color("b0241a")
const DIEP := Color("f1e9d6")
const BLOOD := Color("7a120c")
const BLOOD_DRY := Color("4a0806")
const HOUSE_SKIN := Color(0.76, 0.78, 0.78)

var table: Node                  # game/table.gd: dùng lại _label/_panel/_button và các biến juice (shake, flash, crt_mat)
var font_carved: Font = preload("res://assets/fonts/Bevan-Regular.ttf")
var font_hud: Font = preload("res://assets/fonts/VT323-Regular.ttf")

var seat := -1
var human := false
var fingers: Array = []
var step := Step.ENTER
var stick_sel := -1
var stick_hover := -1
var finger_sel := -1
var finger_hover := -1
var xray: Array = []             # chỉ cảnh debug đưa vào: que nào ngắn; rỗng = tắt
var _after := "next"
var _pull := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]   # mỗi que đã bị kéo xuống bao nhiêu px
var _free := -1                  # que đã tuột khỏi nắm tay (nằm ở stage, không cắt theo nắm tay nữa)
var _drag := -1
var _drag_y0 := 0.0
var _severed := {}               # đốt ngón văng: {node, vel, spin}
var _t := 0.0

var stage: Node2D
var block: Sprite2D
var hand: Node2D
var finger_sprites: Array[Sprite2D] = []
var finger_base: Array[Vector2] = []     # toạ độ trong hand
var finger_tip: Array[Vector2] = []
var finger_areas: Array[Area2D] = []
var marks: Node2D
var cleaver: Node2D
var fist: Node2D
var sticks: Array[Sprite2D] = []
var stick_marks: Node2D
var stick_btns: Array[Button] = []
var tex_long: Texture2D
var tex_short: Texture2D

var hud_top: Label
var hud_sub: Label
var ledger_title: Label
var ledger_rows: Array = []
var total_label: Label
var odds_label: Label
var fingers_title: Label
var finger_btns: Array[Button] = []
var finger_debuffs: Array[Label] = []
var finger_strikes: Array[ColorRect] = []
var rule_label: Label
var main_btn: Button
var main_sub: Label
var result_panel: Panel
var result_head: Label
var result_body: Label
var glass: Control               # lớp kính CRT: máu văng lên rồi chảy xuống, không rung theo bàn

var _hidden: Array[CanvasItem] = []


func _init(owner_table: Node) -> void:
	table = owner_table
	size = Vector2(1920, 1080)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # để click rơi xuống Area2D của ngón tay; bàn chơi bên dưới đã ẩn lúc mở cảnh
	z_index = 50


func _ready() -> void:
	get_viewport().physics_object_picking = true
	var under := Control.new()           # mặt bàn và vết máu cũ; lọc NEAREST cho máu pixel
	under.size = size
	under.show_behind_parent = true
	under.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	under.draw.connect(_draw_under.bind(under))
	add_child(under)
	table._label("EXECUTION", font_carved, 58, DIEP, Vector2(110, 52), self)
	hud_top = table._label("", font_carved, 30, DIEP, Vector2(1310, 62), self)
	hud_sub = table._label("", font_hud, 30, Color("b9a98e"), Vector2(1310, 112), self)
	for l in [hud_top, hud_sub]:
		l.size.x = 500
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var ledger: Panel = table._panel(Vector2(110, 190), Vector2(410, 336), PAPER, INK, self)
	ledger.rotation = deg_to_rad(-2.2)
	ledger_title = table._label("", font_carved, 26, INK, Vector2(24, 18), ledger)
	for i in 4:
		var y := 64 + i * 34 + (14 if i >= 2 else 0)
		var l: Label = table._label("", font_hud, 27, Color("2e221a"), Vector2(24, y), ledger)
		var r: Label = table._label("", font_hud, 27, SON if i >= 2 else Color("2e221a"), Vector2(150, y), ledger)
		r.size.x = 236
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ledger_rows.append([l, r])
	for y in [130, 222]:
		var hr := ColorRect.new()
		hr.color = Color(INK, 0.45)
		hr.position = Vector2(24, y)
		hr.size = Vector2(362, 2)
		ledger.add_child(hr)
	total_label = table._label("", font_carved, 40, SON, Vector2(24, 232), ledger)
	odds_label = table._label("", font_hud, 27, Color("2e221a"), Vector2(24, 284), ledger)

	var fp: Panel = table._panel(Vector2(1400, 190), Vector2(410, 404), PAPER, INK, self)
	fp.rotation = deg_to_rad(1.6)
	fingers_title = table._label("", font_carved, 26, INK, Vector2(24, 18), fp)
	fingers_title.size.x = 362
	fingers_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	for i in 5:
		var b := Button.new()
		b.position = Vector2(14, 112 + i * 46)
		b.size = Vector2(382, 42)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", font_hud)
		b.add_theme_font_size_override("font_size", 28)
		for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			b.add_theme_color_override(c, INK)
		b.add_theme_color_override("font_disabled_color", Color("7a6a57"))
		for k in ["normal", "hover", "pressed", "focus", "disabled"]:
			var st := StyleBoxFlat.new()
			st.bg_color = {"hover": Color(SON, 0.10), "pressed": Color(SON, 0.2)}.get(k, Color(0, 0, 0, 0))
			st.content_margin_left = 10
			st.set_corner_radius_all(3)
			if k == "focus":
				st.set_border_width_all(2)
				st.border_color = INK
			b.add_theme_stylebox_override(k, st)
		b.pressed.connect(_pick_finger.bind(i))
		b.mouse_entered.connect(_hover_finger.bind(i, true))
		b.mouse_exited.connect(_hover_finger.bind(i, false))
		fp.add_child(b)
		finger_btns.append(b)
		var d: Label = table._label(DEBUFFS[i], font_hud, 28, INK, Vector2(150, 4), b)
		d.size.x = 222
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		finger_debuffs.append(d)
		var strike := ColorRect.new()
		strike.color = Color(BLOOD, 0.75)
		strike.position = Vector2(8, 21)
		strike.size = Vector2(366, 2)
		strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(strike)
		finger_strikes.append(strike)
	rule_label = table._label(RULE, font_hud, 24, Color("5a4a3a"), Vector2(24, 356), fp)

	_build_stage()

	for i in 6:   # vùng bấm/kéo trong suốt đè lên phần que lộ ra; bàn phím cũng chọn được
		var b := Button.new()
		b.position = FIST_AT + Vector2(STICK_X[i] - 24, -6)
		b.size = Vector2(48, SHOWN + 12)
		b.tooltip_text = "Stick %s" % ROMAN[i]
		b.mouse_default_cursor_shape = Control.CURSOR_DRAG
		for k in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(k, StyleBoxEmpty.new())
		b.gui_input.connect(_stick_input.bind(i))
		b.pressed.connect(_pick_stick.bind(i))
		b.mouse_entered.connect(_hover_stick.bind(i, true))
		b.mouse_exited.connect(_hover_stick.bind(i, false))
		b.focus_entered.connect(_hover_stick.bind(i, true))
		b.focus_exited.connect(_hover_stick.bind(i, false))
		add_child(b)
		stick_btns.append(b)

	result_panel = table._panel(Vector2(110, 880), Vector2(500, 140), PAPER, INK, self)
	result_panel.rotation = deg_to_rad(1.2)
	result_head = table._label("", font_carved, 34, SON, Vector2(24, 16), result_panel)
	result_body = table._label("", font_hud, 28, Color("2e221a"), Vector2(24, 66), result_panel)
	result_body.size = Vector2(452, 60)
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD

	main_btn = table._button("Pull stick", true, Vector2(1366, 868), Vector2(444, 140), self)
	main_btn.add_theme_font_size_override("font_size", 44)
	main_btn.pressed.connect(_on_main_btn)
	main_sub = table._label("", font_hud, 26, PAPER_LIGHT, Vector2(0, 98), main_btn)
	main_sub.size.x = 444
	main_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var glass_layer := CanvasLayer.new()
	glass_layer.layer = 9            # dưới lớp CRT (10), trên bàn chơi
	add_child(glass_layer)
	glass = Control.new()
	glass.size = size
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass_layer.add_child(glass)


## Dựng các lớp hình: thớt → bàn tay (ngón dưới, lòng bàn tay trên) → vòng son → dao phay → nắm tay gỗ (mặt sau, que, mặt trước).
func _build_stage() -> void:
	stage = Node2D.new()
	add_child(stage)
	block = _sprite("block")
	block.position = BLOCK_C
	stage.add_child(block)

	hand = Node2D.new()
	stage.add_child(hand)
	var palm := _sprite("hand_palm")
	palm.centered = false
	hand.add_child(palm)
	hand.set_meta("home", Vector2(960 - palm.texture.get_width() / 2.0, HAND_TOP))
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/execution/hand_layout.json"))
	for i in 5:
		var f: Dictionary = layout.fingers[FINGER_FILES[i]]
		finger_base.append(Vector2(f.base[0], f.base[1]))
		finger_tip.append(Vector2(f.tip[0], f.tip[1]))
		var s := Sprite2D.new()
		s.centered = false
		hand.add_child(s)
		finger_sprites.append(s)
		var area := Area2D.new()   # vùng bấm theo đa giác từng ngón
		var shape := CollisionPolygon2D.new()
		shape.polygon = PackedVector2Array(f.poly.map(func(q): return Vector2(q[0], q[1])))
		area.add_child(shape)
		area.input_event.connect(_finger_input.bind(i))
		area.mouse_entered.connect(_hover_finger.bind(i, true))
		area.mouse_exited.connect(_hover_finger.bind(i, false))
		hand.add_child(area)
		finger_areas.append(area)

	marks = Node2D.new()
	marks.draw.connect(_draw_marks)
	stage.add_child(marks)

	cleaver = Node2D.new()
	cleaver.position = CLEAVER_REST
	var cs := _sprite("cleaver")
	cs.centered = false
	cs.offset = Vector2(0, -cs.texture.get_height() * CLEAVER_EDGE)
	cleaver.add_child(cs)
	stage.add_child(cleaver)

	fist = Node2D.new()
	fist.position = FIST_AT
	stage.add_child(fist)
	tex_long = load(ART % "stick_long")
	tex_short = load(ART % "stick_short_blood")
	for i in 6:
		var s := Sprite2D.new()
		s.centered = false
		s.region_enabled = true
		fist.add_child(s)
		sticks.append(s)
	stick_marks = Node2D.new()
	stick_marks.draw.connect(_draw_stick_marks)
	fist.add_child(stick_marks)
	var wood := _sprite("puppet_fist")   # vẽ đè lên que: que như ló ra từ trong nắm tay
	wood.centered = false
	wood.offset = -wood.texture.get_size() * FIST_GRIP
	fist.add_child(wood)


func _sprite(file: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(ART % file)
	return s


func _dir(i: int) -> Vector2:
	return (finger_tip[i] - finger_base[i]).normalized()


## Chỗ dao chặt trên ngón i, toạ độ màn (theo vị trí bàn tay lúc nghỉ).
func _chop_point(i: int) -> Vector2:
	return hand.get_meta("home") + finger_base[i].lerp(finger_tip[i], CHOP_AT)


## Mở cảnh cho người lên thớt của ván vừa xong. `ev` là sự kiện hand_over, `v` là view của người chơi.
func open(ev: Dictionary, v: Dictionary, hand_no: int) -> void:
	seat = ev.execution.seat
	var lethal: int = ev.execution.lethal
	human = seat == MatchController.HUMAN
	fingers = v.fingers[seat].duplicate()
	stick_sel = -1
	stick_hover = -1
	finger_sel = -1
	finger_hover = -1
	_after = "next"
	_drag = -1
	_reset_stage()

	var who: String = table.SEAT_NAMES[seat]
	hud_top.text = "STAGE %s · HAND %d" % [_roman(v.stage), hand_no]
	hud_sub.text = "you are on the Block" if human else "%s is on the Block" % who
	ledger_title.text = "HAND %d VERDICT" % hand_no
	var rows := [
		["Final", CardNames.combo(v.last_trick.plays[ev.ket_winner])],
		["Taken by", table.SEAT_NAMES[ev.ket_winner]],
		["Fewest tricks", "%s · %d" % ["You" if human else who, ev.tricks_won[seat]]],
		["Times lost" + ("" if human else " this stage"), str(v.losses[seat])],
	]
	for i in 4:
		ledger_rows[i][0].text = rows[i][0]
		ledger_rows[i][1].text = rows[i][1]
	total_label.text = "%d of 6" % lethal
	odds_label.text = "%d Short Bamboo · %d%%" % [lethal, roundi(lethal * 100.0 / 6.0)]
	fingers_title.text = ("On the Block: %s" % ("You" if human else who)).to_upper()
	for i in 5:
		finger_debuffs[i].text = DEBUFFS[i] if human or i == F.THUMB else "-"
	if not human:
		finger_debuffs[F.THUMB].text = "next stage"
	result_panel.visible = false
	_hidden.clear()
	for c in table.world.get_children():
		if c is CanvasItem and c != self and c.get_index() > 0 and c.visible:   # giữ nền xoáy (con đầu tiên)
			c.visible = false
			_hidden.append(c)
	get_child(0).queue_redraw()
	step = Step.DRAW
	_refresh()
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if human:
		stick_btns[0].grab_focus()
	if table.shot_dir != "":
		table.call_deferred("_shot_exec")


func close() -> void:
	visible = false
	for c in _hidden:
		c.visible = true
	_hidden.clear()
	table.crt_mat.set_shader_parameter("vignette", table.vignette)


func _reset_stage() -> void:
	for i in 6:
		_pull[i] = 0.0
		var s := sticks[i]
		if s.get_parent() != fist:
			s.reparent(fist, false)
			fist.move_child(s, i)
		s.texture = tex_long   # que nào trông cũng như nhau cho tới khi engine lật
		s.rotation = 0.0
		s.modulate = Color.WHITE
	_free = -1
	fist.position = FIST_AT
	hand.position = hand.get_meta("home")
	hand.modulate = Color.WHITE if human else HOUSE_SKIN
	cleaver.position = CLEAVER_REST
	cleaver.rotation = 0.0
	cleaver.scale = Vector2.ONE
	for i in 5:
		_set_finger_tex(i)
	_layout_sticks()


func _set_finger_tex(i: int) -> void:
	finger_sprites[i].texture = load(ART % ("finger_%s%s" % [FINGER_FILES[i], "" if fingers[i] else "_bandaged"]))


# ---------------------------------------------------------------- diễn kết quả từ engine

## Rút que: que ngắn tuột khỏi nắm tay sau một phần ba đường kéo, lộ đầu vát đẫm máu; que dài trượt ra hết.
func play_draw(ev: Dictionary) -> void:
	var i: int = ev.stick
	stick_sel = i
	if not human:   # Nhà Cái ngập ngừng trên que nó chọn
		stick_hover = i
		_tension(true)
		await get_tree().create_timer(0.6).timeout
	step = Step.REVEAL
	_drag = -1
	stick_hover = -1
	_refresh()
	var s := sticks[i]
	s.texture = tex_short if ev.short else tex_long
	var hidden: float = s.texture.get_height() - SHOWN
	var pull := create_tween()
	pull.tween_method(func(d): _pull[i] = d, _pull[i], hidden, 0.16 if ev.short else 0.95) \
		.set_trans(Tween.TRANS_QUAD if ev.short else Tween.TRANS_QUART).set_ease(Tween.EASE_IN if ev.short else Tween.EASE_OUT)
	await pull.finished
	_tension(false)
	var whose := "Your" if human else "The House's"
	if ev.short:
		_free_stick(i, Vector2(-290, 250), 1.15, 0.45)   # rơi sang mép trái thớt, đầu máu hướng lên
		table._slam(0.6)
		table.shake = maxf(table.shake, 12.0)
		table.ca_kick = 2.0
		_result("SHORT BAMBOO", "The stick came out bloody. %s" % ("Choose a finger for the Block." if human else "The House lays a finger on the Block."))
		await get_tree().create_timer(0.7).timeout
		var up := create_tween()   # nắm tay gỗ rút lên, nhường chỗ cho thớt
		up.tween_property(fist, "position:y", FIST_AT.y - 760, 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		await up.finished
		step = Step.SELECT
		if fingers.count(true) == 1:
			finger_sel = fingers.find(true)   # chỉ còn một ngón thì không có gì để chọn
		_refresh()
		if human:
			finger_btns[finger_sel if finger_sel >= 0 else fingers.find(true)].grab_focus()
	else:
		_free_stick(i, Vector2(30, 60), 0.12, 0.4)
		table.shake = maxf(table.shake, 5.0)
		_result("LONG STICK — SPARED", "No finger is taken this time. %s hand pulls back." % whose)
		await get_tree().create_timer(0.45).timeout
		create_tween().tween_property(hand, "position:y", HAND_TOP + 460.0, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		step = Step.SURVIVE
		_after = "next"
		await get_tree().create_timer(0.5).timeout
		_show_continue()


## Que đã ra hết khỏi nắm tay: chuyển sang stage để không bị cắt và không bay theo nắm tay, rồi rơi xuống thớt.
func _free_stick(i: int, drop: Vector2, rot: float, dur: float) -> void:
	var s := sticks[i]
	_free = i
	s.region_rect = Rect2(Vector2.ZERO, s.texture.get_size())
	s.reparent(stage)
	var t := create_tween().set_parallel()
	t.tween_property(s, "position", s.position + drop, dur).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "rotation", rot, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Chặt: dao phay nhấc lên, đặt ngang khớp ngón đã chọn, sập xuống.
func play_chop(ev: Dictionary) -> void:
	var f: int = ev.finger
	finger_sel = f
	if not human:
		finger_hover = f
		await get_tree().create_timer(0.9).timeout
	step = Step.CHOP
	finger_hover = -1
	_refresh()
	var hit := _chop_point(f)
	var tilt := atan2(_dir(f).x, -_dir(f).y)
	var lift := create_tween().set_parallel().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	lift.tween_property(cleaver, "position", hit + Vector2(26, -40), 0.4)
	lift.tween_property(cleaver, "rotation", tilt - PI / 2, 0.4)
	lift.tween_property(cleaver, "scale", Vector2(1.16, 1.16), 0.4)
	await lift.finished
	_tension(true)
	await get_tree().create_timer(0.3).timeout
	var slam := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	slam.tween_property(cleaver, "position", hit, 0.08)
	slam.tween_property(cleaver, "scale", Vector2.ONE, 0.08)
	await slam.finished
	_impact(f, hit)
	_tension(false)
	await get_tree().create_timer(0.8).timeout
	var back := create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	back.tween_property(cleaver, "position", CLEAVER_REST, 0.5)
	back.tween_property(cleaver, "rotation", 0.0, 0.5)
	var whose := "Your %s" % FINGER_NOUNS[f] if human else "The House's %s" % FINGER_NOUNS[f]
	_result("CHOPPED", "%s is gone.%s" % [whose, (" " + DEBUFFS[f][0].to_upper() + DEBUFFS[f].substr(1) + ".") if human else ""])
	step = Step.DONE
	_after = "next"
	await get_tree().create_timer(0.5).timeout
	_show_continue()


## Hậu quả sau chopped: bị loại, qua Màn, thua Run.
func note(ev: Dictionary) -> void:
	match ev.type:
		"eliminated":
			if human:
				_result("ELIMINATED", "Your thumb is gone. Your seat belongs to an Effigy now.")
		"stage_cleared":
			_result("STAGE CLEARED", "The House has no thumb left. A new House sits down: Stage %s." % _roman(ev.stage))
		"run_over":
			_result("RUN OVER", "Your thumb is gone. No one is left at the table.")
			_after = "title"
	_show_continue()


## Dao trúng ngón: hitstop → flash đỏ → rung → CRT nhiễu, đốt ngón văng, máu bắn lên kính, máu thấm thớt ở lại.
func _impact(f: int, hit: Vector2) -> void:
	var cut := Sprite2D.new()   # ngón văng: lớp ngón lành, cắt khung quanh ngón đó
	cut.texture = finger_sprites[f].texture
	cut.region_enabled = true
	var poly: PackedVector2Array = (finger_areas[f].get_child(0) as CollisionPolygon2D).polygon
	var r := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		r = r.expand(q)
	r = r.intersection(Rect2(Vector2.ZERO, cut.texture.get_size()))
	cut.region_rect = r
	cut.offset = -r.size / 2
	cut.position = hand.position + r.get_center()
	cut.modulate = hand.modulate
	stage.add_child(cut)
	_severed = {node = cut, vel = Vector2(260 + _dir(f).x * 300, -900), spin = 9.0}
	fingers[f] = false
	_set_finger_tex(f)
	table.crt_mat.set_shader_parameter("flash_color", Color(0.85, 0.06, 0.04))
	table.flash = 1.0
	table._slam(1.45)                 # hitstop ≈ 100 ms với hitstop mặc định 0.07
	table.shake = 26.0
	var g := create_tween()
	g.tween_method(func(x): table.crt_mat.set_shader_parameter("glitch", x), 1.0, 0.0, 0.6)
	g.tween_callback(func(): table.crt_mat.set_shader_parameter("flash_color", Color(1.0, 0.92, 0.86)))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 4:   # máu thấm thớt: con của block nên ở lại qua mọi lần Hành Quyết
		var b := Sprite2D.new()
		b.texture = blood_blob(rng.randi(), rng.randi_range(24, 56), rng.randi_range(16, 40))
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.scale = Vector2(3, 3)   # hạt máu nhỏ hơn máu trên kính, cho hợp nét vẽ chi tiết của thớt
		b.position = hit - BLOCK_C + Vector2(rng.randf_range(-170, 170), rng.randf_range(-150, 60))
		b.modulate.a = rng.randf_range(0.75, 0.95)
		block.add_child(b)
	for i in 6:
		var blob := TextureRect.new()
		blob.texture = blood_blob(rng.randi(), rng.randi_range(10, 26), rng.randi_range(8, 18))
		blob.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		blob.size = blob.texture.get_size() * 6
		blob.position = Vector2(rng.randf_range(560, 1360), rng.randf_range(220, 720)) - blob.size * 0.5
		blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glass.add_child(blob)
		var t := blob.create_tween().set_parallel()
		t.tween_property(blob, "position:y", blob.position.y + rng.randf_range(90, 200), 3.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_property(blob, "modulate:a", 0.0, 1.4).set_delay(2.2)
		t.chain().tween_callback(blob.queue_free)
	table.add_stain()
	_refresh()


# ---------------------------------------------------------------- thao tác

func _stick_input(ev: InputEvent, i: int) -> void:
	if not human or step != Step.DRAW:
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_drag = i
			_drag_y0 = ev.global_position.y
		elif _drag == i:
			_drag = -1
			var back := create_tween()
			back.tween_method(func(d): _pull[i] = d, _pull[i], 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif ev is InputEventMouseMotion and _drag == i:
		var g := clampf(ev.global_position.y - _drag_y0, 0.0, DRAG_GESTURE)
		_pull[i] = g / DRAG_GESTURE * (tex_short.get_height() - SHOWN)   # chưa tới chỗ que ngắn tuột ra: client chưa biết gì
		if g >= DRAG_GESTURE * DRAG_COMMIT:   # rê đủ xa thì tự chốt rút que này
			_drag = -1
			stick_sel = i
			_pull_stick()


func _pick_stick(i: int) -> void:
	if not human or step != Step.DRAW:
		return
	stick_sel = i
	_refresh()


func _hover_stick(i: int, on: bool) -> void:
	if not human or step != Step.DRAW:
		return
	if on:
		stick_hover = i
	elif stick_hover == i:
		stick_hover = -1
	_tension(stick_hover != -1)


func _finger_input(_vp: Node, ev: InputEvent, _idx: int, i: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_pick_finger(i)


func _pick_finger(i: int) -> void:
	if not human or step != Step.SELECT or not fingers[i]:
		return
	if i == F.THUMB and fingers.count(true) > 1:
		_deny(i)
		return
	finger_sel = i
	_refresh()


func _hover_finger(i: int, on: bool) -> void:
	if not human or step != Step.SELECT:
		return
	if on and fingers[i] and (i != F.THUMB or fingers.count(true) == 1):
		finger_hover = i
	elif finger_hover == i:
		finger_hover = -1


## Chọn ngón Cái khi còn ngón khác: ngón rung, dòng luật đỏ lên.
func _deny(i: int) -> void:
	var n := finger_sprites[i]
	var t := create_tween()
	for k in 6:
		t.tween_property(n, "position", Vector2(7 if k % 2 == 0 else -7, 0), 0.04)
	t.tween_property(n, "position", Vector2.ZERO, 0.04)
	main_sub.text = RULE
	rule_label.add_theme_color_override("font_color", SON)
	var back := create_tween()
	back.tween_interval(1.2)
	back.tween_callback(func(): rule_label.add_theme_color_override("font_color", Color("5a4a3a")))


func _on_main_btn() -> void:
	match step:
		Step.DRAW:
			if stick_sel >= 0:
				_pull_stick()
		Step.SELECT:
			if finger_sel >= 0:
				step = Step.CHOP
				_refresh()
				table.match_ctl.submit({type = "chop", seat = seat, finger = finger_sel})
		Step.SURVIVE, Step.DONE:
			finished.emit(_after)


func _pull_stick() -> void:
	step = Step.REVEAL
	_refresh()
	table.match_ctl.submit({type = "draw_stick", seat = seat, stick = stick_sel})


func _refresh() -> void:
	var drawing := human and step == Step.DRAW
	var selecting := human and step == Step.SELECT
	for b in stick_btns:
		b.visible = drawing
	for i in 5:
		finger_areas[i].input_pickable = selecting
		var b := finger_btns[i]
		b.disabled = not selecting or not fingers[i]
		var now := i == finger_sel and step >= Step.SELECT
		b.text = ("%s · now" % FINGER_NAMES[i]) if now else FINGER_NAMES[i]
		var st: StyleBoxFlat = b.get_theme_stylebox("normal").duplicate()
		st.bg_color = Color(SON, 0.16) if now else Color(0, 0, 0, 0)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("disabled", st)
		var lost: bool = not fingers[i]
		finger_strikes[i].visible = lost
		finger_debuffs[i].add_theme_color_override("font_color", Color("7a6a57") if lost else (SON if now else INK))
		b.add_theme_color_override("font_disabled_color", Color("7a6a57") if lost else (SON if now else Color("5a4a3a")))
	match step:
		Step.DRAW:
			main_btn.visible = human
			main_btn.disabled = stick_sel < 0
			main_btn.text = "PULL STICK %s" % ROMAN[stick_sel] if stick_sel >= 0 else "PULL STICK"
			main_sub.text = "pick a stick, or drag one down"
		Step.SELECT:
			main_btn.visible = human
			main_btn.disabled = finger_sel < 0
			main_btn.text = "CHOP %s" % FINGER_NAMES[finger_sel].to_upper() if finger_sel >= 0 else "CHOP"
			main_sub.text = "pick a finger"
		Step.SURVIVE, Step.DONE:
			pass   # _show_continue() lo nút đi tiếp
		_:
			main_btn.visible = false


func _show_continue() -> void:
	main_btn.visible = true
	main_btn.disabled = false
	main_btn.text = "BACK TO TITLE" if _after == "title" else "NEXT HAND"
	main_sub.text = ""
	main_btn.grab_focus()


func _result(head: String, body: String) -> void:
	result_head.text = head
	result_body.text = body
	result_panel.visible = true


## Lúc lưỡng lự (rê lên que, dao đang giơ): màn căng lên (vignette và chromatic aberration tăng).
func _tension(on: bool) -> void:
	var t := create_tween().set_parallel()
	t.tween_property(table.crt_mat, "shader_parameter/vignette", table.vignette + (0.3 if on else 0.0), 0.3) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	table.ca_base = table.aberration_execution + (1.0 if on else 0.0)


# ---------------------------------------------------------------- vẽ

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_layout_sticks()
	if not _severed.is_empty():
		var n: Sprite2D = _severed.node
		_severed.vel.y += 2600 * delta
		n.position += _severed.vel * delta
		n.rotation += _severed.spin * delta
		if n.position.y > 1400:
			n.queue_free()
			_severed = {}
	marks.queue_redraw()
	stick_marks.queue_redraw()


## Que trong nắm tay chỉ vẽ phần dưới mép nắm tay (region), nên ảnh nắm tay vẽ thế nào cũng không lộ phần que giấu bên trong.
func _layout_sticks() -> void:
	for i in 6:
		if i == _free:
			continue
		var s := sticks[i]
		var sz := s.texture.get_size()
		var top: float = SHOWN - sz.y + _pull[i]
		var cut := maxf(0.0, -top)
		var x: float = STICK_X[i]
		if i == stick_hover and step == Step.DRAW:
			x += sin(_t * 60.0) * 1.5
		s.region_rect = Rect2(0, cut, sz.x, sz.y - cut)
		s.offset = Vector2(-sz.x / 2.0, 0)
		s.position = Vector2(x, top + cut)


func _draw_under(c: Control) -> void:
	var slab := StyleBoxFlat.new()
	slab.bg_color = Color("2a170d")
	slab.set_corner_radius_all(40)
	slab.set_border_width_all(16)
	slab.border_color = Color("120a07")
	slab.shadow_color = Color(0, 0, 0, 0.8)
	slab.shadow_size = 40
	slab.draw(c.get_canvas_item(), Rect2(110, 640, 1700, 560))
	for t in table.stains:
		c.draw_texture_rect(t.texture, Rect2(t.position, t.size), false, Color(1, 1, 1, t.modulate.a))


## Vòng son khoanh khớp ngón đang trỏ / đã chọn.
func _draw_marks() -> void:
	if step != Step.SELECT and step != Step.CHOP:
		return
	for i in [finger_hover, finger_sel]:
		if i < 0 or not fingers[i]:
			continue
		var c: Vector2 = _chop_point(i) - hand.get_meta("home") + hand.position
		var r := 30.0
		if i == finger_sel:
			marks.draw_arc(c, r + 3, 0, TAU, 48, PAPER_LIGHT, 3)
			marks.draw_arc(c, r, 0, TAU, 48, SON, 7)
		else:
			marks.draw_arc(c, r, 0, TAU, 48, Color(SON, 0.7), 4)


## Viền que đang trỏ / đã chọn; X-Ray (debug) tô đỏ mờ que ngắn.
func _draw_stick_marks() -> void:
	for i in 6:
		if i == _free:
			continue
		var s := sticks[i]
		var r := Rect2(s.position + s.offset - Vector2(3, 0), Vector2(s.region_rect.size.x + 6, s.region_rect.size.y + 2))
		if xray.size() == 6 and xray[i]:
			stick_marks.draw_rect(r, Color(SON, 0.35))
			stick_marks.draw_rect(r, Color(1, 0.3, 0.2, 0.8), false, 2)
		if step != Step.DRAW:
			continue
		if i == stick_sel:
			stick_marks.draw_rect(r.grow(3), SON, false, 5)
		elif i == stick_hover:
			stick_marks.draw_rect(r.grow(2), PAPER_LIGHT, false, 3)


static func _roman(n: int) -> String:
	return ROMAN[n - 1] if n >= 1 and n <= ROMAN.size() else str(n)


## Vết máu pixel (vẽ phóng 6× không lọc): vài tâm loang chồng nhau, mép sẫm, có giọt lẻ.
static func blood_blob(seed_value: int, w: int, h: int) -> ImageTexture:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var centers := []
	for i in 4:
		centers.append([Vector2(r.randf_range(0.3, 0.7) * w, r.randf_range(0.3, 0.7) * h), r.randf_range(0.2, 0.36) * minf(w, h) + 1.5])
	for y in h:
		for x in w:
			var d := 9.0
			for c in centers:
				d = minf(d, Vector2(x, y).distance_to(c[0]) / c[1])
			if d < 1.0 + r.randf_range(-0.2, 0.2) or r.randf() < 0.03 * maxf(0.0, 2.0 - d):
				img.set_pixel(x, y, BLOOD_DRY if d > 0.75 else (BLOOD if d > 0.35 else Color("8e1414")))
	return ImageTexture.create_from_image(img)
