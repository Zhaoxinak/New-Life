extends Node
## Dual-actor check resolver (DATA.md).
## chance = clamp(base + Σ contrib, chance_min, chance_max)


func resolve(check_id: String) -> Dictionary:
	## { ok, passed, chance, roll, mods: Array, check: Dictionary }
	var check := PackDB.get_row("checks", check_id)
	if check.is_empty() or str(check.get("enabled", "1")) == "0":
		return {
			"ok": false,
			"passed": true,
			"chance": 1.0,
			"roll": 0.0,
			"mods": [],
			"check": check,
			"message": "no check",
		}

	var base := float(check.get("base", 0.5))
	var chance_min := float(check.get("chance_min", 0.05))
	var chance_max := float(check.get("chance_max", 0.95))
	var contrib_total := 0.0
	var mod_details: Array = []

	for row in PackDB.get_check_mods(check_id):
		var contrib := _mod_contrib(row)
		contrib_total += contrib
		mod_details.append({
			"id": str(row.get("id", "")),
			"mod_kind": str(row.get("mod_kind", "")),
			"key": str(row.get("key", "")),
			"contrib": contrib,
		})

	var chance := clampf(base + contrib_total, chance_min, chance_max)
	var roll := GameState.rng.randf()
	var passed := roll < chance
	return {
		"ok": true,
		"passed": passed,
		"chance": chance,
		"roll": roll,
		"base": base,
		"mods_sum": contrib_total,
		"mods": mod_details,
		"check": check,
		"target_npc_id": str(check.get("target_npc_id", "")),
	}


func preview_chance(check_id: String) -> float:
	var r := resolve_chance_only(check_id)
	return float(r.get("chance", 0.0))


func resolve_chance_only(check_id: String) -> Dictionary:
	var check := PackDB.get_row("checks", check_id)
	if check.is_empty():
		return {"chance": 1.0, "base": 1.0, "mods_sum": 0.0}
	var base := float(check.get("base", 0.5))
	var chance_min := float(check.get("chance_min", 0.05))
	var chance_max := float(check.get("chance_max", 0.95))
	var contrib_total := 0.0
	for row in PackDB.get_check_mods(check_id):
		contrib_total += _mod_contrib(row)
	return {
		"chance": clampf(base + contrib_total, chance_min, chance_max),
		"base": base,
		"mods_sum": contrib_total,
	}


func _mod_contrib(row: Dictionary) -> float:
	var kind := str(row.get("mod_kind", ""))
	var key := str(row.get("key", ""))
	var scale := float(row.get("scale", 0))
	match kind:
		"flag_flat":
			if GameState.get_flag(key) == 1:
				return scale
			return 0.0
		"stat_scale":
			var v := GameState.get_stat(key)
			var ref := float(row.get("ref", 0))
			var mn := _opt_float(row, "min_mod", -1.0)
			var mx := _opt_float(row, "max_mod", 1.0)
			return clampf((v - ref) * scale, mn, mx)
		"relation_scale":
			var parts := key.split(":", false)
			if parts.size() < 3:
				push_warning("CheckResolver: bad relation key %s" % key)
				return 0.0
			var v2 := GameState.get_relation(parts[0], parts[1], parts[2])
			var ref2 := float(row.get("ref", 0))
			var mn2 := _opt_float(row, "min_mod", -1.0)
			var mx2 := _opt_float(row, "max_mod", 1.0)
			return clampf((v2 - ref2) * scale, mn2, mx2)
		_:
			push_warning("CheckResolver: unknown mod_kind '%s'" % kind)
			return 0.0


func _opt_float(row: Dictionary, field: String, default_value: float) -> float:
	var s := str(row.get(field, "")).strip_edges()
	if s.is_empty():
		return default_value
	return float(s)
