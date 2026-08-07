extends Node
## Stock market rules from stock_rules / stock_config.


func on_action(action_id: String, check_passed: bool) -> Array[String]:
	var ran: Array[String] = []
	for row in PackDB.get_stock_rules_for_action(action_id):
		var rid := str(row.get("id", ""))
		## Fake rumor only on success
		if rid == "rule_rumor_fake" and not check_passed:
			continue
		if str(row.get("when_phase", "")) != "on_action":
			continue
		if not check_passed and rid.begins_with("rule_rumor"):
			continue
		_run_rule(row)
		ran.append(rid)
	_clamp_price()
	return ran


func on_day_end() -> void:
	for row in PackDB.get_stock_rules_for_phase("on_day_end"):
		_run_rule(row)
	_clamp_price()
	ThresholdWatcher.evaluate_all()


func _run_rule(row: Dictionary) -> void:
	var rule_type := str(row.get("rule_type", ""))
	match rule_type:
		"open_long":
			_open_long(row)
		"open_short":
			_open_short(row)
		"close_position":
			_close_position(row)
		"price_shock":
			_price_shock(row)
		"set_leverage":
			_set_leverage(row)
		"flag_only":
			_flag_only(row)
		"price_drift":
			_price_drift(row)
		"clamp_price":
			_clamp_price()
		_:
			push_warning("StockEngine: unknown rule_type %s" % rule_type)


func _param_map(row: Dictionary) -> Dictionary:
	var out := {}
	for field in ["param1", "param2", "param3", "param4"]:
		var raw := str(row.get(field, "")).strip_edges()
		if raw.is_empty():
			continue
		var parts := raw.split(":", false)
		if parts.size() < 2:
			continue
		out[parts[0]] = parts[1]
	return out


func _cfg_ref(token: String, default_value: float = 0.0) -> float:
	## token may be config key or literal number
	if token.is_valid_float():
		return float(token)
	return PackDB.get_stock_config(token, default_value)


func _open_long(row: Dictionary) -> void:
	var p := _param_map(row)
	var lots := _cfg_ref(str(p.get("lots", "buy_lots_default")), 1.0)
	var fee := _cfg_ref(str(p.get("fee", "buy_fee_flat")), 0.0)
	var lot_size := PackDB.get_stock_config("lot_size", 10.0)
	var price := GameState.get_stat("stock_price")
	var cost := price * lots * lot_size + fee
	if GameState.get_stat("money") < cost:
		return
	GameState.add_stat("money", -cost)
	if str(p.get("clear_short", "")) == "1" and GameState.get_stat("position_lots") < 0:
		GameState.set_stat("position_lots", 0)
		GameState.set_stat("entry_price", 0)
	GameState.set_stat("position_lots", lots)
	GameState.set_stat("entry_price", price)
	GameState.set_flag("flag_holding_long", 1)
	GameState.set_flag("flag_holding_short", 0)


func _open_short(row: Dictionary) -> void:
	var p := _param_map(row)
	var lots := _cfg_ref(str(p.get("lots", "short_lots_default")), 1.0)
	var margin := _cfg_ref(str(p.get("margin", "short_margin_flat")), 30.0)
	var lev := GameState.get_stat("leverage_mult")
	var cost := margin * lots * lev
	if GameState.get_stat("money") < cost:
		return
	GameState.add_stat("money", -cost)
	var price := GameState.get_stat("stock_price")
	if str(p.get("clear_long", "")) == "1" and GameState.get_stat("position_lots") > 0:
		GameState.set_stat("position_lots", 0)
		GameState.set_stat("entry_price", 0)
	GameState.set_stat("position_lots", -lots)
	GameState.set_stat("entry_price", price)
	GameState.set_flag("flag_holding_short", 1)
	GameState.set_flag("flag_holding_long", 0)


