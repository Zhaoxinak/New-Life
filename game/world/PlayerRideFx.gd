extends Node2D


var tier: int = 0
var facing: String = "s"
var _t: float = 0.0


func _ready() -> void :
	set_process(true)


func set_tier(t: int) -> void :
	tier = t
	queue_redraw()


func set_facing(dir: String) -> void :
	facing = dir
	queue_redraw()


func _process(delta: float) -> void :
	_t += delta
	queue_redraw()


func _draw() -> void :
	if tier < 1:
		return
	var flip: = -1.0 if facing in ["w", "nw", "sw"] else 1.0
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(flip, 1.0))
	match tier:
		1:
			_draw_ebike()
		2:
			_draw_rickshaw()
		3:
			_draw_moto()
		_:
			_draw_car()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ebike() -> void :
	var ink: = Color(0.18, 0.22, 0.28, 0.95)
	var accent: = Color(0.35, 0.55, 0.78, 0.95)
	var metal: = Color(0.55, 0.58, 0.62, 0.9)
	var bob: = sin(_t * 14.0) * 0.6
	draw_circle(Vector2(-12, 4 + bob), 7.5, Color(0.12, 0.12, 0.14, 0.95))
	draw_arc(Vector2(-12, 4 + bob), 7.5, 0.0, TAU, 18, metal, 1.5)
	draw_circle(Vector2(12, 4 - bob), 7.5, Color(0.12, 0.12, 0.14, 0.95))
	draw_arc(Vector2(12, 4 - bob), 7.5, 0.0, TAU, 18, metal, 1.5)
	draw_line(Vector2(-12, 4), Vector2(2, -4), ink, 2.2)
	draw_line(Vector2(2, -4), Vector2(12, 4), ink, 2.2)
	draw_rect(Rect2(-5, 0, 10, 4), accent)
	draw_line(Vector2(0, -4), Vector2(-5, -9), ink, 1.8)
	draw_line(Vector2(-8, -10), Vector2(-1, -10), Color(0.22, 0.2, 0.18, 0.95), 2.8)
	draw_line(Vector2(7, -2), Vector2(9, -11), ink, 1.8)
	draw_line(Vector2(5, -11), Vector2(13, -11), metal, 2.2)
	var lit: = 0.5 + sin(_t * 8.0) * 0.35
	draw_circle(Vector2(12, -5), 2.0, Color(1.0, 0.92, 0.55, lit))


func _draw_rickshaw() -> void :
	var body: = Color(0.42, 0.28, 0.16, 0.95)
	draw_circle(Vector2(-10, 5), 6.0, Color(0.12, 0.1, 0.08, 0.95))
	draw_circle(Vector2(10, 5), 6.0, Color(0.12, 0.1, 0.08, 0.95))
	draw_rect(Rect2(-6, -8, 16, 12), body)


func _draw_moto() -> void :
	var ink: = Color(0.14, 0.14, 0.16, 0.95)
	draw_circle(Vector2(-11, 5), 7.0, ink)
	draw_circle(Vector2(12, 5), 7.0, ink)
	draw_line(Vector2(-11, 5), Vector2(12, 5), Color(0.35, 0.35, 0.38, 0.95), 2.6)
	draw_rect(Rect2(-1, -5, 12, 7), Color(0.55, 0.18, 0.14, 0.95))


func _draw_car() -> void :
	var shell: = Color(0.12, 0.18, 0.28, 0.95)
	draw_rect(Rect2(-18, -4, 36, 12), shell)
	draw_rect(Rect2(-10, -12, 20, 9), Color(0.18, 0.28, 0.4, 0.95))
	draw_circle(Vector2(-10, 7), 4.5, Color(0.1, 0.1, 0.12, 0.95))
	draw_circle(Vector2(10, 7), 4.5, Color(0.1, 0.1, 0.12, 0.95))
