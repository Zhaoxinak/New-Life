extends Node2D


signal prompt_changed(text: String)
signal hotspot_opened(hotspot_id: String)
signal location_entered(location_id: String)
signal request_result(text: String)

const PlayerScene: = preload("res://world/Player.tscn")
const OutdoorScene: = preload("res://world/HarborOutdoor.tscn")
const InteriorScene: = preload("res://world/InteriorRoom.tscn")


const DOOR_INTERACT_DIST: = 48.0
const DOOR_CLEAR_DIST: = 78.0

const DOOR_NEAR_QUEST: = 110.0

var player: CharacterBody2D
var outdoor: Node2D
var interior: Node2D
var mode: String = "outdoor"
var _return_spawn: Vector2 = Vector2.ZERO
var _current_door: Area2D = null
var _current_hotspot: Area2D = null
var _current_transit: Area2D = null
var _current_vehicle: Area2D = null
var _menu_open: bool = false

var _exit_grace_door: String = ""
var _entering: bool = false
var _enter_veil: ColorRect

var _entered_once: Dictionary = {}
var _veil_out_sec: float = 0.28
var _atmosphere: Node


func _ready() -> void :
	add_to_group("world_host")
	player = PlayerScene.instantiate()
	add_child(player)
	player.interact_pressed.connect(_on_interact)
	_ensure_atmosphere()
	_ensure_enter_veil()
	if not GameFlow.block_changed.is_connected(_on_block):
		GameFlow.block_changed.connect(_on_block)
	var pending: Dictionary = SaveSystem.take_pending_world()
	if pending.is_empty():
		_show_outdoor(true)
		SfxPlayer.play_ambience("outdoor")
	else:
		call_deferred("_deferred_restore_world", pending)


func _deferred_restore_world(data: Dictionary) -> void :
	await restore_world_snapshot(data)


func capture_world_snapshot() -> Dictionary:
	var pos: = player.global_position if player else Vector2.ZERO
	var facing: = "s"
	var mounted: = false
	if player:
		if player.has_method("get_facing_dir"):
			facing = str(player.get_facing_dir())
		mounted = bool(player.get("mounted"))
	var vpos: = Vector2.ZERO
	var vtaken: = mounted
	if outdoor and outdoor.has_method("vehicle_prop_position"):
		vpos = outdoor.vehicle_prop_position()
	if outdoor != null and outdoor.get("_vehicle_prop") != null:
		var vp: Variant = outdoor.get("_vehicle_prop")
		if vp != null and is_instance_valid(vp):
			vtaken = bool(vp.get("_taken")) or mounted
			vpos = vp.global_position
	return {
		"mode": mode, 
		"player_x": pos.x, 
		"player_y": pos.y, 
		"return_x": _return_spawn.x, 
		"return_y": _return_spawn.y, 
		"facing": facing, 
		"mounted": mounted, 
		"vehicle_x": vpos.x, 
		"vehicle_y": vpos.y, 
		"vehicle_taken": vtaken, 
		"exit_grace_door": _exit_grace_door, 
		"location_id": GameState.location_id, 
	}


func restore_world_snapshot(data: Dictionary) -> void :
	if data.is_empty():
		await _show_outdoor(true)
		SfxPlayer.play_ambience("outdoor")
		return
	var mode_s: = str(data.get("mode", "outdoor"))
	var pos: = Vector2(float(data.get("player_x", 0.0)), float(data.get("player_y", 0.0)))
	var ret: = Vector2(float(data.get("return_x", 0.0)), float(data.get("return_y", 0.0)))
	_exit_grace_door = str(data.get("exit_grace_door", ""))
	await _ensure_outdoor_ready()
	if mode_s == "interior":
		var loc: = str(data.get("location_id", GameState.location_id))
		if loc.strip_edges() == "" or loc == "dock":
			loc = str(GameState.location_id)
		if loc.strip_edges() == "" or loc == "dock" or not GameState.is_location_unlocked(loc):
			await _show_outdoor(false, pos if pos != Vector2.ZERO else Vector2.ZERO)
			SfxPlayer.play_ambience("outdoor")
		else:
			GameState.location_id = loc
			await _restore_interior_silent(loc, pos, ret)
	else:
		await _show_outdoor(false, pos if pos != Vector2.ZERO else Vector2.ZERO)
		SfxPlayer.play_ambience("outdoor")
	_apply_vehicle_restore(data)
	if player:
		if player.has_method("apply_facing_dir"):
			player.apply_facing_dir(str(data.get("facing", "s")))
		if player.has_method("set_mounted"):
			player.set_mounted(bool(data.get("mounted", false)))
	_update_prompt()


