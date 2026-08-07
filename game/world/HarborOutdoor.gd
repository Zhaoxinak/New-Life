extends Node2D
## Outdoor harbor map: clear paths, enterable doors (no building outline boxes).

signal door_requested(location_id: String, return_spawn: Vector2)

const DoorZoneScene := preload("res://world/DoorZone.tscn")

## Tuned to harbor_outdoor.png (1536×1024) — one name plate at each door.
const LAYOUT := {
	"company": {
		"body": Rect2(0.06, 0.04, 0.26, 0.26),
		"door": Vector2(0.20, 0.335),
		"spawn": Vector2(0.20, 0.385),
		"facing": "south",
	},
	"home": {
		"body": Rect2(0.38, 0.03, 0.24, 0.26),
		"door": Vector2(0.49, 0.325),
		"spawn": Vector2(0.49, 0.380),
		"facing": "south",
	},
	"rival": {
		"body": Rect2(0.68, 0.03, 0.26, 0.26),
		"door": Vector2(0.78, 0.335),
		"spawn": Vector2(0.78, 0.385),
		"facing": "south",
	},
	"exchange": {
		"body": Rect2(0.58, 0.42, 0.34, 0.32),
		"door": Vector2(0.74, 0.60),
		"spawn": Vector2(0.74, 0.64),
		"facing": "west",
	},
	"dock": {
		"body": Rect2(0.38, 0.58, 0.26, 0.28),
		"door": Vector2(0.49, 0.615),
		"spawn": Vector2(0.49, 0.55),
		"facing": "north",
	},
}

var map_size: Vector2 = Vector2(1536, 1024)
var _doors: Dictionary = {}
var _t: float = 0.0

@onready var bg: Sprite2D = %Background
@onready var buildings: Node2D = %Buildings
@onready var doors: Node2D = %Doors
@onready var signs: Node2D = %Signs
@onready var path_fx: Node2D = %PathFx


func _ready() -> void:
	_setup_background()
	_rebuild()
	set_process(true)
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func _process(delta: float) -> void:
	_t += delta
	path_fx.queue_redraw()


func _on_state() -> void:
	_refresh_doors()


func _on_locale(_l: String) -> void:
	_refresh_doors()


func _setup_background() -> void:
	var tex: Texture2D = load("res://art/world/harbor_outdoor.png")
	if tex == null:
		return
	bg.texture = tex
	bg.centered = false
	bg.position = Vector2.ZERO
	map_size = tex.get_size()


func _add_world_bounds() -> void:
	var thickness := 40.0
	_add_wall(Rect2(-thickness, -thickness, map_size.x + thickness * 2, thickness))
	_add_wall(Rect2(-thickness, map_size.y, map_size.x + thickness * 2, thickness))
	_add_wall(Rect2(-thickness, 0, thickness, map_size.y))
	_add_wall(Rect2(map_size.x, 0, thickness, map_size.y))


