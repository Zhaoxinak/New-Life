extends Node


signal action_resolved(result: Dictionary)
signal dialogue_requested(dialogue_id: String, action_id: String)
signal minigame_requested(minigame_id: String, action_id: String)

var last_result: Dictionary = {}
var _pending_action_id: String = ""
var _result_note: String = ""


func set_result_note(note: String) -> void :
	_result_note = note


func can_run(action: Dictionary) -> Dictionary:
	if GameState.game_over:
		return {"ok": false, "reason": L10n.t("ui.ending.continue_hook", "已结束")}
	if GameFlow.is_blocked():
		return {"ok": false, "reason": "…"}
	if action.is_empty():
		return {"ok": false, "reason": "empty"}
	if str(action.get("enabled", "1")) == "0":
		return {"ok": false, "reason": "disabled"}
	var hid: = str(action.get("hotspot_id", ""))
	if hid != "" and not GameState.is_hotspot_unlocked(hid):
		return {"ok": false, "reason": L10n.t("ui.action.locked", "尚未解锁")}
	if hid != "":
		var hs_cond: = ConditionEval.eval_owner("hotspot", hid)
		if not hs_cond.get("ok", false):
			return {"ok": false, "reason": str(hs_cond.get("reason", L10n.t("ui.action.locked", "尚未解锁")))}
	var periods: = str(action.get("periods", "any"))
	if not GameState.period_matches(periods):
		return {"ok": false, "reason": _period_gate_reason(periods)}
	var aid: = str(action.get("id", ""))
	var cond: = ConditionEval.eval_owner("action", aid)
	if not cond.get("ok", false):
		return {"ok": false, "reason": str(cond.get("reason", L10n.t("ui.action.locked", "尚未解锁")))}
	if aid == "co_ask_promotion" or aid == "rival_ask_promotion":
		var promo: = PromotionSystem.can_ask(aid)
		if not promo.get("ok", false):
			return {"ok": false, "reason": str(promo.get("reason", L10n.t("ui.promo.not_ready", "晋升条件未齐")))}
	var use_gate: = _use_limit_reason(action)
	if use_gate != "":
		return {"ok": false, "reason": use_gate}
	return {"ok": true, "reason": ""}


func _use_limit_reason(action: Dictionary) -> String:
	var aid: = str(action.get("id", ""))
	if aid.is_empty():
		return ""
	var max_uses: = int(action.get("max_uses", 0))
	if max_uses > 0 and GameState.uses_today(aid) >= max_uses:
		return L10n.tf(
			"ui.locked.reason_max_uses", 
			{"n": max_uses}, 
			"今日已做过 %d 次" % max_uses
		)
	var cd: = int(action.get("cooldown_days", 0))
	if cd > 0:
		var last: = int(GameState.get_action_use_entry(aid).get("last_day", 0))
		if last > 0 and GameState.day < last + cd:
			var ready: = last + cd
			return L10n.tf(
				"ui.locked.reason_cooldown", 
				{"day": ready}, 
				"冷却中 · 第%d天可再做" % ready
			)
	return ""


func can_show_hotspot(hotspot: Dictionary) -> Dictionary:
	var hid: = str(hotspot.get("id", ""))
	if not GameState.is_hotspot_unlocked(hid):
		return {"ok": false, "reason": L10n.t("ui.action.locked", "尚未解锁")}
	var periods: = str(hotspot.get("periods", "any"))
	if not GameState.period_matches(periods):
		return {"ok": false, "reason": _period_gate_reason(periods)}
	return ConditionEval.eval_owner("hotspot", hid)


func _period_gate_reason(periods: String) -> String:
	if periods.strip_edges() == "" or periods == "any":
		return L10n.t("ui.empty.no_actions", "此时段不可用")
	var names: PackedStringArray = []
	for p in periods.split("|", false):
		var pid: = p.strip_edges()
		if pid.is_empty():
			continue
		names.append(L10n.t("periods.%s.name" % pid, pid))
	var joined: = " / ".join(names)
	return L10n.tf("ui.locked.reason_periods", {"periods": joined}, "仅%s可用" % joined)


