extends Control
class_name SceneStage
## Full-bleed location backdrop: art first, procedural cozy fallback.

signal location_painted(location_id: String)

@export var location_id: String = "dock"
@export var animate: bool = true

var _t: float = 0.0
var _art: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_process(animate)
	_reload_art()
	queue_redraw()


func set_location(id: String) -> void:
	location_id = id
	_reload_art()
	queue_redraw()
	location_painted.emit(location_id)


func _reload_art() -> void:
	_art = UiStyle.location_texture(location_id)


func _process(delta: float) -> void:
	if not animate:
		return
	_t += delta
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x < 2.0 or r.size.y < 2.0:
		return
	if _art != null:
		# Cover-fit crop for 16:9 art.
		var tex_size := _art.get_size()
		var scale := maxf(r.size.x / tex_size.x, r.size.y / tex_size.y)
		var draw_size := tex_size * scale
		var origin := (r.size - draw_size) * 0.5
		draw_texture_rect(_art, Rect2(origin, draw_size), false)
		# Soft storybook vignette (keep art readable).
		draw_rect(Rect2(0, 0, r.size.x, r.size.y * 0.1), Color(0, 0, 0, 0.18))
		draw_rect(Rect2(0, r.size.y * 0.88, r.size.x, r.size.y * 0.12), Color(0, 0, 0, 0.28))
		# Gentle light pulse
		var a := 0.03 + 0.02 * sin(_t * 1.2)
		draw_rect(r, Color(1.0, 0.92, 0.7, a))
		return
	match location_id:
		"company":
			_draw_company(r)
		"home":
			_draw_home(r)
		"rival":
			_draw_rival(r)
		"exchange":
			_draw_exchange(r)
		_:
			_draw_dock(r)
	_draw_vignette(r)


func _pal() -> Array:
	return UiStyle.location_palette(location_id)


func _draw_vignette(r: Rect2) -> void:
	draw_rect(Rect2(0, 0, r.size.x, r.size.y * 0.12), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(0, r.size.y * 0.78, r.size.x, r.size.y * 0.22), Color(0, 0, 0, 0.3))


func _draw_sky_band(r: Rect2, sky: Color, mid: Color, horizon_y: float) -> void:
	var steps := 8
	for i in steps:
		var t := float(i) / float(steps)
		var y0 := horizon_y * t
		var y1 := horizon_y * (t + 1.0 / float(steps))
		draw_rect(Rect2(0, y0, r.size.x, y1 - y0), sky.lerp(mid, t * 0.85))


func _draw_dock(r: Rect2) -> void:
	var p := _pal()
	var horizon := r.size.y * 0.52
	_draw_sky_band(r, p[0], p[1], horizon)
	draw_rect(Rect2(0, horizon + 40, r.size.x, r.size.y), p[4])
	draw_rect(Rect2(0, r.size.y * 0.72, r.size.x, r.size.y * 0.28), p[2])
	_draw_lantern(Vector2(r.size.x * 0.2, r.size.y * 0.55), p[3])
	_draw_lantern(Vector2(r.size.x * 0.75, r.size.y * 0.5), p[3])


func _draw_company(r: Rect2) -> void:
	var p := _pal()
	_draw_sky_band(r, p[0], p[1], r.size.y * 0.35)
	draw_rect(Rect2(0, r.size.y * 0.35, r.size.x, r.size.y), p[2])
	_draw_lantern(Vector2(r.size.x * 0.3, r.size.y * 0.55), p[3])


func _draw_home(r: Rect2) -> void:
	var p := _pal()
	_draw_sky_band(r, p[0], p[1], r.size.y * 0.4)
	draw_rect(Rect2(0, r.size.y * 0.4, r.size.x, r.size.y), Color(0.16, 0.14, 0.2, 1))
	_draw_lantern(Vector2(r.size.x * 0.4, r.size.y * 0.5), Color(0.95, 0.8, 0.45, 1))


func _draw_rival(r: Rect2) -> void:
	var p := _pal()
	_draw_sky_band(r, p[0], p[1], r.size.y * 0.42)
	draw_rect(Rect2(0, r.size.y * 0.42, r.size.x, r.size.y), p[2])
	_draw_lantern(Vector2(r.size.x * 0.5, r.size.y * 0.5), p[3])


func _draw_exchange(r: Rect2) -> void:
	var p := _pal()
	_draw_sky_band(r, p[0], p[1], r.size.y * 0.38)
	draw_rect(Rect2(0, r.size.y * 0.38, r.size.x, r.size.y), p[2])
	_draw_lantern(Vector2(r.size.x * 0.25, r.size.y * 0.55), p[3])
	_draw_lantern(Vector2(r.size.x * 0.75, r.size.y * 0.55), p[3])


func _draw_lantern(pos: Vector2, col: Color) -> void:
	var glow := 0.35 + 0.15 * sin(_t * 3.0 + pos.x * 0.01)
	draw_circle(pos, 28.0, Color(col.r, col.g, col.b, glow * 0.35))
	draw_circle(pos, 10.0, Color(col.r, col.g, col.b, 0.85))
