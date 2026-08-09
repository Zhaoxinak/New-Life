extends Node2D


const ART: = {
	"dock_foreman": "res://art/world/cottages/dock_foreman.png", 
	"stall_aunt": "res://art/world/cottages/stall_aunt.png", 
	"tea_waiter": "res://art/world/cottages/tea_waiter.png", 
	"garage_hand": "res://art/world/cottages/garage_hand.png", 
	"zhou_shaoting": "res://art/world/cottages/zhou_shaoting.png", 
	"chen_manager": "res://art/world/cottages/chen_manager.png", 
}


const PROP_SCALE: = 1.85

var npc_id: String = ""
var _t: float = 0.0
var _sprite: Sprite2D
var _plate: Panel
var _name_label: Label
var _occupied: bool = false


func setup(id: String, door_world: Vector2) -> void :
	npc_id = id
	position = door_world
	_build()
	_refresh_label()
	set_process(true)


func _process(delta: float) -> void :
	_t += delta
	_refresh_occupancy()
	queue_redraw()


func _draw() -> void :
	if not _occupied:
		return
	var pulse: = 0.5 + 0.5 * sin(_t * 2.2)
	draw_circle(Vector2(0, 6), 15.0 + pulse * 3.0, Color(1.0, 0.82, 0.4, 0.12 * pulse))
	draw_arc(Vector2(0, 4), 12.0, 0.0, TAU, 20, Color(1.0, 0.88, 0.45, 0.45 * pulse), 2.0, true)


func _build() -> void :
	for c in get_children():
		c.queue_free()
	_sprite = null
	_plate = null
	_name_label = null

	var path: = str(ART.get(npc_id, ""))
	if path != "":
		var tex: Texture2D = load(path)
		if tex != null:
			_sprite = Sprite2D.new()
			_sprite.texture = tex
			_sprite.centered = true

			var th: = float(tex.get_height()) * PROP_SCALE
			_sprite.position = Vector2(0, - th * 0.5 + 6.0)
			_sprite.scale = Vector2(PROP_SCALE, PROP_SCALE)
			_sprite.z_index = 0
			add_child(_sprite)


	_plate = Panel.new()
	_plate.z_index = 12
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.custom_minimum_size = Vector2(108, 26)
	_plate.size = Vector2(108, 26)
	_plate.position = Vector2(-54, 10)
	var st: = StyleBoxFlat.new()
	st.bg_color = Color(0.16, 0.2, 0.28, 0.72)
	st.border_color = Color(0.85, 0.82, 0.72, 0.55)
	st.set_border_width_all(1)
	st.set_corner_radius_all(8)
	st.content_margin_left = 6
	st.content_margin_right = 6
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	_plate.add_theme_stylebox_override("panel", st)
	add_child(_plate)

	_name_label = Label.new()
	_name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, 1.0))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(_name_label)


func refresh_label() -> void :
	_refresh_label()


func _refresh_label() -> void :
	if _name_label == null:
		return
	var home_name: = L10n.t("npc_homes.%s" % npc_id, npc_id)
	_name_label.text = home_name
	_name_label.tooltip_text = "%s — %s" % [
		home_name, 
		L10n.t("npcs.%s.name" % npc_id, npc_id), 
	]


func _refresh_occupancy() -> void :
	_occupied = false
	for n in get_tree().get_nodes_in_group("outdoor_npc"):
		if not is_instance_valid(n):
			continue
		if str(n.get("npc_id")) != npc_id:
			continue
		if n.has_method("is_indoors") and n.is_indoors():
			_occupied = true
			break
