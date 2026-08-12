extends Node
## 存档 = 运行库快照。多槽落盘到 user://saves。

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 6
const FORMAT := "anchao_save"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))


func slot_path(slot_id: int) -> String:
	return SAVE_DIR.path_join("slot_%d.json" % slot_id)


func save_slot(slot_id: int) -> bool:
	if not RunState.is_running():
		push_error("SaveSystem: no active run")
		DomainBus.tip.emit(L10n.t("ui.save_no_run", "当前没有进行中的一局"))
		return false
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		push_error("SaveSystem: bad slot %d" % slot_id)
		return false

	RunState.meta["slot_id"] = slot_id
	var snap: Dictionary = RunState.snapshot()
	var payload := {
		"format": FORMAT,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"summary": _make_summary(snap),
		"run": snap,
	}
	var path: String = slot_path(slot_id)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot write %s err=%s" % [path, FileAccess.get_open_error()])
		DomainBus.tip.emit(L10n.t("ui.save_fail", "存档失败"))
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.flush()
	f.close()
	if not FileAccess.file_exists(path):
		DomainBus.tip.emit(L10n.t("ui.save_fail", "存档失败"))
		return false
	DomainBus.tip.emit(L10n.t("ui.save_ok_slot", "已存入槽位 %d") % (slot_id + 1))
	DomainBus.emit_domain("save", {"slot_id": slot_id, "path": path})
	return true


func load_slot(slot_id: int) -> bool:
	var path: String = slot_path(slot_id)
	if not FileAccess.file_exists(path):
		DomainBus.tip.emit(L10n.t("ui.load_empty", "该槽位没有存档"))
		return false
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		DomainBus.tip.emit(L10n.t("ui.load_fail", "读档失败"))
		return false
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveSystem: corrupt save")
		DomainBus.tip.emit(L10n.t("ui.load_fail", "读档失败"))
		return false
	var parsed_dict: Dictionary = parsed as Dictionary
	var run: Variant = parsed_dict.get("run", {})
	if typeof(run) != TYPE_DICTIONARY:
		push_error("SaveSystem: missing run")
		DomainBus.tip.emit(L10n.t("ui.load_fail", "读档失败"))
		return false
	var run_dict: Dictionary = run as Dictionary
	var meta: Dictionary = run_dict.get("meta", {}) as Dictionary
	if String(meta.get("schema_version", "")) != RunState.SCHEMA_VERSION:
		push_warning("SaveSystem: schema mismatch %s vs %s" % [
			meta.get("schema_version", "?"), RunState.SCHEMA_VERSION
		])
	if DialogueRunner.has_method("force_abort"):
		DialogueRunner.force_abort()
	RunState.apply_snapshot(run_dict)
	DomainBus.tip.emit(L10n.t("ui.load_ok_slot", "已读入槽位 %d") % (slot_id + 1))
	DomainBus.emit_domain("load", {"slot_id": slot_id})
	return true


func has_slot(slot_id: int) -> bool:
	return FileAccess.file_exists(slot_path(slot_id))


func any_slot() -> bool:
	for i in range(SLOT_COUNT):
		if has_slot(i):
			return true
	return false


func peek_slot(slot_id: int) -> Dictionary:
	## 读摘要，不改运行库。空槽返回 {}。
	var path: String = slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"corrupt": true, "slot_id": slot_id}
	var d: Dictionary = parsed as Dictionary
	var summary: Variant = d.get("summary", {})
	if typeof(summary) != TYPE_DICTIONARY or (summary as Dictionary).is_empty():
		summary = _make_summary(d.get("run", {}) if typeof(d.get("run", {})) == TYPE_DICTIONARY else {})
	var out: Dictionary = (summary as Dictionary).duplicate(true)
	out["slot_id"] = slot_id
	out["saved_at"] = String(d.get("saved_at", ""))
	out["path"] = path
	out["exists"] = true
	return out


func list_slots() -> Array:
	var out: Array = []
	for i in range(SLOT_COUNT):
		var peek := peek_slot(i)
		if peek.is_empty():
			out.append({"slot_id": i, "exists": false})
		else:
			out.append(peek)
	return out


func delete_slot(slot_id: int) -> bool:
	if not has_slot(slot_id):
		return false
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot_id)))
	return err == OK


func _make_summary(snap: Variant) -> Dictionary:
	if typeof(snap) != TYPE_DICTIONARY:
		return {}
	var s: Dictionary = snap
	var meta: Dictionary = s.get("meta", {}) as Dictionary
	var stats: Dictionary = s.get("stats", {}) as Dictionary
	var day := int(meta.get("day", 1))
	var slot := String(meta.get("slot", "morning"))
	var rank := String(meta.get("player_rank", meta.get("rank", "apprentice")))
	var money = stats.get("stat_money", 0)
	var ended := bool(s.get("ended", false))
	return {
		"day": day,
		"slot": slot,
		"rank": rank,
		"money": money,
		"ended": ended,
		"loc": String(meta.get("current_loc", "loc_01")),
	}
