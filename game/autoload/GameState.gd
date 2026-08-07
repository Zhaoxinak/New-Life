extends Node
## Runtime game state: day / period / stats / flags / relations / location.

signal state_changed()
signal period_advanced(day: int, period: String)
signal day_ended(completed_day: int)
signal location_changed(location_id: String)
signal game_ended(ending_id: String)

const MAX_DAY := 30
const PERIODS: PackedStringArray = ["morning", "afternoon", "evening"]
const CAREER_TRACK := "hongyuan_career"

var day: int = 1
var period: String = "morning"
var location_id: String = "dock"
var stats: Dictionary = {} # id -> float
var flags: Dictionary = {} # id -> int
var relations: Dictionary = {} # "source:target:key" -> float
var unlocked_locations: Dictionary = {} # id -> true
var unlocked_hotspots: Dictionary = {} # id -> true
var event_triggers: Dictionary = {} # event_id -> count
var fired_thresholds: Dictionary = {} # threshold_id -> true
var chatter_last_day: Dictionary = {} # chatter_id -> day
var stock_profit_cum: float = 0.0
var game_over: bool = false
var active_ending_id: String = ""
var last_result_text: String = ""
var last_chatter_text: String = ""
var seen_tips: Dictionary = {} # tip_id -> true
var quest_index: int = 0
var rng_seed: int = 0
var rng := RandomNumberGenerator.new()
var _suppress_signals: bool = false


func _ready() -> void:
	if not PackDB.pack_loaded.is_connected(_on_pack_loaded):
		PackDB.pack_loaded.connect(_on_pack_loaded)
	if PackDB.loaded:
		new_game()


func _on_pack_loaded(_pack_id: String) -> void:
	new_game()


func new_game(seed_value: int = 0) -> void:
	day = 1
	period = "morning"
	location_id = "dock"
	last_result_text = ""
	last_chatter_text = ""
	stock_profit_cum = 0.0
	game_over = false
	active_ending_id = ""
	event_triggers.clear()
	fired_thresholds.clear()
	chatter_last_day.clear()
	seen_tips.clear()
	quest_index = 0
	rng_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	rng.seed = rng_seed as int
	_init_stats()
	_init_flags()
	_init_relations()
	UnlockScheduler.apply_for_new_game()
	_emit_changed()
	print("GameState: new game day=%d seed=%d" % [day, rng_seed])


func apply_snapshot(data: Dictionary) -> void:
	_suppress_signals = true
	day = int(data.get("day", 1))
	period = str(data.get("period", "morning"))
	location_id = str(data.get("location_id", "dock"))
	last_result_text = str(data.get("last_result_text", ""))
	rng_seed = int(data.get("rng_seed", rng_seed))
	rng.seed = rng_seed as int
	if data.has("rng_state"):
		rng.state = int(data.get("rng_state"))
	stats = {}
	var stats_in: Dictionary = data.get("stats", {})
	for k in stats_in.keys():
		stats[str(k)] = float(stats_in[k])
	flags = {}
	var flags_in: Dictionary = data.get("flags", {})
	for k in flags_in.keys():
		flags[str(k)] = int(flags_in[k])
	relations = {}
	var rel_in: Dictionary = data.get("relations", {})
	for k in rel_in.keys():
		relations[str(k)] = float(rel_in[k])
	unlocked_locations.clear()
	for id in data.get("unlocked_locations", []):
		unlocked_locations[str(id)] = true
	unlocked_hotspots.clear()
	for id in data.get("unlocked_hotspots", []):
		unlocked_hotspots[str(id)] = true
	event_triggers.clear()
	var et: Dictionary = data.get("event_triggers", {})
	for k in et.keys():
		event_triggers[str(k)] = int(et[k])
	fired_thresholds.clear()
	for tid in data.get("fired_thresholds", []):
		fired_thresholds[str(tid)] = true
	chatter_last_day.clear()
	var cl: Dictionary = data.get("chatter_last_day", {})
	for k in cl.keys():
		chatter_last_day[str(k)] = int(cl[k])
	stock_profit_cum = float(data.get("stock_profit_cum", 0))
	game_over = bool(data.get("game_over", false))
	active_ending_id = str(data.get("active_ending_id", ""))
	last_chatter_text = str(data.get("last_chatter_text", ""))
	seen_tips.clear()
	for tid in data.get("seen_tips", []):
		seen_tips[str(tid)] = true
	quest_index = int(data.get("quest_index", 0))
	_suppress_signals = false
	_emit_changed()
	location_changed.emit(location_id)


func _init_stats() -> void:
	stats.clear()
	for row in PackDB.get_table("stats"):
		var id := str(row.get("id", ""))
		if id.is_empty():
			continue
		stats[id] = float(row.get("initial", 0))


