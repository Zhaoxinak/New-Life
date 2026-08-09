extends SceneTree




func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	await process_frame
	await process_frame
	var ok: = true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB not loaded")
		ok = false
	var money0: = GameState.get_stat("money")
	var day0: = GameState.day
	var period0: = GameState.period
	print("SMOKE: start money=%s day=%s period=%s" % [money0, day0, period0])
	for i in 3:
		var r: Dictionary = ActionPipeline.run("dock_work")
		if not r.get("ok", false):
			push_error("SMOKE FAIL: dock_work blocked on run %d: %s" % [i + 1, r])
			ok = false
			break
		print("SMOKE: run %d -> day=%s period=%s money=%s msg=%s" % [
			i + 1, GameState.day, GameState.period, GameState.get_stat("money"), r.get("message", "")
		])
	var money1: = GameState.get_stat("money")
	if money1 <= money0:
		push_error("SMOKE FAIL: money did not increase (%s -> %s)" % [money0, money1])
		ok = false
	if GameState.day == day0 and GameState.period == period0:
		push_error("SMOKE FAIL: period did not advance")
		ok = false
	if ok:
		print("SMOKE PASS")
		quit(0)
	else:
		print("SMOKE FAIL")
		quit(1)
