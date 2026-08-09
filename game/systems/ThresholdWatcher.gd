extends Node



func evaluate_all() -> Array[String]:
	var fired_now: Array[String] = []
	if GameState.game_over:
		return fired_now
	for row in PackDB.get_table("thresholds"):
		if str(row.get("enabled", "1")) == "0":
			continue
		var tid: = str(row.get("id", ""))
		var once: = str(row.get("once", "0")) == "1"
		if once and GameState.fired_thresholds.get(tid, false):
			continue
		var ok: = ConditionEval.eval_owner("threshold", tid)
		if not ok.get("ok", false):
			continue
		EffectApplier.apply_owner("threshold", tid)
		if once:
			GameState.fired_thresholds[tid] = true
		fired_now.append(tid)
	if not fired_now.is_empty():
		EndingChecker.check_now()
	return fired_now
