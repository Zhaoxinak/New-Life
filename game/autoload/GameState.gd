extends Node


signal state_changed()
signal period_advanced(day: int, period: String)
signal day_ended(completed_day: int)
signal location_changed(location_id: String)
signal game_ended(ending_id: String)
signal weather_changed(weather_id: String)
signal relation_changed(source_id: String, target_id: String, relation_key: String, old_value: float, new_value: float)
signal flag_changed(flag_id: String, old_value: int, new_value: int)

const MAX_DAY: = 30

const PERIODS: PackedStringArray = ["morning", "afternoon", "evening"]
const CAREER_TRACK: = "hongyuan_career"
const EMPLOYER_HONGYUAN: = "hongyuan"
const EMPLOYER_TONGYANG: = "tongyang"
const EMPLOYER_NONE: = "none"
const TRACK_TONGYANG: = "tongyang_career"

var day: int = 1
var period: String = "morning"
var weather: String = ""
var location_id: String = "dock"

var employer_id: String = EMPLOYER_HONGYUAN

var active_career_track: String = CAREER_TRACK
var stats: Dictionary = {}
var flags: Dictionary = {}
var relations: Dictionary = {}

var npc_traits: Dictionary = {}
var unlocked_locations: Dictionary = {}
var unlocked_hotspots: Dictionary = {}
var event_triggers: Dictionary = {}
var fired_thresholds: Dictionary = {}
var fired_npc_beats: Dictionary = {}
var chatter_last_day: Dictionary = {}
var stock_profit_cum: float = 0.0
var game_over: bool = false
var active_ending_id: String = ""
var last_result_text: String = ""
var last_chatter_text: String = ""
var seen_tips: Dictionary = {}

var action_uses: Dictionary = {}

var relation_log: Array = []
var quest_index: int = 0

var quest_pinned: bool = true
var rng_seed: int = 0
var rng: = RandomNumberGenerator.new()

var playtime_sec: float = 0.0
var _suppress_signals: bool = false
var _syncing_employer: bool = false


func _ready() -> void :
	if not PackDB.pack_loaded.is_connected(_on_pack_loaded):
		PackDB.pack_loaded.connect(_on_pack_loaded)
	if PackDB.loaded:
		new_game()


func _on_pack_loaded(_pack_id: String) -> void :
	new_game()


func new_game(seed_value: int = 0) -> void :
	day = 1
	period = "morning"
	weather = ""
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
	action_uses.clear()
	relation_log.clear()
	fired_npc_beats.clear()
	npc_traits.clear()
	quest_index = 0
	quest_pinned = true
	playtime_sec = 0.0
	employer_id = EMPLOYER_HONGYUAN
	active_career_track = CAREER_TRACK
	rng_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	rng.seed = rng_seed as int
	_init_stats()
	_init_flags()
	_init_relations()
	_init_npc_traits()
	UnlockScheduler.apply_for_new_game()
	if NpcScheduler.has_method("clear_runtime"):
		NpcScheduler.clear_runtime()
	if WorldClock:
		WorldClock.reset_for_new_day_start()
	_emit_changed()
	print("GameState: new game day=%d seed=%d" % [day, rng_seed])


func to_snapshot() -> Dictionary:
	return {
		"day": day, 
		"period": period, 
		"weather": weather, 
		"location_id": location_id, 
		"stats": stats.duplicate(true), 
		"flags": flags.duplicate(true), 
		"relations": relations.duplicate(true), 
		"npc_traits": npc_traits.duplicate(true), 
		"unlocked_locations": unlocked_locations.keys(), 
		"unlocked_hotspots": unlocked_hotspots.keys(), 
		"event_triggers": event_triggers.duplicate(true), 
		"fired_thresholds": fired_thresholds.keys(), 
		"fired_npc_beats": fired_npc_beats.keys(), 
		"chatter_last_day": chatter_last_day.duplicate(true), 
		"stock_profit_cum": stock_profit_cum, 
		"game_over": game_over, 
		"active_ending_id": active_ending_id, 
		"last_result_text": last_result_text, 
		"last_chatter_text": last_chatter_text, 
		"seen_tips": seen_tips.keys(), 
		"action_uses": action_uses.duplicate(true), 
		"relation_log": relation_log.duplicate(true), 
		"quest_index": quest_index, 
		"quest_pinned": quest_pinned, 
		"employer_id": employer_id, 
		"active_career_track": active_career_track, 
		"rng_seed": rng_seed, 
		"rng_state": rng.state, 
		"playtime_sec": playtime_sec, 
		"world_window_minute": WorldClock.window_minute if WorldClock else 0.0, 
		"time_speed": WorldClock.time_speed if WorldClock else 1.0, 
	}


