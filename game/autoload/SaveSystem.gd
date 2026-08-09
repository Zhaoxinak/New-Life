extends Node



signal saved(slot: int)
signal loaded(slot: int)
signal slots_changed()


const AUTOSAVE_SLOT: = 0
const MANUAL_SLOT_COUNT: = 5
const SLOT_COUNT: = 6
const SAVE_DIR: = "user://saves"
const META_PATH: = "user://saves/meta.json"
const LEGACY_PATH: = "user://save_slot0.json"
const SAVE_VERSION: = 3
const AUTOSAVE_INTERVAL_SEC: = 20.0

var session_active: bool = false
var _meta: Dictionary = {"last_slot": AUTOSAVE_SLOT, "quick_slot": 1}
var _autosave_timer: float = 0.0
var _pending_world: Dictionary = {}
var _saving: bool = false


func _ready() -> void :
	_ensure_dir()
	_load_meta()
	_migrate_legacy()
	if not GameState.period_advanced.is_connected(_on_period_advanced):
		GameState.period_advanced.connect(_on_period_advanced)
	if not GameState.day_ended.is_connected(_on_day_ended):
		GameState.day_ended.connect(_on_day_ended)


func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if session_active and not GameState.game_over:
			autosave()


func _process(delta: float) -> void :
	if not session_active or GameState.game_over:
		return
	GameState.playtime_sec += delta
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL_SEC:
		_autosave_timer = 0.0
		autosave()


func set_session_active(active: bool) -> void :
	session_active = active
	_autosave_timer = 0.0


func take_pending_world() -> Dictionary:
	var d: = _pending_world.duplicate(true)
	_pending_world.clear()
	return d


func has_pending_world() -> bool:
	return not _pending_world.is_empty()


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, clampi(slot, 0, MANUAL_SLOT_COUNT)]


func is_valid_slot(slot: int) -> bool:
	return slot >= AUTOSAVE_SLOT and slot <= MANUAL_SLOT_COUNT


func is_autosave_slot(slot: int) -> bool:
	return slot == AUTOSAVE_SLOT


func has_save(slot: int = -1) -> bool:
	if slot < 0:
		return has_any_save()
	return FileAccess.file_exists(slot_path(slot))


func has_any_save() -> bool:
	for s in range(SLOT_COUNT):
		if FileAccess.file_exists(slot_path(s)):
			return true
	return FileAccess.file_exists(LEGACY_PATH)


func last_slot() -> int:
	return int(_meta.get("last_slot", AUTOSAVE_SLOT))


func quick_slot() -> int:
	var q: = int(_meta.get("quick_slot", 1))
	return clampi(q, 1, MANUAL_SLOT_COUNT)


func most_recent_slot() -> int:
	var best: = -1
	var best_t: = -1
	for s in range(SLOT_COUNT):
		var summary: = read_slot_summary(s)
		if not bool(summary.get("exists", false)):
			continue
		var t: = int(summary.get("saved_at_unix", 0))
		if t >= best_t:
			best_t = t
			best = s
	if best >= 0:
		return best
	return last_slot()


func list_slot_summaries() -> Array:
	var out: Array = []
	for s in range(SLOT_COUNT):
		out.append(read_slot_summary(s))
	return out


func read_slot_summary(slot: int) -> Dictionary:
	var path: = slot_path(slot)
	var base: = {
		"slot": slot, 
		"exists": false, 
		"autosave": is_autosave_slot(slot), 
		"day": 0, 
		"period": "", 
		"weather": "", 
		"location_id": "", 
		"world_mode": "outdoor", 
		"saved_at_unix": 0, 
		"playtime_sec": 0.0, 
		"employer_id": "", 
		"money": 0.0, 
	}
	if not FileAccess.file_exists(path):
		return base
	var data: = _read_json(path)
	if data.is_empty():
		return base
	var world: Dictionary = data.get("world", {}) if typeof(data.get("world", {})) == TYPE_DICTIONARY else {}
	base["exists"] = true
	base["day"] = int(data.get("day", 0))
	base["period"] = str(data.get("period", ""))
	base["weather"] = str(data.get("weather", ""))
	base["location_id"] = str(data.get("location_id", ""))
	base["world_mode"] = str(world.get("mode", "outdoor"))
	base["saved_at_unix"] = int(data.get("saved_at_unix", 0))
	base["playtime_sec"] = float(data.get("playtime_sec", 0))
	base["employer_id"] = str(data.get("employer_id", ""))
	var stats: Dictionary = data.get("stats", {}) if typeof(data.get("stats", {})) == TYPE_DICTIONARY else {}
	base["money"] = float(stats.get("money", 0))
	return base


