extends CharacterBody2D


const FRAME_W: = 64
const FRAME_H: = 122
const SHEET_COLS: = 6
const DIR_NAMES: = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
const WALK_FPS: = 8.0
const ARRIVE_DIST: = 28.0

const ENTER_DIST: = 72.0
const WAYPOINT_ARRIVE: = 30.0
const STUCK_SKIP_SEC: = 1.2
const STUCK_TELEPORT_SEC: = 3.8
const NEAR_GOAL_DIST: = 96.0

var npc_id: String = ""
var street_dialogue_id: String = ""
var _tint: Color = Color.WHITE
var _target: Vector2 = Vector2.ZERO
var _final_target: Vector2 = Vector2.ZERO
var _waypoints: PackedVector2Array = PackedVector2Array()
var _wp_i: int = 0
var _use_nav: bool = true
var _has_target: bool = false
var _want_indoors: bool = false
var _indoors: bool = false
var _speed: float = 128.0
var _wait: float = 0.0
var _stuck: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO
var _facing_dir: String = "s"
var _anim_key: String = ""
var _home_door: Vector2 = Vector2.ZERO
var _entry_door: Vector2 = Vector2.ZERO
var _inside_building_id: String = ""
var _agent: NavigationAgent2D

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var name_label: Label = %NameLabel
@onready var accent: ColorRect = %Accent


func setup(id: String, tint: Color, dialogue_id: String, home_door: Vector2 = Vector2.ZERO) -> void :
	npc_id = id
	_tint = tint
	street_dialogue_id = dialogue_id
	if home_door != Vector2.ZERO:
		_home_door = home_door
		_entry_door = home_door
	modulate = Color.WHITE
	if sprite:
		sprite.modulate = tint
	if accent:
		accent.color = tint.lightened(0.35)
	_refresh_nameplate()


func _ready() -> void :
	add_to_group("outdoor_npc")
	collision_layer = 0
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING
	_setup_agent()
	_setup_sprite()
	if sprite:
		sprite.modulate = _tint
	if accent:
		accent.color = _tint.lightened(0.35)
	_refresh_nameplate()
	_play("idle")
	_last_pos = global_position


func _setup_agent() -> void :
	_agent = NavigationAgent2D.new()
	_agent.name = "NavAgent"
	_agent.path_desired_distance = 22.0
	_agent.target_desired_distance = 26.0
	_agent.radius = 12.0
	_agent.neighbor_distance = 40.0
	_agent.max_neighbors = 5
	_agent.time_horizon_agents = 0.55
	_agent.max_speed = _speed
	_agent.avoidance_enabled = true
	_agent.avoidance_layers = 1
	_agent.avoidance_mask = 1
	add_child(_agent)
	if not _agent.velocity_computed.is_connected(_on_safe_velocity):
		_agent.velocity_computed.connect(_on_safe_velocity)


func _refresh_nameplate() -> void :
	if name_label == null:
		return
	name_label.text = L10n.t("npcs.%s.name" % npc_id, npc_id)
	name_label.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	name_label.add_theme_constant_override("outline_size", 4)


func set_schedule_target(world_pos: Vector2, indoors_goal: bool, snap: bool = false, building_id: String = "") -> void :
	_final_target = world_pos
	_want_indoors = indoors_goal
	_stuck = 0.0
	_wait = 0.0
	_waypoints = PackedVector2Array()
	_wp_i = 0
	_inside_building_id = building_id if indoors_goal else ""

	if _indoors:
		var same_door: = _entry_door != Vector2.ZERO and _entry_door.distance_to(world_pos) < 48.0
		if indoors_goal and same_door:
			global_position = world_pos
			_entry_door = world_pos
			_has_target = false
			return
		_set_indoors(false)
		var exit_at: = _entry_door if _entry_door != Vector2.ZERO else (_home_door if _home_door != Vector2.ZERO else global_position)
		var h: = absi(npc_id.hash())
		var porch: = exit_at + Vector2(float((h % 5) - 2) * 12.0, 22.0 + float(h % 3) * 6.0)
		var outdoor: = _harbor()
		if outdoor != null and outdoor.has_method("nearest_walk_point"):
			global_position = outdoor.nearest_walk_point(porch)
		else:
			global_position = porch

	if snap:
		global_position = world_pos + Vector2(randf_range(-10, 10), randf_range(6, 14))
		_has_target = false
		_last_pos = global_position
		_entry_door = world_pos
		if indoors_goal:
			_set_indoors(true)
		else:
			_set_indoors(false)
			_play("idle")
		return

	_begin_route(world_pos)


