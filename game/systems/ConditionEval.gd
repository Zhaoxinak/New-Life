extends Node





func eval_owner(owner_type: String, owner_id: String) -> Dictionary:

	var rows: Array = PackDB.get_conditions(owner_type, owner_id)
	if rows.is_empty():
		return {"ok": true, "reason": "", "failed": []}

	var by_group: Dictionary = {}
	for row in rows:
		var g: = str(row.get("cond_group", "1"))
		if not by_group.has(g):
			by_group[g] = []
		by_group[g].append(row)

	var any_group_ok: = false
	var last_failed: Array = []
	for g in by_group.keys():
		var failed: Array = []
		var group_ok: = true
		for row in by_group[g]:
			var one: = eval_row(row)
			if not one.get("ok", false):
				group_ok = false
				failed.append(one)
		if group_ok:
			any_group_ok = true
			break
		last_failed = failed

	if any_group_ok:
		return {"ok": true, "reason": "", "failed": []}
	var reason: = L10n.t("ui.action.locked", "尚未解锁")
	if not last_failed.is_empty():
		reason = str(last_failed[0].get("reason", reason))
	return {"ok": false, "reason": reason, "failed": last_failed}


func eval_row(row: Dictionary) -> Dictionary:
	var cond_type: = str(row.get("cond_type", ""))
	var key: = str(row.get("key", ""))
	var op: = str(row.get("op", "eq"))
	var raw_value: = str(row.get("value", ""))
	var actual: float = 0.0
	var expected: float = 0.0 if raw_value.is_empty() else float(raw_value)
	var label: = key

	match cond_type:
		"stat":
			actual = GameState.get_stat(key)
			label = L10n.t("stats.%s.name" % key, key)
		"flag":
			actual = float(GameState.get_flag(key))
			label = key
		"day":
			actual = float(GameState.day)
			label = L10n.t("ui.hud.day", "天数").replace("{day}", "").strip_edges()
			if label.is_empty():
				label = "day"
		"relation":
			var parts: = key.split(":", false)
			if parts.size() < 3:
				return {"ok": false, "reason": "bad relation key", "row": row}
			actual = GameState.get_relation(parts[0], parts[1], parts[2])
			label = key
		"rank_min":

			var need: = PackDB.get_row("ranks", key)
			if need.is_empty():
				return {"ok": false, "reason": "unknown rank %s" % key, "row": row}
			var need_track: = str(need.get("track_id", GameState.CAREER_TRACK))

			if GameState.active_career_track != need_track:
				actual = 0.0
				expected = float(int(need.get("sort_order", 999)))
				op = "gte"
				label = L10n.t("ranks.%s.name" % key, key)
			else:
				var cur_order: = GameState.get_rank_sort_order(need_track)
				var need_order: = int(need.get("sort_order", 999))
				actual = float(cur_order)
				expected = float(need_order)
				op = "gte"
				label = L10n.t("ranks.%s.name" % key, key)
		"weather":

			actual = 1.0 if GameState.weather == key else 0.0
			expected = 1.0 if raw_value.is_empty() else float(raw_value)
			label = L10n.t("weather.%s.name" % key, key)
		"period":

			actual = 1.0 if GameState.period == key else 0.0
			expected = 1.0 if raw_value.is_empty() else float(raw_value)
			label = L10n.t("periods.%s.name" % key, key)
		"employer":

			actual = 1.0 if GameState.employer_id == key else 0.0
			expected = 1.0 if raw_value.is_empty() else float(raw_value)
			label = L10n.t("ui.employer.%s" % key, key)
		"career_track":

			actual = 1.0 if GameState.active_career_track == key else 0.0
			expected = 1.0 if raw_value.is_empty() else float(raw_value)
			label = L10n.t("rank_tracks.%s.name" % key, key)
		_:
			push_warning("ConditionEval: unknown cond_type '%s'" % cond_type)
			return {"ok": false, "reason": "unknown cond", "row": row}

	var ok: = _compare(actual, op, expected)
	if ok:
		return {"ok": true, "reason": "", "row": row}
	var reason: = _fail_reason(cond_type, key, label, op, expected, actual)
	return {
		"ok": false, 
		"reason": reason, 
		"row": row, 
		"actual": actual, 
		"expected": expected, 
	}


func _fail_reason(
	cond_type: String, 
	key: String, 
	label: String, 
	op: String, 
	expected: float, 
	actual: float
) -> String:
	match cond_type:
		"weather":
			var cur: = L10n.t("weather.%s.name" % GameState.weather, GameState.weather)
			return L10n.tf(
				"ui.locked.reason_weather", 
				{"weather": cur}, 
				"当前天气（%s）不宜此举" % cur
			)
		"period":
			var pname: = L10n.t("periods.%s.name" % GameState.period, GameState.period)
			return L10n.tf(
				"ui.locked.reason_period_now", 
				{"period": pname}, 
				"当前时段（%s）不可用" % pname
			)
		"rank_min":
			return L10n.tf(
				"ui.locked.reason_rank", 
				{"rank": label}, 
				"职级不足：需%s" % label
			)
		"stat":
			return L10n.tf(
				"ui.locked.reason_stat", 
				{"stat": label, "value": int(expected)}, 
				"需要%s ≥ %d" % [label, int(expected)]
			)
		"flag":
			var custom: = L10n.t("ui.locked.flag.%s" % key, "")
			if custom != "" and custom != ("ui.locked.flag.%s" % key):
				return custom
			if is_equal_approx(expected, 0.0) and op == "eq":
				return L10n.tf(
					"ui.locked.reason_flag_clear", 
					{"flag": label}, 
					"条件未满足"
				)
			var desc: = L10n.t("flags.%s.description" % key, "")
			if desc != "" and desc != ("flags.%s.description" % key):
				return desc
			return L10n.t("ui.locked.reason_flag", "尚未达成所需剧情条件")
		"day":
			return L10n.tf("ui.unlock.day", {"day": int(expected)}, "第%d天开放" % int(expected))
		"employer":
			var cur_e: = L10n.t("ui.employer.%s" % GameState.employer_id, GameState.employer_id)
			var need_e: = label
			if op == "eq" and is_equal_approx(expected, 1.0):
				return L10n.tf(
					"ui.locked.reason_employer", 
					{"employer": need_e, "current": cur_e}, 
					"须在职于%s（现：%s）" % [need_e, cur_e]
				)
			return L10n.tf(
				"ui.locked.reason_employer_generic", 
				{"current": cur_e}, 
				"当前雇主不适用（%s）" % cur_e
			)
		"career_track":
			return L10n.tf(
				"ui.locked.reason_career", 
				{"track": label}, 
				"职涯轨道不符：需%s" % label
			)
		_:
			return "%s %s %s (现 %.0f)" % [label, op, str(expected), actual]


func _compare(actual: float, op: String, expected: float) -> bool:
	match op:
		"eq":
			return is_equal_approx(actual, expected)
		"gte":
			return actual >= expected - 0.0001
		"lte":
			return actual <= expected + 0.0001
		"gt":
			return actual > expected
		"lt":
			return actual < expected
		"neq":
			return not is_equal_approx(actual, expected)
		_:
			push_warning("ConditionEval: unknown op '%s'" % op)
			return false
