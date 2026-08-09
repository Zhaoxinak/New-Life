extends Node



func check_now() -> String:
	if GameState.game_over:
		return GameState.active_ending_id
	var endings: Array = []
	for row in PackDB.get_table("endings"):
		if str(row.get("enabled", "1")) == "0":
			continue
		endings.append(row)
	endings.sort_custom( func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	for row in endings:
		var eid: = str(row.get("id", ""))
		var ok: = ConditionEval.eval_owner("ending", eid)
		if ok.get("ok", false):
			GameState.mark_ending(eid)
			return eid
	return ""