func format_slot_line(summary: Dictionary) -> String:
	if not bool(summary.get("exists", false)):
		return L10n.t("ui.save.slot_empty", "空存档")
	var period_id: = str(summary.get("period", "morning"))
	var period_name: = L10n.t("periods.%s.name" % period_id, period_id)
	var loc: = str(summary.get("location_id", ""))
	var mode: = str(summary.get("world_mode", "outdoor"))
	var place: = L10n.t("ui.save.place_outdoor", "港区街道")
	if mode == "interior" and loc != "" and loc != "dock":
		place = L10n.t("locations.%s.name" % loc, loc)
	var info: = L10n.tf(
		"ui.save.slot_info", 
		{"day": int(summary.get("day", 1)), "period": period_name}, 
		"第 %d 天 · %s" % [int(summary.get("day", 1)), period_name]
	)
	var when : = _format_saved_at(int(summary.get("saved_at_unix", 0)))
	return "%s · %s · %s" % [info, place, when ]


func slot_title(slot: int) -> String:
	if is_autosave_slot(slot):
		return L10n.t("ui.save.autosave", "自动存档")
	return L10n.tf("ui.save.slot_n", {"n": slot}, "存档 %d" % slot)



func save_game() -> bool:
	return save_to_slot(quick_slot())



func load_game() -> bool:
	return load_slot(most_recent_slot())


func autosave() -> bool:
	if _saving or GameState.game_over:
		return false
	if not session_active and not _in_main_scene():
		return false
	return save_to_slot(AUTOSAVE_SLOT, true)


func save_to_slot(slot: int, is_auto: bool = false) -> bool:
	if not is_valid_slot(slot):
		push_error("SaveSystem: bad slot %d" % slot)
		return false
	_saving = true
	_ensure_dir()
	_capture_runtime_into_state()
	var data: = build_snapshot()
	data["slot"] = slot
	data["is_autosave"] = is_auto or is_autosave_slot(slot)
	var path: = slot_path(slot)
	var ok: = _write_json(path, data)
	_saving = false
	if not ok:
		return false
	_meta["last_slot"] = slot
	if not is_autosave_slot(slot):
		_meta["quick_slot"] = slot
	_save_meta()
	saved.emit(slot)
	slots_changed.emit()
	print("SaveSystem: saved slot=%d -> %s" % [slot, path])
	return true


func load_slot(slot: int) -> bool:
	if not is_valid_slot(slot):
		push_warning("SaveSystem: bad slot %d" % slot)
		return false
	var path: = slot_path(slot)
	if not FileAccess.file_exists(path):

		if slot == AUTOSAVE_SLOT and FileAccess.file_exists(LEGACY_PATH):
			path = LEGACY_PATH
		else:
			push_warning("SaveSystem: no save at %s" % path)
			return false
	var data: = _read_json(path)
	if data.is_empty():
		push_error("SaveSystem: bad JSON %s" % path)
		return false
	GameState.apply_snapshot(data)
	NpcScheduler.apply_talk_day_snapshot(data.get("npc_talk_day", {}))
	var world: Dictionary = data.get("world", {}) if typeof(data.get("world", {})) == TYPE_DICTIONARY else {}
	_pending_world = world.duplicate(true)
	UnlockScheduler.apply_up_to_day(GameState.day)
	if str(GameState.weather).strip_edges() == "":
		WeatherSystem.apply_for_current(false)
	else:
		SfxPlayer.set_weather(GameState.weather)
	_meta["last_slot"] = slot
	if not is_autosave_slot(slot):
		_meta["quick_slot"] = slot
	_save_meta()
	_autosave_timer = 0.0
	loaded.emit(slot)
	slots_changed.emit()
	print("SaveSystem: loaded slot=%d day=%d period=%s weather=%s pos=(%s,%s)" % [
		slot, GameState.day, GameState.period, GameState.weather, 
		str(world.get("player_x", "?")), str(world.get("player_y", "?")), 
	])
	return true


