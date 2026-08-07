extends CharacterBody2D
## Top-down player: WASD / arrows, frozen when UI blocked.

signal interact_pressed

const SPEED := 160.0

var input_enabled: bool = true
var _facing: Vector2 = Vector2.DOWN

@onready var sprite: Sprite2D = %Sprite
@onready var camera: Camera2D = %Camera
@onready var anim: AnimationPlayer = get_node_or_null("Anim") as AnimationPlayer


func _ready() -> void:
	add_to_group("player")
	camera.make_current()
	if not GameFlow.block_changed.is_connected(_on_block):
		GameFlow.block_changed.connect(_on_block)
	_on_block(GameFlow.is_blocked())


func _on_block(blocked: bool) -> void:
	# Only force-off while UI-blocked; WorldHost restores when menu closes.
	if blocked:
		input_enabled = false
		velocity = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if not input_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Also WASD via custom — map in project or hardcode.
	if dir == Vector2.ZERO:
		dir = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
	# Fallback raw keys if actions missing.
	if dir == Vector2.ZERO:
		dir = Vector2(
			(1.0 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) else 0.0)
			- (1.0 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) else 0.0),
			(1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0)
			- (1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0)
		)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity = dir * SPEED
	move_and_slide()
	if dir != Vector2.ZERO:
		_facing = dir
		_update_sprite_facing()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		interact_pressed.emit()
		get_viewport().set_input_as_handled()


func _update_sprite_facing() -> void:
	if absf(_facing.x) > absf(_facing.y):
		sprite.flip_h = _facing.x < 0.0
	else:
		sprite.flip_h = false
	# Subtle bob when moving
	if velocity.length() > 10.0:
		sprite.offset.y = -2.0 + sin(Time.get_ticks_msec() * 0.02) * 2.0
	else:
		sprite.offset.y = -2.0
