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
		"char_apprentice_xiao_chen": 43,
		"char_apprentice_xiao_liu": 30,
		"char_apprentice_a_fu": 35,
		"char_apprentice_sun_liu": 41,
	},
	"pool_waichang": {
		"char_lin_ruisheng": 30,
		"char_li_waichang": 33,
		"char_zhao_waichang": 31,
	},
	"pool_paojie": {
		"char_lin_ruisheng": 30,
		"char_qian_zian": 38,
	},
}

const NPC_WEEKLY_GROWTH := {
	"char_apprentice_xiao_chen": 5,
	"char_apprentice_xiao_liu": 1,
	"char_apprentice_a_fu": 3,
	"char_apprentice_sun_liu": 3,
	"char_li_waichang": 5,
	"char_zhao_waichang": 3,
	"char_qian_zian": 6,
}

## 各池「明面劲敌」候选人（建言席 / 压迫条）
const RIVAL_CANDIDATES := {
	"pool_apprentice": ["char_apprentice_xiao_chen", "char_apprentice_sun_liu"],
	"pool_waichang": ["char_li_waichang", "char_zhao_waichang"],
	"pool_paojie": ["char_qian_zian"],
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
		DomainBus.tip.emit(L10n.t("ui.duty_rail_hint", "右上已挂本周差事与序位"))


func init_council_queue(ids: Array) -> void:
	ensure_state()
	var q: Array = []
	for id_v in ids:
		q.append(String(id_v))
	RunState.meeting["council_queue"] = q
	RunState.meeting["council_index"] = 0
	RunState.meeting["council_log"] = []
	DomainBus.emit_domain("council_turn_changed", {
		"char": String(q[0]) if not q.is_empty() else "",
		"index": 0,
		"queue": q.duplicate(),
	})


func record_council_speech(fx: Dictionary) -> void:
	ensure_state()
	var entry := {
		"char": String(fx.get("char", "")),
		"spoke": bool(fx.get("spoke", false)),
		"topic_key": String(fx.get("topic_key", "")),
		"stance": String(fx.get("stance", "")),
		"mode": String(fx.get("mode", "speak" if bool(fx.get("spoke", false)) else "pass")),
		"ref": String(fx.get("ref", "")),
	}
	var log: Array = RunState.meeting.get("council_log", [])
	log.append(entry)
	RunState.meeting["council_log"] = log
	var idx := int(RunState.meeting.get("council_index", 0))
	RunState.meeting["council_index"] = idx + 1
	var q: Array = RunState.meeting.get("council_queue", [])
	var next_char := ""
	var next_idx := int(RunState.meeting["council_index"])
	if next_idx >= 0 and next_idx < q.size():
		next_char = String(q[next_idx])
	DomainBus.emit_domain("council_turn_changed", {
		"char": next_char,
		"index": next_idx,
		"queue": q.duplicate(),
		"last": entry,
	})


func last_council_spoke_entry() -> Dictionary:
	## 最近一条「真正开过口」的建言（忽略 pass / 空 stance）。
	ensure_state()
	var log: Array = RunState.meeting.get("council_log", [])
	for i in range(log.size() - 1, -1, -1):
		if typeof(log[i]) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = log[i]
		if bool(e.get("spoke", false)) and String(e.get("mode", "")) != "pass":
			return e
	return {}


func endorse_last_council() -> void:
	## decide 附议：加强上一发言者 stance，不另起话题。
	ensure_state()
	var last := last_council_spoke_entry()
	if last.is_empty():
		record_council_speech({
			"char": "char_lin_ruisheng",
			"spoke": false,
			"mode": "pass",
		})
		return
	var stance := String(last.get("stance", ""))
	if not stance.is_empty():
		add_policy_draft(stance, 2.0)
	record_council_speech({
		"char": "char_lin_ruisheng",
		"spoke": true,
		"stance": stance,
		"mode": "endorse",
		"topic_key": String(last.get("topic_key", "")),
		"ref": String(last.get("char", "")),
	})
	RunState.add_stat("stat_trust_firm", 1.0)
	DomainBus.tip.emit(L10n.t("ui.council_endorse", "你附议了刚才那一句"))


func is_council_brief() -> bool:
	## 简席：queue 里没有子安/仇人等「非常规压迫位」。
	ensure_state()
	var core := {
		"char_zhou_guanshi": true,
		"char_wang_pangzi": true,
		"char_lin_ruisheng": true,
		"char_qian_demao": true,
	}
	for qid_v in RunState.meeting.get("council_queue", []):
		var qid := String(qid_v)
		if qid.is_empty():
			continue
		if not core.has(qid):
			return false
	return true


func set_meeting_segment(segment: String) -> void:
	## 表现层切段信号；不写入数值权威（可不进存档）。
	var seg := segment.strip_edges()
	if seg.is_empty():
		return
	if seg not in ["rollcall", "report", "ceremony", "council", "policy", "tasks"]:
		push_warning("MeetingSystem: unknown segment %s" % seg)
	DomainBus.emit_domain("meeting_segment_changed", {"segment": seg})


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
	var progressed_labels: PackedStringArray = []
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
		var label := L10n.t(String(t.get("label_key", "")), tid)
		progressed_labels.append("%s %d/%d" % [label, int(t["progress"]), target])
		add_meeting_report(int(round(float(t.get("weight", 10)) * 0.25)))
		add_ladder_score("char_lin_ruisheng", 3.0)
	if progressed:
		DomainBus.emit_domain("meeting_tasks_changed", {})
		if not progressed_labels.is_empty():
			DomainBus.tip.emit(L10n.t("ui.duty_progress", "差事推进：%s") % " · ".join(progressed_labels))

	# 学徒池勤恳分
	if String(RunState.ladder.get("pool_id", "")) == "pool_apprentice" and act_id in ["act_01", "act_02"]:
		add_ladder_score("char_lin_ruisheng", 5.0)
		add_meeting_report(4)


func has_incomplete_weekly_tasks() -> bool:
	ensure_state()
	var tasks: Array = RunState.meeting.get("weekly_tasks", [])
	if tasks.is_empty():
		return false
	for t in tasks:
		if typeof(t) != TYPE_DICTIONARY:
			continue
		if int(t.get("progress", 0)) < int(t.get("target", 1)):
			return true
	return false


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
	var left := int(RunState.meeting.get("days_until_next", 0))
	DomainBus.emit_domain("meeting_changed", {
		"days_until_next": left,
	})
	## 临期压迫：差事未完 / 劲敌领先 → tip
	if left <= 2 and has_incomplete_weekly_tasks():
		DomainBus.tip.emit(L10n.t("ui.duty_deadline_nudge", "⚠ 距朝账还剩 %d 日——差事未完，堂上难看。") % maxi(left, 0))
	elif left <= 2:
		var rival := primary_rival()
		if not rival.is_empty():
			var gap := _ladder_score_of(rival) - _ladder_score_of("char_lin_ruisheng")
			if gap > 0.5:
				var rname := L10n.t(rival, rival)
				DomainBus.tip.emit(
					L10n.t("ui.duty_rival_nudge", "⚠ 距朝账还剩 %d 日——%s 还在往前蹿。") % [maxi(left, 0), rname]
				)


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
	var policy := String(RunState.meeting.get("last_policy", ""))
	var spoke_n := 0
	var pass_n := 0
	for entry in RunState.meeting.get("council_log", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if bool(entry.get("spoke", false)):
			spoke_n += 1
		else:
			pass_n += 1
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
	## 履历落笔，供账簿「朝账」页与往来回顾
	var sk := summary_key if not summary_key.is_empty() else String(RunState.meeting.get("last_summary_key", "meeting.summary.generic"))
	RunState.append_history("meeting", "meeting_%d" % int(RunState.meeting["cycle_index"]), sk, {
		"policy": policy,
		"spoke": spoke_n,
		"pass": pass_n,
		"cycle": int(RunState.meeting["cycle_index"]),
	})
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
	## 例行朝账：周 → 王 → 子安? → 仇人? → 玩家?
	## 跑街池劲敌即子安：已入队则不再重复塞 seat/queue
	var q: Array = ["char_zhou_guanshi", "char_wang_pangzi"]
	if bool(RunState.get_flag("flag_zian_arrived", false)):
		q.append("char_qian_zian")
	var rival := pick_meeting_rival()
	if not rival.is_empty() and not q.has(rival):
		q.append(rival)
	var tier := String(RunState.meeting.get("attendance_tier", "listen"))
	if tier in ["report", "decide"] or bool(RunState.get_flag("flag_meeting_report_eligible", false)):
		q.append("char_lin_ruisheng")
	return q


func rival_candidates() -> Array:
	ensure_state()
	var pool := String(RunState.ladder.get("pool_id", ""))
	if pool.is_empty():
		pool = pool_for_rank()
	var raw: Variant = RIVAL_CANDIDATES.get(pool, [])
	return (raw as Array).duplicate() if typeof(raw) == TYPE_ARRAY else []


func primary_rival() -> String:
	## 本池真正咬你的人：分差最近者（同分取更高分）。跑街=子安。
	ensure_state()
	var candidates := rival_candidates()
	if candidates.is_empty():
		## 兜底：池内最高非玩家
		var best_id := ""
		var best_sc := -1.0
		for e in sorted_ladder_entries():
			if typeof(e) != TYPE_DICTIONARY:
				continue
			var cid := String(e.get("char", e.get("char_id", "")))
			if cid.is_empty() or cid == "char_lin_ruisheng":
				continue
			var sc := float(e.get("score", 0))
			if sc > best_sc:
				best_sc = sc
				best_id = cid
		return best_id
	var player_score := _ladder_score_of("char_lin_ruisheng")
	var best_id := ""
	var best_key := 1.0e12
	for cid_v in candidates:
		var cid := String(cid_v)
		var sc := _ladder_score_of(cid)
		var gap := absf(player_score - sc)
		## 关键：更近优先；同距取领先你的；再同取分更高
		var lead_pen := 0.0 if sc >= player_score else 0.01
		var key := gap + lead_pen - sc * 0.0001
		if key < best_key:
			best_key = key
			best_id = cid
	return best_id


func pick_meeting_rival() -> String:
	## 满席压迫周：紧逼劲敌入建言席。跑街池子安已单独入队 → 此处不重复。
	ensure_state()
	var pool := String(RunState.ladder.get("pool_id", ""))
	if pool == "pool_paojie":
		return ""
	var rival := primary_rival()
	if rival.is_empty():
		return ""
	## 子安若已在队，不当第二席劲敌
	if rival == "char_qian_zian" and bool(RunState.get_flag("flag_zian_arrived", false)):
		return ""
	var player_score := _ladder_score_of("char_lin_ruisheng")
	var them := _ladder_score_of(rival)
	var cycle := int(RunState.meeting.get("cycle_index", 0))
	var tight := absf(player_score - them) <= 15.0
	var ahead := them >= player_score - 2.0
	## 首周必露脸；咬紧/领先必踩；其余偶数周例行踩一脚
	var routine_poke := cycle >= 1 and (cycle % 2 == 0)
	if cycle == 0 or tight or ahead or routine_poke:
		return rival
	return ""


func rival_style_line(char_id: String = "") -> String:
	## 差事条短评：让各阶段劲敌「人设」进压迫，而不只是一个分差数字。
	var cid := char_id if not char_id.is_empty() else primary_rival()
	if cid.is_empty():
		return ""
	match cid:
		"char_apprentice_xiao_chen":
			return L10n.t("ui.rival_style.chen", "闷头攒分，货单从不拖")
		"char_apprentice_sun_liu":
			return L10n.t("ui.rival_style.sun", "会做人，朝账周最爱蹿")
		"char_li_waichang":
			return L10n.t("ui.rival_style.li", "差事回得稳，专吃你偷懒")
		"char_zhao_waichang":
			return L10n.t("ui.rival_style.zhao", "媚上嘴快，东家信他时猛涨")
		"char_qian_zian":
			return L10n.t("ui.rival_style.zian", "少爷加成压你一头")
		_:
			return ""


func _ladder_score_of(char_id: String) -> float:
	for e in RunState.ladder.get("entries", []):
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var cid := String(e.get("char", e.get("char_id", "")))
		if cid == char_id:
			return float(e.get("score", 0))
	return 0.0


func ladder_score_of(char_id: String) -> float:
	ensure_state()
	return _ladder_score_of(char_id)


func rival_pressure_line() -> String:
	## 压迫条 / 席位共用：劲敌姓名、分差、人设短评。
	ensure_state()
	var rival := primary_rival()
	if rival.is_empty():
		return ""
	var you := _ladder_score_of("char_lin_ruisheng")
	var them := _ladder_score_of(rival)
	var name := L10n.t(rival, rival)
	var gap := them - you
	var head := ""
	if gap > 0.5:
		head = L10n.t("ui.duty_rival_lead", "[color=#a02818]劲敌 %s[/color] 领先 %.0f") % [name, gap]
	elif gap < -0.5:
		head = L10n.t("ui.duty_rival_trail", "[color=#2e6a2a]劲敌 %s[/color] 落后你 %.0f") % [name, -gap]
	else:
		head = L10n.t("ui.duty_rival_neck", "[color=#7a4210]劲敌 %s[/color] 咬得很紧") % name
	var style := rival_style_line(rival)
	if style.is_empty():
		return head
	return "%s\n[color=#3a2818]%s[/color]" % [head, style]


func duty_rail_bbcode() -> String:
	ensure_state()
	var lines: PackedStringArray = []
	var days := int(RunState.meeting.get("days_until_next", 0))
	if is_meeting_day() and days == 0:
		lines.append("[b]%s[/b]" % L10n.t("ui.duty_urgent_today", "⚠ 今日朝账"))
	elif days <= 2:
		lines.append("[b][color=#a02818]%s[/color][/b]" % (L10n.t("ui.duty_urgent_days", "⚠ 距朝账 %d 日") % maxi(days, 0)))
	else:
		lines.append("[b]%s[/b]" % (L10n.t("ui.meeting_in_days", "距朝账 %d日") % days))

	var tasks: Array = RunState.meeting.get("weekly_tasks", [])
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ui.duty_tasks_title", "本周差事"))
	if tasks.is_empty():
		lines.append(L10n.t("ui.duty_tasks_empty", "暂无派发 — 歇气或点热区行事，差事会挂上来"))
	else:
		var done_n := 0
		for t in tasks:
			if typeof(t) != TYPE_DICTIONARY:
				continue
			var prog := int(t.get("progress", 0))
			var tgt := maxi(1, int(t.get("target", 1)))
			var label := L10n.t(String(t.get("label_key", "")), String(t.get("id", "")))
			if prog >= tgt:
				done_n += 1
				lines.append("[color=#2e6a2a]✓ %s %d/%d[/color]" % [label, prog, tgt])
			else:
				var left := tgt - prog
				lines.append("[color=#a02818]· %s %d/%d[/color] 还差%d" % [label, prog, tgt, left])
		var all_done := done_n >= tasks.size() and not tasks.is_empty()
		if not all_done and days <= 3:
			lines.append(L10n.t("ui.duty_tasks_pressure", "朝账前回不完，堂上难看。"))

	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ui.duty_ladder_title", "序位"))
	var rank := int(RunState.ladder.get("player_rank", 0))
	var total := int(RunState.ladder.get("player_total", 0))
	var delta := int(RunState.ladder.get("last_delta", 0))
	if total > 0 and rank > 0:
		var rank_line := L10n.t("ui.duty_rank_you", "你：第 %d / %d") % [rank, total]
		if delta > 0:
			rank_line += " [color=#2e6a2a]↑%d[/color]" % delta
		elif delta < 0:
			rank_line += " [color=#a02818]↓%d[/color]" % (-delta)
		lines.append(rank_line)
		if rank >= maxi(2, int((total + 1) / 2)):
			lines.append(L10n.t("ui.duty_rank_pressure", "名次偏后——下周仪典有风险。"))
	else:
		lines.append(L10n.t("ui.ladder_pending", "序位 —"))

	var top: Array = sorted_ladder_entries()
	for i in range(mini(3, top.size())):
		var e: Dictionary = top[i]
		var cid := String(e.get("char", e.get("char_id", "")))
		var mark := "★" if cid == "char_lin_ruisheng" or bool(e.get("is_player", false)) else " "
		lines.append("%s%d. %s  %.0f" % [mark, i + 1, L10n.t(cid, cid), float(e.get("score", 0))])

	var rival_line := rival_pressure_line()
	if not rival_line.is_empty():
		lines.append("")
		lines.append(rival_line)
	return "\n".join(lines)


func should_show_duty_rail() -> bool:
	ensure_state()
	if not RunState.meeting.get("weekly_tasks", []).is_empty():
		return true
	if not RunState.ladder.get("entries", []).is_empty():
		return true
	return int(RunState.meeting.get("cycle_index", 0)) > 0


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
	var incomplete := has_incomplete_weekly_tasks()
	var trust := float(RunState.get_stat("stat_trust_firm", 0))
	var father_son := float(RunState.get_meter("father_son", 0.0))
	for e in RunState.ladder.get("entries", []):
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if bool(e.get("is_player", false)):
			continue
		var cid := String(e.get("char_id", e.get("char", "")))
		var growth := int(NPC_WEEKLY_GROWTH.get(cid, 3))
		var noise := 0
		var bias := 0
		match cid:
			"char_apprentice_xiao_chen":
				## 闷头稳涨；你差事拖着，他更显眼
				noise = _rng.randi_range(0, 2)
				if incomplete:
					bias += 5
			"char_apprentice_xiao_liu":
				## 偷懒滑头：偶尔蹭到前排
				noise = _rng.randi_range(-5, 11)
			"char_apprentice_a_fu":
				noise = _rng.randi_range(-2, 3)
			"char_apprentice_sun_liu":
				## 拍马：朝账周爱蹿；你松懈时更敢踩
				noise = _rng.randi_range(-1, 4)
				bias += _rng.randi_range(2, 10)
				if incomplete:
					bias += 6
				if trust >= 40.0:
					bias += 3
			"char_li_waichang":
				## 实干：差事完成度稳；吃你偷懒
				noise = _rng.randi_range(0, 3)
				if incomplete:
					bias += 6
				else:
					bias += 2
			"char_zhao_waichang":
				## 媚上：东家信任高时猛涨
				noise = _rng.randi_range(-2, 3)
				bias += clampi(int(trust / 12.0), 0, 8)
				if trust >= 55.0:
					bias += 4
			"char_qian_zian":
				## 少爷：身份加成 + 父子分利
				noise = _rng.randi_range(-1, 4)
				if bool(RunState.get_flag("flag_zian_arrived", false)):
					bias += 12
				if father_son >= 20.0:
					bias += 4
				elif father_son <= -20.0:
					bias -= 3
			_:
				noise = _rng.randi_range(-2, 3)
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
