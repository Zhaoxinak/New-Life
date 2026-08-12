extends Node
## P12 smoke：run_org 初值 / 组织 effect / 日末压力 / 洋行佣金。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP12.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	for oid in ["org_qianji", "org_jufeng", "org_baoshun", "org_qing"]:
		if PackDB.get_row_by_id("def_org_init", "org_id", oid).is_empty():
			push_error("SMOKE FAIL: missing org init %s" % oid)
			ok = false

	RunState.new_game()
	if float(RunState.get_org_field("org_qianji", "firm_bright", 0)) != 55.0:
		push_error("SMOKE FAIL: qianji bright")
		ok = false
	if float(RunState.get_org_field("org_baoshun", "commission_budget", 0)) != 50.0:
		push_error("SMOKE FAIL: baoshun budget")
		ok = false

	# org effect
	EffectApplier.apply_one({
		"op": "add",
		"org": "org_qianji",
		"key": "firm_heat",
		"value": 10,
	}, "smoke")
	if float(RunState.get_org_field("org_qianji", "firm_heat", 0)) != 35.0:
		push_error("SMOKE FAIL: firm_heat add")
		ok = false

	# day-end father_son pressure
	RunState.set_meter("father_son", 20)
	var liq0 := float(RunState.get_org_field("org_qianji", "liquidity", 0))
	FinanceService.on_day_end()
	if float(RunState.get_org_field("org_qianji", "liquidity", 0)) >= liq0:
		push_error("SMOKE FAIL: liquidity pressure")
		ok = false

	# foreign commission
	RunState.set_stat("stat_money", 10)
	RunState.set_flag("flag_ending_c_ready", true)
	var budget0 := float(RunState.get_org_field("org_baoshun", "commission_budget", 0))
	var money0 := float(RunState.get_stat("stat_money", 0))
	if not FinanceService.apply_service("svc_foreign_commission", "smoke"):
		push_error("SMOKE FAIL: commission service")
		ok = false
	elif float(RunState.get_stat("stat_money", 0)) != money0 + 20.0:
		push_error("SMOKE FAIL: commission payout")
		ok = false
	elif not RunState.get_flag("flag_ending_c", false):
		push_error("SMOKE FAIL: ending_c")
		ok = false
	elif float(RunState.get_org_field("org_baoshun", "commission_budget", 0)) >= budget0:
		push_error("SMOKE FAIL: budget drain")
		ok = false

	# require gate without ready
	RunState.new_game()
	if FinanceService.apply_service("svc_foreign_commission", "smoke"):
		push_error("SMOKE FAIL: commission should require ready")
		ok = false

	# dialogs / action present
	if PackDB.get_row_by_id("def_action", "act_id", "act_foreign_visit").is_empty():
		push_error("SMOKE FAIL: act_foreign_visit")
		ok = false
	for did in ["dialog_act_12f_idle", "dialog_act_12f_ready", "dialog_act_12f_commission"]:
		if PackDB.get_row_by_id("def_dialog", "dialog_id", did).is_empty():
			push_error("SMOKE FAIL: dialog %s" % did)
			ok = false

	# save/load orgs
	RunState.new_game()
	RunState.add_org_field("org_qianji", "firm_heat", 7)
	var snap := RunState.snapshot()
	RunState.new_game()
	RunState.apply_snapshot(snap)
	if float(RunState.get_org_field("org_qianji", "firm_heat", 0)) != 32.0:
		push_error("SMOKE FAIL: org snapshot")
		ok = false

	if ok:
		print("SMOKE P12 OK org+commission+pressure")
		get_tree().quit(0)
	else:
		print("SMOKE P12 FAIL")
		get_tree().quit(1)
