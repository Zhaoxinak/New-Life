extends Node
## Tip queue + coach objective strip for onboarding.

signal tip_shown(tip_id: String, text: String)
signal coach_changed(text: String)

## move → enter → menu → act → free
var coach_step: String = "move"
var _queue: Array[String] = []
var _showing: bool = false
var _current_tip_id: String = ""


func queue_tip(tip_id: String) -> void:
	if tip_id.is_empty():
		return
	if GameState.seen_tips.get(tip_id, false):
		return
	var row := PackDB.get_row("tips", tip_id)
	if row.is_empty() or str(row.get("enabled", "1")) == "0":
		return
	if tip_id in _queue:
		return
	_queue.append(tip_id)
	_try_show()


func queue_category(category: String) -> void:
	var rows: Array = []
	for row in PackDB.get_table("tips"):
		if str(row.get("category", "")) != category:
			continue
		if str(row.get("enabled", "1")) == "0":
			continue
		rows.append(row)
	rows.sort_custom(func(a, b): return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))
	for row in rows:
		queue_tip(str(row.get("id", "")))


func skip_tutorial() -> void:
	for row in PackDB.get_table("tips"):
		if str(row.get("category", "")) != "tutorial":
			continue
		var tid := str(row.get("id", ""))
		GameState.seen_tips[tid] = true
		_queue.erase(tid)
	if coach_step in ["move", "enter"]:
		# Keep coach until they actually act once, unless fully free preferred
		pass
	_emit_coach()


func mark_seen(tip_id: String) -> void:
	if tip_id != "":
		GameState.seen_tips[tip_id] = true


func on_flags_changed() -> void:
	if GameState.get_flag("low_money") == 1:
		queue_tip("tip_low_money")
	if GameState.get_flag("suspicion_light") == 1:
		queue_tip("tip_suspicion")
	if GameState.get_flag("boss_watching") == 1:
		queue_tip("tip_boss_watching")
	if GameState.get_flag("tension_high") == 1:
		queue_tip("tip_clash")


func on_unlock_pulse() -> void:
	if GameState.is_location_unlocked("rival"):
		queue_tip("tip_first_rival")
	if GameState.is_location_unlocked("exchange"):
		queue_tip("tip_first_exchange")
	if GameState.is_hotspot_unlocked("dock_office"):
		queue_tip("tip_dock_office")


func on_first_check() -> void:
	queue_tip("tip_checks")


func on_boot_tutorial() -> void:
	# Tip-banner tutorial disabled — use QuestGuide instead.
	pass


func on_near_door() -> void:
	queue_tip("tip_near_door")
	if coach_step == "move":
		set_coach("enter")


func on_enter_location(_location_id: String = "") -> void:
	queue_tip("tip_enter_menu")
	if coach_step in ["move", "enter"]:
		set_coach("menu")


func on_open_actions(_hotspot_id: String = "") -> void:
	queue_tip("tip_pick_action")
	if coach_step == "menu":
		set_coach("act")


func on_action_done() -> void:
	queue_tip("tip_after_action")
	queue_tip("tip_save_hint")
	set_coach("free")


func set_coach(step: String) -> void:
	if coach_step == step:
		_emit_coach()
		return
	coach_step = step
	_emit_coach()


func get_coach_text() -> String:
	match coach_step:
		"move":
			return L10n.t("guide.coach.move", "引导：WASD 沿石板路走到建筑门口")
		"enter":
			return L10n.t("guide.coach.enter", "引导：再走近门口，会自动进入")
		"menu":
			return L10n.t("guide.coach.menu", "引导：点选一个设施，查看可做的事")
		"act":
			return L10n.t("guide.coach.act", "引导：选择一项行动（每时段一次）")
		_:
			return L10n.t("guide.coach.free", "顶栏看数值 · 右上角可存档 · 嫌疑高就回家歇")


func queue_remaining() -> int:
	return _queue.size()


func current_tip_id() -> String:
	return _current_tip_id


func notify_closed() -> void:
	_showing = false
	_current_tip_id = ""
	_try_show()


func _emit_coach() -> void:
	coach_changed.emit(get_coach_text())


func _try_show() -> void:
	if _showing or _queue.is_empty():
		return
	if GameFlow.dialogue_open or GameFlow.event_open:
		return
	if EventScheduler.active_event_id != "":
		return
	var tip_id: String = _queue.pop_front()
	var row := PackDB.get_row("tips", tip_id)
	var key := str(row.get("text_key", ""))
	var text := L10n.t(key, key)
	if str(row.get("once", "1")) == "1":
		GameState.seen_tips[tip_id] = true
	_showing = true
	_current_tip_id = tip_id
	tip_shown.emit(tip_id, text)


func pulse_when_free() -> void:
	if not _showing:
		_try_show()
