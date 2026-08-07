extends Node
## Evaluates conditions.csv rows against GameState.
## Semantics: within a cond_group → AND; across groups → OR.
## (Current pack only uses group 1.)


func eval_owner(owner_type: String, owner_id: String) -> Dictionary:
	## { ok: bool, reason: String, failed: Array }
	var rows: Array = PackDB.get_conditions(owner_type, owner_id)
	if rows.is_empty():
		return {"ok": true, "reason": "", "failed": []}

	var by_group: Dictionary = {}
	for row in rows:
		var g := str(row.get("cond_group", "1"))
		if not by_group.has(g):
			by_group[g] = []
		by_group[g].append(row)

	var any_group_ok := false
	var last_failed: Array = []
	for g in by_group.keys():
		var failed: Array = []
		var group_ok := true
		for row in by_group[g]:
			var one := eval_row(row)
			if not one.get("ok", false):
				group_ok = false
				failed.append(one)
		if group_ok:
			any_group_ok = true
			break
		last_failed = failed

	if any_group_ok:
		return {"ok": true, "reason": "", "failed": []}
	var reason := L10n.t("ui.action.locked", "尚未解锁")
	if not last_failed.is_empty():
		reason = str(last_failed[0].get("reason", reason))
	return {"ok": false, "reason": reason, "failed": last_failed}


func eval_row(row: Dictionary) -> Dictionary:
	var cond_type := str(row.get("cond_type", ""))
	var key := str(row.get("key", ""))
	var op := str(row.get("op", "eq"))
	var raw_value := str(row.get("value", ""))
	var actual: float = 0.0
	var expected: float = 0.0 if raw_value.is_empty() else float(raw_value)
	var label := key

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
			var parts := key.split(":", false)
			if parts.size() < 3:
				return {"ok": false, "reason": "bad relation key", "row": row}
			actual = GameState.get_relation(parts[0], parts[1], parts[2])
			label = key
		"rank_min":
			## key = rank id; pass if current career rank sort_order >= required
			var need := PackDB.get_row("ranks", key)
			if need.is_empty():
				return {"ok": false, "reason": "unknown rank %s" % key, "row": row}
			var cur_order := GameState.get_rank_sort_order()
			var need_order := int(need.get("sort_order", 999))
			actual = float(cur_order)
			expected = float(need_order)
			op = "gte"
			label = L10n.t("ranks.%s.name" % key, key)
		_:
			push_warning("ConditionEval: unknown cond_type '%s'" % cond_type)
			return {"ok": false, "reason": "unknown cond", "row": row}

	var ok := _compare(actual, op, expected)
	if ok:
		return {"ok": true, "reason": "", "row": row}
	return {
		"ok": false,
		"reason": "%s %s %s (现 %.0f)" % [label, op, str(expected), actual],
		"row": row,
		"actual": actual,
		"expected": expected,
	}


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
