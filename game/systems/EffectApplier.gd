extends Node
## effect 白名单执行器（对齐 docs/暗潮/00_总纲/effect词汇表.md）。非法条跳过+日志。

const RANK_VALUES: PackedStringArray = ["apprentice", "waichang", "paojie", "houtang"]
const EDGE_NUMERIC_KEYS: PackedStringArray = ["score", "suspicion", "trust", "fear"]
const GRUDGE_RESOLVE_MODE := {"punish": "punished", "forgive": "forgiven"}

var _rng := RandomNumberGenerator.new()
var last_errors: PackedStringArray = []
## goto_dialog 由 DialogueRunner 消费；此处只记录最近一次
var pending_goto_dialog: String = ""
var pending_mod_success: float = 0.0


func _ready() -> void:
	_rng.randomize()


func apply_all(effects: Array, reason: String = "") -> void:
	last_errors.clear()
	pending_goto_dialog = ""
	for fx in effects:
		if typeof(fx) != TYPE_DICTIONARY:
			_skip("non-dict effect", reason)
			continue
		apply_one(fx as Dictionary, reason)


func apply_one(fx: Dictionary, reason: String = "") -> bool:
	var op := String(fx.get("op", ""))
	if op.is_empty():
		_skip("missing op", reason)
		return false

	if fx.has("edge"):
		return _apply_edge(op, fx, reason)
	if fx.has("meter"):
		return _apply_meter(op, fx, reason)
	if fx.has("org"):
		return _apply_org(op, fx, reason)

	match op:
		"add", "set", "add_range":
			return _apply_stat(op, fx, reason)
		"set_flag":
			return _set_flag(fx, reason)
		"clear_flag":
			return _clear_flag(fx, reason)
		"set_rank":
			return _set_rank(fx, reason)
		"unlock_clue":
			return _clue(fx, true, reason)
		"revoke_clue":
			return _clue(fx, false, reason)
		"grant_item":
			return _item(fx, true, reason)
		"revoke_item":
			return _item(fx, false, reason)
		"open_service":
			return FinanceService.apply_service(String(fx.get("id", fx.get("service_id", ""))), reason)
		"open_debt":
			return _open_debt(fx, reason)
		"repay_debt":
			return _repay_debt(fx, reason)
		"set_debt_status":
			return _set_debt_status(fx, reason)
		"unlock_grudge", "bury_grudge", "open_grudge":
			# unlock=埋债(open)；兼容旧别名
			var st := "open"
			if op == "bury_grudge":
				st = "buried"
			return _grudge_status(fx, st, reason)
		"resolve_grudge":
			var mode := String(fx.get("mode", fx.get("status", "punish")))
			var mapped := String(GRUDGE_RESOLVE_MODE.get(mode, mode))
			if mapped != "punished" and mapped != "forgiven":
				mapped = "punished"
			var gid_pre := String(fx.get("id", fx.get("grudge_id", "")))
			if bool(fx.get("if_open", false)):
				if not RunState.grudges.has(gid_pre) \
					or String(RunState.grudges[gid_pre].get("status", "")) != "open":
					return true
			var ok_g := _grudge_status(fx, mapped, reason)
			if ok_g:
				var gid2 := String(fx.get("id", fx.get("grudge_id", "")))
				var def_g: Dictionary = PackDB.get_row_by_id("def_grudge", "grudge_id", gid2)
				DomainBus.emit_domain("grudge_resolved", {
					"id": gid2,
					"mode": mode,
					"status": mapped,
					"flashback_key": String(def_g.get("flashback_key", "")),
				})
			return ok_g
		"expire_grudge":
			return _grudge_status(fx, "expired", reason)
		"set_temp":
			var tkey := String(fx.get("key", ""))
			if tkey.is_empty():
				_skip("set_temp missing key", reason)
				return false
			RunState.set_temp(tkey, fx.get("value", true))
			return true
		"queue_event", "enqueue_event":
			var eid := String(fx.get("id", ""))
			if eid.is_empty():
				_skip("%s missing id" % op, reason)
				return false
			RunState.enqueue_event(eid)
			return true
		"goto_dialog":
			var did := String(fx.get("id", ""))
			if did.is_empty():
				_skip("goto_dialog missing id", reason)
				return false
			pending_goto_dialog = did
			DomainBus.emit_domain("goto_dialog", {"id": did})
			return true
		"mod_success":
			pending_mod_success = float(fx.get("value", 0))
			RunState.set_temp("mod_success", pending_mod_success)
			return true
		"end_run":
			RunState.end_run(String(fx.get("reason", "ended")))
			return true
		"menu":
			# 设计期形状；运行时由对话/UI 展平。此处跳过并提示。
			_skip("menu must be flattened to dialog choices", reason)
			return false
		_:
			_skip("unknown op %s" % op, reason)
			return false


