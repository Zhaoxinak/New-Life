extends Node
## 金融服务：按 def_finance_service 开业务、日末计息/逾期。


func apply_service(service_id: String, reason: String = "") -> bool:
	var row: Dictionary = PackDB.get_row_by_id("def_finance_service", "service_id", service_id)
	if row.is_empty():
		push_warning("FinanceService: unknown %s" % service_id)
		return false
	if not ConditionEval.eval_all(row.get("require", [])):
		DomainBus.tip.emit(L10n.t("ui.require_fail", "条件未满足"))
		return false

	var stype := String(row.get("service_type", ""))
	if stype == "rollover":
		return _apply_rollover(row, reason)
	if stype == "commission":
		return _apply_commission(row, reason)

	EffectApplier.apply_all(row.get("effects_on_open", []), "svc:%s" % service_id)
	if stype == "loan" and row.has("debt_template"):
		_open_from_template(row, reason)
	DomainBus.emit_domain("finance_service", {"service_id": service_id, "type": stype})
	return true


func find_active_debt(service_id: String = "", creditor: String = "") -> String:
	for debt_id in RunState.debts.keys():
		var d: Dictionary = RunState.debts[debt_id]
		var status := String(d.get("status", ""))
		if status != "active" and status != "overdue":
			continue
		if not service_id.is_empty() and String(d.get("service_id", "")) != service_id:
			continue
		if not creditor.is_empty() and String(d.get("creditor", "")) != creditor:
			continue
		return String(debt_id)
	return ""


func repay_from_money(debt_id: String, amount: float = -1.0, reason: String = "") -> bool:
	if debt_id.is_empty() or not RunState.debts.has(debt_id):
		return false
	var d: Dictionary = RunState.debts[debt_id]
	var rem := float(d.get("remaining", 0))
	if rem <= 0.0:
		d["status"] = "cleared"
		_clear_loan_flags_if_idle()
		return true
	var pay := rem if amount < 0.0 else minf(amount, rem)
	var money := float(RunState.get_stat("stat_money", 0))
	pay = minf(pay, money)
	if pay <= 0.0:
		DomainBus.tip.emit(L10n.t("ui.debt_cant_pay", "银两不足，还不起这桩账。"))
		return false
	RunState.add_stat("stat_money", -pay)
	rem = maxf(0.0, rem - pay)
	d["remaining"] = rem
	if rem <= 0.0:
		d["status"] = "cleared"
		_clear_loan_flags_if_idle()
	DomainBus.emit_domain("debt_repaid", {"debt_id": debt_id, "remaining": rem, "reason": reason})
	return true


func on_day_end() -> void:
	_refresh_money_bands()
	_tick_org_pressures()
	for debt_id in RunState.debts.keys():
		var d: Dictionary = RunState.debts[debt_id]
		var status := String(d.get("status", ""))
		if status != "active" and status != "overdue":
			continue
		var interest := float(d.get("interest_per_day", 0))
		if interest != 0.0:
			d["remaining"] = float(d.get("remaining", 0)) + interest
		var due_day := int(d.get("due_day", 0))
		if due_day > 0 and RunState.day() > due_day and status == "active":
			_mark_overdue(String(debt_id), d)
	_clear_loan_flags_if_idle()


func _apply_commission(row: Dictionary, reason: String) -> bool:
	var service_id := String(row.get("service_id", ""))
	var provider := String(row.get("provider", "org_baoshun"))
	var payout: Dictionary = row.get("payout_rule", {})
	var upfront := float(payout.get("upfront_money", 0))
	if upfront > 0.0:
		RunState.add_stat("stat_money", upfront)
	# 抽佣金预算
	var budget := float(RunState.get_org_field(provider, "commission_budget", 0))
	if budget > 0.0:
		RunState.add_org_field(provider, "commission_budget", -minf(15.0, budget))
		RunState.add_org_field(provider, "channel_hunger", -5.0)
	EffectApplier.apply_all(row.get("effects_on_open", []), "svc:%s" % service_id)
	DomainBus.emit_domain("finance_service", {"service_id": service_id, "type": "commission"})
	return true


