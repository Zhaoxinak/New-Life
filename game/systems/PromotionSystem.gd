extends Node



func get_status() -> Dictionary:
	if GameState.employer_id == GameState.EMPLOYER_NONE or GameState.active_career_track == "":
		return {
			"employed": false, 
			"at_max": false, 
			"ready": false, 
			"checks": [], 
			"ask_action_id": "", 
			"hint": L10n.t("ui.promo.unemployed_hint", "无业：先靠码头/广场谋生，或争取通洋入职。"), 
		}
	var cur_rank: = GameState.get_rank_id()
	var gate: = _active_gate()
	if not gate.is_empty():
		return _status_for_gate(gate, cur_rank)
	var next: = GameState.get_next_rank_info()
	if next.is_empty():
		return {
			"employed": true, 
			"at_max": true, 
			"ready": false, 
			"current_rank_id": cur_rank, 
			"next_rank_id": "", 
			"stat_id": "", 
			"current": 0.0, 
			"need": 0.0, 
			"checks": [], 
			"ask_action_id": "", 
			"gate_id": "", 
			"hint": L10n.t("ui.hud.rank_max", "已在当前职涯顶端"), 
		}

	var stat_id: = str(next.get("stat_id", "trust"))
	var current: = float(next.get("current", 0))
	var need: = float(next.get("need_stat", 0))
	var checks: Array = [_check_stat(stat_id, current, need)]
	var from_name: = L10n.t("ranks.%s.name" % cur_rank, cur_rank)
	var to_name: = L10n.t("ranks.%s.name" % str(next.get("rank_id", "")), str(next.get("rank_id", "")))
	return {
		"employed": true, 
		"at_max": false, 
		"ready": false, 
		"current_rank_id": cur_rank, 
		"next_rank_id": str(next.get("rank_id", "")), 
		"stat_id": stat_id, 
		"current": current, 
		"need": need, 
		"checks": checks, 
		"ask_action_id": "", 
		"gate_id": "", 
		"title": L10n.tf(
			"ui.promo.title", 
			{"from": from_name, "to": to_name}, 
			"晋升进度  %s → %s" % [from_name, to_name]
		), 
		"hint": L10n.t("ui.promo.hint_passive", "攒满主条即可进入下一职级带。"), 
	}


func can_ask(action_id: String) -> Dictionary:
	var st: = get_status()
	if not bool(st.get("employed", false)):
		return {"ok": false, "reason": L10n.t("ui.promo.unemployed_hint", "无业无法申请晋升")}
	if bool(st.get("at_max", false)):
		return {"ok": false, "reason": L10n.t("ui.hud.rank_max", "已在当前职涯顶端")}
	var ask: = str(st.get("ask_action_id", ""))
	if ask.is_empty():
		return {"ok": false, "reason": L10n.t("ui.promo.passive_rank", "继续办事攒信任，职级会自动跟上")}
	if ask != action_id:
		return {"ok": false, "reason": L10n.t("ui.promo.wrong_ask", "此处不能申请该档晋升")}
	if not bool(st.get("ready", false)):
		for c in st.get("checks", []):
			if not bool(c.get("ok", false)):
				return {"ok": false, "reason": str(c.get("label", L10n.t("ui.promo.not_ready", "晋升条件未齐")))}
		return {"ok": false, "reason": L10n.t("ui.promo.not_ready", "晋升条件未齐，打开档案查看")}
	return {"ok": true, "reason": ""}


func claim_next() -> void :
	var gate: = _active_gate()
	if gate.is_empty():
		return
	var claim: = str(gate.get("claim_flag", ""))
	if claim != "":
		GameState.set_flag(claim, 1)
	if claim == "claimed_promo_manager":
		GameState.set_flag("claimed_hongyuan_promo", 1)
	var track: = PackDB.get_row("rank_tracks", str(gate.get("track_id", "")))
	var stat_id: = str(track.get("stat_id", "trust")) if not track.is_empty() else "trust"
	var need: = _effective_stat_min(gate, float(str(gate.get("stat_min", 0))))
	if GameState.get_stat(stat_id) < need:
		GameState.set_stat(stat_id, need)
	else:
		GameState.set_stat(stat_id, GameState.get_stat(stat_id) + 3.0)