func _ensure_outdoor_ready() -> void :
	if outdoor != null:
		return
	outdoor = OutdoorScene.instantiate()
	add_child(outdoor)
	outdoor.door_requested.connect(_on_door_requested)
	if outdoor.has_signal("transit_requested") and not outdoor.transit_requested.is_connected(_on_transit_requested):
		outdoor.transit_requested.connect(_on_transit_requested)
	if outdoor.has_signal("mount_requested") and not outdoor.mount_requested.is_connected(_on_mount_requested):
		outdoor.mount_requested.connect(_on_mount_requested)
	await get_tree().process_frame


func _restore_interior_silent(location_id: String, pos: Vector2, ret: Vector2) -> void :
	_entering = true
	_return_spawn = ret if ret != Vector2.ZERO else pos
	if player and bool(player.get("mounted")):
		player.set_mounted(false)
	if player and player.camera:
		player.camera.limit_enabled = false
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
	if pos != Vector2.ZERO:
		player.global_position = pos
	else:
		player.global_position = interior.get_entry_spawn()
	_current_door = null
	_current_hotspot = null
	SfxPlayer.play_ambience(location_id)
	if _atmosphere and _atmosphere.has_method("set_outdoor"):
		_atmosphere.set_outdoor(false)
	_update_prompt()
	_entering = false

	location_entered.emit(location_id)


func _apply_vehicle_restore(data: Dictionary) -> void :
	if outdoor == null:
		return
	var vx: = float(data.get("vehicle_x", 0.0))
	var vy: = float(data.get("vehicle_y", 0.0))
	if Vector2(vx, vy) != Vector2.ZERO and outdoor.has_method("park_vehicle_at"):
		outdoor.park_vehicle_at(Vector2(vx, vy))
	if outdoor.has_method("set_vehicle_taken"):
		outdoor.set_vehicle_taken(bool(data.get("vehicle_taken", false)))


func _ensure_atmosphere() -> void :
	if _atmosphere != null:
		return
	var fx_script: = load("res://world/AtmosphereFx.gd")
	_atmosphere = Node.new()
	_atmosphere.set_script(fx_script)
	_atmosphere.name = "AtmosphereFx"
	add_child(_atmosphere)


func _ensure_enter_veil() -> void :
	if _enter_veil != null:
		return
	var layer: = CanvasLayer.new()
	layer.layer = 40
	layer.name = "EnterVeilLayer"
	add_child(layer)
	_enter_veil = ColorRect.new()
	_enter_veil.name = "EnterVeil"
	_enter_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_enter_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enter_veil.visible = false
	_enter_veil.modulate.a = 0.0
	layer.add_child(_enter_veil)


func set_menu_open(open: bool) -> void :
	_menu_open = open
	_apply_player_input()
	_update_prompt()


func _apply_player_input() -> void :
	if player:
		player.input_enabled = not _menu_open and not GameFlow.is_blocked()


func _on_block(_blocked: bool) -> void :
	_apply_player_input()
	_update_prompt()


