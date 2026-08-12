extends Node
## P0 smoke（兼容）：走 DialogueRunner 播完 E001。
## 推荐改用 SmokeP1.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB not loaded")
		ok = false

	RunState.new_game()
	TickPipeline.on_slot_enter()

	if RunState.get_stat("stat_money") != 30:
		push_error("SMOKE FAIL: money initial != 30")
		ok = false

	if RunState.queue.is_empty() or String(RunState.queue[0]) != "E001":
		push_error("SMOKE FAIL: E001 not queued")
		ok = false
	else:
		TickPipeline.begin_queued_event()
		var guard := 0
		while DialogueRunner.is_active() and guard < 40:
			guard += 1
			DialogueRunner.continue_linear()
		if DialogueRunner.is_active():
			push_error("SMOKE FAIL: dialog stuck")
			ok = false

	if float(RunState.get_stat("stat_trust_firm")) < 45.0:
		push_error("SMOKE FAIL: trust after E001")
		ok = false

	var acted := false
	for _i in 8:
		if TickPipeline.try_player_action("act_01"):
			acted = true
			break
		TickPipeline.advance_after_idle()
	if not acted:
		push_error("SMOKE FAIL: act_01")
		ok = false

	if not SaveSystem.save_slot(0):
		push_error("SMOKE FAIL: save")
		ok = false
	var money_saved := float(RunState.get_stat("stat_money"))
	var day_saved := RunState.day()
	RunState.new_game()
	if not SaveSystem.load_slot(0):
		push_error("SMOKE FAIL: load")
		ok = false
	if float(RunState.get_stat("stat_money")) != money_saved or RunState.day() != day_saved:
		push_error("SMOKE FAIL: load mismatch")
		ok = false

	if ok:
		print("SMOKE P0 OK money=%s trust=%s day=%s slot=%s" % [
			RunState.get_stat("stat_money"),
			RunState.get_stat("stat_trust_firm"),
			RunState.day(),
			RunState.slot(),
		])
		get_tree().quit(0)
	else:
		print("SMOKE P0 FAILED")
		get_tree().quit(1)
