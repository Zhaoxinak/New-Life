extends Node



func apply_owner(owner_type: String, owner_id: String) -> Array[Dictionary]:
	var applied: Array[Dictionary] = []
	for row in PackDB.get_effects(owner_type, owner_id):
		if _apply_row(row):
			applied.append(row)
	return applied


func apply_rows(rows: Array) -> Array[Dictionary]:
	var applied: Array[Dictionary] = []
	for row in rows:
		if _apply_row(row):
			applied.append(row)
	return applied


func _apply_row(row: Dictionary) -> bool:
	var chance: = float(row.get("chance", 1))
	if chance < 1.0 and GameState.rng.randf() > chance:
		return false
	var effect_type: = str(row.get("effect_type", ""))
	var key: = str(row.get("key", ""))
	var op: = str(row.get("op", "add"))
	var value: = float(row.get("value", 0))
	var target: = str(row.get("target", ""))
	match effect_type:
		"stat":
			_apply_stat(key, op, value)
		"flag":
			_apply_flag(key, op, value)
		"relation":

			_apply_relation(key if not key.is_empty() else target, op, value)
		"weather":
			WeatherSystem.set_weather_now(key if not key.is_empty() else target)
		"employer":

			GameState.set_employer(key if not key.is_empty() else target)
		"career_track":
			GameState.active_career_track = key if not key.is_empty() else target
			GameState._emit_changed()
		"promo_claim":
			PromotionSystem.claim_next()
		"unlock":

			_apply_unlock(key if not key.is_empty() else target)
		_:
			push_warning("EffectApplier: unknown effect_type '%s' in %s" % [effect_type, row.get("id", "?")])
			return false
	return true


func _apply_unlock(spec: String) -> void :
	var parts: = spec.split(":", false)
	if parts.size() < 2:
		push_warning("EffectApplier: bad unlock spec '%s'" % spec)
		return
	var kind: = parts[0]
	var id: = parts[1]
	match kind:
		"location":
			GameState.unlocked_locations[id] = true
		"hotspot":
			GameState.unlocked_hotspots[id] = true
		_:
			push_warning("EffectApplier: unknown unlock kind '%s'" % kind)
			return
	GameState._emit_changed()


func _apply_stat(stat_id: String, op: String, value: float) -> void :
	var cur: = GameState.get_stat(stat_id)
	GameState.set_stat(stat_id, _op(cur, op, value))


func _apply_flag(flag_id: String, op: String, value: float) -> void :
	var cur: = float(GameState.get_flag(flag_id))
	GameState.set_flag(flag_id, int(round(_op(cur, op, value))))


func _apply_relation(spec: String, op: String, value: float) -> void :

	var parts: = spec.split(":", false)
	if parts.size() < 3:
		push_warning("EffectApplier: bad relation spec '%s'" % spec)
		return
	var source_id: = parts[0]
	var target_id: = parts[1]
	var rel_key: = parts[2]
	var cur: = GameState.get_relation(source_id, target_id, rel_key)
	GameState.set_relation(source_id, target_id, rel_key, _op(cur, op, value))


func _op(current: float, op: String, value: float) -> float:
	match op:
		"add":
			return current + value
		"set":
			return value
		"mul":
			return current * value
		"clamp_add":

			return current + value
		_:
			push_warning("EffectApplier: unknown op '%s'" % op)
			return current