func _status_for_gate(gate: Dictionary, cur_rank: String) -> Dictionary:
	var target: = str(gate.get("target_rank_id", ""))
	var track: = PackDB.get_row("rank_tracks", str(gate.get("track_id", "")))
	var stat_id: = str(track.get("stat_id", "trust")) if not track.is_empty() else "trust"
	var current: = GameState.get_stat(stat_id)
	var need: = _effective_stat_min(gate, float(str(gate.get("stat_min", 0))))
	var checks: Array = [_check_stat(stat_id, current, need)]
	checks.append_array(_gate_checks(gate))
	var ready: = true
	for c in checks:
		if not bool(c.get("ok", false)):
			ready = false
			break
	var ask_id: = str(gate.get("ask_action_id", ""))
	var from_name: = L10n.t("ranks.%s.name" % cur_rank, cur_rank)
	var to_name: = L10n.t("ranks.%s.name" % target, target)
	return {
		"employed": true, 
		"at_max": false, 
		"ready": ready and ask_id != "", 
		"current_rank_id": cur_rank, 
		"next_rank_id": target, 
		"stat_id": stat_id, 
		"current": current, 
		"need": need, 
		"checks": checks, 
		"ask_action_id": ask_id, 
		"gate_id": str(gate.get("id", "")), 
		"title": L10n.tf(
			"ui.promo.title", 
			{"from": from_name, "to": to_name}, 
			"晋升进度  %s → %s" % [from_name, to_name]
		), 
		"hint": _ready_hint(ready, ask_id), 
	}


func _ready_hint(ready: bool, ask_id: String) -> String:
	if ask_id == "":
		return L10n.t("ui.promo.hint_passive", "攒满主条即可进入下一职级带。")
	if ready:
		return L10n.t("ui.promo.hint_ready", "条件已齐——去老板处/通洋办公室申请晋升。")
	return L10n.t("ui.promo.hint_blocked", "先凑齐下方条件，再申请晋升。")



func _active_gate() -> Dictionary:
	var best: Dictionary = {}
	var best_order: = 999
	for row in PackDB.get_table("promotion_gates"):
		if str(row.get("enabled", "1")) == "0":
			continue
		if str(row.get("track_id", "")) != GameState.active_career_track:
			continue
		var claim: = str(row.get("claim_flag", "")).strip_edges()
		if claim != "" and GameState.get_flag(claim) != 0:
			continue
		var target: = str(row.get("target_rank_id", ""))
		var rank_row: = PackDB.get_row("ranks", target)
		var order: = int(rank_row.get("sort_order", 999)) if not rank_row.is_empty() else 999
		if order < best_order:
			best_order = order
			best = row
	return best


func _effective_stat_min(gate: Dictionary, fallback: float) -> float:
	if gate.is_empty():
		return fallback
	var base: = float(str(gate.get("stat_min", fallback)))
	var alt_flag: = str(gate.get("alt_if_flag", "")).strip_edges()
	var alt: = str(gate.get("stat_min_alt", "")).strip_edges()
	if alt_flag != "" and alt != "" and float(alt) > 0.0 and GameState.get_flag(alt_flag) != 0:
		var claim: = str(gate.get("claim_flag", ""))
		if claim == "" or GameState.get_flag(claim) == 0:
			return float(alt)
	return base if base > 0.0 else fallback


