extends Node


signal quest_changed(quest_id: String, title: String, hint: String, index: int, total: int)
signal quest_advanced(completed_id: String, next_id: String)
signal quests_finished()

var _rows: Array = []
var _ready_tracking: bool = false


func _ready() -> void :
	if not PackDB.pack_loaded.is_connected(_on_pack):
		PackDB.pack_loaded.connect(_on_pack)
	if not ActionPipeline.action_resolved.is_connected(_on_action):
		ActionPipeline.action_resolved.connect(_on_action)
	if not GameState.period_advanced.is_connected(_on_period):
		GameState.period_advanced.connect(_on_period)
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)
	if not GameState.game_ended.is_connected(_on_ending):
		GameState.game_ended.connect(_on_ending)
	if PackDB.loaded:
		_reload_rows()


func _on_pack(_id: String) -> void :
	_reload_rows()


func _reload_rows() -> void :
	_rows.clear()
	for row in PackDB.get_table("quests"):
		if str(row.get("enabled", "1")) == "0":
			continue
		_rows.append(row)
	_rows.sort_custom( func(a, b): return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))


func start_or_resume() -> void :
	_ready_tracking = true
	_reload_rows()
	_sync_index_for_midgame_save()
	_skip_unavailable()
	_check_reach_day(GameState.day)
	_check_flag_quests()
	refresh_ui()


func _sync_index_for_midgame_save() -> void :

	if GameState.quest_index > 0:
		return
	if GameState.day <= 1:
		return
	var best: = 0
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		if str(row.get("complete_type", "")) != "reach_day":
			continue
		if GameState.day >= int(str(row.get("complete_param", "1"))):
			best = i + 1
	if best > 0:
		GameState.quest_index = mini(best, _rows.size())
	elif GameState.day >= 2:

		GameState.quest_index = mini(5, _rows.size())


func current_row() -> Dictionary:
	var i: = clampi(GameState.quest_index, 0, maxi(_rows.size() - 1, 0))
	if _rows.is_empty() or GameState.quest_index >= _rows.size():
		return {}
	return _rows[i]


func total() -> int:
	return _rows.size()


func is_finished() -> bool:
	return _rows.is_empty() or GameState.quest_index >= _rows.size()


func notify_near_door() -> void :
	_try("near_door", "")


func notify_enter_location(location_id: String) -> void :
	_try("enter_location", location_id)


func _on_action(result: Dictionary) -> void :
	if not bool(result.get("ok", false)):
		return
	var aid: = str(result.get("action_id", ""))
	if aid.is_empty():
		aid = str(result.get("id", ""))
	_try("run_action", aid)
	_try("run_action_prefix", aid)


func _on_period(day: int, _period: String) -> void :
	_skip_unavailable()
	_check_reach_day(day)
	_check_flag_quests()


func _on_state() -> void :
	_skip_unavailable()
	_check_flag_quests()


func _on_ending(_ending_id: String) -> void :

	var guard: = 0
	while guard < 30 and not is_finished():
		guard += 1
		_skip_unavailable()
		var row: = current_row()
		if row.is_empty():
			break
		var ctype: = str(row.get("complete_type", ""))
		if ctype == "reach_day" or ctype == "flag_set":
			_advance()
		else:
			break


func _quest_matches_route(row: Dictionary) -> bool:
	var req: = str(row.get("require_flag", "")).strip_edges()
	if req == "":
		return true
	for p in req.split("|"):
		var flag_id: = str(p).strip_edges()
		if flag_id != "" and int(GameState.get_flag(flag_id)) != 0:
			return true
	return false


func _skip_unavailable() -> void :

	var guard: = 0
	while guard < 40 and not is_finished():
		guard += 1
		var row: = current_row()
		if row.is_empty() or _quest_matches_route(row):
			break

		if str(row.get("require_flag", "")).strip_edges() != ""\
		and not _any_flag_set("route_focus_a|route_focus_b|route_focus_c"):
			break
		GameState.quest_index += 1


func _check_reach_day(day: int) -> void :

	var guard: = 0
	while guard < 20 and not is_finished():
		guard += 1
		_skip_unavailable()
		var row: = current_row()
		if row.is_empty() or str(row.get("complete_type", "")) != "reach_day":
			break
		var need: = int(str(row.get("complete_param", "1")))
		if day < need:
			break
		_advance()


func _try(complete_type: String, value: String) -> void :
	if not _ready_tracking or is_finished():
		return
	_skip_unavailable()
	var row: = current_row()
	if row.is_empty():
		return
	if str(row.get("complete_type", "")) != complete_type:
		return
	var param: = str(row.get("complete_param", "")).strip_edges()
	if not _match(complete_type, param, value):
		return
	_advance()


func _match(complete_type: String, param: String, value: String) -> bool:
	match complete_type:
		"near_door":
			return true
		"enter_location", "run_action":
			if param == "":
				return value != ""
			for p in param.split("|"):
				if str(p).strip_edges() == value:
					return true
			return false
		"run_action_prefix":
			for p in param.split("|"):
				var pref: = str(p).strip_edges()
				if pref != "" and value.begins_with(pref):
					return true
			return false
		"reach_day":
			return GameState.day >= int(param) if param != "" else false
		"flag_set":
			return _any_flag_set(param)
		_:
			return false


func _any_flag_set(param: String) -> bool:
	if param.strip_edges() == "":
		return false
	for p in param.split("|"):
		var flag_id: = str(p).strip_edges()
		if flag_id != "" and int(GameState.get_flag(flag_id)) != 0:
			return true
	return false


func _check_flag_quests() -> void :
	var guard: = 0
	while guard < 20 and not is_finished():
		guard += 1
		_skip_unavailable()
		var row: = current_row()
		if row.is_empty() or str(row.get("complete_type", "")) != "flag_set":
			break
		var param: = str(row.get("complete_param", "")).strip_edges()
		if not _any_flag_set(param):
			break
		_advance()


func _advance() -> void :
	var done: = current_row()
	var done_id: = str(done.get("id", ""))
	GameState.quest_index += 1
	_skip_unavailable()
	if not GameState._suppress_signals:
		GameState.state_changed.emit()
	var next_id: = ""
	if not is_finished():
		next_id = str(current_row().get("id", ""))
		quest_advanced.emit(done_id, next_id)
		_emit()

		_check_reach_day(GameState.day)
		_check_flag_quests()
	else:
		quest_advanced.emit(done_id, "")
		quests_finished.emit()
		_emit()


func refresh_ui() -> void :
	_emit()


func is_current_optional() -> bool:
	var row: = current_row()
	if row.is_empty():
		return false
	return str(row.get("optional", "0")) in ["1", "true", "True"]


func _emit() -> void :
	_skip_unavailable()
	if is_finished():
		quest_changed.emit(
			"", 
			L10n.t("quest.done.title", "主线指引完成"), 
			L10n.t("quest.done.hint", "自由探索：打工、升职、跳槽，或继续把裂缝推到爆点"), 
			total(), 
			total()
		)
		return
	var row: = current_row()
	var id: = str(row.get("id", ""))
	var title: = L10n.t(str(row.get("title_key", "")), id)
	var hint: = L10n.t(str(row.get("hint_key", "")), "")
	if is_current_optional():
		var opt: = L10n.t("quest.optional.suffix", "（可稍后再做）")
		if not hint.contains(opt):
			hint = hint + "||" + opt if hint != "" else opt
	quest_changed.emit(id, title, hint, GameState.quest_index + 1, total())
