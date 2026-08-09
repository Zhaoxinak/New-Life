extends Node



var _modulate: CanvasModulate
var _layer: CanvasLayer
var _veil: ColorRect
var _rain_view: Control
var _outdoor: bool = true
var _tween: Tween
var _drops: Array[Dictionary] = []
var _intensity: float = 0.0
var _splash_t: float = 0.0


func _ready() -> void :
	var host: = get_parent()
	_modulate = CanvasModulate.new()
	_modulate.name = "PeriodModulate"
	_modulate.color = Color.WHITE
	host.add_child(_modulate)

	_layer = CanvasLayer.new()
	_layer.name = "WeatherLayer"
	_layer.layer = 4
	host.add_child(_layer)

	_veil = ColorRect.new()
	_veil.name = "WeatherVeil"
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.color = Color(0.12, 0.18, 0.32, 0.0)
	_layer.add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_rain_view = Control.new()
	_rain_view.name = "RainView"
	_rain_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_rain_view)
	_rain_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rain_view.draw.connect(_draw_rain)

	if not get_viewport().size_changed.is_connected(_on_viewport):
		get_viewport().size_changed.connect(_on_viewport)
	if not GameState.state_changed.is_connected(refresh):
		GameState.state_changed.connect(refresh)
	if not GameState.weather_changed.is_connected(_on_weather):
		GameState.weather_changed.connect(_on_weather)
	if WorldClock and not WorldClock.clock_ticked.is_connected(_on_clock):
		WorldClock.clock_ticked.connect(_on_clock)
	set_process(true)
	refresh()


func _on_clock() -> void :
	## Soft refresh every few game-minutes; avoid tween spam.
	if int(WorldClock.window_minute) % 8 == 0:
		refresh()


func _on_viewport() -> void :
	_rebuild_drops(true)
	if _rain_view:
		_rain_view.queue_redraw()


func _on_weather(_w: String) -> void :
	refresh()


func set_outdoor(outdoor: bool) -> void :
	_outdoor = outdoor
	refresh()


func _process(delta: float) -> void :
	if _intensity <= 0.01 or _rain_view == null:
		return
	var vp: = _rain_view.size
	if vp.x < 8.0 or vp.y < 8.0:
		return
	_splash_t += delta
	for d in _drops:
		d["y"] = float(d["y"]) + float(d["spd"]) * delta
		d["x"] = float(d["x"]) + float(d["drift"]) * delta
		if float(d["y"]) > vp.y + 20.0:
			d["y"] = - randf_range(8.0, 120.0)
			d["x"] = randf_range(-40.0, vp.x + 40.0)
	_rain_view.queue_redraw()


func refresh() -> void :
	if _modulate == null:
		return
	var target: = WeatherSystem.atmosphere_modulate()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_modulate, "color", target, 0.45)

	var intensity: = WeatherSystem.rain_intensity()
	if not _outdoor:
		intensity *= 0.35
	_intensity = intensity
	_rebuild_drops(false)

	var veil_a: = 0.0
	match GameState.weather:
		"cloudy":
			veil_a = 0.12 if _outdoor else 0.06
		"rain":
			veil_a = 0.28 if _outdoor else 0.16
		"storm":
			veil_a = 0.42 if _outdoor else 0.22
		_:
			veil_a = 0.0
	var phase: = WorldClock.day_phase01() if WorldClock else 0.0
	if phase >= 0.55:
		veil_a += lerpf(0.06, 0.16, (phase - 0.55) / 0.45) if _outdoor else 0.04
	var tw2: = create_tween()
	tw2.tween_property(_veil, "color:a", veil_a, 0.35)
	if _rain_view:
		_rain_view.visible = intensity > 0.05
		_rain_view.queue_redraw()


func _rebuild_drops(force: bool) -> void :
	var want: = 0
	if _intensity > 0.05:
		want = int(lerp(70.0, 220.0, _intensity))
	if not force and _drops.size() == want:
		return
	_drops.clear()
	var vp: = Vector2(1280, 720)
	if _rain_view and _rain_view.size.x > 8.0:
		vp = _rain_view.size
	for i in want:
		_drops.append({
			"x": randf_range(-40.0, vp.x + 40.0), 
			"y": randf_range( - vp.y, vp.y), 
			"len": randf_range(10.0, 22.0) * (0.8 + _intensity * 0.5), 
			"spd": randf_range(520.0, 900.0) * (0.75 + _intensity * 0.55), 
			"drift": randf_range(40.0, 120.0) * (0.6 + _intensity * 0.5), 
			"a": randf_range(0.35, 0.85), 
		})


func _draw_rain() -> void :
	if _intensity <= 0.05 or _rain_view == null:
		return
	var col: = Color(0.78, 0.88, 1.0, 0.55)
	if GameState.weather == "storm":
		col = Color(0.7, 0.8, 0.95, 0.7)
	for d in _drops:
		var x: = float(d["x"])
		var y: = float(d["y"])
		var length: = float(d["len"])
		var a: = float(d["a"]) * clampf(_intensity + 0.25, 0.0, 1.0)
		var c: = Color(col.r, col.g, col.b, a)

		_rain_view.draw_line(Vector2(x, y), Vector2(x + length * 0.28, y + length), c, 1.15, true)
