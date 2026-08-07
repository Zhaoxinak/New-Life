extends Node2D
## Owns outdoor/interior maps + player; handles enter/exit and interact.

signal prompt_changed(text: String)
signal hotspot_opened(hotspot_id: String)
signal location_entered(location_id: String)
signal request_result(text: String)

const PlayerScene := preload("res://world/Player.tscn")
const OutdoorScene := preload("res://world/HarborOutdoor.tscn")
const InteriorScene := preload("res://world/InteriorRoom.tscn")

## Enter only when standing at the door; E still works as backup.
const DOOR_ENTER_DIST := 0.0
const DOOR_CLEAR_DIST := 78.0

var player: CharacterBody2D
var outdoor: Node2D
var interior: Node2D
var mode: String = "outdoor" # outdoor | interior
var _return_spawn: Vector2 = Vector2.ZERO
var _current_door: Area2D = null
var _current_hotspot: Area2D = null
var _menu_open: bool = false
## After exiting, ignore auto-enter until player walks clear of that door.
var _exit_grace_door: String = ""
var _entering: bool = false


func _ready() -> void:
	player = PlayerScene.instantiate()
	add_child(player)
	player.interact_pressed.connect(_on_interact)
	_show_outdoor(true)
	if not GameFlow.block_changed.is_connected(_on_block):
		GameFlow.block_changed.connect(_on_block)


func set_menu_open(open: bool) -> void:
	_menu_open = open
	_apply_player_input()
	_update_prompt()


func _apply_player_input() -> void:
	if player:
		player.input_enabled = not _menu_open and not GameFlow.is_blocked()


func _on_block(_blocked: bool) -> void:
	_apply_player_input()
	_update_prompt()


func _show_outdoor(at_default: bool = false, spawn: Vector2 = Vector2.ZERO) -> void:
	_clear_interior()
	if outdoor == null:
		outdoor = OutdoorScene.instantiate()
		add_child(outdoor)
		outdoor.door_requested.connect(_on_door_requested)
	outdoor.visible = true
	mode = "outdoor"
	await get_tree().process_frame
	if at_default or spawn == Vector2.ZERO:
		player.global_position = outdoor.get_default_spawn()
	else:
		player.global_position = spawn
	_return_spawn = player.global_position
	_current_door = null
	_current_hotspot = null
	_exit_grace_door = ""
	_update_prompt()


func _clear_interior() -> void:
	if interior != null:
		interior.queue_free()
		interior = null


func _on_door_requested(location_id: String, return_spawn: Vector2) -> void:
	enter_interior(location_id, return_spawn)


func enter_interior(location_id: String, return_spawn: Vector2) -> void:
	if _entering or mode == "interior":
		return
	if not GameState.is_location_unlocked(location_id):
		request_result.emit(L10n.t("ui.world.locked", "此地尚未开放"))
		return
	_entering = true
	_return_spawn = return_spawn
	if outdoor:
		outdoor.visible = false
	_clear_interior()
	interior = InteriorScene.instantiate()
	add_child(interior)
	interior.setup(location_id)
	interior.exit_requested.connect(_on_exit_interior)
	interior.hotspot_requested.connect(_on_hotspot_requested)
	mode = "interior"
	await get_tree().process_frame
	player.global_position = interior.get_entry_spawn()
	_current_door = null
	_current_hotspot = null
	SfxPlayer.play_click()
	_update_prompt()
	# 太阁式：进门直接弹地点选项
	location_entered.emit(location_id)
	QuestGuide.notify_enter_location(location_id)
	_entering = false


func exit_interior() -> void:
	_on_exit_interior()


func _on_exit_interior() -> void:
	_menu_open = false
	_apply_player_input()
	var left_id := str(GameState.location_id)
	_clear_interior()
	if outdoor:
		outdoor.visible = true
		outdoor._refresh_doors()
	mode = "outdoor"
	player.global_position = _return_spawn
	_exit_grace_door = left_id
	GameState.set_location("dock")
	SfxPlayer.play_click()
	_current_door = null
	_current_hotspot = null
	_update_prompt()


func _on_hotspot_requested(hotspot_id: String) -> void:
	hotspot_opened.emit(hotspot_id)


func _physics_process(_delta: float) -> void:
	if _menu_open or mode == "interior":
		if _current_door != null or _current_hotspot != null:
			_current_door = null
			_current_hotspot = null
			_update_prompt()
		return
	_scan_overlaps()


func _scan_overlaps() -> void:
	_current_door = null
	_current_hotspot = null
	if player == null or _entering:
		return

	var nearest: Area2D = null
	var nearest_d := INF
	for area in get_tree().get_nodes_in_group("door_zone"):
		if not (area is Area2D) or not is_instance_valid(area):
			continue
		if outdoor == null or not outdoor.is_ancestor_of(area):
			continue
		var lid := str(area.location_id)
		var d: float = player.global_position.distance_to(area.global_position)
		if _exit_grace_door != "" and lid == _exit_grace_door and not area.get_overlapping_bodies().has(player):
			_exit_grace_door = ""
		if d < nearest_d:
			nearest_d = d
			nearest = area

	_current_door = nearest
	_update_prompt()

	if nearest == null or GameFlow.is_blocked():
		return
	var enter_id := str(nearest.location_id)
	if enter_id == "__exit__":
		return
	if _exit_grace_door != "" and enter_id == _exit_grace_door:
		return
	if bool(nearest.get("locked")):
		return
	if nearest.get_overlapping_bodies().has(player):
		nearest.try_activate()


func _update_prompt() -> void:
	prompt_changed.emit("")


func _on_interact() -> void:
	if GameFlow.is_blocked() or _menu_open:
		return
	if mode == "interior":
		location_entered.emit(str(GameState.location_id))
		return
	_scan_overlaps()
	if _current_door != null:
		var lid := str(_current_door.location_id)
		# Manual E can override exit grace if player insists.
		if _exit_grace_door != "" and lid == _exit_grace_door:
			_exit_grace_door = ""
		_current_door.try_activate()


func refresh_after_action() -> void:
	if mode == "interior" and interior != null and interior.has_method("refresh_hotspots"):
		interior.refresh_hotspots()
	elif outdoor != null:
		outdoor._refresh_doors()
	_update_prompt()