func _tick_org_pressures() -> void:
	# 钱记：父子不和 → 周转紧、养人压升高；庆系上供吃暗钱
	var fs := float(RunState.get_meter("father_son", 50))
	if fs < 30.0:
		RunState.add_org_field("org_qianji", "liquidity", -1.0)
		RunState.add_org_field("org_qianji", "payroll_pressure", 1.0)
		RunState.add_org_field("org_qianji", "firm_heat", 1.0)
	var tribute := float(RunState.get_org_field("org_qianji", "tribute_pressure", 0))
	if tribute >= 30.0:
		var dark := float(RunState.get_org_field("org_qianji", "cash_dark", 0))
		if dark > 0.0:
			RunState.add_org_field("org_qianji", "cash_dark", -1.0)
	# 洋行：缺代理人时门路饥渴略升
	if not RunState.get_flag("flag_ending_c", false) and not RunState.get_flag("flag_ending_c_ready", false):
		RunState.add_org_field("org_baoshun", "channel_hunger", 0.5)


func _open_from_template(row: Dictionary, reason: String) -> void:
	var tmpl: Dictionary = row.get("debt_template", {})
	var service_id := String(row.get("service_id", ""))
	var creditor := String(row.get("provider", "org_bank"))
	var principal := float(tmpl.get("principal", 0))
	var due_in := int(tmpl.get("due_in_days", 3))
	var debt_id := "debt_%s_%d" % [service_id, RunState.debts.size() + 1]
	EffectApplier.apply_one({
		"op": "open_debt",
		"debt_id": debt_id,
		"service_id": service_id,
		"creditor": creditor,
		"principal": principal,
		"interest_per_day": float(tmpl.get("interest_per_day", 0)),
		"due_day": RunState.day() + due_in,
		"collateral": String(tmpl.get("collateral", "none")),
		"opened_day": RunState.day(),
	}, reason)


func _apply_rollover(row: Dictionary, reason: String) -> bool:
	var creditor := String(row.get("provider", "org_bank"))
	var debt_id := find_active_debt("", creditor)
	if debt_id.is_empty():
		DomainBus.tip.emit(L10n.t("ui.debt_none", "柜上没有你的往来账。"))
		return false
	EffectApplier.apply_all(row.get("effects_on_open", []), "svc:%s" % row.get("service_id", ""))
	var tmpl: Dictionary = row.get("debt_template", {})
	var d: Dictionary = RunState.debts[debt_id]
	var extend := int(tmpl.get("extend_days", 2))
	var extra := float(tmpl.get("extra_interest", 0))
	d["due_day"] = maxi(int(d.get("due_day", RunState.day())), RunState.day()) + extend
	d["remaining"] = float(d.get("remaining", 0)) + extra
	if String(d.get("status", "")) == "overdue":
		d["status"] = "active"
		RunState.clear_flag("flag_bank_loan_overdue")
	DomainBus.emit_domain("debt_rollover", {"debt_id": debt_id, "due_day": d["due_day"]})
	return true


func _mark_overdue(debt_id: String, d: Dictionary) -> void:
	d["status"] = "overdue"
	var svc: Dictionary = PackDB.get_row_by_id("def_finance_service", "service_id", String(d.get("service_id", "")))
	var risk: Dictionary = svc.get("risk", {})
	var overdue_flag := String(risk.get("overdue_flag", "flag_bank_loan_overdue"))
	if not overdue_flag.is_empty():
		RunState.set_flag(overdue_flag, true)
	EffectApplier.apply_all(risk.get("on_overdue", []), "debt_overdue:%s" % debt_id)
	DomainBus.emit_domain("debt_status", {"debt_id": debt_id, "status": "overdue"})


func _refresh_money_bands() -> void:
	var money := float(RunState.get_stat("stat_money", 0))
	RunState.clear_flag("flag_money_broke")
	RunState.clear_flag("flag_money_tight")
	if money < 10.0:
		RunState.set_flag("flag_money_broke", true)
	elif money < 20.0:
		RunState.set_flag("flag_money_tight", true)


func _clear_loan_flags_if_idle() -> void:
	if not find_active_debt("svc_bank_loan_short", "").is_empty():
		RunState.set_flag("flag_bank_loan_active", true)
		return
	# any bank debt still open?
	if not find_active_debt("", "org_bank").is_empty():
		RunState.set_flag("flag_bank_loan_active", true)
		return
	RunState.clear_flag("flag_bank_loan_active")
	RunState.clear_flag("flag_bank_loan_overdue")
