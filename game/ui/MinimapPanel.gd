extends CanvasLayer


@onready var root: Control = %Root
@onready var title_label: Label = %Title
@onready var hint_label: Label = %Hint
@onready var map_frame: Control = %MapFrame
@onready var map_tex: TextureRect = %MapTex
@onready var markers: Control = %Markers
@onready var player_dot: ColorRect = %PlayerDot
@onready var close_btn: Button = %CloseButton

var _open: bool = false
var _map_size: Vector2 = Vector2(1536, 1024)


func _ready() -> void :
	add_to_group("minimap_panel")
	visible = false
	root.visible = false
	close_btn.pressed.connect(close)
	UiStyle.apply_cozy_button(close_btn)
	set_process(false)
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("toggle_minimap") or (
		event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M
	):
		if GameFlow.is_blocked() and not _open:
			return
		if _open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return
	if _open and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void :
	_open = true
	visible = true
	root.visible = true
	set_process(true)
	SfxPlayer.play_click()
	_rebuild()
	_refresh_player()


func close() -> void :
	_open = false
	visible = false
	root.visible = false
	set_process(false)


func _process(_delta: float) -> void :
	if _open:
		_refresh_player()


func _rebuild() -> void :
	title_label.text = L10n.t("minimap.title", "港区地图")
	hint_label.text = L10n.t("minimap.hint", "M 关闭 · 蓝点为你 · 黄点建筑 · 青点主线角色")
	close_btn.text = L10n.t("ui.common.close", "关闭")
	var tex: Texture2D = load("res://art/world/harbor_outdoor.png")
	map_tex.texture = tex
	map_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for c in markers.get_children():
		if c != player_dot:
			c.queue_free()
	var host: = get_tree().get_first_node_in_group("world_host")
	if host == null or host.outdoor == null:
		return
	var outdoor: Node = host.outdoor
	_map_size = outdoor.map_size
	if outdoor.has_method("get_minimap_markers"):
		for item in outdoor.get_minimap_markers():
			var kind: = str(item.get("kind", "building"))
			_add_map_marker(str(item.get("id", "")), item.get("pos", Vector2.ZERO) as Vector2, kind)
	elif outdoor.has_method("list_stop_ids"):
		for id in outdoor.list_stop_ids():
			var p: Vector2 = outdoor.get_stop_spawn(str(id))
			_add_map_marker(str(id), p, "building")
	call_deferred("_place_markers")


func _add_map_marker(id: String, world_pos: Vector2, kind: String = "building") -> void :
	var dot: = ColorRect.new()
	dot.name = "m_%s" % id
	dot.size = Vector2(8, 8) if kind == "building" else Vector2(7, 7)
	dot.color = UiStyle.BRASS if kind == "building" else Color("5a9aaa")
	dot.set_meta("world_pos", world_pos)
	var label_text: = L10n.t("locations.%s.name" % id, id) if kind == "building" else L10n.t("npcs.%s.name" % id, id)
	dot.tooltip_text = label_text
	markers.add_child(dot)
	var lab: = Label.new()
	lab.text = label_text
	lab.add_theme_font_size_override("font_size", 10)
	lab.add_theme_color_override("font_color", UiStyle.TEXT)
	lab.position = Vector2(10, -2)
	dot.add_child(lab)


func _place_markers() -> void :
	var frame_size: = map_frame.size
	if frame_size.x < 8.0 or frame_size.y < 8.0:
		return
	var tex_size: = _map_size
	if map_tex.texture:

		pass
	for c in markers.get_children():
		if c == player_dot or not c.has_meta("world_pos"):
			continue
		var wp: Vector2 = c.get_meta("world_pos")
		c.position = _world_to_map(wp, frame_size) - c.size * 0.5


func _world_to_map(world_pos: Vector2, frame_size: Vector2) -> Vector2:
	if _map_size.x <= 0.0 or _map_size.y <= 0.0:
		return frame_size * 0.5

	var scale: = minf(frame_size.x / _map_size.x, frame_size.y / _map_size.y)
	var drawn: = _map_size * scale
	var origin: = (frame_size - drawn) * 0.5
	return origin + world_pos * scale


func _refresh_player() -> void :
	var host: = get_tree().get_first_node_in_group("world_host")
	if host == null or host.player == null:
		player_dot.visible = false
		return
	if str(host.get("mode")) != "outdoor":
		player_dot.visible = false
		hint_label.text = L10n.t("minimap.indoor", "室内中 · 出门后显示位置（M 关闭）")
		return
	player_dot.visible = true
	hint_label.text = L10n.t("minimap.hint", "M 关闭 · 蓝点为你 · 黄点建筑 · 青点主线角色")
	if host.outdoor:
		_map_size = host.outdoor.map_size
	var frame_size: = map_frame.size
	player_dot.position = _world_to_map(host.player.global_position, frame_size) - player_dot.size * 0.5
