extends Area2D


signal transit_activated(stop_id: String)

var stop_id: String = ""
var _t: float = 0.0

@onready var label: Label = %Label


func _ready() -> void :
	add_to_group("transit_stop")
	monitoring = true
	set_process(true)
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)
	if label:
		label.visible = true
	_refresh()


func _exit_tree() -> void :
	if GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.disconnect(_on_state)


func _on_state() -> void :
	_refresh()


func _process(delta: float) -> void :
	_t += delta
	queue_redraw()


func setup(id: String) -> void :
	stop_id = id
	_refresh()


func _refresh() -> void :

	var show: = int(GameState.get_stat("vehicle_tier")) <= 0
	visible = show
	monitoring = show
	if label == null:
		return
	if stop_id == "":
		label.text = L10n.t("transit.stop_mark", "站")
	else:
		var loc: = L10n.t("locations.%s.name" % stop_id, stop_id)
		label.text = L10n.tf("transit.stop_named", {"name": loc}, "站·%s" % loc)
	queue_redraw()


func _draw() -> void :
	if int(GameState.get_stat("vehicle_tier")) >= 1:
		return
	var alpha: = 0.16 + sin(_t * 2.6) * 0.05
	draw_circle(Vector2.ZERO, 30.0, Color(0.28, 0.48, 0.82, alpha))
	draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 28, Color(0.65, 0.82, 1.0, 0.9), 3.2)
	draw_line(Vector2(0, 8), Vector2(0, 26), Color(0.85, 0.88, 0.95, 0.75), 3.0)


func try_activate() -> bool:
	if stop_id == "" or int(GameState.get_stat("vehicle_tier")) >= 1:
		return false
	transit_activated.emit(stop_id)
	return true
