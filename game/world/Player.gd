extends CharacterBody2D



signal interact_pressed(mount_ok: bool)
signal mount_changed(mounted: bool)

const MAX_SPEED: = 158.0
const ACCEL: = 900.0
const FRICTION: = 1100.0
const WALK_ANIM_FPS: = 10.0

const EBIKE_SPEED_MULT: = 2.35
const RICKSHAW_SPEED_MULT: = 2.0
const MOTO_SPEED_MULT: = 2.75
const CAR_SPEED_MULT: = 3.05

const FRAME_W: = 64
const FRAME_H: = 122
const SHEET_COLS: = 6
const DIR_NAMES: = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
const RideFxScript: = preload("res://world/PlayerRideFx.gd")

var input_enabled: bool = true
var mounted: bool = false
var _facing: Vector2 = Vector2.DOWN
var _facing_dir: String = "s"
var _anim_key: String = ""
var _ride_fx: Node2D
var _ride_t: float = 0.0

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var camera: Camera2D = %Camera


func _ready() -> void :
	add_to_group("player")
	camera.make_current()
	_setup_sprite_frames()
	_ensure_ride_fx()
	if not GameFlow.block_changed.is_connected(_on_block):
		GameFlow.block_changed.connect(_on_block)
	_on_block(GameFlow.is_blocked())
	_play_anim("idle", true)


func _ensure_ride_fx() -> void :
	if _ride_fx != null:
		return
	_ride_fx = Node2D.new()
	_ride_fx.name = "RideFx"
	_ride_fx.z_index = -1
	_ride_fx.visible = false
	_ride_fx.set_script(RideFxScript)
	add_child(_ride_fx)


func _setup_sprite_frames() -> void :
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
		frames.set_animation_speed(walk_name, WALK_ANIM_FPS)
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


func _on_block(blocked: bool) -> void :
	if blocked:
		input_enabled = false
		velocity = Vector2.ZERO


func set_mounted(on: bool) -> void :
	var next: = on and int(GameState.get_stat("vehicle_tier")) >= 1
	if mounted == next:
		_sync_ride_fx()
		return
	mounted = next
	_sync_ride_fx()
	mount_changed.emit(mounted)


func get_facing_dir() -> String:
	return _facing_dir


func apply_facing_dir(dir: String) -> void :
	var d: = dir.strip_edges()
	if d == "" or not (d in DIR_NAMES):
		return
	_facing_dir = d
	match d:
		"n":
			_facing = Vector2.UP
		"s":
			_facing = Vector2.DOWN
		"e":
			_facing = Vector2.RIGHT
		"w":
			_facing = Vector2.LEFT
		"ne":
			_facing = Vector2(1, -1).normalized()
		"nw":
			_facing = Vector2(-1, -1).normalized()
		"se":
			_facing = Vector2(1, 1).normalized()
		"sw":
			_facing = Vector2(-1, 1).normalized()
	_play_anim("idle", true)


func _sync_ride_fx() -> void :
	_ensure_ride_fx()
	if _ride_fx == null:
		return
	_ride_fx.visible = mounted
	if _ride_fx.has_method("set_tier"):
		_ride_fx.set_tier(int(GameState.get_stat("vehicle_tier")) if mounted else 0)
	if mounted:
		sprite.position.y = -10.0
	else:
		sprite.position.y = 0.0


func _physics_process(delta: float) -> void :
	var wish: = Vector2.ZERO
	if input_enabled:
		wish = _read_move_input()
		if wish.length() > 1.0:
			wish = wish.normalized()

	if wish != Vector2.ZERO:
		var speed: = MAX_SPEED * _mount_speed_mult()
		velocity = velocity.move_toward(wish * speed, ACCEL * delta)
		_facing = wish
		_facing_dir = _vector_to_dir8(_facing)
		_play_anim("walk")
		if mounted and sprite.sprite_frames:
			sprite.speed_scale = 1.35
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		_play_anim("idle")
		sprite.speed_scale = 1.0

	if mounted:
		_ride_t += delta
		if _ride_fx:
			_ride_fx.rotation = 0.0

			if _ride_fx.has_method("set_facing"):
				_ride_fx.set_facing(_facing_dir)

	move_and_slide()


func _mount_speed_mult() -> float:
	if not mounted:
		return 1.0
	var host: = get_tree().get_first_node_in_group("world_host")
	if host == null or str(host.get("mode")) != "outdoor":
		return 1.0
	match int(GameState.get_stat("vehicle_tier")):
		1:
			return EBIKE_SPEED_MULT
		2:
			return RICKSHAW_SPEED_MULT
		3:
			return MOTO_SPEED_MULT
		4:
			return CAR_SPEED_MULT
		_:
			return 1.0


func _read_move_input() -> Vector2:
	var dir: = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		return dir
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")


func _vector_to_dir8(v: Vector2) -> String:
	if v == Vector2.ZERO:
		return _facing_dir
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


func _play_anim(state: String, force: bool = false) -> void :
	var key: = "%s_%s" % [state, _facing_dir]
	if not force and key == _anim_key:
		return
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(key):
		return
	var keep_frame: = _anim_key.begins_with("walk_") and key.begins_with("walk_")
	var frame_i: = sprite.frame
	_anim_key = key
	sprite.play(key)
	if keep_frame:
		var count: = sprite.sprite_frames.get_frame_count(key)
		if count > 0:
			sprite.frame = frame_i % count


func _unhandled_input(event: InputEvent) -> void :
	if not input_enabled:
		return

	if event is InputEventKey:
		var k: = event as InputEventKey
		if not k.pressed or k.echo:
			return
		var is_e: = k.keycode == KEY_E or k.physical_keycode == KEY_E
		var is_space: = k.keycode == KEY_SPACE or k.physical_keycode == KEY_SPACE
		if is_e:
			interact_pressed.emit(true)
			get_viewport().set_input_as_handled()
			return

		if is_space or event.is_action_pressed("ui_accept"):
			interact_pressed.emit(false)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		interact_pressed.emit(false)
		get_viewport().set_input_as_handled()