func _apply_stat(op: String, fx: Dictionary, reason: String) -> bool:
	var key := String(fx.get("key", ""))
	if not key.begins_with("stat_"):
		_skip("stat op needs key stat_*", reason)
		return false
	match op:
		"add":
			RunState.add_stat(key, float(fx.get("value", 0)))
		"set":
			RunState.set_stat(key, fx.get("value", 0))
		"add_range":
			var amin := int(fx.get("min", 0))
			var amax := int(fx.get("max", amin))
			if amax < amin:
				var tmp := amin
				amin = amax
				amax = tmp
			RunState.add_stat(key, float(_rng.randi_range(amin, amax)))
	return true


func _apply_edge(op: String, fx: Dictionary, reason: String) -> bool:
	var edge: Dictionary = fx.get("edge", {}) as Dictionary
	var from_id := String(edge.get("from", ""))
	var to_id := String(edge.get("to", ""))
	var key := String(fx.get("key", "score"))
	if from_id.is_empty() or to_id.is_empty():
		_skip("edge missing from/to", reason)
		return false
	var before := int(RunState.get_edge(from_id, to_id).get(key, 0)) if key in ["suspicion", "trust", "fear"] else 0
	match op:
		"add":
			if key in ["suspicion", "trust", "fear"]:
				var cur := int(RunState.get_edge(from_id, to_id).get(key, 0))
				var nxt: int = clampi(cur + int(fx.get("value", 0)), 0, _edge_band_max(key))
				RunState.set_edge_field(from_id, to_id, key, nxt)
			else:
				RunState.add_edge_field(from_id, to_id, key, float(fx.get("value", 0)))
		"add_range":
			var amin := int(fx.get("min", 0))
			var amax := int(fx.get("max", amin))
			if amax < amin:
				var tmp := amin
				amin = amax
				amax = tmp
			var delta := float(_rng.randi_range(amin, amax))
			if key in ["suspicion", "trust", "fear"]:
				var cur2 := int(RunState.get_edge(from_id, to_id).get(key, 0))
				RunState.set_edge_field(from_id, to_id, key, clampi(cur2 + int(delta), 0, _edge_band_max(key)))
			else:
				RunState.add_edge_field(from_id, to_id, key, delta)
		"set":
			if key in ["suspicion", "trust", "fear"]:
				var capped: int = clampi(int(fx.get("value", 0)), 0, _edge_band_max(key))
				RunState.set_edge_field(from_id, to_id, key, capped)
			else:
				RunState.set_edge_field(from_id, to_id, key, fx.get("value", 0))
		_:
			_skip("edge unsupported op %s" % op, reason)
			return false
	if key == "suspicion":
		_warn_demao_suspicion(from_id, to_id, before)
	_log_edge_history(from_id, to_id, key, op)
	return true


func _edge_band_max(key: String) -> int:
	## suspicion 可到 4=杀意（F005）；trust/fear 仍 0–3。
	return 4 if key == "suspicion" else 3


func _warn_demao_suspicion(from_id: String, to_id: String, before: int) -> void:
	if from_id != "char_qian_demao" or to_id != "char_lin_ruisheng":
		return
	var after := int(RunState.get_edge(from_id, to_id).get("suspicion", 0))
	if after <= before:
		return
	if after >= 3 and before < 3:
		DomainBus.tip.emit(L10n.t("ui.demao_suspicion_high", "东家眼神已经不对了……"))
	elif after >= 2 and before < 2:
		DomainBus.tip.emit(L10n.t("ui.demao_suspicion_mid", "东家多看了你一眼。"))


