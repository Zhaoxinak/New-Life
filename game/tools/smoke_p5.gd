extends Node
## P5 smoke：Ceremony 可装载 + F001 警告 + F003 开除 end_run。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP5.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	for eid in ["F001", "F002", "F003", "F004", "F005"]:
		var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		if ev.is_empty():
			push_error("SMOKE FAIL: missing event %s" % eid)
			ok = false

	var overlay_res := load("res://ui/CeremonyOverlay.tscn")
	if overlay_res == null:
		push_error("SMOKE FAIL: CeremonyOverlay missing")
		ok = false

	RunState.new_game()
	TickPipeline.on_slot_enter()
	# 避开日历主线：清空队列后测失败扫描
	RunState.queue.clear()

	RunState.set_stat("stat_suspicion", 35)
	RunState.set_stat("stat_trust_firm", 40)
	var f1 := FailureScanner.scan_and_enqueue()
	if f1 != "F001":
		push_error("SMOKE FAIL: expected F001 got '%s'" % f1)
		ok = false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_F001", false)), 80):
		push_error("SMOKE FAIL: F001 playback")
		ok = false

	# 降职快测（不播完日历）
	RunState.queue.clear()
	RunState.set_stat("stat_suspicion", 55)
	RunState.set_stat("stat_trust_firm", 15)
	EffectApplier.apply_one({"op": "set_rank", "value": "waichang"}, "smoke")
	var f2 := FailureScanner.scan_and_enqueue()
	if f2 != "F002":
		push_error("SMOKE FAIL: expected F002 got '%s'" % f2)
		ok = false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_F002", false)), 80):
		push_error("SMOKE FAIL: F002 playback")
		ok = false
	if not RunState.get_flag("flag_demoted", false):
		push_error("SMOKE FAIL: flag_demoted")
		ok = false
	if RunState.player_rank() != "apprentice":
		push_error("SMOKE FAIL: demote rank got %s" % RunState.player_rank())
		ok = false
	if int(RunState.meta.get("monthly_stipend", -1)) != 2:
		push_error("SMOKE FAIL: monthly after demote %s" % str(RunState.meta.get("monthly_stipend", -1)))
		ok = false

	# 开除终局
	RunState.queue.clear()
	RunState.set_stat("stat_suspicion", 75)
	var f3 := FailureScanner.scan_and_enqueue()
	if f3 != "F003":
		push_error("SMOKE FAIL: expected F003 got '%s'" % f3)
		ok = false
	if not _play_until(func() -> bool: return RunState.ended, 80):
		push_error("SMOKE FAIL: F003 end_run")
		ok = false
	if RunState.end_reason != "fired":
		push_error("SMOKE FAIL: end_reason=%s" % RunState.end_reason)
		ok = false
	if not RunState.get_flag("flag_fired", false) or not RunState.get_flag("flag_ending_fail", false):
		push_error("SMOKE FAIL: fired flags")
		ok = false

	# F004 / F005 条件可触发（独立新局，不播完）
	RunState.new_game()
	RunState.queue.clear()
	RunState.set_edge_field("char_liu_ruyan", "char_lin_ruisheng", "score", -25)
	RunState.set_meter("pursuit", 65)
	if FailureScanner.scan_and_enqueue() != "F004":
		push_error("SMOKE FAIL: F004 require")
		ok = false

	RunState.new_game()
	RunState.queue.clear()
	RunState.set_edge_field("char_qian_demao", "char_lin_ruisheng", "suspicion", 4)
	if FailureScanner.scan_and_enqueue() != "F005":
		push_error("SMOKE FAIL: F005 require")
		ok = false

	if ok:
		print("SMOKE P5 OK f001+f002+f003 fired monthly=2 overlay=ok")
		get_tree().quit(0)
	else:
		print("SMOKE P5 FAILED")
		get_tree().quit(1)


func _play_until(pred: Callable, max_steps: int) -> bool:
	var guard := 0
	while guard < max_steps:
		guard += 1
		# 先收完对白（end_run 可能在叶节点入场就写 ended）
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
	DialogueRunner.select_choice(visible[0])
