extends Node



func _ready() -> void :
	if not GameState.period_advanced.is_connected(_on_period):
		GameState.period_advanced.connect(_on_period)
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)
	call_deferred("_boot")


func _boot() -> void :
	if str(GameState.weather).strip_edges() == "":
		apply_for_current(false)


func _on_state() -> void :

	if str(GameState.weather).strip_edges() == "":
		apply_for_current(false)


func _on_period(_day: int, _period: String) -> void :
	apply_for_current(true)


func apply_for_current(_announce: bool = false) -> String:
	var forced: = _forced_weather(GameState.day, GameState.period)
	var wid: = forced if forced != "" else _roll_weather(GameState.day, GameState.period)
	if wid == "":
		wid = "clear"
	GameState.set_weather(wid)
	SfxPlayer.set_weather(wid)
	return wid


func set_weather_now(weather_id: String) -> void :
	var wid: = weather_id.strip_edges()
	if wid == "":
		return
	GameState.set_weather(wid)
	SfxPlayer.set_weather(wid)


func _forced_weather(day: int, period: String) -> String:
	var best: = ""
	var best_pri: = -1
	for row in PackDB.get_table("weather_schedule"):
		if int(row.get("day", -1)) != day:
			continue
		var p: = str(row.get("period", "any")).strip_edges()
		if p != "any" and p != period:
			continue
		var pri: = int(row.get("priority", 0))
		if pri >= best_pri:
			best_pri = pri
			best = str(row.get("weather_id", "")).strip_edges()
	return best


func _roll_weather(day: int, period: String) -> String:
	var pool: Array[Dictionary] = []
	var total: = 0.0
	for row in PackDB.get_table("weather_weights"):
		if str(row.get("period", "")) != period:
			continue
		var lo: = int(row.get("min_day", 1))
		var hi: = int(row.get("max_day", 30))
		if day < lo or day > hi:
			continue
		var w: = float(row.get("weight", 0))
		if w <= 0.0:
			continue
		pool.append(row)
		total += w
	if pool.is_empty() or total <= 0.0:
		return "clear"
	var pick: = GameState.rng.randf() * total
	var acc: = 0.0
	for row in pool:
		acc += float(row.get("weight", 0))
		if pick <= acc:
			return str(row.get("weather_id", "clear"))
	return str(pool[pool.size() - 1].get("weather_id", "clear"))


func period_tint(period: String = "") -> Color:
	var p: = period if period != "" else GameState.period
	match p:
		"morning":
			return Color(1.06, 1.02, 0.94)
		"afternoon":
			return Color(1.1, 1.06, 0.98)
		"evening":
			return Color(0.58, 0.64, 0.88)
		_:
			return Color.WHITE


## Smooth daylight curve across the 06:00→02:00 window (phase 0…1).
func period_tint_lerped(phase01: float = -1.0) -> Color:
	var t: = phase01
	if t < 0.0:
		t = WorldClock.day_phase01() if WorldClock else 0.0
	t = clampf(t, 0.0, 1.0)
	var morning: = Color(1.06, 1.02, 0.94)
	var noon: = Color(1.1, 1.06, 0.98)
	var dusk: = Color(0.78, 0.72, 0.82)
	var night: = Color(0.48, 0.54, 0.78)
	var late: = Color(0.38, 0.42, 0.62)
	if t < 0.25:
		return morning.lerp(noon, t / 0.25)
	if t < 0.5:
		return noon.lerp(dusk, (t - 0.25) / 0.25)
	if t < 0.75:
		return dusk.lerp(night, (t - 0.5) / 0.25)
	return night.lerp(late, (t - 0.75) / 0.25)


func weather_tint(weather_id: String = "") -> Color:
	var w: = weather_id if weather_id != "" else GameState.weather
	match w:
		"cloudy":
			return Color(0.88, 0.9, 0.94)
		"rain":
			return Color(0.72, 0.78, 0.9)
		"storm":
			return Color(0.52, 0.58, 0.72)
		_:
			return Color.WHITE


func atmosphere_modulate(period: String = "", weather_id: String = "") -> Color:
	var a: = period_tint_lerped() if period == "" else period_tint(period)
	var b: = weather_tint(weather_id)
	return Color(a.r * b.r, a.g * b.g, a.b * b.b, 1.0)


func rain_intensity(weather_id: String = "") -> float:
	var w: = weather_id if weather_id != "" else GameState.weather
	match w:
		"rain":
			return 0.55
		"storm":
			return 1.0
		_:
			return 0.0