func _log_edge_history(from_id: String, to_id: String, key: String, op: String) -> void:
	var e: Dictionary = RunState.get_edge(from_id, to_id)
	var score := float(e.get("score", 0))
	var tier := ConditionEval.score_to_tier(score)
	var summary := "history.edge.score" if key == "score" else "history.edge.shift"
	RunState.append_history("edge", "%s|%s" % [from_id, to_id], summary, {
		"from": from_id,
		"to": to_id,
		"key": key,
		"op": op,
		"score": score,
		"tier": tier,
		"trust": int(e.get("trust", 0)),
		"suspicion": int(e.get("suspicion", 0)),
		"fear": int(e.get("fear", 0)),
	})


func _apply_meter(op: String, fx: Dictionary, reason: String) -> bool:
	var meter_id := String(fx.get("meter", ""))
	if meter_id.is_empty():
		_skip("meter missing id", reason)
		return false
	match op:
		"add":
			RunState.add_meter(meter_id, float(fx.get("value", 0)))
		"set":
			RunState.set_meter(meter_id, float(fx.get("value", 0)))
		_:
			_skip("meter unsupported op %s" % op, reason)
			return false
	return true


func _apply_org(op: String, fx: Dictionary, reason: String) -> bool:
	var org_id := String(fx.get("org", ""))
	var key := String(fx.get("key", ""))
	if org_id.is_empty() or key.is_empty():
		_skip("org missing id/key", reason)
		return false
	match op:
		"add":
			RunState.add_org_field(org_id, key, float(fx.get("value", 0)))
		"set":
			RunState.set_org_field(org_id, key, fx.get("value", 0))
		_:
			_skip("org unsupported op %s" % op, reason)
			return false
	return true


func _set_flag(fx: Dictionary, reason: String) -> bool:
	var key := String(fx.get("key", ""))
	if key.is_empty():
		_skip("set_flag missing key", reason)
		return false
	RunState.set_flag(key, fx.get("value", true))
	return true


func _clear_flag(fx: Dictionary, reason: String) -> bool:
	var key := String(fx.get("key", ""))
	if key.is_empty():
		_skip("clear_flag missing key", reason)
		return false
	RunState.clear_flag(key)
	return true


func _set_rank(fx: Dictionary, reason: String) -> bool:
	var rank := String(fx.get("value", fx.get("rank", "")))
	if rank.is_empty() or not RANK_VALUES.has(rank):
		_skip("set_rank bad value %s" % rank, reason)
		return false
	RunState.set_player_rank(rank)
	return true


func _clue(fx: Dictionary, grant: bool, reason: String) -> bool:
	var cid := String(fx.get("id", ""))
	if cid.is_empty():
		_skip("clue op missing id", reason)
		return false
	if grant:
		RunState.clues[cid] = {"owned": true, "quality": fx.get("quality", "partial")}
		DomainBus.emit_domain("clue_unlocked", {"id": cid})
		var defc: Dictionary = PackDB.get_row_by_id("def_clue", "clue_id", cid)
		RunState.append_history("clue", cid, String(defc.get("loc_key", cid)), {"quality": fx.get("quality", "partial")})
	else:
		RunState.clues.erase(cid)
		DomainBus.emit_domain("clue_revoked", {"id": cid})
	return true


func _item(fx: Dictionary, grant: bool, reason: String) -> bool:
	var iid := String(fx.get("id", ""))
	if iid.is_empty():
		_skip("item op missing id", reason)
		return false
	if grant:
		RunState.items[iid] = {"owned": true}
		DomainBus.emit_domain("item_granted", {"id": iid})
	else:
		RunState.items.erase(iid)
		DomainBus.emit_domain("item_revoked", {"id": iid})
	return true


