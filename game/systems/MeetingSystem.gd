extends Node
## 朝账 + 序位战：run_meeting / run_ladder 权威读写。

const TASK_DEFS := {
	"task_tidy_manifest": {"label_key": "meeting.task.tidy_manifest", "target": 2, "weight": 15, "acts": ["act_02"]},
	"task_front_duty": {"label_key": "meeting.task.front_duty", "target": 1, "weight": 12, "acts": ["act_01"]},
	"task_errand": {"label_key": "meeting.task.errand", "target": 1, "weight": 10, "acts": ["act_01"]},
	"task_street_watch": {"label_key": "meeting.task.street_watch", "target": 1, "weight": 18, "acts": ["act_07", "act_09"]},
	"task_delivery": {"label_key": "meeting.task.delivery", "target": 2, "weight": 15, "acts": ["act_01"]},
	"task_intel": {"label_key": "meeting.task.intel", "target": 1, "weight": 20, "acts": ["act_03", "act_12"]},
	"task_entertain": {"label_key": "meeting.task.entertain", "target": 1, "weight": 20, "acts": ["act_07"]},
	"task_lead_clerk": {"label_key": "meeting.task.lead_clerk", "target": 1, "weight": 15, "acts": ["act_05"]},
}

const POOL_ROSTERS := {
	"pool_apprentice": [
		"char_lin_ruisheng",
		"char_apprentice_xiao_chen",
		"char_apprentice_xiao_liu",
		"char_apprentice_a_fu",
		"char_apprentice_sun_liu",
	],
	"pool_waichang": [
		"char_lin_ruisheng",
		"char_li_waichang",
		"char_zhao_waichang",
	],
	"pool_paojie": [
		"char_lin_ruisheng",
		"char_qian_zian",
	],
}

const POOL_BASE_SCORE := {
	"pool_apprentice": {
		"char_lin_ruisheng": 40,
		"char_apprentice_xiao_chen": 44,
		"char_apprentice_xiao_liu": 32,
		"char_apprentice_a_fu": 36,
		"char_apprentice_sun_liu": 38,
	},
	"pool_waichang": {
		"char_lin_ruisheng": 30,
		"char_li_waichang": 34,
		"char_zhao_waichang": 32,
	},
	"pool_paojie": {
		"char_lin_ruisheng": 28,
		"char_qian_zian": 40,
	},
}

const NPC_WEEKLY_GROWTH := {
	"char_apprentice_xiao_chen": 4,
	"char_apprentice_xiao_liu": 2,
	"char_apprentice_a_fu": 3,
	"char_apprentice_sun_liu": 3,
	"char_li_waichang": 5,
	"char_zhao_waichang": 4,
	"char_qian_zian": 6,
}

var _rng := RandomNumberGenerator.new()
## 本周基准（finalize 用）
var _week_trust0: float = 0.0
var _week_intel0: float = 0.0
var _week_suspicion0: float = 0.0


func _ready() -> void:
	_rng.randomize()
	DomainBus.rank_changed.connect(_on_rank_changed)
	DomainBus.day_ended.connect(_on_day_ended_countdown)


func default_meeting() -> Dictionary:
	return {
		"cycle_index": 0,
		"days_until_next": 0, # Day1 即朝账日
		"report_score": 0,
		"attendance_tier": "listen",
		"weekly_tasks": [],
		"last_summary_key": "",
		"council_queue": [],
		"council_index": 0,
		"council_log": [],
		"policy_draft": {},
	}


func default_ladder() -> Dictionary:
	return {
		"pool_id": "",
		"cycle_week": 0,
		"promotion_slots": 1,
		"entries": [],
		"player_rank": 0,
		"player_total": 0,
		"last_delta": 0,
	}


func ensure_state() -> void:
	if RunState.meeting.is_empty():
		RunState.meeting = default_meeting()
	if RunState.ladder.is_empty():
		RunState.ladder = default_ladder()


func is_meeting_day(day: int = -1) -> bool:
	var d := day if day >= 1 else RunState.day()
	return d % 7 == 1


func next_day_is_meeting() -> bool:
	return is_meeting_day(RunState.day() + 1)


