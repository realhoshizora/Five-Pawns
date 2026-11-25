extends Control
## Màn tiêu đề (theo mockups/title.html): năm lá Tốt Đỏ xòe quạt, chữ FIVE PAWNS, menu.
## Chỉ "Play offline" và "Quit" chạy; các mục khác mờ cho tới giai đoạn làm ra chúng.

const TABLE := "res://game/table.tscn"
const PAPER := Color("d8c294")
const PAPER_LIGHT := Color("eadcb4")
const SON := Color("b0241a")
const DIEP := Color("f1e9d6")

var font_carved: Font = preload("res://assets/fonts/Bevan-Regular.ttf")
var font_hud: Font = preload("res://assets/fonts/VT323-Regular.ttf")


func _ready() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(1920, 1080)
	var swirl := ShaderMaterial.new()
	swirl.shader = preload("res://shaders/swirl.gdshader")
	for i in 4:
		swirl.set_shader_parameter("c%d" % i, [Color("0c0806"), Color("1e0f0a"), Color("3a130d"), Color("5c1b11")][i])
	swirl.set_shader_parameter("twist", 1.3)
	swirl.set_shader_parameter("speed", 0.06)
	bg.material = swirl
	add_child(bg)

	# Quạt năm lá Tốt Đỏ; khung cắt ở mép chữ để phần chữ lộn ngược ở đáy lá không lộ qua khe giữa các chữ cái.
	var fan := Control.new()
	fan.size = Vector2(1920, 528)
	fan.clip_contents = true
	add_child(fan)
	var pawn: Texture2D = load("res://assets/cards/png/red_pawn.png")
	for i in 5:
		var c := TextureRect.new()
		c.texture = pawn
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_SCALE
		c.size = Vector2(150, 513)
		c.position = Vector2(960 - 75, 96 - (14 if i == 2 else 8 if i % 2 else 0))
		c.pivot_offset = Vector2(75, 513 * 1.6)
		c.rotation = deg_to_rad((i - 2) * 16.0)
		fan.add_child(c)

	var title := _label("FIVE PAWNS", font_carved, 178, DIEP, Vector2(0, 452))
	title.size.x = 1920
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_y", 14)
	# font cắt chỉ còn "五子" và dấu cách (~2 KB); muốn thêm chữ thì cắt lại từ LXGW WenKai TC Bold (xem assets/fonts)
	var sub := _label("五 子", preload("res://assets/fonts/LXGWWenKaiTC-Bold-wuzi.ttf"), 92, Color("d0372a"), Vector2(0, 652))
	sub.size.x = 1920
	sub.add_theme_constant_override("outline_size", 7)   # viền cùng màu cho nét đậm như chữ trên lá bài
	sub.add_theme_color_override("font_outline_color", Color("d0372a"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label("Lose the hand. Cut a rope.", font_hud, 34, Color("cdbb98"), Vector2(1500, 930))
	_label("v0.1 · prototype", font_hud, 26, Color("a8987e"), Vector2(1700, 980))

	var menu := VBoxContainer.new()
	menu.position = Vector2(118, 716)
	menu.add_theme_constant_override("separation", 6)
	add_child(menu)
	var play := _menu_item(menu, "Play offline", true)
	play.pressed.connect(func(): get_tree().change_scene_to_file(TABLE))
	_menu_item(menu, "Co-op online · phase 5", false)
	_menu_item(menu, "How to play · soon", false)
	_menu_item(menu, "Settings · soon", false)
	_menu_item(menu, "Quit", true).pressed.connect(get_tree().quit)
	play.grab_focus()

	var crt_layer := CanvasLayer.new()
	crt_layer.layer = 10
	add_child(crt_layer)
	var crt := ColorRect.new()
	crt.size = Vector2(1920, 1080)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_mat := ShaderMaterial.new()
	crt_mat.shader = preload("res://shaders/crt.gdshader")
	crt.material = crt_mat
	crt_layer.add_child(crt)

	# Chế độ chụp màn tự động (xem table.gd): chụp tiêu đề rồi vào bàn chơi.
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			await get_tree().create_timer(1.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(a.substr(7).path_join("title.png"))
			get_tree().change_scene_to_file(TABLE)


func _label(text: String, font: Font, size_px: int, color: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _menu_item(menu: VBoxContainer, text: String, enabled: bool) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.disabled = not enabled
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", font_carved)
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", PAPER_LIGHT)
	b.add_theme_color_override("font_focus_color", PAPER_LIGHT)
	b.add_theme_color_override("font_disabled_color", Color(PAPER, 0.35))
	var plain := StyleBoxEmpty.new()
	plain.content_margin_left = 0
	var seal := StyleBoxFlat.new()   # mục đang trỏ/focus thành con dấu son
	seal.bg_color = SON
	seal.set_border_width_all(3)
	seal.border_color = PAPER_LIGHT
	seal.set_corner_radius_all(5)
	seal.content_margin_left = 22
	seal.content_margin_right = 22
	for k in ["normal", "disabled", "pressed"]:
		b.add_theme_stylebox_override(k, plain)
	b.add_theme_stylebox_override("hover", seal)
	b.add_theme_stylebox_override("focus", seal)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu.add_child(b)
	return b