func run(action_id: String) -> Dictionary:
	var action: = PackDB.get_row("actions", action_id)
	var gate: = can_run(action)
	if not gate.get("ok", false):
		last_result = {
			"ok": false, 
			"action_id": action_id, 
			"message": str(gate.get("reason", "blocked")), 
		}
		action_resolved.emit(last_result)
		return last_result

	var minigame_id: = _minigame_for(action)
	if minigame_id != "":
		_pending_action_id = action_id
		minigame_requested.emit(minigame_id, action_id)
		return {"ok": true, "pending_minigame": true, "action_id": action_id, "minigame_id": minigame_id}

	var tags: = str(action.get("tags", ""))
	if "transit_open" in tags or action_id == "home_drive":
		var host: = get_tree().get_first_node_in_group("world_host")
		if host and host.has_method("mount_vehicle_from_home"):
			host.mount_vehicle_from_home()
		elif host and host.has_method("open_transit"):
			if str(GameState.location_id) != "" and host.has_method("exit_interior"):
				host.exit_interior()
			host.open_transit("home")
		last_result = {
			"ok": true, 
			"action_id": action_id, 
			"message": L10n.t("actions.home_drive.result", "轮子一转，街巷矮下去。"), 
		}
		action_resolved.emit(last_result)
		return last_result

	var dialogue_id: = str(action.get("dialogue_id", "")).strip_edges()
	if dialogue_id != "":
		_pending_action_id = action_id
		dialogue_requested.emit(dialogue_id, action_id)
		return {"ok": true, "pending_dialogue": true, "action_id": action_id}

	return finish_action(action_id, "")


func _minigame_for(action: Dictionary) -> String:
	var tags: = str(action.get("tags", ""))
	var aid: = str(action.get("id", ""))
	if "minigame_scratch" in tags or aid == "plaza_scratch":
		return "scratch"
	if "minigame_dice" in tags or aid == "plaza_dice":
		return "dice"
	if "minigame_morra" in tags or aid == "plaza_morra":
		return "morra"
	if "minigame_fish" in tags or aid == "dock_fish":
		return "fish"
	return ""


func finish_after_dialogue(action_id: String, choice_id: String) -> Dictionary:
	if choice_id != "":
		EffectApplier.apply_owner("dialogue_choice", choice_id)
	return finish_action(action_id, choice_id)


func cancel_pending(message: String = "") -> void :
	_pending_action_id = ""
	last_result = {
		"ok": false, 
		"cancelled": true, 
		"message": message if message != "" else L10n.t("scratch.cancel", "没买票，摊主把木板收回去了。"), 
	}
	action_resolved.emit(last_result)