func apply_snapshot(data: Dictionary) -> void :
	_suppress_signals = true
	day = int(data.get("day", 1))
	period = str(data.get("period", "morning"))
	weather = str(data.get("weather", ""))
	location_id = str(data.get("location_id", "dock"))
	last_result_text = str(data.get("last_result_text", ""))
	rng_seed = int(data.get("rng_seed", rng_seed))
	rng.seed = rng_seed as int
	if WorldClock:
		var win: = float(data.get("world_window_minute", 0.0))
		var spd: = float(data.get("time_speed", 1.0))
		## Legacy saves: map period bucket onto window start.
		if not data.has("world_window_minute"):
			match period:
				"afternoon":
					win = float(6 * 60)
				"evening":
					win = float(12 * 60)
				_:
					win = 0.0
		WorldClock.load_state(win, spd)
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
	npc_traits = {}
	var nt_in: Dictionary = data.get("npc_traits", {})
	for k in nt_in.keys():
		npc_traits[str(k)] = float(nt_in[k])
	if npc_traits.is_empty():
		_init_npc_traits()
	fired_npc_beats.clear()
	for bid in data.get("fired_npc_beats", []):
		fired_npc_beats[str(bid)] = true
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
	action_uses.clear()
	var au: Dictionary = data.get("action_uses", {})
	for k in au.keys():
		var row: Variant = au[k]
		if typeof(row) == TYPE_DICTIONARY:
			action_uses[str(k)] = {
				"day": int(row.get("day", 0)), 
				"count": int(row.get("count", 0)), 
				"last_day": int(row.get("last_day", 0)), 
			}
	quest_index = int(data.get("quest_index", 0))
	quest_pinned = bool(data.get("quest_pinned", true))
	relation_log.clear()
	var log_in: Array = data.get("relation_log", [])
	for entry in log_in:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = entry
		relation_log.append({
			"day": int(e.get("day", 1)), 
			"period": str(e.get("period", "")), 
			"npc_id": str(e.get("npc_id", "")), 
			"other_id": str(e.get("other_id", "")), 
			"kind": str(e.get("kind", "")), 
			"text_key": str(e.get("text_key", "")), 
			"params": e.get("params", {}) if typeof(e.get("params", {})) == TYPE_DICTIONARY else {}, 
		})
	if data.has("employer_id"):
		employer_id = str(data.get("employer_id", EMPLOYER_HONGYUAN))
		active_career_track = str(data.get("active_career_track", CAREER_TRACK))
	else:

		if int(flags.get("joined_tongyang", 0)) != 0:
			employer_id = EMPLOYER_TONGYANG
			active_career_track = TRACK_TONGYANG
		elif int(flags.get("hongyuan_fired", 0)) != 0 or int(flags.get("resigned_hongyuan", 0)) != 0:
			employer_id = EMPLOYER_NONE
			active_career_track = ""
		else:
			employer_id = EMPLOYER_HONGYUAN
			active_career_track = CAREER_TRACK
	playtime_sec = float(data.get("playtime_sec", 0.0))
	_sync_employer_flags()
	_suppress_signals = false
	_emit_changed()
	location_changed.emit(location_id)


func _init_stats() -> void :
	stats.clear()
	for row in PackDB.get_table("stats"):
		var id: = str(row.get("id", ""))
		if id.is_empty():
			continue
		stats[id] = float(row.get("initial", 0))


func _init_flags() -> void :
	flags.clear()
	for row in PackDB.get_table("flags"):
		var id: = str(row.get("id", ""))
		if id.is_empty():
			continue
		flags[id] = int(row.get("default", 0))


func _init_relations() -> void :
	relations.clear()
	for row in PackDB.get_table("relations_init"):
		var key: = _rel_key(str(row.get("source_id", "")), str(row.get("target_id", "")), str(row.get("relation_key", "")))
		relations[key] = float(row.get("initial", 0))


func _init_npc_traits() -> void :
	npc_traits.clear()
	for row in PackDB.get_table("npc_traits"):
		var nid: = str(row.get("id", ""))
		if nid == "":
			continue
		for trait_id in ["influence", "nerve", "gossip", "temper", "means"]:
			npc_traits["%s:%s" % [nid, trait_id]] = float(row.get(trait_id, 0))


func _rel_key(source_id: String, target_id: String, relation_key: String) -> String:
	return "%s:%s:%s" % [source_id, target_id, relation_key]


func get_npc_trait(npc_id: String, trait_id: String, default_value: float = 0.0) -> float:
	return float(npc_traits.get("%s:%s" % [npc_id, trait_id], default_value))


func set_npc_trait(npc_id: String, trait_id: String, value: float) -> void :
	npc_traits["%s:%s" % [npc_id, trait_id]] = clampf(value, 0.0, 100.0)
	_emit_changed()


func add_npc_trait(npc_id: String, trait_id: String, delta: float) -> void :
	set_npc_trait(npc_id, trait_id, get_npc_trait(npc_id, trait_id) + delta)