func _add_wall(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.position + r.size * 0.5
	body.add_child(shape)
	buildings.add_child(body)


func _rebuild() -> void:
	for c in buildings.get_children():
		c.queue_free()
	for c in doors.get_children():
		c.queue_free()
	if signs:
		for c in signs.get_children():
			c.queue_free()
	_doors.clear()
	_add_world_bounds()
	_add_water_collision()
	_add_tree_colliders()
	_build_path_highlight()
	for id in LAYOUT.keys():
		var conf: Dictionary = LAYOUT[id]
		var body_r: Rect2 = conf["body"]
		var world_r := Rect2(body_r.position * map_size, body_r.size * map_size)
		_add_building_body(world_r, id)
		_add_building_sign(id, world_r)
		var door: Area2D = DoorZoneScene.instantiate()
		doors.add_child(door)
		door.position = conf["door"] * map_size
		door.setup(id, conf["spawn"] * map_size, str(conf.get("facing", "south")))
		door.door_activated.connect(_on_door)
		_doors[id] = door
	_refresh_doors()


func _add_water_collision() -> void:
	# Water from ~y0.77; keep pier + north dock approach walkable.
	_add_wall(Rect2(Vector2(0.0, 0.76) * map_size, Vector2(0.36, 0.24) * map_size))
	_add_wall(Rect2(Vector2(0.64, 0.76) * map_size, Vector2(0.36, 0.24) * map_size))
	_add_wall(Rect2(Vector2(0.36, 0.93) * map_size, Vector2(0.28, 0.07) * map_size))
	_add_wall(Rect2(Vector2(0.0, 0.74) * map_size, Vector2(0.36, 0.03) * map_size))
	_add_wall(Rect2(Vector2(0.64, 0.74) * map_size, Vector2(0.36, 0.03) * map_size))
	_add_wall(Rect2(Vector2(0.0, 0.96) * map_size, Vector2(1.0, 0.06) * map_size))


func _add_tree_colliders() -> void:
	for r in [
		Rect2(0.00, 0.00, 0.07, 0.20),
		Rect2(0.93, 0.00, 0.07, 0.20),
		Rect2(0.00, 0.42, 0.07, 0.20),
		Rect2(0.92, 0.38, 0.08, 0.20),
	]:
		_add_wall(Rect2(r.position * map_size, r.size * map_size))


func _build_path_highlight() -> void:
	if not path_fx.has_method("set_paths"):
		return
	# Centerline polylines follow painted boulevards + door aprons.
	var polys: Array = [
		# Horizontal boulevard
		PackedVector2Array([
			Vector2(0.10, 0.34), Vector2(0.30, 0.34), Vector2(0.49, 0.34),
			Vector2(0.68, 0.34), Vector2(0.88, 0.34),
		]),
		# Vertical to dock
		PackedVector2Array([
			Vector2(0.49, 0.34), Vector2(0.49, 0.45), Vector2(0.49, 0.55), Vector2(0.49, 0.615),
		]),
		# Spur to exchange
		PackedVector2Array([
			Vector2(0.49, 0.56), Vector2(0.56, 0.56),
		]),
		# Door aprons
		PackedVector2Array([Vector2(0.20, 0.34), Vector2(0.20, 0.325)]),
		PackedVector2Array([Vector2(0.49, 0.34), Vector2(0.49, 0.315)]),
		PackedVector2Array([Vector2(0.78, 0.34), Vector2(0.78, 0.325)]),
	]
	# Tiny mats only at junctions (keep glow soft)
	var mats: Array = [
		Rect2(0.46, 0.32, 0.06, 0.05), # T junction
		Rect2(0.46, 0.58, 0.06, 0.05), # dock approach
	]
	path_fx.call("set_paths", map_size, mats, polys)


func get_spawn_for(location_id: String) -> Vector2:
	if LAYOUT.has(location_id):
		return LAYOUT[location_id]["spawn"] * map_size
	return map_size * Vector2(0.49, 0.38)


func get_default_spawn() -> Vector2:
	return map_size * Vector2(0.49, 0.38)


func _add_building_body(r: Rect2, location_id: String = "") -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var solid: Rect2
	match location_id:
		"dock":
			solid = Rect2(r.position + Vector2(r.size.x * 0.12, r.size.y * 0.30), Vector2(r.size.x * 0.76, r.size.y * 0.60))
		"exchange":
			solid = Rect2(r.position + Vector2(r.size.x * 0.24, r.size.y * 0.10), Vector2(r.size.x * 0.70, r.size.y * 0.70))
		_:
			solid = Rect2(r.position + Vector2(r.size.x * 0.10, 0.02 * map_size.y), Vector2(r.size.x * 0.80, r.size.y * 0.55))
	rect.size = solid.size
	shape.shape = rect
	shape.position = solid.position + solid.size * 0.5
	body.add_child(shape)
	buildings.add_child(body)


func _add_building_sign(location_id: String, body_r: Rect2) -> void:
	if signs == null:
		return
	var sign := Node2D.new()
	sign.position = body_r.position + Vector2(body_r.size.x * 0.5, body_r.size.y * 0.06)
	sign.z_index = 10

	var board := Panel.new()
	board.position = Vector2(-100, -24)
	board.custom_minimum_size = Vector2(200, 38)
	board.size = Vector2(200, 38)
	var sign_style := StyleBoxFlat.new()
	sign_style.bg_color = UiStyle.PARCHMENT
	sign_style.border_color = UiStyle.WOOD
	sign_style.set_border_width_all(2)
	sign_style.set_corner_radius_all(8)
	sign_style.content_margin_left = 10
	sign_style.content_margin_right = 10
	sign_style.content_margin_top = 8
	sign_style.content_margin_bottom = 8
	sign_style.shadow_color = Color(0, 0, 0, 0.18)
	sign_style.shadow_size = 4
	board.add_theme_stylebox_override("panel", sign_style)
	sign.add_child(board)

	var title := Label.new()
	title.text = L10n.t("locations.%s.name" % location_id, location_id)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UiStyle.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 0)
	title.size = board.custom_minimum_size
	board.add_child(title)

	signs.add_child(sign)


func _refresh_doors() -> void:
	for id in _doors.keys():
		_doors[id].refresh()


func _on_door(location_id: String, return_spawn: Vector2) -> void:
	door_requested.emit(location_id, return_spawn)