func delete_slot(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	var path: = slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var err: = DirAccess.remove_absolute(path)
	if err != OK:

		var d: = DirAccess.open(SAVE_DIR)
		if d:
			err = d.remove("slot_%d.json" % slot)
	slots_changed.emit()
	return err == OK


func build_snapshot() -> Dictionary:
	var data: = GameState.to_snapshot()
	data["version"] = SAVE_VERSION
	data["saved_at_unix"] = int(Time.get_unix_time_from_system())
	data["pack_id"] = str(PackDB.pack_meta.get("id", "core"))
	data["pack_version"] = str(PackDB.pack_meta.get("version", ""))
	data["world"] = _capture_world()
	data["npc_talk_day"] = NpcScheduler.get_talk_day_snapshot()
	return data


func _capture_runtime_into_state() -> void :

	pass


func _capture_world() -> Dictionary:
	var host: = get_tree().get_first_node_in_group("world_host")
	if host != null and host.has_method("capture_world_snapshot"):
		return host.capture_world_snapshot()
	return {}


func _on_period_advanced(_day: int, _period: String) -> void :
	if session_active:
		call_deferred("autosave")


func _on_day_ended(_completed_day: int) -> void :
	if session_active:
		call_deferred("autosave")


func _in_main_scene() -> bool:
	var sc: = get_tree().current_scene
	return sc != null and str(sc.name) == "Main"


func _ensure_dir() -> void :
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _migrate_legacy() -> void :
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	if FileAccess.file_exists(slot_path(AUTOSAVE_SLOT)):
		return
	var data: = _read_json(LEGACY_PATH)
	if data.is_empty():
		return
	data["version"] = int(data.get("version", 2))
	data["slot"] = AUTOSAVE_SLOT
	data["is_autosave"] = true
	if not data.has("saved_at_unix"):
		data["saved_at_unix"] = int(Time.get_unix_time_from_system())
	_write_json(slot_path(AUTOSAVE_SLOT), data)
	_meta["last_slot"] = AUTOSAVE_SLOT
	_save_meta()
	print("SaveSystem: migrated legacy save -> autosave")


func _load_meta() -> void :
	if not FileAccess.file_exists(META_PATH):
		return
	var data: = _read_json(META_PATH)
	if data.is_empty():
		return
	_meta["last_slot"] = int(data.get("last_slot", AUTOSAVE_SLOT))
	_meta["quick_slot"] = int(data.get("quick_slot", 1))


func _save_meta() -> void :
	_ensure_dir()
	_write_json(META_PATH, _meta)


func _read_json(path: String) -> Dictionary:
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _write_json(path: String, data: Dictionary) -> bool:
	var json: = JSON.stringify(data, "\t")
	var f: = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot write %s" % path)
		return false
	f.store_string(json)
	f.close()
	return true


func _format_saved_at(unix_ts: int) -> String:
	if unix_ts <= 0:
		return L10n.t("ui.save.time_unknown", "未知时间")
	var dt: = Time.get_datetime_dict_from_unix_time(unix_ts)
	return "%02d-%02d %02d:%02d" % [
		int(dt.get("month", 0)), int(dt.get("day", 0)), 
		int(dt.get("hour", 0)), int(dt.get("minute", 0)), 
	]