func is_talkable() -> bool:
	return visible and not _indoors and npc_id != "" and street_dialogue_id != ""


func is_indoors() -> bool:
	return _indoors


func inside_building_id() -> String:
	return _inside_building_id if _indoors else ""


func get_street_dialogue_id() -> String:
	return street_dialogue_id


func _harbor() -> Node:
	if is_inside_tree():
		var g: = get_tree().get_first_node_in_group("harbor_outdoor")
		if g != null:
			return g
	var p: Node = get_parent()
	while p != null:
		if p.is_in_group("harbor_outdoor") or p.has_method("find_walk_path"):
			return p
		p = p.get_parent()
	return null


func _snap_goal(world_pos: Vector2) -> Vector2:
	var outdoor: = _harbor()
	if outdoor != null and outdoor.has_method("nearest_walk_point"):
		return outdoor.nearest_walk_point(world_pos)
	return world_pos


func _begin_route(world_pos: Vector2) -> void :
	_final_target = _snap_goal(world_pos)
	_waypoints = PackedVector2Array()
	_wp_i = 0
	_stuck = 0.0
	_last_pos = global_position
	_has_target = true
	_use_nav = true
	if _agent != null:
		_agent.target_position = _final_target
	if global_position.distance_to(_final_target) < ARRIVE_DIST:
		_arrive()
		return

	call_deferred("_validate_nav_or_graph")


func _validate_nav_or_graph() -> void :
	if not _has_target or _indoors:
		return
	await get_tree().physics_frame
	if not _has_target or _agent == null:
		return
	var path: = _agent.get_current_navigation_path()
	if path.size() >= 2:
		_use_nav = true
		return

	_use_nav = false
	var outdoor: = _harbor()
	if outdoor != null and outdoor.has_method("find_walk_path"):
		_waypoints = outdoor.find_walk_path(global_position, _final_target)
	if _waypoints.is_empty():
		_waypoints.append(_final_target)
	_wp_i = 0
	_target = _waypoints[0]


func _set_indoors(v: bool) -> void :
	_indoors = v
	visible = not v
	velocity = Vector2.ZERO
	if v:
		_has_target = false
		_waypoints = PackedVector2Array()
		if _agent:
			_agent.set_velocity(Vector2.ZERO)
		if name_label:
			name_label.visible = false
		if accent:
			accent.visible = false
	else:
		if name_label:
			name_label.visible = true
		if accent:
			accent.visible = true


func _setup_sprite() -> void :
	var tex: Texture2D = preload("res://art/player/player_walk_8dir.png")
	var frames: = SpriteFrames.new()
	for row in DIR_NAMES.size():
		var d: String = DIR_NAMES[row]
		var idle_name: = "idle_%s" % d
		var walk_name: = "walk_%s" % d
		frames.add_animation(idle_name)
		frames.set_animation_speed(idle_name, 1.0)
		frames.set_animation_loop(idle_name, true)
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, WALK_FPS)
		frames.set_animation_loop(walk_name, true)
		for col in SHEET_COLS:
			var atlas: = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
			atlas.filter_clip = true
			if col == 0:
				frames.add_frame(idle_name, atlas)
			frames.add_frame(walk_name, atlas)
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.64, 0.64)
	sprite.offset = Vector2(0, -52)