func finish_action(action_id: String, choice_id: String = "") -> Dictionary:
	var action: = PackDB.get_row("actions", action_id)
	if action.is_empty():
		return {"ok": false, "message": "missing action"}


	GameState.mark_action_used(action_id)


	var applied_action: = EffectApplier.apply_owner("action", action_id)

	if action_id == "home_rest":
		var ht: = int(GameState.get_stat("home_tier"))
		if ht >= 2:
			GameState.add_stat("suspicion", -2.0 if ht < 4 else -4.0)
		if ht >= 3:
			GameState.add_stat("intel", 1.0)


	var check_id: = str(action.get("check_id", "")).strip_edges()
	var applied_check: Array[Dictionary] = []
	var check_passed: = true
	var check_info: Dictionary = {}
	if check_id != "":
		check_info = CheckResolver.resolve(check_id)
		check_passed = bool(check_info.get("passed", true))
		if check_passed:
			applied_check = EffectApplier.apply_owner("check_success", check_id)
		else:
			applied_check = EffectApplier.apply_owner("check_fail", check_id)


	var stock_ran: Array[String] = StockEngine.on_action(action_id, check_passed)


	var suspicion_delta: = _calc_suspicion(action)
	if not is_zero_approx(suspicion_delta):
		GameState.add_stat("suspicion", suspicion_delta)


	var result_key: = "actions.%s.result" % action_id
	var message: = L10n.t(result_key, L10n.t("actions.%s.name" % action_id, action_id))
	if _result_note != "":
		message = "%s\n%s" % [_result_note, message]
		_result_note = ""
	var situation: = _situation_beat(applied_action, applied_check, suspicion_delta)
	if situation != "":
		message = "%s\n%s" % [message, L10n.tf("ui.situation.line", {"text": situation}, "局势：%s" % situation)]
	if check_id != "":
		var check_line: = L10n.t("ui.check.success", "检定成功") if check_passed else L10n.t("ui.check.fail", "检定失败")
		var pct: = int(round(float(check_info.get("chance", 0.0)) * 100.0))
		var chance_line: = L10n.tf("ui.check.chance", {"pct": pct}, "成功率约 %d%%" % pct)
		message = "%s\n%s（%s）" % [message, check_line, chance_line]
	var chatter: = IdleChatter.pick_for_current(str(action.get("hotspot_id", "")))
	if chatter != "":
		message = "%s\n[%s] %s" % [message, L10n.t("ui.chatter.title", "耳边闲话"), chatter]


	var prev_weather: = str(GameState.weather)
	var time_cost: = int(action.get("time_cost", 1))
	for _i in time_cost:
		GameState.advance_period()
	SfxPlayer.play_period()
	var period_line: = L10n.t("ui.period.to_%s" % GameState.period, "")
	if period_line != "":
		message = "%s\n%s" % [message, period_line]
	if str(GameState.weather) != prev_weather and str(GameState.weather) != "":
		var wname: = L10n.t("weather.%s.name" % GameState.weather, GameState.weather)
		message = "%s\n%s" % [
			message, 
			L10n.tf("ui.weather.changed", {"name": wname}, "天色转：%s" % wname), 
		]

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
	var base: = float(action.get("suspicion_base", 0))
	if is_zero_approx(base):
		return 0.0
	var hid: = str(action.get("hotspot_id", ""))
	var hotspot: = PackDB.get_row("hotspots", hid)
	var mult: = float(hotspot.get("suspicion_mult", 1)) if not hotspot.is_empty() else 1.0
	return base * mult


func _situation_beat(applied_action: Array, applied_check: Array, suspicion_delta: float) -> String:

	if suspicion_delta > 0.05:
		return L10n.t("ui.situation.suspicion_up", "有人多盯了你一眼")
	if suspicion_delta < -0.05:
		return L10n.t("ui.situation.suspicion_down", "风声暂时松了")
	var favor_delta: = 0.0
	var tension_delta: = 0.0
	var intel_delta: = 0.0
	var money_delta: = 0.0
	var trust_delta: = 0.0
	var network_delta: = 0.0
	for row in applied_action + applied_check:
		var et: = str(row.get("effect_type", ""))
		var key: = str(row.get("key", ""))
		var op: = str(row.get("op", "add"))
		var value: = float(row.get("value", 0))
		if op != "add":
			continue
		if et == "relation" and key.ends_with(":favor"):
			favor_delta += value
		elif et == "stat" and key == "father_son_tension":
			tension_delta += value
		elif et == "stat" and key == "intel":
			intel_delta += value
		elif et == "stat" and key == "money":
			money_delta += value
		elif et == "stat" and (key == "trust" or key == "tongyang_trust"):
			trust_delta += value
		elif et == "stat" and key == "network_elite":
			network_delta += value
	if favor_delta <= -2.0:
		return L10n.t("ui.situation.favor_down", "身边的人更冷了")
	if favor_delta >= 2.0:
		return L10n.t("ui.situation.favor_up", "有人把你往里拉了半步")
	if tension_delta >= 2.0:
		return L10n.t("ui.situation.tension_up", "楼里的裂缝又深了一寸")
	if trust_delta >= 3.0:
		return L10n.t("ui.situation.trust_up", "楼里又有人把你往名册里记了一笔")
	if trust_delta <= -8.0:
		return L10n.t("ui.situation.trust_down", "公司这边的信任裂开了一截")
	if intel_delta >= 3.0:
		return L10n.t("ui.situation.intel_up", "你多攥住了一句能用的话")
	if network_delta >= 2.0:
		return L10n.t("ui.situation.network_up", "上层圈子多听见了你的名字")
	if money_delta >= 8.0:
		return L10n.t("ui.situation.money_up", "口袋沉了，也更容易被人盯")
	if not applied_action.is_empty() or not applied_check.is_empty():
		return L10n.t("ui.situation.generic", "这一步留下了痕迹")
	return ""
