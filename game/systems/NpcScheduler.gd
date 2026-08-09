extends Node


var _outdoor: Node2D = null
var _talk_day: Dictionary = {}
var _bootstrapped: bool = false


func _ready() -> void :
	if not GameState.period_advanced.is_connected(_on_period):
		GameState.period_advanced.connect(_on_period)
	if not GameState.day_ended.is_connected(_on_day_ended):
		GameState.day_ended.connect(_on_day_ended)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func bind_outdoor(outdoor: Node2D) -> void :
	_outdoor = outdoor
	_bootstrapped = false

	call_deferred("_bootstrap_deferred")


func unbind_outdoor(outdoor: Node2D) -> void :
	if _outdoor == outdoor:
		_outdoor = null
		_bootstrapped = false


func _bootstrap_deferred() -> void :
	await get_tree().physics_frame
	await get_tree().physics_frame
	_bootstrap()


func _bootstrap() -> void :

	resync_all(false)
	_bootstrapped = true
	TipSystem.queue_tip("tip_street_npc")


func _on_period(_day: int, _period: String) -> void :

	resync_all(false)


func _on_day_ended(_completed_day: int) -> void :
	_talk_day.clear()


func _on_locale(_l: String) -> void :
	for n in get_tree().get_nodes_in_group("outdoor_npc"):
		if n.has_method("_refresh_nameplate"):
			n._refresh_nameplate()


func resync_all(snap: bool = false) -> void :
	if _outdoor == null or not is_instance_valid(_outdoor):
		return
	var npcs: = get_tree().get_nodes_in_group("outdoor_npc")
	if npcs.is_empty():

		if not snap:
			return
		call_deferred("_retry_bootstrap")
		return
	for n in npcs:
		if not is_instance_valid(n):
			continue
		_apply_to(n, snap)


func _retry_bootstrap() -> void :
	if _outdoor == null or not is_instance_valid(_outdoor):
		return
	resync_all(false)
	_bootstrapped = true


func _apply_to(npc: Node, snap: bool) -> void :
	var nid: = str(npc.get("npc_id"))
	if nid == "":
		return
	var dest: = resolve_destination(nid)
	if dest.is_empty():
		push_warning("NpcScheduler: no destination for %s" % nid)
		NpcWalkDebug.trace(nid, "scheduler NO_DEST period=%s" % GameState.period)
		return
	var pos: Vector2 = dest.get("pos", Vector2.ZERO)
	var indoors: bool = bool(dest.get("indoors", false))
	var building_id: = str(dest.get("building_id", ""))
	NpcWalkDebug.trace(nid, "scheduler dest kind=%s indoors=%s building=%s pos=%s snap=%s period=%s" % [
		dest.get("kind", ""), indoors, building_id, pos, snap, GameState.period
	])
	if npc.has_method("set_schedule_target"):
		npc.set_schedule_target(pos, indoors, snap, building_id)



func resolve_destination(npc_id: String) -> Dictionary:
	if _outdoor == null or not is_instance_valid(_outdoor):
		return {}
	var period: = str(GameState.period).strip_edges()
	var row: = _pick_schedule(npc_id, period)
	if row.is_empty():
		push_warning("NpcScheduler: no schedule for %s @ %s (table=%d)" % [
			npc_id, period, PackDB.get_table("npc_schedules").size()
		])
		var home: = _home_pos(npc_id)
		return {"pos": _goal_on_path(home, npc_id), "indoors": false, "kind": "home", "building_id": ""}
	var kind: = str(row.get("dest_kind", "home")).strip_edges()
	var dest_id: = str(row.get("dest_id", npc_id)).strip_edges()
	match kind:
		"building":

			var spawn: Vector2 = _outdoor.get_spawn_for(dest_id)

			spawn += _lane_offset(npc_id)
			return {
				"pos": _goal_on_path(spawn, npc_id), 
				"indoors": true, 
				"kind": kind, 
				"building_id": dest_id, 
			}
		"spot":

			var spot: = _spot_pos(dest_id)
			return {
				"pos": _goal_on_path(spot, npc_id), 
				"indoors": false, 
				"kind": kind, 
				"building_id": "", 
			}
		_:
			var home_pos: = _home_pos(dest_id if dest_id != "" else npc_id)

			return {
				"pos": _goal_on_path(home_pos + Vector2(0, 18.0), npc_id), 
				"indoors": true, 
				"kind": "home", 
				"building_id": "", 
			}


func npcs_at_building(location_id: String) -> Array:

	var out: Array = []
	var lid: = location_id.strip_edges()
	if lid == "":
		return out
	for n in get_tree().get_nodes_in_group("outdoor_npc"):
		if not is_instance_valid(n):
			continue
		var nid: = str(n.get("npc_id"))
		if nid == "":
			continue
		if n.has_method("inside_building_id") and str(n.inside_building_id()) == lid:
			out.append(nid)
	return out


