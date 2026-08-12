extends Node
## Tick 管线（契约顺序）：事件入队 → 对白/行动 → after → 推进。

signal action_resolved(act_id: String)
signal event_queued(event_id: String)


func on_slot_enter() -> void:
	if not RunState.is_running():
		return
	_queue_calendar_events()
	DomainBus.emit_domain("slot_enter", {
		"day": RunState.day(),
		"slot": RunState.slot(),
	})


func try_player_action(act_id: String) -> bool:
	if not RunState.is_running():
		return false
	if DialogueRunner.is_active():
		DomainBus.tip.emit(L10n.t("ui.dialog_busy", "对话进行中"))
		return false
	if not RunState.queue.is_empty():
		DomainBus.tip.emit(L10n.t("ui.event_pending", "有事件待处理"))
		return false

	var row: Dictionary = PackDB.get_row_by_id("def_action", "act_id", act_id)
	if row.is_empty():
		push_error("TickPipeline: unknown act %s" % act_id)
		return false

	var loc_id := String(row.get("loc_id", ""))
	if not loc_id.is_empty():
		RunState.set_current_loc(loc_id)
		if not _location_open(loc_id):
			DomainBus.tip.emit(L10n.t("ui.loc_closed", "此地此时未开放"))
			return false

	var requires: Array = row.get("require", [])
	if not ConditionEval.eval_all(requires):
		DomainBus.tip.emit(L10n.t("ui.require_fail", "条件未满足"))
		return false

	var effects: Array = row.get("effects", [])
	EffectApplier.apply_all(effects, "act:%s" % act_id)
	MeetingSystem.on_player_action(act_id)
	RunState.meta["last_act_id"] = act_id
	action_resolved.emit(act_id)

	# 行动口风：goto_dialog_by_condition
	var outro := _pick_goto_dialog_by_condition(row.get("goto_dialog_by_condition", []))
	if not outro.is_empty():
		if not DialogueRunner.dialog_finished.is_connected(_on_action_dialog_finished):
			DialogueRunner.dialog_finished.connect(_on_action_dialog_finished, CONNECT_ONE_SHOT)
		DialogueRunner.start_loose(outro)
		return true

	_after_action(true)
	return true


func _on_action_dialog_finished(_event_id: String) -> void:
	_after_action(true)


func begin_queued_event() -> bool:
	if RunState.queue.is_empty():
		return false
	if DialogueRunner.is_active():
		return false
	var eid := String(RunState.queue[0])
	# 从队列取出再播，避免重复入队
	RunState.dequeue_event()
	return DialogueRunner.start_event(eid)


func finish_event_playback(event_id: String) -> void:
	var erow: Dictionary = PackDB.get_row_by_id("def_event", "event_id", event_id)
	RunState.append_history("event", event_id, String(erow.get("loc_key", event_id)), {})
	if event_id == "M000":
		RunState.set_flag("seen_event_M000_%d" % RunState.day(), true)
	DomainBus.emit_domain("event_finished", {"event_id": event_id})
	if RunState.ended:
		DomainBus.emit_domain("run_over", {"reason": RunState.end_reason, "last_event": event_id})
		return
	_after_action(false)


func play_queued_event_effects(event_id: String, choice_effects: Array = []) -> void:
	## 兼容 P0 smoke / 无对白回退
	var row: Dictionary = PackDB.get_row_by_id("def_event", "event_id", event_id)
	if not row.is_empty():
		EffectApplier.apply_all(row.get("effects", []), "event:%s" % event_id)
	if not choice_effects.is_empty():
		EffectApplier.apply_all(choice_effects, "event_choice:%s" % event_id)
	RunState.set_flag("seen_event_%s" % event_id, true)
	_after_action(false)


func advance_after_idle() -> void:
	if not RunState.is_running():
		return
	if DialogueRunner.is_active():
		return
	_after_action(false)


func _after_action(allow_random: bool = false) -> void:
	if RunState.ended:
		return
	DomainBus.emit_domain("action_after", {
		"day": RunState.day(),
		"slot": RunState.slot(),
		"last_act": RunState.meta.get("last_act_id", ""),
	})
	var fail_id := FailureScanner.scan_and_enqueue()
	var rand_id := ""
	if fail_id.is_empty() and RunState.queue.is_empty() and allow_random:
		rand_id = RandomScanner.scan_and_enqueue()
	if not fail_id.is_empty() or not rand_id.is_empty() or not RunState.queue.is_empty():
		if not DialogueRunner.is_active():
			begin_queued_event()
		return
	var was_late := RunState.slot() == "late_night"
	RunState.advance_slot()
	if was_late:
		_on_day_end_hooks()
	on_slot_enter()
	# 时段进入若排入主线，自动开播
	if not RunState.queue.is_empty() and not DialogueRunner.is_active():
		begin_queued_event()


func _on_day_end_hooks() -> void:
	RandomScanner.clear_day_flags()
	for row in PackDB.get_rows("def_tick"):
		if String(row.get("when", "")) != "on_day_end":
			continue
		var requires: Array = row.get("require", [])
		if ConditionEval.eval_all(requires):
			EffectApplier.apply_all(row.get("effects", []), "tick:%s" % row.get("tick_id", "?"))
	MeetingSystem.on_day_end()
	FinanceService.on_day_end()


func _queue_calendar_events() -> void:
	var matched: Array = []
	for row in PackDB.get_rows("def_calendar"):
		if int(row.get("day", -1)) != RunState.day():
			continue
		if String(row.get("slot", "")) != RunState.slot():
			continue
		matched.append(row)
	var ids: Array = RouteMutex.pick_calendar_candidates(matched)
	for eid_v in ids:
		var eid := String(eid_v)
		RunState.enqueue_event(eid)
		event_queued.emit(eid)
	_maybe_queue_routine_meeting(ids)


func _maybe_queue_routine_meeting(already: Array) -> void:
	## 朝账日早上：若日历未排 M*，自动入队例行朝账 M000。
	if RunState.slot() != "morning":
		return
	if not MeetingSystem.is_meeting_day():
		return
	for eid_v in already:
		var eid := String(eid_v)
		if eid.begins_with("M"):
			return
	if RunState.queue.has("M000") or bool(RunState.get_flag("seen_event_M000_%d" % RunState.day(), false)):
		return
	# 同日已有任意 M* 在队列也不重复
	for q in RunState.queue:
		if String(q).begins_with("M"):
			return
	var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", "M000")
	if ev.is_empty():
		return
	if not ConditionEval.eval_all(ev.get("require", [])):
		return
	RunState.enqueue_event("M000")
	event_queued.emit("M000")


func _location_open(loc_id: String) -> bool:
	var loc: Dictionary = PackDB.get_row_by_id("def_location", "loc_id", loc_id)
	if loc.is_empty():
		return true
	var open_slots: Array = loc.get("open_slots", [])
	if open_slots.is_empty():
		return true
	return open_slots.has(RunState.slot())


func available_actions() -> Array:
	var out: Array = []
	for row in PackDB.get_rows("def_action"):
		var act_id := String(row.get("act_id", ""))
		if act_id.is_empty():
			continue
		var loc_id := String(row.get("loc_id", ""))
		if not loc_id.is_empty() and not _location_open(loc_id):
			continue
		if not ConditionEval.eval_all(row.get("require", [])):
			continue
		out.append(row)
	return out


func _pick_goto_dialog_by_condition(rules: Array) -> String:
	for item in rules:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var it: Dictionary = item
		if it.has("default"):
			return String(it["default"])
		if ConditionEval.eval_all(it.get("require", [])):
			return String(it.get("id", ""))
	return ""