func pool_for_rank(rank: String = "") -> String:
	var r := rank if not rank.is_empty() else RunState.player_rank()
	match r:
		"apprentice":
			return "pool_apprentice"
		"waichang":
			return "pool_waichang"
		"paojie", "houtang":
			return "pool_paojie"
		_:
			return "pool_apprentice"


func init_ladder_pool(pool_id: String) -> void:
	ensure_state()
	if pool_id.is_empty():
		pool_id = pool_for_rank()
	var roster: Array = POOL_ROSTERS.get(pool_id, POOL_ROSTERS["pool_apprentice"])
	var bases: Dictionary = POOL_BASE_SCORE.get(pool_id, {})
	var entries: Array = []
	for cid_v in roster:
		var cid := String(cid_v)
		entries.append({
			"char_id": cid,
			"score": float(bases.get(cid, 30)),
			"is_player": cid == "char_lin_ruisheng",
			"trend": 0,
		})
	RunState.ladder = {
		"pool_id": pool_id,
		"cycle_week": 1,
		"promotion_slots": int(RunState.ladder.get("promotion_slots", 1)),
		"entries": entries,
		"player_rank": 0,
		"player_total": entries.size(),
		"last_delta": 0,
	}
	_recompute_player_rank(true)
	DomainBus.emit_domain("ladder_rank_changed", _ladder_payload())


func add_ladder_score(char_id: String, value: float) -> void:
	ensure_state()
	if String(RunState.ladder.get("pool_id", "")).is_empty():
		init_ladder_pool(pool_for_rank())
	var before := int(RunState.ladder.get("player_rank", 0))
	for e in RunState.ladder.get("entries", []):
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if String(e.get("char_id", "")) == char_id:
			e["score"] = float(e.get("score", 0)) + value
			break
	_recompute_player_rank(false)
	var after := int(RunState.ladder.get("player_rank", 0))
	RunState.ladder["last_delta"] = before - after # 名次数字变小=上升
	DomainBus.emit_domain("ladder_rank_changed", _ladder_payload())


func bias_ladder_npc(char_id: String, value: float) -> void:
	add_ladder_score(char_id, value)


func set_ladder_slots(value: int) -> void:
	ensure_state()
	RunState.ladder["promotion_slots"] = maxi(0, value)


func set_meeting_tier(tier: String) -> void:
	ensure_state()
	if tier not in ["listen", "report", "decide"]:
		return
	RunState.meeting["attendance_tier"] = tier
	DomainBus.emit_domain("meeting_changed", {"tier": tier})


func add_meeting_report(value: int) -> void:
	ensure_state()
	var cur := int(RunState.meeting.get("report_score", 0))
	RunState.meeting["report_score"] = clampi(cur + value, 0, 100)


func assign_weekly_tasks(ids: Array) -> void:
	ensure_state()
	var tasks: Array = []
	for id_v in ids:
		var tid := String(id_v)
		var def: Dictionary = TASK_DEFS.get(tid, {})
		if def.is_empty():
			continue
		tasks.append({
			"id": tid,
			"label_key": String(def.get("label_key", tid)),
			"target": int(def.get("target", 1)),
			"progress": 0,
			"weight": int(def.get("weight", 10)),
		})
	RunState.meeting["weekly_tasks"] = tasks
	DomainBus.emit_domain("meeting_tasks_changed", {"count": tasks.size()})
	if not tasks.is_empty():
		DomainBus.tip.emit(L10n.t("ui.meeting_tasks_assigned", "本周差事已摊派"))


func init_council_queue(ids: Array) -> void:
	ensure_state()
	var q: Array = []
	for id_v in ids:
		q.append(String(id_v))
	RunState.meeting["council_queue"] = q
	RunState.meeting["council_index"] = 0
	RunState.meeting["council_log"] = []


func record_council_speech(fx: Dictionary) -> void:
	ensure_state()
	var entry := {
		"char": String(fx.get("char", "")),
		"spoke": bool(fx.get("spoke", false)),
		"topic_key": String(fx.get("topic_key", "")),
		"stance": String(fx.get("stance", "")),
		"mode": String(fx.get("mode", "speak" if bool(fx.get("spoke", false)) else "pass")),
	}
	var log: Array = RunState.meeting.get("council_log", [])
	log.append(entry)
	RunState.meeting["council_log"] = log
	var idx := int(RunState.meeting.get("council_index", 0))
	RunState.meeting["council_index"] = idx + 1


