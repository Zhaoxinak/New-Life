extends Control
class_name PortraitView


var speaker_id: String = ""
var _tex: Texture2D = null
var _t: float = 0.0
var _cold: bool = false


func _ready() -> void :

	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(160, 210)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_speaker(id: String) -> void :
	speaker_id = id
	var key: = UiStyle.portrait_key_for_speaker(id)
	_tex = UiStyle.portrait_texture(key)
	# Street NPCs without painted portraits: crop bust from classic walk sheet.
	if _tex == null and id.strip_edges() != "" and id != "narrator":
		_tex = WalkSheets.bust_texture(id)
	queue_redraw()


func set_cold(on: bool) -> void :
	_cold = on
	modulate = Color(0.55, 0.58, 0.68, 1.0) if on else Color(1, 1, 1, 1)
	queue_redraw()


func _process(delta: float) -> void :
	_t += delta
	if _tex == null:
		queue_redraw()


func _draw() -> void :
	var r: = Rect2(Vector2.ZERO, size)

	draw_rect(r, UiStyle.WOOD)
	var inner: = r.grow(-6)
	draw_rect(inner, UiStyle.PARCHMENT)
	var art: = inner.grow(-4)
	if _tex != null:
		# demo_ai_town resident fronts / paper-doll busts: keep aspect, sit in frame.
		var tex_size: = _tex.get_size()
		if tex_size.x > 1.0 and tex_size.y > 1.0:
			var pad: = art.grow(-4.0)
			var s: = minf(pad.size.x / tex_size.x, pad.size.y / tex_size.y)
			var dest_size: = tex_size * s
			var dest: = Rect2(
				pad.position.x + (pad.size.x - dest_size.x) * 0.5, 
				pad.position.y + (pad.size.y - dest_size.y) * 0.2, 
				dest_size.x, 
				dest_size.y
			)
			draw_texture_rect(_tex, dest, false)
		else:
			draw_texture_rect(_tex, art, false)
	else:
		var base: = UiStyle.portrait_color(speaker_id)
		draw_rect(art, Color(base.r * 0.55, base.g * 0.55, base.b * 0.55, 1))
		var shoulder: = Rect2(art.position.x + art.size.x * 0.08, art.position.y + art.size.y * 0.62, art.size.x * 0.84, art.size.y * 0.4)
		draw_rect(shoulder, Color(base.r * 0.75, base.g * 0.75, base.b * 0.75, 1))
		var head_c: = art.position + Vector2(art.size.x * 0.5, art.size.y * 0.38)
		draw_circle(head_c, art.size.x * 0.22, Color(minf(base.r * 1.1, 1.0), minf(base.g * 1.1, 1.0), minf(base.b * 1.1, 1.0), 1.0))

	draw_rect(Rect2(r.position, Vector2(14, 3)), UiStyle.BRASS)
	draw_rect(Rect2(r.position, Vector2(3, 14)), UiStyle.BRASS)
	draw_rect(Rect2(Vector2(r.end.x - 14, r.position.y), Vector2(14, 3)), UiStyle.BRASS)
	draw_rect(Rect2(Vector2(r.end.x - 3, r.position.y), Vector2(3, 14)), UiStyle.BRASS)