func _init_flags() -> void:
	flags.clear()
	for row in PackDB.get_table("flags"):
		var id := str(row.get("id", ""))
		if id.is_empty():
			continue
		flags[id] = int(row.get("default", 0))


func _init_relations() -> void:
	relations.clear()
	for row in PackDB.get_table("relations_init"):
		var key := _rel_key(str(row.get("source_id", "")), str(row.get("target_id", "")), str(row.get("relation_key", "")))
		relations[key] = float(row.get("initial", 0))


func _rel_key(source_id: String, target_id: String, relation_key: String) -> String:
	return "%s:%s:%s" % [source_id, target_id, relation_key]


func _emit_changed() -> void:
	if not _suppress_signals:
		state_changed.emit()


func get_stat(stat_id: String, default_value: float = 0.0) -> float:
	return float(stats.get(stat_id, default_value))


func set_stat(stat_id: String, value: float) -> void:
	var row := PackDB.get_row("stats", stat_id)
	var lo := float(row.get("min", -999999)) if not row.is_empty() else -999999.0
	var hi := float(row.get("max", 999999)) if not row.is_empty() else 999999.0
	stats[stat_id] = clampf(value, lo, hi)
	_emit_changed()


func add_stat(stat_id: String, delta: float) -> void:
	set_stat(stat_id, get_stat(stat_id) + delta)


func get_flag(flag_id: String, default_value: int = 0) -> int:
	return int(flags.get(flag_id, default_value))


func set_flag(flag_id: String, value: int) -> void:
	flags[flag_id] = value
	_emit_changed()


func get_relation(source_id: String, target_id: String, relation_key: String, default_value: float = 0.0) -> float:
	return float(relations.get(_rel_key(source_id, target_id, relation_key), default_value))


func set_relation(source_id: String, target_id: String, relation_key: String, value: float) -> void:
	var key := _rel_key(source_id, target_id, relation_key)
	var lo := 0.0
	var hi := 100.0
	for row in PackDB.get_table("relations_init"):
		if str(row.get("source_id", "")) == source_id \
				and str(row.get("target_id", "")) == target_id \
				and str(row.get("relation_key", "")) == relation_key:
			lo = float(row.get("min", 0))
			hi = float(row.get("max", 100))
			break
	relations[key] = clampf(value, lo, hi)
	_emit_changed()


func add_relation(source_id: String, target_id: String, relation_key: String, delta: float) -> void:
	set_relation(source_id, target_id, relation_key, get_relation(source_id, target_id, relation_key) + delta)


func get_rank_id(track_id: String = CAREER_TRACK) -> String:
	var track := PackDB.get_row("rank_tracks", track_id)
	var stat_id := str(track.get("stat_id", "trust")) if not track.is_empty() else "trust"
	var v := get_stat(stat_id)
	var best_id := ""
	var best_order := -1
	for row in PackDB.get_table("ranks"):
		if str(row.get("track_id", "")) != track_id:
			continue
		var lo := float(row.get("stat_min", 0))
		var hi := float(row.get("stat_max", 100))
		if v >= lo and v <= hi:
			var order := int(row.get("sort_order", 0))
			if order > best_order:
				best_order = order
				best_id = str(row.get("id", ""))
	return best_id


func get_rank_sort_order(track_id: String = CAREER_TRACK) -> int:
	var rid := get_rank_id(track_id)
	if rid.is_empty():
		return 0
	var row := PackDB.get_row("ranks", rid)
	return int(row.get("sort_order", 0))


func is_location_unlocked(id: String) -> bool:
	return unlocked_locations.get(id, false) == true


func is_hotspot_unlocked(id: String) -> bool:
	return unlocked_hotspots.get(id, false) == true


func set_location(id: String) -> bool:
	if not is_location_unlocked(id):
		return false
	location_id = id
	location_changed.emit(location_id)
	_emit_changed()
	return true


func advance_period() -> void:
	var idx := PERIODS.find(period)
	if idx < 0:
		idx = 0
	if idx >= PERIODS.size() - 1:
		var completed := day
		day_ended.emit(completed)
		day = mini(day + 1, MAX_DAY)
		period = PERIODS[0]
		UnlockScheduler.apply_day(day)
	else:
		period = PERIODS[idx + 1]
	period_advanced.emit(day, period)
	_emit_changed()


func period_matches(allowed: String) -> bool:
	var a := allowed.strip_edges()
	if a.is_empty() or a == "any":
		return true
	for p in a.split("|", false):
		if p.strip_edges() == period:
			return true
	return false


func mark_ending(ending_id: String) -> void:
	game_over = true
	active_ending_id = ending_id
	game_ended.emit(ending_id)
	_emit_changed()