func _show_outdoor(at_default: bool = false, spawn: Vector2 = Vector2.ZERO) -> void :
	_clear_interior()
	if outdoor == null:
		outdoor = OutdoorScene.instantiate()
		add_child(outdoor)
		outdoor.door_requested.connect(_on_door_requested)
		if outdoor.has_signal("transit_requested") and not outdoor.transit_requested.is_connected(_on_transit_requested):
			outdoor.transit_requested.connect(_on_transit_requested)
		if outdoor.has_signal("mount_requested") and not outdoor.mount_requested.is_connected(_on_mount_requested):
			outdoor.mount_requested.connect(_on_mount_requested)
	outdoor.visible = true
	mode = "outdoor"
	GameState.location_id = ""
	await get_tree().process_frame
	if at_default or spawn == Vector2.ZERO:
		player.global_position = outdoor.get_default_spawn()
	else:
		player.global_position = spawn
	_return_spawn = player.global_position
	_current_door = null
	_current_hotspot = null
	_exit_grace_door = ""
	_apply_outdoor_camera_limits()
	if _atmosphere and _atmosphere.has_method("set_outdoor"):
		_atmosphere.set_outdoor(true)

	NpcScheduler.resync_all(false)
	_update_prompt()


func _apply_outdoor_camera_limits() -> void :
	if player == null or player.camera == null or outdoor == null:
		return
	var ms: Vector2 = outdoor.map_size
	player.camera.limit_enabled = true
	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = int(ms.x)
	player.camera.limit_bottom = int(ms.y)
	player.camera.limit_smoothed = true


func _clear_interior() -> void :
	if interior != null:
		interior.queue_free()
		interior = null


func _on_door_requested(location_id: String, return_spawn: Vector2) -> void :
	enter_interior(location_id, return_spawn)


func _on_transit_requested(from_stop_id: String) -> void :

	if int(GameState.get_stat("vehicle_tier")) >= 1:
		return
	open_transit(from_stop_id)


func _on_mount_requested() -> void :
	mount_vehicle()


func open_transit(from_stop_id: String = "home") -> void :
	if int(GameState.get_stat("vehicle_tier")) >= 1:
		mount_vehicle_from_home()
		return
	var panel: = get_tree().get_first_node_in_group("transit_panel")
	if panel and panel.has_method("open"):
		panel.open(from_stop_id)


func mount_vehicle_from_home() -> void :

	if mode == "interior":
		exit_interior()
	if outdoor and outdoor.has_method("vehicle_prop_position") and player:
		player.global_position = outdoor.vehicle_prop_position()
	mount_vehicle()


func mount_vehicle() -> void :
	if player == null or mode != "outdoor":
		return
	if int(GameState.get_stat("vehicle_tier")) < 1:
		return
	if bool(player.mounted):
		return
	player.set_mounted(true)
	if outdoor and outdoor.has_method("set_vehicle_taken"):
		outdoor.set_vehicle_taken(true)
	SfxPlayer.play_ride(int(GameState.get_stat("vehicle_tier")))
	TipSystem.queue_tip("tip_transit")
	_update_prompt()
	request_result.emit(L10n.t("vehicle.mount", "跨上车，电门在手里。"))


func dismount_vehicle(park_pos: Vector2 = Vector2.ZERO) -> void :
	if player == null or not bool(player.mounted):
		return
	var at: = park_pos if park_pos != Vector2.ZERO else player.global_position
	player.set_mounted(false)
	if outdoor and outdoor.has_method("park_vehicle_at"):
		outdoor.park_vehicle_at(at)
	SfxPlayer.play_stinger("tick")
	_update_prompt()
	request_result.emit(L10n.t("vehicle.dismount", "下车，车停在脚边。"))


func is_mounted() -> bool:
	return player != null and bool(player.mounted)


func teleport_to_stop(stop_id: String) -> void :
	if outdoor == null or player == null:
		return
	_teleport_to_stop_async(stop_id)


func _teleport_to_stop_async(stop_id: String) -> void :

	if player:
		player.input_enabled = false
	_ensure_enter_veil()
	_enter_veil.visible = true
	_enter_veil.color = Color(0.08, 0.1, 0.16, 1)
	_enter_veil.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(_enter_veil, "modulate:a", 1.0, 0.12)
	await tw.finished
	if mode != "outdoor":
		_clear_interior()
		outdoor.visible = true
		mode = "outdoor"
		GameState.location_id = ""
		SfxPlayer.play_ambience("outdoor")
		if _atmosphere and _atmosphere.has_method("set_outdoor"):
			_atmosphere.set_outdoor(true)
	var dest: Vector2
	if outdoor.has_method("get_stop_spawn"):
		dest = outdoor.get_stop_spawn(stop_id)
	else:
		dest = outdoor.get_default_spawn()
	player.global_position = dest
	_return_spawn = dest
	_current_door = null
	_exit_grace_door = ""
	_update_prompt()
	TipSystem.queue_tip("tip_transit")
	var tw2: = create_tween()
	tw2.tween_property(_enter_veil, "modulate:a", 0.0, 0.18)
	await tw2.finished
	_enter_veil.visible = false
	_apply_player_input()