func get_npc_faction(npc_id: String) -> String:
	var row: = PackDB.get_row("npc_traits", npc_id)
	if row.is_empty():
		return ""
	return str(row.get("faction", ""))


func list_npc_web(npc_id: String) -> Array:

	var out: Array = []
	var seen: Dictionary = {}
	for row in PackDB.get_table("relations_init"):
		var src: = str(row.get("source_id", ""))
		var tgt: = str(row.get("target_id", ""))
		var key: = str(row.get("relation_key", ""))
		if src == "player" or tgt == "player":
			continue
		if src != npc_id and tgt != npc_id:
			continue
		var other: = tgt if src == npc_id else src
		var sk: = "%s|%s|%s" % [src, tgt, key]
		if seen.has(sk):
			continue
		seen[sk] = true
		out.append({
			"source_id": src, 
			"target_id": tgt, 
			"other_id": other, 
			"relation_key": key, 
			"value": get_relation(src, tgt, key), 
		})
	return out


func _emit_changed() -> void :
	if not _suppress_signals:
		state_changed.emit()


func get_stat(stat_id: String, default_value: float = 0.0) -> float:
	return float(stats.get(stat_id, default_value))


func set_stat(stat_id: String, value: float) -> void :
	var row: = PackDB.get_row("stats", stat_id)
	var lo: = float(row.get("min", -999999)) if not row.is_empty() else -999999.0
	var hi: = float(row.get("max", 999999)) if not row.is_empty() else 999999.0
	stats[stat_id] = clampf(value, lo, hi)
	_emit_changed()


func add_stat(stat_id: String, delta: float) -> void :
	set_stat(stat_id, get_stat(stat_id) + delta)


func get_flag(flag_id: String, default_value: int = 0) -> int:
	return int(flags.get(flag_id, default_value))


func set_flag(flag_id: String, value: int) -> void :
	var old: = int(flags.get(flag_id, 0))
	flags[flag_id] = value
	if old != value and not _suppress_signals:
		flag_changed.emit(flag_id, old, value)

	if flag_id == "joined_tongyang" and not _syncing_employer and old != value:
		_syncing_employer = true
		if value != 0 and employer_id != EMPLOYER_TONGYANG:
			employer_id = EMPLOYER_TONGYANG
			active_career_track = TRACK_TONGYANG
		elif value == 0 and employer_id == EMPLOYER_TONGYANG:
			employer_id = EMPLOYER_NONE
			active_career_track = ""
		_syncing_employer = false
	_emit_changed()


func get_relation(source_id: String, target_id: String, relation_key: String, default_value: float = 0.0) -> float:
	return float(relations.get(_rel_key(source_id, target_id, relation_key), default_value))


func set_relation(source_id: String, target_id: String, relation_key: String, value: float) -> void :
	var key: = _rel_key(source_id, target_id, relation_key)
	var lo: = 0.0
	var hi: = 100.0
	for row in PackDB.get_table("relations_init"):
		if str(row.get("source_id", "")) == source_id\
		and str(row.get("target_id", "")) == target_id\
		and str(row.get("relation_key", "")) == relation_key:
			lo = float(row.get("min", 0))
			hi = float(row.get("max", 100))
			break
	var old: = float(relations.get(key, 0.0))
	var new_v: = clampf(value, lo, hi)
	relations[key] = new_v
	if absf(old - new_v) > 0.001 and not _suppress_signals:
		relation_changed.emit(source_id, target_id, relation_key, old, new_v)
	_emit_changed()


func append_relation_log(entry: Dictionary) -> void :
	relation_log.append(entry)
	if relation_log.size() > 200:
		relation_log = relation_log.slice(relation_log.size() - 200)
	_emit_changed()


func get_relation_log_for(npc_id: String) -> Array:
	var out: Array = []
	for e in relation_log:
		if str(e.get("npc_id", "")) == npc_id or str(e.get("other_id", "")) == npc_id:
			out.append(e)
	out.reverse()
	return out


func add_relation(source_id: String, target_id: String, relation_key: String, delta: float) -> void :
	set_relation(source_id, target_id, relation_key, get_relation(source_id, target_id, relation_key) + delta)


func set_employer(id: String) -> void :
	var next: = id.strip_edges()
	if next.is_empty():
		next = EMPLOYER_NONE
	if next != EMPLOYER_HONGYUAN and next != EMPLOYER_TONGYANG and next != EMPLOYER_NONE:
		push_warning("GameState: unknown employer '%s'" % next)
		next = EMPLOYER_NONE
	employer_id = next
	match employer_id:
		EMPLOYER_HONGYUAN:
			active_career_track = CAREER_TRACK
		EMPLOYER_TONGYANG:
			active_career_track = TRACK_TONGYANG
		_:
			active_career_track = ""
	_sync_employer_flags()
	_emit_changed()


