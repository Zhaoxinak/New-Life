extends Node2D


var _map_size: Vector2 = Vector2.ZERO
var _norms: Array = []
var _polylines: Array = []
var _t: float = 0.0
var _path_width: float = 0.055


func set_paths(map_size: Vector2, normalized_rects: Array, polylines: Array = []) -> void :
	_map_size = map_size
	_norms = normalized_rects.duplicate()
	_polylines = polylines.duplicate()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void :
	_t += delta
	queue_redraw()


func _draw() -> void :
	if _map_size == Vector2.ZERO:
		return
	var pulse: = 0.1 + 0.035 * sin(_t * 2.0)
	var w: = _path_width * minf(_map_size.x, _map_size.y)
	for poly in _polylines:
		if poly == null or poly.size() < 2:
			continue
		var pts: = PackedVector2Array()
		for p in poly:
			pts.append(Vector2(p) * _map_size)

		draw_polyline(pts, Color(1.0, 0.88, 0.4, pulse * 0.28), w + 10.0, true)
		draw_polyline(pts, Color(1.0, 0.92, 0.55, pulse * 0.55), w, true)
		draw_polyline(pts, Color(1.0, 0.98, 0.78, pulse * 0.35), maxf(w * 0.35, 4.0), true)

		for p in pts:
			draw_circle(p, w * 0.45, Color(1.0, 0.94, 0.55, pulse * 0.4))
	for item in _norms:
		var nr: Rect2 = item
		var r: = Rect2(nr.position * _map_size, nr.size * _map_size)
		draw_rect(r.grow(3.0), Color(1.0, 0.88, 0.4, pulse * 0.25))
		draw_rect(r, Color(1.0, 0.92, 0.55, pulse * 0.45))