func add_policy_draft(key: String, value: float) -> void:
	ensure_state()
	if key.is_empty():
		return
	var draft: Dictionary = RunState.meeting.get("policy_draft", {})
	draft[key] = float(draft.get(key, 0)) + value
	RunState.meeting["policy_draft"] = draft


func on_player_action(act_id: String) -> void:
	ensure_state()
	var progressed := false
	var tasks: Array = RunState.meeting.get("weekly_tasks", [])
	for t in tasks:
		if typeof(t) != TYPE_DICTIONARY:
			continue
		var tid := String(t.get("id", ""))
		var def: Dictionary = TASK_DEFS.get(tid, {})
		var acts: Array = def.get("acts", [])
		if not acts.has(act_id):
			continue
		var prog := int(t.get("progress", 0))
		var target := int(t.get("target", 1))
		if prog >= target:
			continue
		t["progress"] = prog + 1
		progressed = true
		add_meeting_report(int(round(float(t.get("weight", 10)) * 0.25)))
		add_ladder_score("char_lin_ruisheng", 3.0)
	if progressed:
		DomainBus.emit_domain("meeting_tasks_changed", {})

	# 学徒池勤恳分
	if String(RunState.ladder.get("pool_id", "")) == "pool_apprentice" and act_id in ["act_01", "act_02"]:
		add_ladder_score("char_lin_ruisheng", 5.0)
		add_meeting_report(4)


func on_day_end() -> void:
	## TickPipeline 在 late_night→次日 之后调用；此时 day 已是新的一天。
	## 若今日为朝账日，则结算「上周」汇报分与 NPC 周增长（供早上朝账播报）。
	ensure_state()
	if is_meeting_day():
		finalize_meeting_report()
		_npc_weekly_tick()


func _on_day_ended_countdown(_ended_day: int) -> void:
	ensure_state()
	# advance_slot 已把 day+1；此处对「刚结束的一天」做倒数
	# TickPipeline 在 late→next day 后调用 on_day_end hooks；days_until_next 在朝账结束时重置
	var days := int(RunState.meeting.get("days_until_next", 7))
	if days > 0:
		RunState.meeting["days_until_next"] = days - 1
	DomainBus.emit_domain("meeting_changed", {
		"days_until_next": int(RunState.meeting.get("days_until_next", 0)),
	})


func finalize_meeting_report() -> void:
	ensure_state()
	var score := 0
	# 差事完成
	var tasks: Array = RunState.meeting.get("weekly_tasks", [])
	var any_task := not tasks.is_empty()
	var all_done := any_task
	var any_incomplete := false
	for t in tasks:
		if typeof(t) != TYPE_DICTIONARY:
			continue
		var prog := int(t.get("progress", 0))
		var target := int(t.get("target", 1))
		if prog >= target:
			score += int(t.get("weight", 10))
		else:
			all_done = false
			any_incomplete = true
	if any_incomplete:
		score -= 15
	if all_done and any_task:
		score += 10

	var trust_delta := float(RunState.get_stat("stat_trust_firm", 0)) - _week_trust0
	var intel_delta := float(RunState.get_stat("stat_intel", 0)) - _week_intel0
	var sus_delta := float(RunState.get_stat("stat_suspicion", 0)) - _week_suspicion0
	score += clampi(int(trust_delta / 2.0), 0, 10)
	score += clampi(int(intel_delta / 3.0), 0, 8)
	if sus_delta >= 10.0:
		score -= 10
	if bool(RunState.get_flag("flag_demoted", false)):
		score = mini(score, 40)

	score = clampi(score + int(RunState.meeting.get("report_score", 0)), 0, 100)
	RunState.meeting["report_score"] = score
	# 50% 权重入序位池
	add_ladder_score("char_lin_ruisheng", float(score) * 0.5)
	_reset_week_baselines()
	DomainBus.emit_domain("meeting_report_finalized", {"score": score})