## Curfew / forced rest: snap into home whether outdoors or in another interior.
func force_home_for_curfew() -> void :
	if _entering:
		return
	if mode == "interior" and str(GameState.location_id) == "home":
		return
	var ret: = player.global_position if player else Vector2.ZERO
	if mode == "interior":
		## Tear down current room without the usual exit-to-street path.
		_clear_interior()
		mode = "outdoor"
		if outdoor:
			outdoor.visible = true
		if _atmosphere and _atmosphere.has_method("set_outdoor"):
			_atmosphere.set_outdoor(true)
	if outdoor != null and outdoor.has_method("get_spawn_for"):
		ret = outdoor.get_spawn_for("home")
	await enter_interior("home", ret)


func enter_interior(location_id: String, return_spawn: Vector2) -> void :
	if _entering or mode == "interior":
		return

	if player and bool(player.mounted):
		dismount_vehicle(return_spawn)
	if not GameState.is_location_unlocked(location_id):
		var reason: = UnlockScheduler.pending_reason("location", location_id)
		var loc_name: = L10n.t("locations.%s.name" % location_id, location_id)
		if reason == "":
			reason = L10n.t("ui.world.locked", "此地尚未开放")
		request_result.emit(L10n.tf(
			"ui.world.locked_named", 
			{"name": loc_name, "reason": reason}, 
			"%s尚未开放（%s）" % [loc_name, reason]
		))
		return
	_entering = true
	_return_spawn = return_spawn
	await _veil_in(location_id)
	if player and player.camera:
		player.camera.limit_enabled = false
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
	SfxPlayer.play_ambience(location_id)
	if _atmosphere and _atmosphere.has_method("set_outdoor"):
		_atmosphere.set_outdoor(false)
	_update_prompt()

	QuestGuide.notify_near_door()

	location_entered.emit(location_id)
	QuestGuide.notify_enter_location(location_id)
	TipSystem.on_enter_location(location_id)
	await _veil_out()
	_entering = false
	SaveSystem.autosave()


func _veil_in(location_id: String) -> void :
	_ensure_enter_veil()
	var tint: Color = UiStyle.location_color(location_id)
	var in_sec: = 0.16
	_veil_out_sec = 0.28
	var first: = not bool(_entered_once.get(location_id, false))
	_entered_once[location_id] = true
	if location_id == "company" and first:
		in_sec = 0.32
		_veil_out_sec = 0.4
	elif location_id == "home" and GameState.get_flag("su_accepts_son_gifts", 0) >= 1:

		tint = Color(0.12, 0.16, 0.28, 1.0)
		in_sec = 0.24
		_veil_out_sec = 0.36
	tint.a = 1.0
	_enter_veil.color = Color(tint.r, tint.g, tint.b, 1.0)
	_enter_veil.visible = true
	_enter_veil.modulate = Color(1, 1, 1, 0)
	var tw: = create_tween()
	tw.tween_property(_enter_veil, "modulate:a", 1.0, in_sec)
	await tw.finished


func _veil_out() -> void :
	if _enter_veil == null:
		return
	var tw: = create_tween()
	tw.tween_property(_enter_veil, "modulate:a", 0.0, _veil_out_sec)
	await tw.finished
	_enter_veil.visible = false
	_veil_out_sec = 0.28


func exit_interior() -> void :
	_on_exit_interior()


