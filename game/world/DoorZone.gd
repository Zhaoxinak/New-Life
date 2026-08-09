extends Area2D


signal door_activated(location_id: String, spawn_outdoor: Vector2)

@export var location_id: String = "dock"
var spawn_outdoor: Vector2 = Vector2.ZERO
var locked: bool = false
var _facing: String = "south"
var _t: float = 0.0

@onready var label: Label = %Label
@onready var lock_icon: Label = %Lock
@onready var arrow: Label = %Arrow
@onready var plate: ColorRect = %Plate


func _ready() -> void :
	add_to_group("door_zone")
	monitoring = true
	set_process(true)
	if lock_icon:
		lock_icon.visible = false
	if arrow:
		arrow.visible = false

	if label:
		label.visible = false
	if plate:
		plate.visible = false
	_layout_chrome()


func _process(delta: float) -> void :
	_t += delta
	queue_redraw()


func _draw() -> void :
	if locked:
		return
	var alpha: = 0.12 + sin(_t * 3.0) * 0.04
	var base_radius: = 38.0
	var glow_color: = Color(1.0, 0.82, 0.25, alpha)


	draw_circle(Vector2.ZERO, base_radius + 8.0, glow_color)

	var ring_points: = []
	for i in range(36):
		var angle: = float(i) / 35.0 * TAU
		ring_points.append(Vector2(cos(angle), sin(angle)) * base_radius)
	draw_polyline(ring_points, Color(1.0, 0.82, 0.25, 0.9), 6.0)

	var accent_points: = []
	for i in range(18):
		var angle: = float(i) / 17.0 * TAU
		accent_points.append(Vector2(cos(angle), sin(angle)) * (base_radius - 10.0))
	draw_polyline(accent_points, Color(1.0, 0.82, 0.25, 0.55), 2.5)


func setup(id: String, outdoor_spawn: Vector2, facing: String = "south") -> void :
	location_id = id
	spawn_outdoor = outdoor_spawn
	_facing = facing if facing != "" else "south"
	_layout_chrome()
	refresh()


func _arrow_base_y() -> float:
	match _facing:
		"west":
			return -20.0
		"north":
			return 28.0
		_:
			return -52.0


func _layout_chrome() -> void :

	if plate == null or label == null or arrow == null:
		return
	match _facing:
		"west":

			plate.offset_left = -150.0
			plate.offset_top = -16.0
			plate.offset_right = -10.0
			plate.offset_bottom = 16.0
			label.offset_left = -150.0
			label.offset_top = -14.0
			label.offset_right = -10.0
			label.offset_bottom = 14.0
			arrow.offset_left = -120.0
			arrow.offset_top = -42.0
			arrow.offset_right = -40.0
			arrow.offset_bottom = -20.0
		"north":

			plate.offset_left = -78.0
			plate.offset_top = -70.0
			plate.offset_right = 78.0
			plate.offset_bottom = -38.0
			label.offset_left = -78.0
			label.offset_top = -68.0
			label.offset_right = 78.0
			label.offset_bottom = -40.0
			arrow.offset_left = -50.0
			arrow.offset_top = -92.0
			arrow.offset_right = 50.0
			arrow.offset_bottom = -72.0
		_:

			plate.offset_left = -78.0
			plate.offset_top = -48.0
			plate.offset_right = 78.0
			plate.offset_bottom = -16.0
			label.offset_left = -78.0
			label.offset_top = -46.0
			label.offset_right = 78.0
			label.offset_bottom = -18.0
			arrow.offset_left = -50.0
			arrow.offset_top = -72.0
			arrow.offset_right = 50.0
			arrow.offset_bottom = -52.0


func refresh() -> void :
	if location_id == "__exit__":
		locked = false
		if label:
			label.text = L10n.t("ui.world.exit", "出门")
		if lock_icon:
			lock_icon.visible = false
		if arrow:
			arrow.text = "▲"
			arrow.visible = true
		if plate:
			plate.color = Color(0.95, 0.9, 0.78, 0.95)
		return
	locked = not GameState.is_location_unlocked(location_id)
	var name: = L10n.t("locations.%s.name" % location_id, location_id)
	if label:
		label.text = ("🔒 " + name) if locked else name
	if lock_icon:
		lock_icon.visible = false
	if arrow:
		arrow.visible = false
	if plate:
		plate.color = Color(0.78, 0.74, 0.66, 0.94) if locked else Color(0.95, 0.9, 0.78, 0.96)
	monitoring = true


func try_activate() -> bool:
	refresh()
	if locked:
		return false
	door_activated.emit(location_id, spawn_outdoor)
	return true