func _open_debt(fx: Dictionary, reason: String) -> bool:
	var service_id := String(fx.get("service_id", ""))
	var creditor := String(fx.get("creditor", ""))
	var principal := float(fx.get("principal", 0))
	if service_id.is_empty() or creditor.is_empty():
		_skip("open_debt needs service_id+creditor", reason)
		return false
	var debt_id := String(fx.get("debt_id", "debt_%s_%d" % [service_id, RunState.debts.size() + 1]))
	var remaining := float(fx.get("remaining", principal))
	RunState.debts[debt_id] = {
		"debt_id": debt_id,
		"service_id": service_id,
		"creditor": creditor,
		"principal": principal,
		"remaining": remaining,
		"interest_per_day": float(fx.get("interest_per_day", 0)),
		"opened_day": int(fx.get("opened_day", RunState.day())),
		"due_day": int(fx.get("due_day", 0)),
		"collateral": String(fx.get("collateral", "none")),
		"status": String(fx.get("status", "active")),
	}
	DomainBus.emit_domain("debt_opened", {"debt_id": debt_id})
	RunState.append_history("debt", debt_id, "history.debt.opened", {"remaining": remaining})
	return true


func _repay_debt(fx: Dictionary, reason: String) -> bool:
	var debt_id := String(fx.get("debt_id", ""))
	if debt_id.is_empty() and fx.has("service_id"):
		debt_id = FinanceService.find_active_debt(String(fx.get("service_id", "")), String(fx.get("creditor", "")))
	if bool(fx.get("from_money", false)) or bool(fx.get("pay_all", false)):
		var amount := -1.0 if bool(fx.get("pay_all", true)) else float(fx.get("value", -1))
		return FinanceService.repay_from_money(debt_id, amount, reason)
	if debt_id.is_empty() or not RunState.debts.has(debt_id):
		_skip("repay_debt missing debt", reason)
		return false
	var d: Dictionary = RunState.debts[debt_id]
	var pay := float(fx.get("value", 0))
	var rem := maxf(0.0, float(d.get("remaining", 0)) - pay)
	d["remaining"] = rem
	if rem <= 0.0:
		d["status"] = "cleared"
		FinanceService._clear_loan_flags_if_idle()
	DomainBus.emit_domain("debt_repaid", {"debt_id": debt_id, "remaining": rem})
	return true


func _set_debt_status(fx: Dictionary, reason: String) -> bool:
	var debt_id := String(fx.get("debt_id", ""))
	if debt_id.is_empty() or not RunState.debts.has(debt_id):
		_skip("set_debt_status missing debt", reason)
		return false
	var status := String(fx.get("value", ""))
	if status.is_empty():
		_skip("set_debt_status missing value", reason)
		return false
	RunState.debts[debt_id]["status"] = status
	DomainBus.emit_domain("debt_status", {"debt_id": debt_id, "status": status})
	return true


func _grudge_status(fx: Dictionary, status: String, reason: String) -> bool:
	var gid := String(fx.get("id", fx.get("grudge_id", "")))
	if gid.is_empty():
		_skip("grudge op missing id", reason)
		return false
	if not RunState.grudges.has(gid):
		RunState.grudges[gid] = {"status": status, "debtor": "", "buried_by": ""}
	else:
		RunState.grudges[gid]["status"] = status
	if status == "open":
		var by := String(fx.get("buried_by", ""))
		if by.is_empty() and DialogueRunner.is_active() and not DialogueRunner.current_event_id.is_empty():
			by = DialogueRunner.current_event_id
		if not by.is_empty():
			RunState.grudges[gid]["buried_by"] = by
	if status == "buried":
		RunState.grudges[gid]["buried_by"] = "player"
	DomainBus.grudge_changed.emit(gid, status)
	var defg: Dictionary = PackDB.get_row_by_id("def_grudge", "grudge_id", gid)
	RunState.append_history("grudge", gid, String(defg.get("loc_key", gid)), {"status": status})
	return true


func _skip(msg: String, reason: String) -> void:
	var line := "EffectApplier skip: %s (%s)" % [msg, reason]
	last_errors.append(line)
	push_warning(line)
