extends Node
## P1 smoke：对白链播完 → effect → 日 tick → 存读档 → validate 关键检查。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP1.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	RunState.new_game()
	TickPipeline.on_slot_enter()

	if RunState.queue.is_empty() or String(RunState.queue[0]) != "E001":
		push_error("SMOKE FAIL: E001 not queued")
		ok = false
	else:
		if not TickPipeline.begin_queued_event():
			push_error("SMOKE FAIL: begin_queued_event")
			ok = false
		# 线性点完对白
		var guard := 0
		while DialogueRunner.is_active() and guard < 40:
			guard += 1
			var choices: Array = []
			if not DialogueRunner.current_node.is_empty():
				choices = DialogueRunner.current_node.get("choices", DialogueRunner.current_node.get("options", []))
			if choices.is_empty():
				DialogueRunner.continue_linear()
			else:
				DialogueRunner.select_choice(choices[0])
		if DialogueRunner.is_active():
			push_error("SMOKE FAIL: dialog still active after %d steps" % guard)
			ok = false

	var trust := float(RunState.get_stat("stat_trust_firm"))
	if trust < 45.0:
		push_error("SMOKE FAIL: trust expected >=45 after E001 close, got %s" % trust)
		ok = false

	var edge: Dictionary = RunState.get_edge("char_qian_demao", "char_lin_ruisheng")
	if float(edge.get("score", 0)) < 40.0:
		push_error("SMOKE FAIL: demao edge score should include +8")
		ok = false

	# 推进到日末触发 tick
	var money_before_tick := float(RunState.get_stat("stat_money"))
	for _i in 12:
		if RunState.day() > 1:
			break
		TickPipeline.advance_after_idle()
	if RunState.day() < 2:
		push_error("SMOKE FAIL: did not reach day 2")
		ok = false
	var money_after := float(RunState.get_stat("stat_money"))
	if money_after > money_before_tick:
		# day end tick -1; may have done actions too — just ensure tick ran somehow
		pass
	# 明确测 tick：从早晨推满一天
	var m0 := float(RunState.get_stat("stat_money"))
	RunState.meta["slot"] = "late_night"
	TickPipeline.advance_after_idle()
	var m1 := float(RunState.get_stat("stat_money"))
	if m1 != m0 - 1.0:
		push_error("SMOKE FAIL: day-end tick living cost expected -1 (%s -> %s)" % [m0, m1])
		ok = false

	# effect 词汇冒烟
	EffectApplier.apply_one({"op": "set_flag", "key": "route_endure", "value": true}, "smoke")
	EffectApplier.apply_one({"op": "clear_flag", "key": "route_endure"}, "smoke")
	EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_slight"}, "smoke")
	EffectApplier.apply_one({"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish"}, "smoke")
	if String(RunState.grudges["grudge_zian_slight"].get("status", "")) != "punished":
		push_error("SMOKE FAIL: resolve_grudge")
		ok = false

	if not SaveSystem.save_slot(0) or not SaveSystem.load_slot(0):
		push_error("SMOKE FAIL: save/load")
		ok = false

	if ok:
		print("SMOKE P1 OK trust=%s edge=%s day=%s slot=%s money=%s" % [
			RunState.get_stat("stat_trust_firm"),
			edge.get("score"),
			RunState.day(),
			RunState.slot(),
			RunState.get_stat("stat_money"),
		])
		get_tree().quit(0)
	else:
		print("SMOKE P1 FAILED")
		get_tree().quit(1)