func _close_position(row: Dictionary) -> void:
	var lots := GameState.get_stat("position_lots")
	if is_zero_approx(lots):
		return
	var pnl := _mark_pnl()
	var p := _param_map(row)
	if str(p.get("pnl_to_money", "1")) == "1":
		GameState.add_stat("money", pnl)
	GameState.stock_profit_cum += pnl
	GameState.set_stat("position_lots", 0.0)
	GameState.set_stat("entry_price", 0.0)
	GameState.set_flag("flag_holding_long", 0)
	GameState.set_flag("flag_holding_short", 0)
	var check := str(p.get("check_route_c", ""))
	if check != "":
		## format: route_c_profit_target|set_flag:ending_route_c_ready
		var bits := check.split("|", false)
		var target_key := bits[0]
		var target := PackDB.get_stock_config(target_key, 80.0)
		if GameState.stock_profit_cum >= target:
			GameState.set_flag("ending_route_c_ready", 1)


func _price_shock(row: Dictionary) -> void:
	var p := _param_map(row)
	var delta := float(str(p.get("price_delta", "0")))
	var intel_cost := float(str(p.get("intel_cost", "0")))
	var money_cost := float(str(p.get("money_cost", "0")))
	var suspicion := float(str(p.get("suspicion", "0")))
	if GameState.get_flag("boss_watching") == 1:
		delta -= PackDB.get_stock_config("watched_slippage", 2.0)
	GameState.add_stat("intel", -intel_cost)
	GameState.add_stat("money", -money_cost)
	GameState.add_stat("suspicion", suspicion)
	GameState.add_stat("stock_price", delta)


func _set_leverage(row: Dictionary) -> void:
	var p := _param_map(row)
	var mult := _cfg_ref(str(p.get("mult", "leverage_default")), 2.0)
	GameState.set_stat("leverage_mult", mult)
	var flag_id := str(p.get("flag", "flag_used_leverage"))
	GameState.set_flag(flag_id, 1)
	var suspicion := float(str(p.get("suspicion", "0")))
	if suspicion != 0.0:
		GameState.add_stat("suspicion", suspicion)


func _flag_only(row: Dictionary) -> void:
	var p := _param_map(row)
	var flag_id := str(p.get("flag", ""))
	if flag_id != "":
		GameState.set_flag(flag_id, 1)
	var money_cost := float(str(p.get("money_cost", "0")))
	if money_cost != 0.0:
		GameState.add_stat("money", -money_cost)
	if p.has("network_elite"):
		GameState.add_stat("network_elite", float(str(p["network_elite"])))


func _price_drift(row: Dictionary) -> void:
	var p := _param_map(row)
	var mn := _cfg_ref(str(p.get("min", "day_drift_min")), -3.0)
	var mx := _cfg_ref(str(p.get("max", "day_drift_max")), 3.0)
	var delta := GameState.rng.randf_range(mn, mx)
	GameState.add_stat("stock_price", delta)
	if str(p.get("apply_pnl_mark", "")) == "1":
		## mark-to-market is informational; Demo only tracks on close
		pass
	var floor := _cfg_ref(str(p.get("bust_check", "bust_price_floor")), 25.0)
	if GameState.get_stat("leverage_mult") >= 2.0 \
			and GameState.get_stat("stock_price") <= floor \
			and not is_zero_approx(GameState.get_stat("position_lots")):
		## Force close with loss
		var pnl := _mark_pnl()
		GameState.add_stat("money", pnl)
		GameState.stock_profit_cum += pnl
		GameState.set_stat("position_lots", 0)
		GameState.set_stat("entry_price", 0)
		GameState.set_flag("flag_holding_long", 0)
		GameState.set_flag("flag_holding_short", 0)


func _mark_pnl() -> float:
	var lots := GameState.get_stat("position_lots")
	if is_zero_approx(lots):
		return 0.0
	var price := GameState.get_stat("stock_price")
	var entry := GameState.get_stat("entry_price")
	var lot_size := PackDB.get_stock_config("lot_size", 10.0)
	var lev := GameState.get_stat("leverage_mult")
	if lots > 0.0:
		return (price - entry) * lots * lot_size * lev
	return (entry - price) * absf(lots) * lot_size * lev


func _clamp_price() -> void:
	var mn := PackDB.get_stock_config("min_price", 10.0)
	var mx := PackDB.get_stock_config("max_price", 200.0)
	var v := GameState.get_stat("stock_price")
	GameState.set_stat("stock_price", clampf(v, mn, mx))
