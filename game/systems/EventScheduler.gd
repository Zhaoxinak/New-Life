extends Node



signal event_available(event_id: String)
signal event_resolved(event_id: String, choice_id: String, applied: Array)

var active_event_id: String = ""
var _event_effects_applied: bool = false
var _fired_this_period: Dictionary = {}


func _ready() -> void :
	if not GameState.period_advanced.is_connected(_on_period):
		GameState.period_advanced.connect(_on_period)
	if not GameState.day_ended.is_connected(_on_day_ended):
		GameState.day_ended.connect(_on_day_ended)


func _on_period(_day: int, _period: String) -> void :
	_fired_this_period.clear()
	call_deferred("pulse")


func _on_day_ended(_completed: int) -> void :
	StockEngine.on_day_end()


func pulse() -> void :
	if GameState.game_over:
		return
	## Title / settings must not start events — EventPanel only exists in Main.
	if not SaveSystem.session_active:
		return
	if active_event_id != "":
		return
	if GameFlow.is_blocked():
		return
	var picked: = _pick_event()
	if picked.is_empty():
		EndingChecker.check_now()
		return
	start_event(str(picked.get("id", "")))


func start_event(event_id: String) -> void :
	active_event_id = event_id
	_event_effects_applied = false
	_fired_this_period[event_id] = true
	event_available.emit(event_id)


## Re-emit so EventPanel can open if start_event fired before Main was ready.
func present_active_event() -> void :
	if active_event_id.is_empty():
		return
	event_available.emit(active_event_id)


func ensure_event_effects() -> void :
	if active_event_id.is_empty() or _event_effects_applied:
		return
	EffectApplier.apply_owner("event", active_event_id)
	_event_effects_applied = true


func resolve_choice(choice_id: String) -> void :
	if active_event_id.is_empty():
		return
	ensure_event_effects()

	var applied: Array = []
	if choice_id != "":
		applied = EffectApplier.apply_owner("choice", choice_id)
	var eid: = active_event_id
	var count: = int(GameState.event_triggers.get(eid, 0)) + 1
	GameState.event_triggers[eid] = count
	if eid == "ev_day1_intro":
		GameState.set_flag("intro_lock", 0)
	active_event_id = ""
	_event_effects_applied = false
	ThresholdWatcher.evaluate_all()
	EndingChecker.check_now()
	event_resolved.emit(eid, choice_id, applied)

	call_deferred("pulse")


func _pick_event() -> Dictionary:
	var candidates: Array = []
	for row in PackDB.get_table("events"):
		if str(row.get("enabled", "1")) == "0":
			continue
		var eid: = str(row.get("id", ""))
		if _fired_this_period.get(eid, false):
			continue
		if not GameState.period_matches(str(row.get("period", "any"))):
			continue
		var max_t: = int(row.get("max_triggers", 0))
		var cur: = int(GameState.event_triggers.get(eid, 0))
		if max_t > 0 and cur >= max_t:
			continue
		var cond: = ConditionEval.eval_owner("event", eid)
		if not cond.get("ok", false):
			continue
		candidates.append(row)
	if candidates.is_empty():
		return {}
	candidates.sort_custom( func(a, b):
		var pa: = int(a.get("priority", 0))
		var pb: = int(b.get("priority", 0))
		if pa == pb:
			return int(a.get("weight", 0)) > int(b.get("weight", 0))
		return pa > pb
	)

	var top_p: = int(candidates[0].get("priority", 0))
	var band: Array = []
	var total_w: = 0
	for row in candidates:
		if int(row.get("priority", 0)) != top_p:
			break
		var w: = maxi(1, int(row.get("weight", 1)))
		band.append({"row": row, "w": w})
		total_w += w
	var roll: = GameState.rng.randi_range(1, total_w)
	var acc: = 0
	for item in band:
		acc += int(item["w"])
		if roll <= acc:
			return item["row"]
	return band[0]["row"]