func _on_exit_interior() -> void :
	_menu_open = false
	_apply_player_input()
	var left_id: = str(GameState.location_id)
	_clear_interior()
	if outdoor:
		outdoor.visible = true
		outdoor._refresh_doors()
	mode = "outdoor"
	player.global_position = _return_spawn
	_exit_grace_door = left_id
	GameState.set_location("dock")
	SfxPlayer.play_click()
	SfxPlayer.play_ambience("outdoor")
	_apply_outdoor_camera_limits()
	if _atmosphere and _atmosphere.has_method("set_outdoor"):
		_atmosphere.set_outdoor(true)
	_current_door = null
	_current_hotspot = null
	NpcScheduler.resync_all(false)
	_update_prompt()
	SaveSystem.autosave()


func _on_hotspot_requested(hotspot_id: String) -> void :
	hotspot_opened.emit(hotspot_id)


func _physics_process(_delta: float) -> void :
	if _menu_open or mode == "interior":
		if _current_door != null or _current_hotspot != null:
			_current_door = null
			_current_hotspot = null
			_update_prompt()
		return
	_scan_overlaps()


func _door_in_reach(area: Area2D) -> bool:
	if area == null or player == null:
		return false
	if area.get_overlapping_bodies().has(player):
		return true
	return player.global_position.distance_to(area.global_position) <= DOOR_INTERACT_DIST


func _scan_overlaps() -> void :
	_current_door = null
	_current_hotspot = null
	_current_transit = null
	_current_vehicle = null
	if player == null or _entering:
		return

	var nearest: Area2D = null
	var nearest_d: = INF
	var nearest_any: Area2D = null
	var nearest_any_d: = INF
	for area in get_tree().get_nodes_in_group("door_zone"):
		if not (area is Area2D) or not is_instance_valid(area):
			continue
		if outdoor == null or not outdoor.is_ancestor_of(area):
			continue
		var lid: = str(area.location_id)
		var d: float = player.global_position.distance_to(area.global_position)


		if _exit_grace_door != "" and lid == _exit_grace_door and d > DOOR_CLEAR_DIST:
			_exit_grace_door = ""
		if d < nearest_any_d:
			nearest_any_d = d
			nearest_any = area

		if not _door_in_reach(area):
			continue
		if d < nearest_d:
			nearest_d = d
			nearest = area

	_current_door = nearest

	if not bool(player.mounted):
		var nearest_bike: Area2D = null
		var bike_d: = INF
		for area in get_tree().get_nodes_in_group("vehicle_prop"):
			if not (area is Area2D) or not is_instance_valid(area):
				continue
			if outdoor == null or not outdoor.is_ancestor_of(area):
				continue
			if not area.visible:
				continue
			var db: float = player.global_position.distance_to(area.global_position)
			if db < bike_d:
				bike_d = db
				nearest_bike = area
		if nearest_bike != null and bike_d <= 56.0:
			_current_vehicle = nearest_bike

	var nearest_stop: Area2D = null
	var stop_d: = INF
	for area in get_tree().get_nodes_in_group("transit_stop"):
		if not (area is Area2D) or not is_instance_valid(area):
			continue
		if outdoor == null or not outdoor.is_ancestor_of(area):
			continue
		if not area.visible:
			continue
		var d2: float = player.global_position.distance_to(area.global_position)
		if d2 < stop_d:
			stop_d = d2
			nearest_stop = area
	if nearest_stop != null and stop_d <= 56.0:
		_current_transit = nearest_stop

	_update_prompt()


	if nearest_any != null and nearest_any_d <= DOOR_NEAR_QUEST and not GameFlow.is_blocked():
		QuestGuide.notify_near_door()
		TipSystem.on_near_door()

	if nearest == null or GameFlow.is_blocked():
		return

	if bool(player.mounted):
		return
	var enter_id: = str(nearest.location_id)
	if enter_id == "__exit__":
		return
	if _exit_grace_door != "" and enter_id == _exit_grace_door:
		return
	if bool(nearest.get("locked")):
		_toast_locked_location(enter_id)
		return

	if nearest.get_overlapping_bodies().has(player):
		nearest.try_activate()


