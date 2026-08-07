extends Node
## Full action pipeline (DATA.md): dialogue → costs → check → stock → time.

signal action_resolved(result: Dictionary)
signal dialogue_requested(dialogue_id: String, action_id: String)

var last_result: Dictionary = {}
var _pending_action_id: String = ""


func can_run(action: Dictionary) -> Dictionary:
	if GameState.game_over:
		return {"ok": false, "reason": L10n.t("ui.ending.continue_hook", "已结束")}
	if GameFlow.is_blocked():
		return {"ok": false, "reason": "…"}
	if action.is_empty():
		return {"ok": false, "reason": "empty"}
	if str(action.get("enabled", "1")) == "0":
		return {"ok": false, "reason": "disabled"}
	var hid := str(action.get("hotspot_id", ""))
	if hid != "" and not GameState.is_hotspot_unlocked(hid):
		return {"ok": false, "reason": L10n.t("ui.action.locked", "尚未解锁")}
	if hid != "":
		var hs_cond := ConditionEval.eval_owner("hotspot", hid)
		if not hs_cond.get("ok", false):
			return {"ok": false, "reason": str(hs_cond.get("reason", L10n.t("ui.action.locked", "尚未解锁")))}
	var periods := str(action.get("periods", "any"))
	if not GameState.period_matches(periods):
		return {"ok": false, "reason": L10n.t("ui.empty.no_actions", "此时段不可用")}
	var aid := str(action.get("id", ""))
	var cond := ConditionEval.eval_owner("action", aid)
	if not cond.get("ok", false):
		return {"ok": false, "reason": str(cond.get("reason", L10n.t("ui.action.locked", "尚未解锁")))}
	return {"ok": true, "reason": ""}


func can_show_hotspot(hotspot: Dictionary) -> Dictionary:
	var hid := str(hotspot.get("id", ""))
	if not GameState.is_hotspot_unlocked(hid):
		return {"ok": false, "reason": L10n.t("ui.action.locked", "尚未解锁")}
	if not GameState.period_matches(str(hotspot.get("periods", "any"))):
		return {"ok": false, "reason": L10n.t("ui.empty.no_actions", "此时段不可用")}
	return ConditionEval.eval_owner("hotspot", hid)


func run(action_id: String) -> Dictionary:
	var action := PackDB.get_row("actions", action_id)
	var gate := can_run(action)
	if not gate.get("ok", false):
		last_result = {
			"ok": false,
			"action_id": action_id,
			"message": str(gate.get("reason", "blocked")),
		}
		action_resolved.emit(last_result)
		return last_result

	var dialogue_id := str(action.get("dialogue_id", "")).strip_edges()
	if dialogue_id != "":
		_pending_action_id = action_id
		dialogue_requested.emit(dialogue_id, action_id)
		return {"ok": true, "pending_dialogue": true, "action_id": action_id}

	return finish_action(action_id, "")


func finish_after_dialogue(action_id: String, choice_id: String) -> Dictionary:
	if choice_id != "":
		EffectApplier.apply_owner("dialogue_choice", choice_id)
	return finish_action(action_id, choice_id)


func finish_action(action_id: String, choice_id: String = "") -> Dictionary:
	var action := PackDB.get_row("actions", action_id)
	if action.is_empty():
		return {"ok": false, "message": "missing action"}

	# 1) Fixed action effects
	var applied_action := EffectApplier.apply_owner("action", action_id)

	# 2) Check
	var check_id := str(action.get("check_id", "")).strip_edges()
	var applied_check: Array[Dictionary] = []
	var check_passed := true
	var check_info: Dictionary = {}
	if check_id != "":
		check_info = CheckResolver.resolve(check_id)
		check_passed = bool(check_info.get("passed", true))
		if check_passed:
			applied_check = EffectApplier.apply_owner("check_success", check_id)
		else:
			applied_check = EffectApplier.apply_owner("check_fail", check_id)

	# 3) Stock rules for this action
	var stock_ran: Array[String] = StockEngine.on_action(action_id, check_passed)

	# 4) Suspicion
	var suspicion_delta := _calc_suspicion(action)
	if not is_zero_approx(suspicion_delta):
		GameState.add_stat("suspicion", suspicion_delta)

	# 5) Copy + chatter
	var result_key := "actions.%s.result" % action_id
	var message := L10n.t(result_key, L10n.t("actions.%s.name" % action_id, action_id))
	if check_id != "":
		var check_line := L10n.t("ui.check.success", "检定成功") if check_passed else L10n.t("ui.check.fail", "检定失败")
		var pct := int(round(float(check_info.get("chance", 0.0)) * 100.0))
		var chance_line := L10n.tf("ui.check.chance", {"pct": pct}, "成功率约 %d%%" % pct)
		message = "%s\n%s（%s）" % [message, check_line, chance_line]
	var chatter := IdleChatter.pick_for_current(str(action.get("hotspot_id", "")))
	if chatter != "":
		message = "%s\n[%s] %s" % [message, L10n.t("ui.chatter.title", "耳边闲话"), chatter]

	# 6) Time
	var time_cost := int(action.get("time_cost", 1))
	for _i in time_cost:
		GameState.advance_period()

	ThresholdWatcher.evaluate_all()
	EndingChecker.check_now()

	last_result = {
		"ok": true,
		"action_id": action_id,
		"choice_id": choice_id,
		"check_id": check_id,
		"check_passed": check_passed,
		"check_info": check_info,
		"applied_action": applied_action,
		"applied_check": applied_check,
		"stock_ran": stock_ran,
		"suspicion_delta": suspicion_delta,
		"message": message,
	}
	GameState.last_result_text = message
	_pending_action_id = ""
	GameState.state_changed.emit()
	action_resolved.emit(last_result)
	return last_result


func _calc_suspicion(action: Dictionary) -> float:
	var base := float(action.get("suspicion_base", 0))
	if is_zero_approx(base):
		return 0.0
	var hid := str(action.get("hotspot_id", ""))
	var hotspot := PackDB.get_row("hotspots", hid)
	var mult := float(hotspot.get("suspicion_mult", 1)) if not hotspot.is_empty() else 1.0
	return base * mult