func _sync_employer_flags() -> void :
	if _syncing_employer:
		return
	_syncing_employer = true
	var want_ty: = 1 if employer_id == EMPLOYER_TONGYANG else 0
	if int(flags.get("joined_tongyang", 0)) != want_ty:
		flags["joined_tongyang"] = want_ty
		if not _suppress_signals:
			flag_changed.emit("joined_tongyang", 1 - want_ty, want_ty)
	_syncing_employer = false


func is_employed_at(id: String) -> bool:
	return employer_id == id


func get_rank_id(track_id: String = "") -> String:
	var tid: = track_id if track_id != "" else active_career_track
	if tid.is_empty():
		return ""
	var track: = PackDB.get_row("rank_tracks", tid)
	var stat_id: = str(track.get("stat_id", "trust")) if not track.is_empty() else "trust"
	var v: = get_stat(stat_id)
	var best_id: = ""
	var best_order: = -1
	for row in PackDB.get_table("ranks"):
		if str(row.get("track_id", "")) != tid:
			continue
		var lo: = float(row.get("stat_min", 0))
		var hi: = float(row.get("stat_max", 100))
		if v >= lo and v <= hi:
			var order: = int(row.get("sort_order", 0))
			if order > best_order:
				best_order = order
				best_id = str(row.get("id", ""))
	return best_id


func get_rank_sort_order(track_id: String = "") -> int:
	var tid: = track_id if track_id != "" else active_career_track
	var rid: = get_rank_id(tid)
	if rid.is_empty():
		return 0
	var row: = PackDB.get_row("ranks", rid)
	return int(row.get("sort_order", 0))



func get_next_rank_info() -> Dictionary:
	var tid: = active_career_track
	if tid.is_empty():
		return {}
	var track: = PackDB.get_row("rank_tracks", tid)
	var stat_id: = str(track.get("stat_id", "trust")) if not track.is_empty() else "trust"
	var cur_order: = get_rank_sort_order(tid)
	var best: Dictionary = {}
	var best_order: = 999
	for row in PackDB.get_table("ranks"):
		if str(row.get("track_id", "")) != tid:
			continue
		var order: = int(row.get("sort_order", 0))
		if order <= cur_order:
			continue
		if order < best_order:
			best_order = order
			best = row
	if best.is_empty():
		return {}
	return {
		"rank_id": str(best.get("id", "")), 
		"stat_id": stat_id, 
		"need_stat": float(best.get("stat_min", 0)), 
		"current": get_stat(stat_id), 
	}


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


func advance_period() -> void :
	## Legacy/debug: snap to next period (or sleep at end of evening window).
	if WorldClock:
		WorldClock.advance_to_next_period()
		_emit_changed()
		return
	var idx: = PERIODS.find(period)
	if idx < 0:
		idx = 0
	if idx >= PERIODS.size() - 1:
		var completed: = day
		day_ended.emit(completed)
		day = mini(day + 1, MAX_DAY)
		period = PERIODS[0]

		if get_flag("divorce_snooze") != 0:
			set_flag("divorce_snooze", 0)
		UnlockScheduler.apply_day(day)
	else:
		period = PERIODS[idx + 1]
	period_advanced.emit(day, period)
	_emit_changed()


func period_matches(allowed: String) -> bool:
	var a: = allowed.strip_edges()
	if a.is_empty() or a == "any":
		return true
	for p in a.split("|", false):
		if p.strip_edges() == period:
			return true
	return false


func set_weather(weather_id: String) -> void :
	var wid: = weather_id.strip_edges()
	if wid == "":
		return
	if weather == wid:
		return
	weather = wid
	weather_changed.emit(weather)
	_emit_changed()


func mark_ending(ending_id: String) -> void :
	game_over = true
	active_ending_id = ending_id
	game_ended.emit(ending_id)
	_emit_changed()


func get_action_use_entry(action_id: String) -> Dictionary:
	var e: Variant = action_uses.get(action_id, {})
	if typeof(e) != TYPE_DICTIONARY:
		return {"day": 0, "count": 0, "last_day": 0}
	return {
		"day": int(e.get("day", 0)), 
		"count": int(e.get("count", 0)), 
		"last_day": int(e.get("last_day", 0)), 
	}


func uses_today(action_id: String) -> int:
	var e: = get_action_use_entry(action_id)
	if int(e.get("day", 0)) != day:
		return 0
	return int(e.get("count", 0))


func mark_action_used(action_id: String) -> void :
	var e: = get_action_use_entry(action_id)
	var count: = int(e.get("count", 0))
	if int(e.get("day", 0)) != day:
		count = 0
	action_uses[action_id] = {
		"day": day, 
		"count": count + 1, 
		"last_day": day, 
	}
