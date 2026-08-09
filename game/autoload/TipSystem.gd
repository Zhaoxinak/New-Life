extends Node


signal tip_shown(tip_id: String, text: String)
signal coach_changed(text: String)


## Opening / convenience tips that "跳过提示" should silence for the run.
const SKIP_BUNDLE: PackedStringArray = [
	"tip_minimap",
	"tip_transit",
	"tip_street_npc",
	"tip_dossier",
	"tip_npc_world",
	"tip_home_upgrade",
	"tip_variety",
	"tip_after_action",
	"tip_save_hint",
]

var coach_step: String = "move"
var _queue: Array[String] = []
var _showing: bool = false
var _current_tip_id: String = ""


func _ready() -> void :
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)


func queue_tip(tip_id: String) -> void :
	if tip_id.is_empty():
		return
	if GameState.seen_tips.get(tip_id, false):
		return
	var row: = PackDB.get_row("tips", tip_id)
	if row.is_empty() or str(row.get("enabled", "1")) == "0":
		return
	if tip_id in _queue:
		return
	_queue.append(tip_id)
	_try_show()


func queue_category(category: String) -> void :
	var rows: Array = []
	for row in PackDB.get_table("tips"):
		if str(row.get("category", "")) != category:
			continue
		if str(row.get("enabled", "1")) == "0":
			continue
		rows.append(row)
	rows.sort_custom( func(a, b): return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))
	for row in rows:
		queue_tip(str(row.get("id", "")))


func skip_tutorial() -> void :
	skip_all_pending()


## Clear the queue and silence the common opening tip bundle.
func skip_all_pending() -> void :
	if _current_tip_id != "":
		GameState.seen_tips[_current_tip_id] = true
	for tid in _queue:
		GameState.seen_tips[tid] = true
	_queue.clear()
	for tid in SKIP_BUNDLE:
		GameState.seen_tips[tid] = true
	for row in PackDB.get_table("tips"):
		if str(row.get("category", "")) != "tutorial":
			continue
		GameState.seen_tips[str(row.get("id", ""))] = true
	_showing = false
	_current_tip_id = ""
	_emit_coach()


func mark_seen(tip_id: String) -> void :
	if tip_id != "":
		GameState.seen_tips[tip_id] = true


func on_flags_changed() -> void :
	if GameState.get_flag("low_money") == 1:
		queue_tip("tip_low_money")
		queue_tip("tip_money_ways")
	if GameState.get_flag("suspicion_light") == 1:
		queue_tip("tip_suspicion")
	if GameState.get_flag("boss_watching") == 1:
		queue_tip("tip_boss_watching")
	if GameState.get_flag("tension_high") == 1:
		queue_tip("tip_clash")


func on_unlock_pulse() -> void :
	## Only tip places that unlock mid-run — start locations tip on enter.
	if GameState.is_location_unlocked("rival") and not UnlockScheduler.is_start_unlocked("location", "rival"):
		queue_tip("tip_first_rival")
	if GameState.is_location_unlocked("exchange") and not UnlockScheduler.is_start_unlocked("location", "exchange"):
		queue_tip("tip_first_exchange")
	if GameState.is_hotspot_unlocked("dock_office") and not UnlockScheduler.is_start_unlocked("hotspot", "dock_office"):
		queue_tip("tip_dock_office")
	_maybe_queue_dossier()


func on_first_check() -> void :
	queue_tip("tip_checks")


func on_boot_tutorial() -> void :
	pass


func on_near_door() -> void :
	queue_tip("tip_near_door")
	if coach_step == "move":
		set_coach("enter")


func on_enter_location(location_id: String = "") -> void :
	queue_tip("tip_enter_menu")
	if location_id == "plaza":
		queue_tip("tip_plaza")
		queue_tip("tip_arcade")
		queue_tip("tip_variety")
	if location_id == "tea_house":
		queue_tip("tip_tea_house")
		queue_tip("tip_variety")
	if location_id == "garage":
		queue_tip("tip_garage")
	if location_id == "home":
		queue_tip("tip_home_upgrade")
	if coach_step in ["move", "enter"]:
		set_coach("menu")


func on_open_actions(_hotspot_id: String = "") -> void :
	queue_tip("tip_pick_action")
	if coach_step == "menu":
		set_coach("act")


func on_action_done() -> void :
	queue_tip("tip_after_action")
	queue_tip("tip_save_hint")
	## 钱→场面：攒到能升宅基时串「赚钱→撑门面」
	if float(GameState.get_stat("money")) >= 120.0 and int(GameState.get_stat("home_tier")) < 3:
		queue_tip("tip_money_ways")
		queue_tip("tip_home_upgrade")
	set_coach("free")


func set_coach(step: String) -> void :
	var changed: = coach_step != step
	if not changed:
		_emit_coach()
		return
	coach_step = step
	_emit_coach()
	if step == "free":
		queue_tip("tip_minimap")


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


func notify_closed() -> void :
	_showing = false
	_current_tip_id = ""
	_try_show()


func _on_state() -> void :
	_maybe_queue_dossier()


func _maybe_queue_dossier() -> void :
	if GameState.day >= 2:
		queue_tip("tip_dossier")


func _emit_coach() -> void :
	coach_changed.emit(get_coach_text())


func _try_show() -> void :
	if _showing or _queue.is_empty():
		return
	if GameFlow.dialogue_open or GameFlow.event_open:
		return
	if EventScheduler.active_event_id != "":
		return
	var tip_id: String = _queue.pop_front()
	var row: = PackDB.get_row("tips", tip_id)
	var key: = str(row.get("text_key", ""))
	var text: = L10n.t(key, key)
	if str(row.get("once", "1")) == "1":
		GameState.seen_tips[tip_id] = true
	_showing = true
	_current_tip_id = tip_id
	tip_shown.emit(tip_id, text)


func pulse_when_free() -> void :
	if not _showing:
		_try_show()
