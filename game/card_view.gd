class_name CardView
extends Control
## Một lá bài trên bàn: chạy theo vật lý lò xo tới vị trí/góc/tỉ lệ đích, nghiêng 3D theo chuột, nhấc khi chọn,
## kéo được, lật được. Không biết luật; chỉ báo click/kéo cho bàn chơi xử lý.

signal clicked(card: CardView)
signal drag_released(card: CardView, global_point: Vector2)

const SIZE := Vector2(100, 342)
const FILE := ["pawn", "horse", "cannon", "chariot", "elephant", "advisor", "general"]
const TILT_SHADER := preload("res://shaders/card_tilt.gdshader")
const BACK := preload("res://assets/cards/png/back.png")

# Lò xo hơi thiếu tắt dần để lá nảy nhẹ khi tới đích.
const K := 230.0
const DAMP := 21.0

var card_id := -1                 # -1 = chưa biết mặt (bài úp của người khác)
var face_up := false
var interactive := false
var selected := false
var home := Vector2.ZERO          # vị trí đích (góc trên-trái theo toạ độ cha)
var home_rot := 0.0
var home_scale := 1.0
var lift := 0.0                   # nhấc lên khi chọn/hover (px, hướng lên)

var _vel := Vector2.ZERO
var _rot_vel := 0.0
var _scale_vel := 0.0
var _tilt := Vector2.ZERO
var _hover := false
var _press_pos := Vector2.ZERO
var _dragging := false
var _drag_offset := Vector2.ZERO
var _flipping := false
var base_z := 0
var _face: TextureRect
var _shadow: TextureRect
var _mat: ShaderMaterial


static func texture_for(id: int) -> Texture2D:
	var suit := "red" if Card.suit(id) == Card.Suit.RED else "black"
	return load("res://assets/cards/png/%s_%s.png" % [suit, FILE[Card.rank(id)]])


static func name_for(id: int) -> String:
	return "%s %s" % ["Red" if Card.suit(id) == Card.Suit.RED else "Black", CardNames.RANK[Card.rank(id)]]


func _init(id := -1, show_face := false) -> void:
	card_id = id
	face_up = show_face and id >= 0
	size = SIZE
	pivot_offset = SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow = _make_rect(Color(0, 0, 0, 0.55))
	_face = _make_rect(Color.WHITE)
	_mat = ShaderMaterial.new()
	_mat.shader = TILT_SHADER
	_mat.set_shader_parameter("size", SIZE)
	_face.material = _mat
	_refresh_texture()


func _make_rect(tint: Color) -> TextureRect:
	var r := TextureRect.new()
	r.size = SIZE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _refresh_texture() -> void:
	var tex: Texture2D = texture_for(card_id) if face_up else BACK
	_face.texture = tex
	_shadow.texture = tex
	tooltip_text = name_for(card_id) if face_up else ""


func set_interactive(on: bool) -> void:
	interactive = on
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	if not on:
		_hover = false


## Đặt ngay vào vị trí (không bay), ví dụ khi sinh ra ở cọc bài.
func snap(pos: Vector2, rot := 0.0, sc := 1.0) -> void:
	position = pos
	rotation = rot
	scale = Vector2.ONE * sc
	home = pos
	home_rot = rot
	home_scale = sc


## Lật bài: thu bề ngang về 0, đổi mặt, mở ra lại.
func flip_to(id: int, duration := 0.22) -> void:
	_flipping = true
	var t := create_tween()
	t.tween_property(self, "scale:x", 0.0, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		card_id = id
		face_up = id >= 0
		_refresh_texture())
	t.tween_property(self, "scale:x", home_scale, duration * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	_flipping = false


func _process(delta: float) -> void:
	delta = minf(delta, 1.0 / 30.0)
	var want_lift := lift + (18.0 if _hover and not selected else 0.0)
	var target := home + Vector2(0, -want_lift)
	if _dragging:
		target = get_parent().get_local_mouse_position() - _drag_offset
	# lò xo vị trí
	var acc := (target - position) * K - _vel * DAMP
	_vel += acc * delta
	position += _vel * delta
	# lò xo góc và tỉ lệ (không đụng scale.x khi đang lật)
	_rot_vel += ((home_rot - rotation) * K - _rot_vel * DAMP) * delta
	rotation += _rot_vel * delta
	var want_scale := home_scale * (1.06 if _dragging else 1.0)
	_scale_vel += ((want_scale - scale.y) * K - _scale_vel * DAMP) * delta
	scale.y += _scale_vel * delta
	if not _flipping:
		scale.x = scale.y
	# nghiêng: theo chuột khi hover, theo vận tốc khi bay/kéo
	var want_tilt := Vector2(clampf(_vel.x * 0.0009, -0.35, 0.35), clampf(-_vel.y * 0.0006, -0.3, 0.3))
	if _hover or _dragging:
		var m := (get_local_mouse_position() / SIZE) - Vector2(0.5, 0.5)
		want_tilt += Vector2(m.x * 0.7, -m.y * 0.55)
	_tilt = _tilt.lerp(want_tilt, 1.0 - exp(-14.0 * delta))
	_mat.set_shader_parameter("tilt", _tilt)
	# bóng đổ: lá càng nhấc cao bóng càng lệch xa
	var h := clampf(home.y - position.y + 6.0, 4.0, 60.0)
	_shadow.position = Vector2(h * 0.25, h * 0.6)
	_shadow.modulate.a = clampf(0.6 - h * 0.006, 0.25, 0.6)


func _gui_input(ev: InputEvent) -> void:
	if not interactive:
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_press_pos = ev.global_position
			_drag_offset = get_local_mouse_position()
		else:
			if _dragging:
				_dragging = false
				z_index = base_z
				drag_released.emit(self, ev.global_position)
			elif ev.global_position.distance_to(_press_pos) < 8.0:
				clicked.emit(self)
		accept_event()
	elif ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT):
		if not _dragging and ev.global_position.distance_to(_press_pos) > 10.0:
			_dragging = true
			z_index = 50


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hover = true
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hover = false