func occupant_names_line(location_id: String, max_names: int = 3) -> String:
	var ids: = npcs_at_building(location_id)
	if ids.is_empty():
		return ""
	var names: PackedStringArray = []
	for i in mini(ids.size(), max_names):
		var nid: = str(ids[i])
		names.append(L10n.t("npcs.%s.name" % nid, nid))
	var sep: = "、" if str(L10n.locale).begins_with("zh") else ", "
	var line: = sep.join(names)
	if ids.size() > max_names:
		line = "%s…" % line
	return line


func try_start_indoor_talk(npc_id: String) -> bool:

	if npc_id == "" or not can_talk(npc_id):
		return false
	var dlg: = ""
	for n in get_tree().get_nodes_in_group("outdoor_npc"):
		if not is_instance_valid(n):
			continue
		if str(n.get("npc_id")) == npc_id:
			dlg = str(n.get("street_dialogue_id"))
			break
	if dlg == "":

		for row in PackDB.get_table("npc_homes"):
			if str(row.get("npc_id", "")) == npc_id:
				dlg = str(row.get("street_dialogue_id", ""))
				break
	if dlg == "":
		return false
	mark_talked(npc_id)
	var panel: = get_tree().get_first_node_in_group("dialogue_panel")
	if panel != null and panel.has_method("open"):
		panel.open(dlg, "")
		return true
	ActionPipeline.dialogue_requested.emit(dlg, "")
	return true


func _pick_schedule(npc_id: String, period: String) -> Dictionary:
	var candidates: Array = []
	for row in PackDB.get_table("npc_schedules"):
		if str(row.get("enabled", "1")) in ["0", "false", "False"]:
			continue
		if str(row.get("npc_id", "")).strip_edges() != npc_id:
			continue
		if str(row.get("period", "")).strip_edges() != period:
			continue
		candidates.append(row)
	if candidates.is_empty():
		return {}
	if candidates.size() == 1:
		return candidates[0]
	var total: = 0.0
	for c in candidates:
		total += maxf(1.0, float(c.get("weight", 10)))
	var roll: = randf() * total
	var acc: = 0.0
	for c in candidates:
		acc += maxf(1.0, float(c.get("weight", 10)))
		if roll <= acc:
			return c
	return candidates[0]


func _goal_on_path(raw: Vector2, npc_id: String) -> Vector2:

	if _outdoor != null and _outdoor.has_method("snap_walk_goal"):
		return _outdoor.snap_walk_goal(raw, npc_id)
	return raw + _slot_offset(npc_id)


func _lane_offset(npc_id: String) -> Vector2:

	var h: = absi(npc_id.hash())
	return Vector2(float((h % 5) - 2) * 22.0, float((h % 3) - 1) * 14.0)


func _slot_offset(npc_id: String) -> Vector2:

	var h: = absi(npc_id.hash())
	return Vector2(float((h % 5) - 2) * 16.0, float(h % 3) * 10.0)


func _home_pos(npc_id: String) -> Vector2:
	if _outdoor != null and _outdoor.has_method("get_npc_home_pos"):
		return _outdoor.get_npc_home_pos(npc_id)
	return Vector2.ZERO


func _spot_pos(spot_id: String) -> Vector2:
	if _outdoor != null and _outdoor.has_method("get_npc_spot"):
		return _outdoor.get_npc_spot(spot_id)
	return _home_pos(spot_id)


func can_talk(npc_id: String) -> bool:
	var last: = int(_talk_day.get(npc_id, -1))
	return last != int(GameState.day)


func mark_talked(npc_id: String) -> void :
	_talk_day[npc_id] = int(GameState.day)


func clear_runtime() -> void :
	_talk_day.clear()
	_bootstrapped = false


func get_talk_day_snapshot() -> Dictionary:
	return _talk_day.duplicate(true)


func apply_talk_day_snapshot(data: Variant) -> void :
	_talk_day.clear()
	if typeof(data) != TYPE_DICTIONARY:
		return
	var d: Dictionary = data
	for k in d.keys():
		_talk_day[str(k)] = int(d[k])


func try_start_street_talk(npc: Node) -> bool:
	if npc == null or not is_instance_valid(npc):
		return false
	if not npc.has_method("is_talkable") or not npc.is_talkable():
		return false
	var nid: = str(npc.get("npc_id"))
	if not can_talk(nid):
		return false
	var dlg: = str(npc.get("street_dialogue_id"))
	if dlg == "":
		return false
	mark_talked(nid)
	var panel: = get_tree().get_first_node_in_group("dialogue_panel")
	if panel != null and panel.has_method("open"):
		panel.open(dlg, "")
		return true
	ActionPipeline.dialogue_requested.emit(dlg, "")
	return true


func nearest_talkable(from: Vector2, max_dist: float = 56.0) -> Node:
	var best: Node = null
	var best_d: = max_dist
	for n in get_tree().get_nodes_in_group("outdoor_npc"):
		if not is_instance_valid(n):
			continue
		if not n.has_method("is_talkable") or not n.is_talkable():
			continue
		var nid: = str(n.get("npc_id"))
		if not can_talk(nid):
			continue
		var d: float = from.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best
