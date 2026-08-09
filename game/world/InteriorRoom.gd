extends Node2D


signal exit_requested
signal hotspot_requested(hotspot_id: String)

var location_id: String = "dock"
var room_size: Vector2 = Vector2(1536, 1024)

@onready var bg: Sprite2D = %Background
@onready var props: Node2D = %Props
@onready var exit_door: Area2D = %ExitDoor


func setup(id: String) -> void :
	location_id = id
	GameState.set_location(id)
	_load_bg()
	_add_menu_veil()

	if exit_door:
		exit_door.visible = false
		exit_door.set_deferred("monitoring", false)
		exit_door.set_deferred("monitorable", false)
	if props:
		for c in props.get_children():
			if c is Area2D:
				c.visible = false


func _load_bg() -> void :
	var tex: Texture2D = UiStyle.location_texture(location_id)
	if tex == null:
		tex = load("res://art/world/harbor_outdoor.png")
	bg.texture = tex
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.modulate = Color(1, 1, 1, 1)
	if tex:
		room_size = tex.get_size()

		var target_w: = 1280.0
		if room_size.x != target_w:
			var s: = target_w / room_size.x
			bg.scale = Vector2(s, s)
			room_size *= s


func _add_menu_veil() -> void :

	var old: = props.get_node_or_null("MenuVeil")
	if old:
		old.queue_free()
	var poly: = Polygon2D.new()
	poly.name = "MenuVeil"
	poly.color = Color(0.06, 0.04, 0.02, 0.32)
	poly.polygon = PackedVector2Array([
		Vector2.ZERO, 
		Vector2(room_size.x, 0), 
		room_size, 
		Vector2(0, room_size.y), 
	])
	poly.z_index = 5
	props.add_child(poly)


func get_entry_spawn() -> Vector2:
	return Vector2(room_size.x * 0.5, room_size.y * 0.82)


func refresh_hotspots() -> void :
	pass