func complete_meeting_cycle(summary_key: String = "") -> void:
	ensure_state()
	RunState.meeting["cycle_index"] = int(RunState.meeting.get("cycle_index", 0)) + 1
	RunState.meeting["days_until_next"] = 7
	RunState.meeting["report_score"] = 0
	RunState.meeting["council_queue"] = []
	RunState.meeting["council_index"] = 0
	RunState.meeting["council_log"] = []
	# 保留 last_policy 供账簿/摘要；清空草稿
	RunState.meeting["policy_draft"] = {}
	if not summary_key.is_empty():
		RunState.meeting["last_summary_key"] = summary_key
	var week := int(RunState.ladder.get("cycle_week", 0))
	RunState.ladder["cycle_week"] = week + 1
	_reset_week_baselines()
	DomainBus.emit_domain("meeting_changed", {"cycle_index": RunState.meeting["cycle_index"]})


func leading_policy_key() -> String:
	ensure_state()
	var cached := String(RunState.meeting.get("last_policy", ""))
	if not cached.is_empty():
		return cached
	return _compute_leading_policy()


func resolve_meeting_policy() -> String:
	## ⑤ 定调：取 policy_draft 最高项；玩家对齐则信任+；黑线被驳则嫌疑+。
	ensure_state()
	var key := _compute_leading_policy()
	if key.is_empty():
		key = "bright_steady"
	RunState.meeting["last_policy"] = key

	var player_stance := _player_council_stance()
	if not player_stance.is_empty() and player_stance == key:
		RunState.add_stat("stat_trust_firm", 2.0)
		DomainBus.tip.emit(L10n.t("ui.policy_aligned", "你的建言与东家定调相合"))
	elif player_stance in ["risk_report", "manifest_risk"] and key != player_stance:
		RunState.add_stat("stat_suspicion", 5.0)
		DomainBus.tip.emit(L10n.t("ui.policy_rebuked", "东家驳回了你的直陈——眼神沉了沉"))

	DomainBus.emit_domain("meeting_policy_resolved", {"policy": key, "player_stance": player_stance})
	return key


func build_default_council_queue() -> Array:
	## 例行朝账发言顺序：周 → 王 → 子安(若到) → 玩家(若可汇报)
	var q: Array = ["char_zhou_guanshi", "char_wang_pangzi"]
	if bool(RunState.get_flag("flag_zian_arrived", false)):
		q.append("char_qian_zian")
	var tier := String(RunState.meeting.get("attendance_tier", "listen"))
	if tier in ["report", "decide"] or bool(RunState.get_flag("flag_meeting_report_eligible", false)):
		q.append("char_lin_ruisheng")
	return q


func default_tasks_for_rank() -> Array:
	match RunState.player_rank():
		"waichang":
			return ["task_street_watch", "task_delivery"]
		"paojie", "houtang":
			return ["task_entertain", "task_lead_clerk"]
		_:
			return ["task_tidy_manifest", "task_front_duty"]


func apply_route_policy_bias() -> void:
	## 例行朝账开场：按路线给建言池一点底噪，影响 ⑤ 定调。
	if bool(RunState.get_flag("route_defect", false)):
		add_policy_draft("watch_jufeng", 1.0)
	elif bool(RunState.get_flag("route_foreign", false)):
		add_policy_draft("foreign_caution", 1.0)
	else:
		add_policy_draft("bright_steady", 1.0)


func sorted_ladder_entries() -> Array:
	ensure_state()
	var entries: Array = RunState.ladder.get("entries", []).duplicate()
	entries.sort_custom(func(a, b): return float(a.get("score", 0)) > float(b.get("score", 0)))
	return entries


func _compute_leading_policy() -> String:
	var draft: Dictionary = RunState.meeting.get("policy_draft", {})
	var best_key := ""
	var best_val := -999999.0
	for k in draft.keys():
		var v := float(draft[k])
		if v > best_val:
			best_val = v
			best_key = String(k)
	return best_key


func _player_council_stance() -> String:
	var log: Array = RunState.meeting.get("council_log", [])
	for i in range(log.size() - 1, -1, -1):
		var e = log[i]
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if String(e.get("char", "")) != "char_lin_ruisheng":
			continue
		if not bool(e.get("spoke", false)):
			return ""
		return String(e.get("stance", ""))
	return ""