func _check_stat(stat_id: String, current: float, need: float) -> Dictionary:
	var sname: = L10n.t("stats.%s.name" % stat_id, stat_id)
	return {
		"id": "stat_%s" % stat_id, 
		"ok": current + 0.0001 >= need, 
		"label": L10n.tf(
			"ui.promo.check_stat", 
			{"stat": sname, "cur": int(current), "need": int(need)}, 
			"%s  %d / %d" % [sname, int(current), int(need)]
		), 
		"is_main": true, 
	}


func _gate_checks(gate: Dictionary) -> Array:
	var out: Array = []
	var npc: = str(gate.get("relation_npc", "")).strip_edges()
	if npc != "":
		var tmin: = str(gate.get("relation_trust_min", "")).strip_edges()
		if tmin != "" and float(tmin) > 0.0:
			var tv: = GameState.get_relation(npc, "player", "trust")
			var need_t: = float(tmin)
			var nname: = L10n.t("npcs.%s.name" % npc, npc)
			out.append({
				"id": "rel_trust", 
				"ok": tv + 0.0001 >= need_t, 
				"label": L10n.tf(
					"ui.promo.check_boss_trust", 
					{"npc": nname, "cur": int(tv), "need": int(need_t)}, 
					"%s信任  %d / %d" % [nname, int(tv), int(need_t)]
				), 
			})
		var fmin: = str(gate.get("relation_favor_min", "")).strip_edges()
		if fmin != "" and float(fmin) > 0.0:
			var fv: = GameState.get_relation(npc, "player", "favor")
			var need_f: = float(fmin)
			var nname2: = L10n.t("npcs.%s.name" % npc, npc)
			out.append({
				"id": "rel_favor", 
				"ok": fv + 0.0001 >= need_f, 
				"label": L10n.tf(
					"ui.promo.check_boss_favor", 
					{"npc": nname2, "cur": int(fv), "need": int(need_f)}, 
					"%s好感  %d / %d" % [nname2, int(fv), int(need_f)]
				), 
			})
	var smax: = str(gate.get("suspicion_max", "")).strip_edges()
	if smax != "":
		var sus: = GameState.get_stat("suspicion")
		var limit: = float(smax)
		out.append({
			"id": "suspicion", 
			"ok": sus < limit - 0.0001, 
			"label": L10n.tf(
				"ui.promo.check_suspicion", 
				{"cur": int(sus), "max": int(limit)}, 
				"嫌疑  %d ＜ %d" % [int(sus), int(limit)]
			), 
		})
	var tmax: = str(gate.get("tension_max", "")).strip_edges()
	if tmax != "":
		var ten: = GameState.get_stat("father_son_tension")
		var tlimit: = float(tmax)
		out.append({
			"id": "tension", 
			"ok": ten < tlimit - 0.0001, 
			"label": L10n.tf(
				"ui.promo.check_tension", 
				{"cur": int(ten), "max": int(tlimit)}, 
				"父子张力  %d ＜ %d" % [int(ten), int(tlimit)]
			), 
		})
	var req_flag: = str(gate.get("require_flag", "")).strip_edges()
	if req_flag != "":
		var want: = int(float(str(gate.get("require_flag_eq", "1"))))
		var got: = GameState.get_flag(req_flag)
		out.append({
			"id": "flag_%s" % req_flag, 
			"ok": got == want, 
			"label": L10n.t(
				"ui.promo.flag.%s" % req_flag, 
				L10n.t("flags.%s.description" % req_flag, req_flag)
			), 
		})
	var any_flags: = str(gate.get("require_any_flags", "")).strip_edges()
	if any_flags != "":
		var ok_any: = false
		for p in any_flags.split("|"):
			var fid: = str(p).strip_edges()
			if fid != "" and GameState.get_flag(fid) != 0:
				ok_any = true
				break
		out.append({
			"id": "any_flags", 
			"ok": ok_any, 
			"label": L10n.t(
				"ui.promo.any_flags.%s" % str(gate.get("id", "")), 
				L10n.t("ui.promo.check_any_flags", "完成情报售卖或挖人铺垫")
			), 
		})
	return out
