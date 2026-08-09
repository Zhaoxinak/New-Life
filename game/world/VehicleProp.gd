extends Area2D


signal mount_requested

var _t: float = 0.0
var _tip: Label
var _taken: bool = false


func _ready() -> void :
	add_to_group("vehicle_prop")
	monitoring = true
	collision_layer = 8
	collision_mask = 2
	if get_node_or_null("Collision") == null:
		var col: = CollisionShape2D.new()
		col.name = "Collision"
		var shape: = CircleShape2D.new()
		shape.radius = 40.0
		col.shape = shape
		add_child(col)
	_tip = Label.new()
	_tip.name = "Tip"
	_tip.position = Vector2(-48, -36)
	_tip.size = Vector2(96, 18)
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.add_theme_font_size_override("font_size", 11)
	_tip.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	_tip.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.16, 0.9))
	_tip.add_theme_constant_override("outline_size", 3)
	add_child(_tip)
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)
	set_process(true)
	refresh_visual()


func _exit_tree() -> void :
	if GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.disconnect(_on_state)


func _on_state() -> void :
	refresh_visual()


func _process(delta: float) -> void :
	_t += delta
	queue_redraw()


func _tier() -> int:
	return int(GameState.get_stat("vehicle_tier"))


func set_taken(taken: bool) -> void :
	_taken = taken
	refresh_visual()


func park_at(world_pos: Vector2) -> void :
	global_position = world_pos
	_taken = false
	refresh_visual()


func refresh_visual() -> void :
	var tier: = _tier()
	var show: = tier >= 1 and not _taken
	visible = show
	monitoring = show
	if _tip:
		_tip.text = L10n.t("vehicle.tier.%d" % tier, "车") if show else ""
	queue_redraw()


func try_activate() -> bool:
	if _tier() < 1 or _taken:
		return false
	mount_requested.emit()
	return true


func _draw() -> void :
	var tier: = _tier()
	if tier < 1 or _taken:
		return
	match tier:
		1:
			_draw_ebike()
		2:
			_draw_rickshaw()
		3:
			_draw_moto()
		_:
			_draw_car()


func _draw_ebike() -> void :
	var pulse: = 0.08 + sin(_t * 2.2) * 0.03
	draw_circle(Vector2.ZERO, 22.0, Color(0.15, 0.22, 0.32, pulse))
	var ink: = Color(0.18, 0.22, 0.28, 0.95)
	var accent: = Color(0.35, 0.55, 0.78, 0.95)
	var metal: = Color(0.55, 0.58, 0.62, 0.9)
	draw_circle(Vector2(-14, 6), 8.5, Color(0.12, 0.12, 0.14, 0.95))
	draw_arc(Vector2(-14, 6), 8.5, 0.0, TAU, 20, metal, 1.6)
	draw_circle(Vector2(14, 6), 8.5, Color(0.12, 0.12, 0.14, 0.95))
	draw_arc(Vector2(14, 6), 8.5, 0.0, TAU, 20, metal, 1.6)
	draw_line(Vector2(-14, 6), Vector2(2, -2), ink, 2.4)
	draw_line(Vector2(2, -2), Vector2(14, 6), ink, 2.4)
	draw_line(Vector2(-14, 6), Vector2(-2, 6), ink, 2.0)
	draw_line(Vector2(-2, 6), Vector2(2, -2), ink, 2.0)
	draw_rect(Rect2(-6, 2, 12, 5), accent)
	draw_line(Vector2(-1, -2), Vector2(-6, -8), ink, 2.0)
	draw_line(Vector2(-10, -9), Vector2(-2, -9), Color(0.22, 0.2, 0.18, 0.95), 3.2)
	draw_line(Vector2(8, 0), Vector2(10, -10), ink, 2.0)
	draw_line(Vector2(5, -10), Vector2(15, -10), metal, 2.4)
	var lit: = 0.45 + sin(_t * 5.0) * 0.35
	draw_circle(Vector2(14, -4), 2.2, Color(1.0, 0.92, 0.55, lit))


func _draw_rickshaw() -> void :
	var body: = Color(0.42, 0.28, 0.16, 0.95)
	draw_circle(Vector2(-12, 6), 7.0, Color(0.12, 0.1, 0.08, 0.95))
	draw_circle(Vector2(12, 6), 7.0, Color(0.12, 0.1, 0.08, 0.95))
	draw_rect(Rect2(-8, -10, 20, 14), body)
	draw_line(Vector2(-8, -10), Vector2(-16, -2), body, 2.0)
	draw_line(Vector2(4, -10), Vector2(4, -16), Color(0.3, 0.2, 0.12, 0.9), 2.0)


func _draw_moto() -> void :
	var ink: = Color(0.14, 0.14, 0.16, 0.95)
	draw_circle(Vector2(-12, 6), 8.0, ink)
	draw_circle(Vector2(14, 6), 8.0, ink)
	draw_line(Vector2(-12, 6), Vector2(14, 6), Color(0.35, 0.35, 0.38, 0.95), 3.0)
	draw_rect(Rect2(-2, -6, 14, 8), Color(0.55, 0.18, 0.14, 0.95))
	draw_line(Vector2(10, -2), Vector2(12, -12), ink, 2.2)
	draw_line(Vector2(8, -12), Vector2(16, -12), Color(0.5, 0.5, 0.55, 0.9), 2.4)


func _draw_car() -> void :
	var shell: = Color(0.12, 0.18, 0.28, 0.95)
	draw_rect(Rect2(-20, -6, 40, 14), shell)
	draw_rect(Rect2(-12, -14, 24, 10), Color(0.18, 0.28, 0.4, 0.95))
	draw_circle(Vector2(-12, 8), 5.0, Color(0.1, 0.1, 0.12, 0.95))
	draw_circle(Vector2(12, 8), 5.0, Color(0.1, 0.1, 0.12, 0.95))
	draw_rect(Rect2(16, -2, 4, 3), Color(1.0, 0.85, 0.4, 0.7))
