extends Control
class_name PortraitView
## Painted portrait with wood frame + silhouette fallback.

var speaker_id: String = ""
var _tex: Texture2D = null
var _t: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(160, 210)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_speaker(id: String) -> void:
	speaker_id = id
	var key := UiStyle.portrait_key_for_speaker(id)
	_tex = UiStyle.portrait_texture(key)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _tex == null:
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	# Wood frame
	draw_rect(r, UiStyle.WOOD)
	var inner := r.grow(-6)
	draw_rect(inner, UiStyle.PARCHMENT)
	var art := inner.grow(-4)
	if _tex != null:
		draw_texture_rect(_tex, art, false)
	else:
		var base := UiStyle.portrait_color(speaker_id)
		draw_rect(art, Color(base.r * 0.55, base.g * 0.55, base.b * 0.55, 1))
		var shoulder := Rect2(art.position.x + art.size.x * 0.08, art.position.y + art.size.y * 0.62, art.size.x * 0.84, art.size.y * 0.4)
		draw_rect(shoulder, Color(base.r * 0.75, base.g * 0.75, base.b * 0.75, 1))
		var head_c := art.position + Vector2(art.size.x * 0.5, art.size.y * 0.38)
		draw_circle(head_c, art.size.x * 0.22, Color(minf(base.r * 1.1, 1.0), minf(base.g * 1.1, 1.0), minf(base.b * 1.1, 1.0), 1.0))
	# Brass corner accents
	draw_rect(Rect2(r.position, Vector2(14, 3)), UiStyle.BRASS)
	draw_rect(Rect2(r.position, Vector2(3, 14)), UiStyle.BRASS)
	draw_rect(Rect2(Vector2(r.end.x - 14, r.position.y), Vector2(14, 3)), UiStyle.BRASS)
	draw_rect(Rect2(Vector2(r.end.x - 3, r.position.y), Vector2(3, 14)), UiStyle.BRASS)
