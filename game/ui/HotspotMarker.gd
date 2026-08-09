extends Control
class_name HotspotMarker


signal activated(hotspot_id: String)

var hotspot_id: String = ""
var label_text: String = ""
var gated: bool = false
var gate_reason: String = ""
var selected: bool = false

var _t: float = 0.0
var _icon: Texture2D = null


func _ready() -> void :
	custom_minimum_size = Vector2(140, 72)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_icon = UiStyle.ui_texture("hotspot_marker")
	set_process(true)


func setup(id: String, text: String, is_gated: bool, reason: String = "") -> void :
	hotspot_id = id
	label_text = text
	gated = is_gated
	gate_reason = reason
	tooltip_text = reason if is_gated else text
	queue_redraw()


func set_selected(on: bool) -> void :
	selected = on
	queue_redraw()


func _process(delta: float) -> void :
	_t += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if gated:
			return
		activated.emit(hotspot_id)
		accept_event()


func _draw() -> void :
	var c: = Vector2(size.x * 0.5, 22.0)
	var bob: = sin(_t * 2.8) * 3.0
	c.y += bob
	var pulse: = 1.0 + 0.08 * sin(_t * 3.0)
	if _icon != null and not gated:
		var isz: = 44.0 * pulse
		var ir: = Rect2(c.x - isz * 0.5, c.y - isz * 0.5, isz, isz)
		draw_texture_rect(_icon, ir, false)
	else:
		var base: = UiStyle.BRASS if not gated else UiStyle.TEXT_DIM
		if selected:
			base = UiStyle.OK
		draw_circle(c, 18.0 * pulse, Color(base.r, base.g, base.b, 0.3))
		draw_circle(c, 8.0, Color(base.r, base.g, base.b, 0.95 if not gated else 0.4))

	var font: = ThemeDB.fallback_font
	var fs: = 14
	var tw: = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tx: = c.x - tw * 0.5
	var ty: = c.y + 24.0
	var plate: = Rect2(tx - 10, ty - 2, tw + 20, 24)
	draw_rect(plate, UiStyle.PARCHMENT if not gated else Color("c4b090"))
	draw_rect(plate, UiStyle.WOOD if selected else Color("6b4226"), false, 2.0)
	var tc: = UiStyle.TEXT if not gated else UiStyle.TEXT_DIM
	draw_string(font, Vector2(tx, ty + 16), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)
