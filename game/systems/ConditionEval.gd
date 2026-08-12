extends Node
## require / 条件求值（对齐 effect 词汇表 §3）。

const TIER_NAMES := {
	"仇隙": 1, "不睦": 2, "泛泛": 3, "相善": 4, "厚交": 5,
}


func eval_all(requires: Array) -> bool:
	for req in requires:
		if typeof(req) != TYPE_DICTIONARY:
			continue
		if not eval_one(req as Dictionary):
			return false
	return true


func eval_one(req: Dictionary) -> bool:
	if req.has("or"):
		var alts: Array = req["or"]
		for sub in alts:
			if typeof(sub) == TYPE_DICTIONARY and eval_one(sub as Dictionary):
				return true
		return false
	if req.has("and"):
		return eval_all(req["and"])

	if req.has("flag"):
		var flag_id := String(req["flag"])
		var expected: Variant = true
		if req.has("value"):
			expected = req["value"]
		var actual: Variant = RunState.get_flag(flag_id, false)
		var op := String(req.get("op", "=="))
		return _compare(actual, op, expected)

	if req.has("clue"):
		var owned := RunState.clues.has(String(req["clue"]))
		var want: bool = bool(req.get("owned", true))
		return owned == want

	if req.has("item"):
		var owned_i := RunState.items.has(String(req["item"]))
		var want_i: bool = bool(req.get("owned", true))
		return owned_i == want_i

	if req.has("loc"):
		return RunState.current_loc() == String(req["loc"])

	if req.has("slot_in"):
		var slots: Array = req["slot_in"]
		return slots.has(RunState.slot())

	if req.has("slot"):
		return _compare(RunState.slot(), String(req.get("op", "==")), String(req["slot"]))

	if req.has("rank_in"):
		var ranks: Array = req["rank_in"]
		return ranks.has(RunState.player_rank())

	if req.has("rank"):
		return _compare(RunState.player_rank(), String(req.get("op", "==")), String(req["rank"]))

	if req.has("grudge"):
		var gid := String(req["grudge"])
		var want_status := String(req.get("status", "open"))
		if want_status == "absent":
			return not RunState.grudges.has(gid) \
				or String(RunState.grudges[gid].get("status", "")) == "latent"
		if not RunState.grudges.has(gid):
			return false
		return String(RunState.grudges[gid].get("status", "")) == want_status

	if req.has("meter"):
		var actual_m: Variant = RunState.get_meter(String(req["meter"]))
		return _compare(actual_m, String(req.get("op", ">=")), req.get("value", 0))

	if req.has("org"):
		var org_id := String(req["org"])
		var key := String(req.get("key", ""))
		if key.is_empty():
			return RunState.orgs.has(org_id)
		var actual_o: Variant = RunState.get_org_field(org_id, key, 0)
		return _compare(actual_o, String(req.get("op", ">=")), req.get("value", 0))

	if req.has("day"):
		return _compare(RunState.day(), String(req.get("op", ">=")), int(req["day"]))

	if req.has("next_day_meeting"):
		var want := bool(req["next_day_meeting"])
		return MeetingSystem.next_day_is_meeting() == want

	if req.has("meeting_day"):
		var want_m := bool(req["meeting_day"])
		return MeetingSystem.is_meeting_day() == want_m

	if req.has("policy_leading"):
		return MeetingSystem.leading_policy_key() == String(req["policy_leading"])

	if req.has("meeting_tier"):
		MeetingSystem.ensure_state()
		return String(RunState.meeting.get("attendance_tier", "listen")) == String(req["meeting_tier"])

	if req.has("edge"):
		return _eval_edge(req)

	if req.has("key") and String(req["key"]).begins_with("stat_"):
		var actual_s: Variant = RunState.get_stat(String(req["key"]), 0)
		return _compare(actual_s, String(req.get("op", ">=")), req.get("value", 0))

	push_warning("ConditionEval: unrecognized require %s" % str(req))
	return true


func score_to_tier(score: float) -> String:
	if score <= -60.0:
		return "仇隙"
	if score <= -20.0:
		return "不睦"
	if score <= 19.0:
		return "泛泛"
	if score <= 59.0:
		return "相善"
	return "厚交"


func _eval_edge(req: Dictionary) -> bool:
	var edge: Dictionary = req["edge"] as Dictionary
	var e: Dictionary = RunState.get_edge(String(edge.get("from", "")), String(edge.get("to", "")))
	if req.has("tier_in"):
		var tier := score_to_tier(float(e.get("score", 0)))
		var allowed: Array = req["tier_in"]
		return allowed.has(tier)
	var key := String(req.get("key", "score"))
	var actual: Variant = e.get(key, 0)
	return _compare(actual, String(req.get("op", ">=")), req.get("value", 0))


func _compare(actual: Variant, op: String, expected: Variant) -> bool:
	match op:
		"==":
			return actual == expected
		"!=":
			return actual != expected
		">=":
			return float(actual) >= float(expected)
		"<=":
			return float(actual) <= float(expected)
		">":
			return float(actual) > float(expected)
		"<":
			return float(actual) < float(expected)
		_:
			push_warning("ConditionEval: bad op %s" % op)
			return false
