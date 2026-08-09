extends Node




func apply_for_new_game() -> void :
	GameState.unlocked_locations.clear()
	GameState.unlocked_hotspots.clear()
	ensure_start_unlocked()
	apply_up_to_day(GameState.day)



func ensure_start_unlocked() -> void :
	for row in PackDB.get_table("locations"):
		var id: = str(row.get("id", ""))
		if id.is_empty():
			continue
		if str(row.get("start_unlocked", "0")) == "1":
			GameState.unlocked_locations[id] = true
	for row in PackDB.get_table("hotspots"):
		var id: = str(row.get("id", ""))
		if id.is_empty():
			continue
		if str(row.get("start_unlocked", "0")) == "1":
			GameState.unlocked_hotspots[id] = true


func apply_up_to_day(day: int) -> void :
	ensure_start_unlocked()
	for d in range(1, day + 1):
		_apply_day(d)
	GameState.state_changed.emit()


func apply_day(day: int) -> void :
	_apply_day(day)
	GameState.state_changed.emit()


func _apply_day(day: int) -> void :
	for row in PackDB.get_unlocks_for_day(day):
		var unlock_type: = str(row.get("unlock_type", ""))
		var unlock_id: = str(row.get("unlock_id", ""))
		match unlock_type:
			"location":
				GameState.unlocked_locations[unlock_id] = true
			"hotspot":
				GameState.unlocked_hotspots[unlock_id] = true
			"flag":
				GameState.set_flag(unlock_id, 1)
			_:
				push_warning("UnlockScheduler: unknown unlock_type '%s'" % unlock_type)


func schedule_day_for(unlock_type: String, unlock_id: String) -> int:

	var best: = 0
	for row in PackDB.get_table("unlock_schedule"):
		if str(row.get("enabled", "1")) == "0":
			continue
		if str(row.get("unlock_type", "")) != unlock_type:
			continue
		if str(row.get("unlock_id", "")) != unlock_id:
			continue
		var d: = int(row.get("day", 0))
		if d <= 0:
			continue
		if best == 0 or d < best:
			best = d
	return best


func is_start_unlocked(unlock_type: String, unlock_id: String) -> bool:
	var table: = "locations" if unlock_type == "location" else "hotspots"
	if unlock_type != "location" and unlock_type != "hotspot":
		return false
	var row: = PackDB.get_row(table, unlock_id)
	return str(row.get("start_unlocked", "0")) == "1"


func pending_reason(unlock_type: String, unlock_id: String) -> String:

	if unlock_type == "location" and GameState.is_location_unlocked(unlock_id):
		return ""
	if unlock_type == "hotspot" and GameState.is_hotspot_unlocked(unlock_id):
		return ""
	var key: = "unlock.%s.%s" % [unlock_type, unlock_id]
	var custom: = L10n.t(key, "")
	if custom != "" and custom != key:
		return custom
	var day: = schedule_day_for(unlock_type, unlock_id)
	if day > 0:
		if GameState.day < day:
			return L10n.tf("ui.unlock.day", {"day": day}, "第%d天开放" % day)

		return L10n.tf("ui.unlock.day_ready", {"day": day}, "第%d天起开放（推进日程）" % day)
	if is_start_unlocked(unlock_type, unlock_id):
		return L10n.t("ui.action.locked", "尚未解锁")
	return L10n.t("ui.unlock.story", "完成相关剧情后开放")


func location_sign_text(location_id: String) -> String:
	var name: = L10n.t("locations.%s.name" % location_id, location_id)
	if location_id == "home":
		var tier: = clampi(int(GameState.get_stat("home_tier")), 1, 4)
		name = L10n.t("locations.home.t%d" % tier, name)
	if GameState.is_location_unlocked(location_id):
		return name
	var reason: = pending_reason("location", location_id)
	if reason == "":
		return name
	return "%s · %s" % [name, reason]


func hotspot_button_text(hotspot_id: String, base_name: String = "") -> String:
	var name: = base_name if base_name != "" else L10n.t("hotspots.%s.name" % hotspot_id, hotspot_id)
	if GameState.is_hotspot_unlocked(hotspot_id):
		return name
	var reason: = pending_reason("hotspot", hotspot_id)
	if reason == "":
		return name
	return "%s（%s）" % [name, reason]
