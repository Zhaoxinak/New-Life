extends Node
## 运行库（存档权威）。定义永不写入本对象。

const SLOTS: PackedStringArray = [
	"morning", "noon", "afternoon", "evening", "late_night"
]

const SCHEMA_VERSION := "0.1"

var meta: Dictionary = {}
var stats: Dictionary = {}
var edges: Dictionary = {} ## "from|to" -> {score, suspicion, trust, fear, debt, leverage}
var meters: Dictionary = {}
var flags: Dictionary = {}
var grudges: Dictionary = {} ## grudge_id -> {status, debtor, buried_by}
var clues: Dictionary = {}
var items: Dictionary = {}
var debts: Dictionary = {}
var orgs: Dictionary = {} ## org_id -> {fields...}
var dialog_seen: Dictionary = {}
var queue: Array = [] ## pending event ids
var history: Array = [] ## 履历 [{day,slot,kind,ref,summary_key,payload}]
var temps: Dictionary = {} ## 仅当前时段
var active: bool = false
var ended: bool = false
var end_reason: String = ""


func is_running() -> bool:
	return active and not ended


func new_game() -> void:
	if not PackDB.loaded:
		push_error("RunState.new_game: PackDB not loaded")
		return

	meta = {
		"slot_id": 0,
		"schema_version": SCHEMA_VERSION,
		"content_version": PackDB.content_version(),
		"pack_id": PackDB.pack_id,
		"day": 1,
		"slot": "morning",
		"player_rank": "apprentice",
		"rng_seed": randi(),
		"playtime_sec": 0,
		"last_act_id": "",
		"current_loc": "loc_01",
	}
	stats.clear()
	edges.clear()
	meters.clear()
	flags.clear()
	grudges.clear()
	clues.clear()
	items.clear()
	debts.clear()
	orgs.clear()
	dialog_seen.clear()
	queue.clear()
	history.clear()
	temps.clear()
	ended = false
	end_reason = ""
	active = true

	for row in PackDB.get_rows("def_stat"):
		var sid: String = String(row.get("stat_id", ""))
		if sid.is_empty():
			continue
		stats[sid] = row.get("initial", 0)

	for row in PackDB.get_rows("def_edge_init"):
		var from_id: String = String(row.get("from", ""))
		var to_id: String = String(row.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			continue
		_ensure_edge(from_id, to_id)
		var e: Dictionary = edges[_edge_key(from_id, to_id)]
		for k in ["score", "suspicion", "trust", "fear"]:
			if row.has(k):
				e[k] = row[k]
		if row.has("debt"):
			e["debt"] = row["debt"]
		if row.has("leverage"):
			e["leverage"] = row["leverage"]

	for row in PackDB.get_rows("def_grudge"):
		var gid: String = String(row.get("grudge_id", ""))
		if gid.is_empty():
			continue
		grudges[gid] = {
			"status": String(row.get("initial_status", "latent")),
			"debtor": String(row.get("debtor", "")),
			"buried_by": "",
		}

	var meter_init: Dictionary = PackDB.get_table_dict("def_meter_init")
	for mid in meter_init.keys():
		meters[String(mid)] = float(meter_init[mid])

	for row in PackDB.get_rows("def_org_init"):
		var oid := String(row.get("org_id", ""))
		if oid.is_empty():
			continue
		var org: Dictionary = row.duplicate(true)
		org.erase("org_id")
		org.erase("loc_key")
		orgs[oid] = org

	DomainBus.slot_changed.emit(int(meta["day"]), String(meta["slot"]))
	DomainBus.emit_domain("new_game", {"day": meta["day"]})


func snapshot() -> Dictionary:
	return {
		"meta": meta.duplicate(true),
		"stats": stats.duplicate(true),
		"edges": edges.duplicate(true),
		"meters": meters.duplicate(true),
		"flags": flags.duplicate(true),
		"grudges": grudges.duplicate(true),
		"clues": clues.duplicate(true),
		"items": items.duplicate(true),
		"debts": debts.duplicate(true),
		"orgs": orgs.duplicate(true),
		"dialog_seen": dialog_seen.duplicate(true),
		"queue": queue.duplicate(true),
		"history": history.duplicate(true),
		"ended": ended,
		"end_reason": end_reason,
	}


func apply_snapshot(data: Dictionary) -> void:
	meta = data.get("meta", {}).duplicate(true)
	stats = data.get("stats", {}).duplicate(true)
	edges = data.get("edges", {}).duplicate(true)
	meters = data.get("meters", {}).duplicate(true)
	flags = data.get("flags", {}).duplicate(true)
	grudges = data.get("grudges", {}).duplicate(true)
	clues = data.get("clues", {}).duplicate(true)
	items = data.get("items", {}).duplicate(true)
	debts = data.get("debts", {}).duplicate(true)
	orgs = data.get("orgs", {}).duplicate(true)
	dialog_seen = data.get("dialog_seen", {}).duplicate(true)
	queue = data.get("queue", []).duplicate(true)
	history = data.get("history", []).duplicate(true)
	ended = bool(data.get("ended", false))
	end_reason = String(data.get("end_reason", ""))
	temps.clear()
	active = true
	if history.is_empty():
		backfill_history_from_flags()
	DomainBus.slot_changed.emit(day(), slot())


func day() -> int:
	return int(meta.get("day", 1))


func slot() -> String:
	return String(meta.get("slot", "morning"))


func player_rank() -> String:
	return String(meta.get("player_rank", "apprentice"))


func set_player_rank(rank: String) -> void:
	var old := player_rank()
	if old == rank:
		return
	meta["player_rank"] = rank
	DomainBus.rank_changed.emit(old, rank)


func get_stat(stat_id: String, default_value: Variant = 0) -> Variant:
	return stats.get(stat_id, default_value)


func set_stat(stat_id: String, value: Variant) -> void:
	var old: Variant = stats.get(stat_id, null)
	stats[stat_id] = value
	DomainBus.stat_changed.emit(stat_id, old, value)


func add_stat(stat_id: String, delta: float) -> void:
	var cur := float(get_stat(stat_id, 0))
	set_stat(stat_id, cur + delta)


func get_flag(flag_id: String, default_value: Variant = false) -> Variant:
	return flags.get(flag_id, default_value)


func set_flag(flag_id: String, value: Variant) -> void:
	flags[flag_id] = value
	DomainBus.flag_changed.emit(flag_id, value)
	if value and String(flag_id).begins_with("flag_ending_"):
		DomainBus.emit_domain("ending_reached", {"flag": flag_id})
		DomainBus.tip.emit(L10n.t("ui.ending_reached", "阶段性结局已达成：%s") % flag_id)
	if value and String(flag_id) in ["route_endure", "route_defect", "route_foreign"]:
		append_history("route", String(flag_id), "history.%s" % String(flag_id), {})


func clear_flag(flag_id: String) -> void:
	flags.erase(flag_id)
	DomainBus.flag_changed.emit(flag_id, false)


func set_temp(key: String, value: Variant) -> void:
	temps[key] = value


func get_temp(key: String, default_value: Variant = null) -> Variant:
	return temps.get(key, default_value)


func clear_temps() -> void:
	temps.clear()


func current_loc() -> String:
	return String(meta.get("current_loc", "loc_01"))


func set_current_loc(loc_id: String) -> void:
	meta["current_loc"] = loc_id


func mark_dialog_seen(dialog_id: String) -> void:
	dialog_seen[dialog_id] = true


func end_run(reason: String = "ended") -> void:
	ended = true
	end_reason = reason
	DomainBus.emit_domain("end_run", {"reason": reason})
	DomainBus.tip.emit(L10n.t("ui.run_ended", "本局结束：%s") % reason)


func get_meter(meter_id: String, default_value: float = 0.0) -> float:
	return float(meters.get(meter_id, default_value))


func set_meter(meter_id: String, value: float) -> void:
	var old := get_meter(meter_id)
	meters[meter_id] = value
	DomainBus.meter_changed.emit(meter_id, old, value)


func add_meter(meter_id: String, delta: float) -> void:
	set_meter(meter_id, get_meter(meter_id) + delta)


func get_edge(from_id: String, to_id: String) -> Dictionary:
	_ensure_edge(from_id, to_id)
	return edges[_edge_key(from_id, to_id)]


func set_edge_field(from_id: String, to_id: String, key: String, value: Variant) -> void:
	_ensure_edge(from_id, to_id)
	var e: Dictionary = edges[_edge_key(from_id, to_id)]
	e[key] = value
	DomainBus.edge_changed.emit(from_id, to_id, key, value)


func add_edge_field(from_id: String, to_id: String, key: String, delta: float) -> void:
	var e := get_edge(from_id, to_id)
	var cur := float(e.get(key, 0))
	set_edge_field(from_id, to_id, key, cur + delta)


func enqueue_event(event_id: String) -> void:
	queue.append(event_id)


func dequeue_event() -> String:
	if queue.is_empty():
		return ""
	return String(queue.pop_front())


func advance_slot() -> void:
	clear_temps()
	var idx := SLOTS.find(slot())
	if idx < 0:
		idx = 0
	if idx >= SLOTS.size() - 1:
		var ended_day := day()
		meta["day"] = ended_day + 1
		meta["slot"] = SLOTS[0]
		DomainBus.day_ended.emit(ended_day)
	else:
		meta["slot"] = SLOTS[idx + 1]
	DomainBus.slot_changed.emit(day(), slot())


func _edge_key(from_id: String, to_id: String) -> String:
	return "%s|%s" % [from_id, to_id]


func _ensure_edge(from_id: String, to_id: String) -> void:
	var k := _edge_key(from_id, to_id)
	if edges.has(k):
		return
	edges[k] = {
		"from": from_id,
		"to": to_id,
		"score": 0,
		"suspicion": 0,
		"trust": 0,
		"fear": 0,
		"debt": "",
		"leverage": "",
	}


func get_org(org_id: String) -> Dictionary:
	if not orgs.has(org_id):
		orgs[org_id] = {}
	return orgs[org_id]


func get_org_field(org_id: String, key: String, default: Variant = 0) -> Variant:
	return get_org(org_id).get(key, default)


func set_org_field(org_id: String, key: String, value: Variant) -> void:
	var o := get_org(org_id)
	var old: Variant = o.get(key, 0)
	o[key] = value
	DomainBus.org_changed.emit(org_id, key, old, value)


func add_org_field(org_id: String, key: String, delta: float) -> void:
	set_org_field(org_id, key, float(get_org_field(org_id, key, 0)) + delta)


func append_history(kind: String, ref: String, summary_key: String, payload: Dictionary = {}) -> void:
	history.append({
		"day": day(),
		"slot": slot(),
		"kind": kind,
		"ref": ref,
		"summary_key": summary_key,
		"payload": payload.duplicate(true),
	})


func backfill_history_from_flags() -> void:
	## 旧档无履历时，用 seen_event_* 回填标题级条目。
	for k in flags.keys():
		var fk := String(k)
		if not fk.begins_with("seen_event_"):
			continue
		if not bool(flags[k]):
			continue
		var eid := fk.substr("seen_event_".length())
		var exists := false
		for e in history:
			if typeof(e) == TYPE_DICTIONARY and String(e.get("ref", "")) == eid:
				exists = true
				break
		if exists:
			continue
		var erow: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		history.append({
			"day": int(meta.get("day", 1)),
			"slot": String(meta.get("slot", "morning")),
			"kind": "event",
			"ref": eid,
			"summary_key": String(erow.get("loc_key", eid)),
			"payload": {"backfill": true},
		})