func _physics_process(delta: float) -> void :
	if _indoors or not visible:
		velocity = Vector2.ZERO
		return
	if GameFlow.dialogue_open or GameFlow.event_open or GameFlow.ending_open:
		velocity = Vector2.ZERO
		_play("idle")
		move_and_slide()
		return
	if _wait > 0.0:
		_wait -= delta
		velocity = Vector2.ZERO
		_play("idle")
		move_and_slide()
		if _wait <= 0.0 and _want_indoors and not _has_target and not _indoors:
			_set_indoors(true)
		return
	if not _has_target:
		velocity = Vector2.ZERO
		_play("idle")
		move_and_slide()
		return

	var dist_goal: = global_position.distance_to(_final_target)
	var arrive_r: = ENTER_DIST if _want_indoors else ARRIVE_DIST
	if dist_goal < arrive_r:
		_arrive()
		return

	if global_position.distance_to(_last_pos) < 0.7:
		_stuck += delta
	else:
		_stuck = 0.0
	_last_pos = global_position


	var near_goal: = dist_goal < NEAR_GOAL_DIST
	if _agent != null:
		_agent.avoidance_enabled = not near_goal

	if _want_indoors and near_goal and _stuck >= 0.7:
		_stuck = 0.0
		_arrive()
		return
	if _stuck >= STUCK_TELEPORT_SEC:
		_stuck = 0.0
		if _want_indoors:
			_arrive()
		else:
			global_position = _final_target
			_arrive()
		return
	if _stuck >= STUCK_SKIP_SEC:
		_stuck = 0.0
		if _want_indoors and near_goal:
			_arrive()
			return
		_begin_route(_final_target)
		return

	var wish: = Vector2.ZERO
	if _use_nav and _agent != null:

		if _agent.is_navigation_finished():
			_arrive()
			return
		var next: = _agent.get_next_path_position()
		wish = global_position.direction_to(next)
	else:
		var to: = _target - global_position
		var arrive: = WAYPOINT_ARRIVE if _wp_i < _waypoints.size() - 1 else arrive_r
		if to.length() < arrive:
			_advance_waypoint()
			return
		wish = to.normalized()
		if _stuck > 0.55:
			wish = wish.rotated(PI * 0.5 if int(_stuck * 4.0) % 2 == 0 else - PI * 0.5)

	if wish == Vector2.ZERO:
		velocity = Vector2.ZERO
		_play("idle")
		move_and_slide()
		return

	_facing_dir = _dir8(wish)
	_play("walk")
	var desired: = wish * _speed
	if _use_nav and _agent != null and _agent.avoidance_enabled:
		_agent.set_velocity(desired)

	else:
		velocity = desired
		move_and_slide()


func _on_safe_velocity(safe: Vector2) -> void :
	if not _has_target or _indoors or not visible:
		return
	if GameFlow.dialogue_open or GameFlow.event_open or GameFlow.ending_open:
		return
	velocity = safe
	if safe.length_squared() > 4.0:
		_facing_dir = _dir8(safe.normalized())
		_play("walk")
	move_and_slide()


func _advance_waypoint() -> void :
	_wp_i += 1
	_stuck = 0.0
	if _wp_i >= _waypoints.size():
		_arrive()
		return
	_target = _waypoints[_wp_i]


func _arrive() -> void :
	velocity = Vector2.ZERO
	_has_target = false
	_stuck = 0.0
	_waypoints = PackedVector2Array()
	_play("idle")
	_final_target = _snap_goal(_final_target)
	_entry_door = _final_target
	global_position = _final_target
	if _agent:
		_agent.set_velocity(Vector2.ZERO)
	if _want_indoors:
		_wait = 0.28
	else:
		_wait = randf_range(0.8, 2.4)


func _dir8(v: Vector2) -> String:
	var ix: = 0
	if v.x > 0.3:
		ix = 1
	elif v.x < -0.3:
		ix = -1
	var iy: = 0
	if v.y > 0.3:
		iy = 1
	elif v.y < -0.3:
		iy = -1
	match Vector2i(ix, iy):
		Vector2i(0, 1):
			return "s"
		Vector2i(1, 1):
			return "se"
		Vector2i(1, 0):
			return "e"
		Vector2i(1, -1):
			return "ne"
		Vector2i(0, -1):
			return "n"
		Vector2i(-1, -1):
			return "nw"
		Vector2i(-1, 0):
			return "w"
		Vector2i(-1, 1):
			return "sw"
		_:
			return _facing_dir


func _play(state: String) -> void :
	var key: = "%s_%s" % [state, _facing_dir]
	if key == _anim_key or sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(key):
		return
	_anim_key = key
	sprite.play(key)
