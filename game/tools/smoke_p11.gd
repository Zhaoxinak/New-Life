extends Node
## P11 smoke：票号短借/计息逾期/还款/汇兑清婚事旗 + 交情五档与人情债字段。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP11.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	var svc: Dictionary = PackDB.get_row_by_id("def_finance_service", "service_id", "svc_bank_loan_short")
	if svc.is_empty():
		push_error("SMOKE FAIL: missing finance service")
		ok = false

	# —— 交情五档 / 人情债（非 run_debt）——
	RunState.new_game()
	EffectApplier.apply_one({
		"op": "set",
		"edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
		"key": "score",
		"value": 25,
	}, "smoke")
	var tier := ConditionEval.score_to_tier(float(RunState.get_edge("char_qian_demao", "char_lin_ruisheng").get("score", 0)))
	if tier != "相善":
		push_error("SMOKE FAIL: edge tier=%s" % tier)
		ok = false
	EffectApplier.apply_one({
		"op": "set",
		"edge": {"from": "char_wang_pangzi", "to": "char_lin_ruisheng"},
		"key": "debt",
		"value": "酒情未还",
	}, "smoke")
	if String(RunState.get_edge("char_wang_pangzi", "char_lin_ruisheng").get("debt", "")) != "酒情未还":
		push_error("SMOKE FAIL: edge.debt")
		ok = false

	# —— 短借 ——
	RunState.new_game()
	RunState.set_stat("stat_money", 12)
	RunState.set_current_loc("loc_04")
	RunState.meta["slot"] = "morning"
	var money0 := float(RunState.get_stat("stat_money", 0))
	if not FinanceService.apply_service("svc_bank_loan_short", "smoke"):
		push_error("SMOKE FAIL: open loan")
		ok = false
	elif float(RunState.get_stat("stat_money", 0)) != money0 + 15.0:
		push_error("SMOKE FAIL: loan money")
		ok = false
	elif not RunState.get_flag("flag_bank_loan_active", false):
		push_error("SMOKE FAIL: loan flag")
		ok = false
	var debt_id := FinanceService.find_active_debt("svc_bank_loan_short", "")
	if debt_id.is_empty():
		push_error("SMOKE FAIL: no debt instance")
		ok = false
	else:
		var d0: Dictionary = RunState.debts[debt_id]
		if float(d0.get("remaining", 0)) != 15.0 or int(d0.get("due_day", 0)) != RunState.day() + 3:
			push_error("SMOKE FAIL: debt template %s" % str(d0))
			ok = false

	# —— 日末计息；越过 due → 逾期 ——
	var rem1 := float(RunState.debts[debt_id].get("remaining", 0))
	FinanceService.on_day_end()
	if float(RunState.debts[debt_id].get("remaining", 0)) != rem1 + 1.0:
		push_error("SMOKE FAIL: interest")
		ok = false
	RunState.meta["day"] = int(RunState.debts[debt_id].get("due_day", 0)) + 1
	var credit_before := float(RunState.get_stat("stat_credit_bank", 0))
	FinanceService.on_day_end()
	if String(RunState.debts[debt_id].get("status", "")) != "overdue":
		push_error("SMOKE FAIL: overdue status")
		ok = false
	elif not RunState.get_flag("flag_bank_loan_overdue", false):
		push_error("SMOKE FAIL: overdue flag")
		ok = false
	elif float(RunState.get_stat("stat_credit_bank", 0)) >= credit_before:
		push_error("SMOKE FAIL: overdue credit hit")
		ok = false

	# —— 还款 ——
	RunState.set_stat("stat_money", 80)
	if not FinanceService.repay_from_money(debt_id, -1.0, "smoke"):
		push_error("SMOKE FAIL: repay")
		ok = false
	elif String(RunState.debts[debt_id].get("status", "")) != "cleared":
		push_error("SMOKE FAIL: cleared")
		ok = false
	elif RunState.get_flag("flag_bank_loan_active", false):
		push_error("SMOKE FAIL: loan flag cleared")
		ok = false

	# —— 汇兑清婚事旗 ——
	RunState.set_stat("stat_money", 30)
	RunState.set_flag("flag_need_marriage_fund", true)
	if not FinanceService.apply_service("svc_bank_remit_home", "smoke"):
		push_error("SMOKE FAIL: remit")
		ok = false
	elif RunState.get_flag("flag_need_marriage_fund", false):
		push_error("SMOKE FAIL: marriage flag")
		ok = false

	# —— ACT 入口对白存在 ——
	for did in ["dialog_act_11_menu", "dialog_act_11_loan", "dialog_act_11_remit"]:
		if PackDB.get_row_by_id("def_dialog", "dialog_id", did).is_empty():
			push_error("SMOKE FAIL: dialog %s" % did)
			ok = false

	# —— 断炊旗 ——
	RunState.set_stat("stat_money", 5)
	FinanceService.on_day_end()
	if not RunState.get_flag("flag_money_broke", false):
		push_error("SMOKE FAIL: money broke")
		ok = false

	if ok:
		print("SMOKE P11 OK loan+interest+overdue+repay+remit+edge")
		get_tree().quit(0)
	else:
		print("SMOKE P11 FAIL")
		get_tree().quit(1)
