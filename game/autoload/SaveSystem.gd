extends Node
## JSON save / load for Demo.


const SAVE_PATH := "user://save_slot0.json"
const SAVE_VERSION := 2


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var data := {
		"version": SAVE_VERSION,
		"day": GameState.day,
		"period": GameState.period,
		"location_id": GameState.location_id,
		"stats": GameState.stats.duplicate(true),
		"flags": GameState.flags.duplicate(true),
		"relations": GameState.relations.duplicate(true),
		"unlocked_locations": GameState.unlocked_locations.keys(),
		"unlocked_hotspots": GameState.unlocked_hotspots.keys(),
		"event_triggers": GameState.event_triggers.duplicate(true),
		"fired_thresholds": GameState.fired_thresholds.keys(),
		"chatter_last_day": GameState.chatter_last_day.duplicate(true),
		"stock_profit_cum": GameState.stock_profit_cum,
		"game_over": GameState.game_over,
		"active_ending_id": GameState.active_ending_id,
		"last_result_text": GameState.last_result_text,
		"last_chatter_text": GameState.last_chatter_text,
		"seen_tips": GameState.seen_tips.keys(),
		"quest_index": GameState.quest_index,
		"rng_seed": GameState.rng_seed,
		"rng_state": GameState.rng.state,
	}
	var json := JSON.stringify(data, "\t")
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot write %s" % SAVE_PATH)
		return false
	f.store_string(json)
	f.close()
	print("SaveSystem: saved -> %s" % SAVE_PATH)
	return true


func load_game() -> bool:
	if not has_save():
		push_warning("SaveSystem: no save at %s" % SAVE_PATH)
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_error("SaveSystem: cannot read %s" % SAVE_PATH)
		return false
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveSystem: bad JSON")
		return false
	var data: Dictionary = parsed
	GameState.apply_snapshot(data)
	UnlockScheduler.apply_up_to_day(GameState.day)
	print("SaveSystem: loaded day=%d period=%s" % [GameState.day, GameState.period])
	return true
