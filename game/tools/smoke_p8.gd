extends Node
## P8 smoke：随机池 + 每日上限 + 仅玩家行动触发 + 主线不被打断。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP8.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	for eid in ["R001", "R003", "R005", "R006", "R010"]:
		var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		if ev.is_empty() or String(ev.get("event_type", "")) != "random":
			push_error("SMOKE FAIL: missing random %s" % eid)
			ok = false

	# —— R010 ——
	RunState.new_game()
	RunState.set_flag("flag_zian_arrived", true)
	RunState.set_edge_field("char_qian_zian", "char_lin_ruisheng", "score", -25)
	RunState.set_current_loc("loc_01")
	RunState.meta["slot"] = "morning"
	RunState.clear_flag("flag_random_fired_today")
	if RandomScanner.scan_and_enqueue() != "R010":
		push_error("SMOKE FAIL: R010 enqueue")
		ok = false
	elif not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_R010", false)), 40):
		push_error("SMOKE FAIL: R010 play")
		ok = false
	elif String(RunState.grudges.get("grudge_onlooker", {}).get("status", "")) != "open":
		push_error("SMOKE FAIL: onlooker")
		ok = false

	if not RandomScanner.scan_and_enqueue().is_empty():
		push_error("SMOKE FAIL: same-day second random")
		ok = false

	# —— R001 次日茶楼 ——
	RandomScanner.clear_day_flags()
	RunState.meta["day"] = int(RunState.day()) + 1
	RunState.meta["slot"] = "evening"
	RunState.set_current_loc("loc_03")
	RunState.set_stat("stat_money", 20)
	RunState.set_flag("route_endure", true)
	RunState.set_flag("route_defect", false)
	if RandomScanner.scan_and_enqueue() != "R001":
		push_error("SMOKE FAIL: R001 enqueue")
		ok = false
	else:
		var money_before := float(RunState.get_stat("stat_money", 0))
		if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_R001", false)), 40):
			push_error("SMOKE FAIL: R001 play")
			ok = false
		elif float(RunState.get_stat("stat_money", 0)) >= money_before:
			push_error("SMOKE FAIL: R001 money")
			ok = false

	# —— R006 钱庄 ——
	RandomScanner.clear_day_flags()
	RunState.meta["day"] = int(RunState.day()) + 1
	RunState.meta["slot"] = "morning"
	RunState.set_current_loc("loc_04")
	RunState.set_stat("stat_money", 50)
	if RandomScanner.scan_and_enqueue() != "R006":
		push_error("SMOKE FAIL: R006 enqueue")
		ok = false
	elif not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_R006", false)), 40):
		push_error("SMOKE FAIL: R006 play")
		ok = false
	elif not RunState.get_flag("flag_bank_tier2", false):
		push_error("SMOKE FAIL: bank tier2")
		ok = false

	# —— idle 不滚随机（用无日历的日子）——
	RandomScanner.clear_day_flags()
	RunState.meta["day"] = 30
	RunState.meta["slot"] = "afternoon"
	RunState.set_current_loc("loc_02")
	RunState.set_stat("stat_trust_firm", 45)
	RunState.queue.clear()
	TickPipeline.advance_after_idle()
	if DialogueRunner.is_active():
		_play_until(func() -> bool: return not DialogueRunner.is_active(), 40)
	if RunState.get_flag("seen_event_R008", false) or (not RunState.queue.is_empty() and String(RunState.queue[0]).begins_with("R")):
		push_error("SMOKE FAIL: idle rolled random q=%s" % str(RunState.queue))
		ok = false

	# —— R008 伙计私语 ——
	if DialogueRunner.is_active():
		_play_until(func() -> bool: return not DialogueRunner.is_active(), 40)
	RandomScanner.clear_day_flags()
	RunState.meta["day"] = 31
	RunState.meta["slot"] = "afternoon"
	RunState.set_current_loc("loc_02")
	RunState.set_stat("stat_trust_firm", 45)
	RunState.queue.clear()
	var rid8 := RandomScanner.scan_and_enqueue()
	if rid8 != "R008":
		push_error("SMOKE FAIL: R008 enqueue got '%s'" % rid8)
		ok = false
	elif not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_R008", false)), 40):
		push_error("SMOKE FAIL: R008 play")
		ok = false
	else:
		RandomScanner.clear_day_flags()
		RunState.meta["day"] = 32
		RunState.meta["slot"] = "evening"
		RunState.set_current_loc("loc_03")
		RunState.set_stat("stat_money", 20)
		if not TickPipeline.try_player_action("act_03"):
			push_error("SMOKE FAIL: teahouse act")
			ok = false
		if DialogueRunner.is_active() or not RunState.queue.is_empty():
			_play_until(func() -> bool: return not DialogueRunner.is_active() and RunState.queue.is_empty(), 80)

	# —— 主线日历不被随机卡住 ——
	RunState.new_game()
	TickPipeline.on_slot_enter()
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E002", false)), 200):
		push_error("SMOKE FAIL: calendar E002 day=%s q=%s" % [RunState.day(), str(RunState.queue)])
		ok = false

	if ok:
		print("SMOKE P8 OK r010+r001+r006+idle_gate+calendar")
		get_tree().quit(0)
	else:
		print("SMOKE P8 FAILED")
		get_tree().quit(1)


func _play_until(pred: Callable, max_steps: int) -> bool:
	var guard := 0
	while guard < max_steps:
		guard += 1
		if DialogueRunner.is_active():
			_step_dialog()
			continue
		if pred.call():
			return true
		if not RunState.queue.is_empty():
			TickPipeline.begin_queued_event()
			continue
		if RunState.ended:
			return pred.call()
		TickPipeline.advance_after_idle()
	return pred.call()


func _step_dialog() -> void:
	var node: Dictionary = DialogueRunner.current_node
	var choices: Array = node.get("choices", node.get("options", []))
	var visible: Array = []
	for ch in choices:
		if typeof(ch) == TYPE_DICTIONARY and ConditionEval.eval_all((ch as Dictionary).get("require", [])):
			visible.append(ch)
	if visible.is_empty():
		DialogueRunner.continue_linear()
		return
	var pick: Dictionary = visible[0]
	var did := String(node.get("dialog_id", ""))
	if did == "dialog_r004_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	DialogueRunner.select_choice(pick)