func hud_ladder_text() -> String:
	ensure_state()
	var pool := String(RunState.ladder.get("pool_id", ""))
	if pool.is_empty() or RunState.ladder.get("entries", []).is_empty():
		return ""
	var pool_name := L10n.t("ladder.%s.name" % pool, _pool_fallback(pool))
	var rank := int(RunState.ladder.get("player_rank", 0))
	var total := int(RunState.ladder.get("player_total", 0))
	var delta := int(RunState.ladder.get("last_delta", 0))
	var arrow := ""
	if delta > 0:
		arrow = " ↑%d" % delta
	elif delta < 0:
		arrow = " ↓%d" % (-delta)
	return "%s %d/%d%s" % [pool_name, rank, total, arrow]


func hud_meeting_text() -> String:
	ensure_state()
	var days := int(RunState.meeting.get("days_until_next", 0))
	if is_meeting_day() and days == 0:
		return L10n.t("ui.meeting_today", "今日朝账")
	return L10n.t("ui.meeting_in_days", "距朝账 %d日") % maxi(days, 0)


func _pool_fallback(pool: String) -> String:
	match pool:
		"pool_apprentice":
			return "学徒序"
		"pool_waichang":
			return "外场序"
		"pool_paojie":
			return "跑街序"
		_:
			return "序位"


func _recompute_player_rank(reset_delta: bool) -> void:
	var entries: Array = RunState.ladder.get("entries", [])
	var sorted: Array = entries.duplicate()
	sorted.sort_custom(func(a, b): return float(a.get("score", 0)) > float(b.get("score", 0)))
	var rank := 0
	for i in range(sorted.size()):
		if bool(sorted[i].get("is_player", false)) or String(sorted[i].get("char_id", "")) == "char_lin_ruisheng":
			rank = i + 1
			break
	RunState.ladder["player_rank"] = rank
	RunState.ladder["player_total"] = entries.size()
	if reset_delta:
		RunState.ladder["last_delta"] = 0


func _npc_weekly_tick() -> void:
	ensure_state()
	if String(RunState.ladder.get("pool_id", "")).is_empty():
		return
	for e in RunState.ladder.get("entries", []):
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if bool(e.get("is_player", false)):
			continue
		var cid := String(e.get("char_id", ""))
		var growth := int(NPC_WEEKLY_GROWTH.get(cid, 3))
		var noise := _rng.randi_range(-2, 3)
		var bias := 0
		if cid == "char_qian_zian" and bool(RunState.get_flag("flag_zian_arrived", false)):
			bias += 12
		if cid == "char_apprentice_sun_liu":
			bias += _rng.randi_range(0, 8)
		e["score"] = float(e.get("score", 0)) + growth + noise + bias
	_recompute_player_rank(false)
	DomainBus.emit_domain("ladder_rank_changed", _ladder_payload())


func _on_rank_changed(_old: String, new_rank: String) -> void:
	ensure_state()
	var want := pool_for_rank(new_rank)
	if String(RunState.ladder.get("pool_id", "")) != want:
		init_ladder_pool(want)
	# 升外场后默认可汇报
	if new_rank in ["waichang", "paojie", "houtang"]:
		if not bool(RunState.get_flag("flag_meeting_report_eligible", false)):
			RunState.set_flag("flag_meeting_report_eligible", true)
		if new_rank == "waichang":
			set_meeting_tier("report")
		elif new_rank in ["paojie", "houtang"]:
			set_meeting_tier("decide")


func _reset_week_baselines() -> void:
	_week_trust0 = float(RunState.get_stat("stat_trust_firm", 0))
	_week_intel0 = float(RunState.get_stat("stat_intel", 0))
	_week_suspicion0 = float(RunState.get_stat("stat_suspicion", 0))


func _ladder_payload() -> Dictionary:
	return {
		"pool_id": String(RunState.ladder.get("pool_id", "")),
		"player_rank": int(RunState.ladder.get("player_rank", 0)),
		"player_total": int(RunState.ladder.get("player_total", 0)),
		"last_delta": int(RunState.ladder.get("last_delta", 0)),
	}


func bootstrap_new_game() -> void:
	RunState.meeting = default_meeting()
	RunState.ladder = default_ladder()
	_reset_week_baselines()
