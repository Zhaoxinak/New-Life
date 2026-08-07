extends Node
## Applies unlock_schedule + start_unlocked flags/locations/hotspots.


func apply_for_new_game() -> void:
	GameState.unlocked_locations.clear()
	GameState.unlocked_hotspots.clear()
	for row in PackDB.get_table("locations"):
		var id := str(row.get("id", ""))
		if id.is_empty():
			continue
		if str(row.get("start_unlocked", "0")) == "1":
			GameState.unlocked_locations[id] = true
	for row in PackDB.get_table("hotspots"):
		var id := str(row.get("id", ""))
		if id.is_empty():
			continue
		if str(row.get("start_unlocked", "0")) == "1":
			GameState.unlocked_hotspots[id] = true
	apply_up_to_day(GameState.day)


func apply_up_to_day(day: int) -> void:
	for d in range(1, day + 1):
		_apply_day(d)
	GameState.state_changed.emit()


func apply_day(day: int) -> void:
	_apply_day(day)
	GameState.state_changed.emit()


func _apply_day(day: int) -> void:
	for row in PackDB.get_unlocks_for_day(day):
		var unlock_type := str(row.get("unlock_type", ""))
		var unlock_id := str(row.get("unlock_id", ""))
		match unlock_type:
			"location":
				GameState.unlocked_locations[unlock_id] = true
			"hotspot":
				GameState.unlocked_hotspots[unlock_id] = true
			"flag":
				GameState.set_flag(unlock_id, 1)
			_:
				push_warning("UnlockScheduler: unknown unlock_type '%s'" % unlock_type)