func _update_prompt() -> void :
	if mode == "outdoor" and player != null:
		var npc: Node = NpcScheduler.nearest_talkable(player.global_position, 56.0)
		if npc != null and not bool(player.mounted):
			var nid: = str(npc.get("npc_id"))
			var nm: = L10n.t("npcs.%s.name" % nid, nid)
			prompt_changed.emit(L10n.tf("ui.world.talk_npc", {"name": nm}, "按 E 与%s交谈" % nm))
			return
		if bool(player.mounted):
			if _current_door != null:
				var lid_m: = str(_current_door.location_id)
				var loc_m: = L10n.t("locations.%s.name" % lid_m, lid_m)
				prompt_changed.emit(L10n.tf("ui.world.enter_dismount_prompt", {"name": loc_m}, "按 E 下车进入%s" % loc_m))
			else:
				prompt_changed.emit(L10n.t("ui.world.dismount_prompt", "按 E 下车"))
			return
		if _current_vehicle != null:
			prompt_changed.emit(L10n.t("ui.world.ride_prompt", "按 E 上车"))
			return
		if _current_transit != null:
			prompt_changed.emit(L10n.t("ui.world.transit_prompt", "按 E 乘车"))
			return
		if _current_door != null:
			var lid: = str(_current_door.location_id)
			var loc_name: = L10n.t("locations.%s.name" % lid, lid)
			if bool(_current_door.get("locked")):
				prompt_changed.emit(L10n.tf("ui.world.locked_prompt", {"name": loc_name}, "%s尚未开放" % loc_name))
			else:
				prompt_changed.emit(L10n.tf("ui.world.enter_prompt", {"name": loc_name}, "按 E 进入%s" % loc_name))
			return
	prompt_changed.emit("")


func _on_interact(mount_ok: bool = true) -> void :
	if GameFlow.is_blocked() or _menu_open:
		return
	if mode == "interior":
		location_entered.emit(str(GameState.location_id))
		return
	_scan_overlaps()
	if _entering:
		return

	if player and bool(player.mounted):
		if not mount_ok:
			return
		if _current_door != null and _door_in_reach(_current_door):
			var lid_r: = str(_current_door.location_id)
			if _exit_grace_door != "" and lid_r == _exit_grace_door:
				_exit_grace_door = ""
			if bool(_current_door.get("locked")):
				_toast_locked_location(lid_r)
				return
			_current_door.try_activate()
			return
		dismount_vehicle()
		return

	var street: Node = NpcScheduler.nearest_talkable(player.global_position, 56.0)
	if street != null and NpcScheduler.try_start_street_talk(street):
		return
	if _current_vehicle != null and _current_vehicle.has_method("try_activate"):
		if not mount_ok:
			return
		_current_vehicle.try_activate()
		return
	if _current_transit != null and _current_transit.has_method("try_activate"):

		if _current_transit.get_overlapping_bodies().has(player) or player.global_position.distance_to(_current_transit.global_position) <= 56.0:
			_current_transit.try_activate()
			return

	if _current_door != null and _door_in_reach(_current_door):
		var lid: = str(_current_door.location_id)

		if _exit_grace_door != "" and lid == _exit_grace_door:
			_exit_grace_door = ""
		if bool(_current_door.get("locked")):
			_toast_locked_location(lid)
			return
		_current_door.try_activate()


var _last_lock_toast_id: String = ""
var _last_lock_toast_ms: int = 0


func _toast_locked_location(location_id: String) -> void :
	var now: = Time.get_ticks_msec()
	if location_id == _last_lock_toast_id and now - _last_lock_toast_ms < 1200:
		return
	_last_lock_toast_id = location_id
	_last_lock_toast_ms = now
	var reason: = UnlockScheduler.pending_reason("location", location_id)
	var loc_name: = L10n.t("locations.%s.name" % location_id, location_id)
	if reason == "":
		reason = L10n.t("ui.world.locked", "此地尚未开放")
	request_result.emit(L10n.tf(
		"ui.world.locked_named", 
		{"name": loc_name, "reason": reason}, 
		"%s尚未开放（%s）" % [loc_name, reason]
	))


func refresh_after_action() -> void :
	if mode == "interior" and interior != null and interior.has_method("refresh_hotspots"):
		interior.refresh_hotspots()
	elif outdoor != null:
		outdoor._refresh_doors()
	_update_prompt()
