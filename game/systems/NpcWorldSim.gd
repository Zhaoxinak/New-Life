extends Node



func _ready() -> void :
	if not GameState.period_advanced.is_connected(_on_period):
		GameState.period_advanced.connect(_on_period)


func _on_period(_day: int, _period: String) -> void :
	_simulate_period()


func _simulate_period() -> void :
	var candidates: Array = []
	for row in PackDB.get_table("npc_beats"):
		if not _eligible(row):
			continue
		candidates.append(row)
	if candidates.is_empty():
		return

	var picks: = 1
	if str(GameState.period) == "morning" and GameState.rng.randf() < 0.35:
		picks = 2
	var used: Dictionary = {}
	for _i in picks:
		var row: = _weighted_pick(candidates, used)
		if row.is_empty():
			break
		used[str(row.get("id", ""))] = true
		_apply_beat(row)


func _eligible(row: Dictionary) -> bool:
	if str(row.get("enabled", "1")) in ["0", "false", "False"]:
		return false
	var bid: = str(row.get("id", ""))
	if str(row.get("once", "0")) in ["1", "true", "True"] and GameState.fired_npc_beats.has(bid):
		return false
	var day: = GameState.day
	if day < int(float(row.get("min_day", 1))) or day > int(float(row.get("max_day", 30))):
		return false
	var need_period: = str(row.get("period", "any")).strip_edges()
	if need_period != "" and need_period != "any" and need_period != GameState.period:
		return false
	var req: = str(row.get("require_flag", "")).strip_edges()
	if req != "" and GameState.get_flag(req, 0) < 1:
		return false
	var block: = str(row.get("block_flag", "")).strip_edges()
	if block != "" and GameState.get_flag(block, 0) >= 1:
		return false
	var route: = str(row.get("require_route", "")).strip_edges()
	if route != "" and GameState.get_flag(route, 0) < 1:
		return false
	return true


func _weighted_pick(candidates: Array, used: Dictionary) -> Dictionary:
	var total: = 0.0
	var pool: Array = []
	for row in candidates:
		var id: = str(row.get("id", ""))
		if used.has(id):
			continue
		var w: = maxf(1.0, float(row.get("weight", 10)))
		total += w
		pool.append(row)
	if pool.is_empty() or total <= 0.0:
		return {}
	var roll: = GameState.rng.randf() * total
	var acc: = 0.0
	for row in pool:
		acc += maxf(1.0, float(row.get("weight", 10)))
		if roll <= acc:
			return row
	return pool[pool.size() - 1]


func _apply_beat(row: Dictionary) -> void :
	var bid: = str(row.get("id", ""))
	var a: = str(row.get("actor_a", ""))
	var b: = str(row.get("actor_b", ""))
	var text_key: = str(row.get("text_key", ""))
	var src: = str(row.get("source_id", "")).strip_edges()
	var tgt: = str(row.get("target_id", "")).strip_edges()
	var rkey: = str(row.get("relation_key", "")).strip_edges()
	var rdelta: = float(row.get("relation_delta", 0))
	if src != "" and tgt != "" and rkey != "" and absf(rdelta) > 0.001:
		GameState.add_relation(src, tgt, rkey, rdelta)
	var tn: = str(row.get("trait_npc", "")).strip_edges()
	var tk: = str(row.get("trait_key", "")).strip_edges()
	var td: = float(row.get("trait_delta", 0))
	if tn != "" and tk != "" and absf(td) > 0.001:
		GameState.add_npc_trait(tn, tk, td)
	if str(row.get("once", "0")) in ["1", "true", "True"]:
		GameState.fired_npc_beats[bid] = true
	var body: = L10n.t(text_key, text_key)
	if body != "":
		GameState.last_chatter_text = body
		call_deferred("_toast_world_beat", body)
	GameState.append_relation_log({
		"day": GameState.day, 
		"period": GameState.period, 
		"npc_id": a, 
		"other_id": b, 
		"kind": "world", 
		"text_key": text_key, 
		"params": {}, 
	})
	TipSystem.queue_tip("tip_street_npc")


func _toast_world_beat(body: String) -> void :
	if body.strip_edges() == "":
		return
	var tree: = get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("beat_feed"):
		if n.has_method("push_notice"):
			n.push_notice(L10n.t("ui.chatter.title", "耳边闲话"), body)
			return
