extends Control
## 开罗风设施舞台：房间 + 家具热区 + 可点 NPC 路径踱步。

signal hotspot_pressed(hotspot_id: String)
signal actor_clicked(char_id: String) ## 左键：闲聊
signal actor_inspected(char_id: String) ## 右键：档案
signal location_changed(loc_id: String)

@onready var bg: TextureRect = %Bg
@onready var fog: ColorRect = %Fog
@onready var lantern: ColorRect = %Lantern
@onready var hotspot_layer: Control = %HotspotLayer
@onready var actor_layer: Control = %ActorLayer
@onready var fx_layer: Control = %FxLayer
@onready var loc_title: Label = %LocTitle
@onready var loc_blurb: Label = %LocBlurb
@onready var loc_plate: PanelContainer = %LocPlate

var _loc_id: String = "loc_01"
var _fog_tween: Tween
var _actors: Array = [] ## {btn, char_id, waypoints, wp_i, t, speed, bob_phase}
var _interactive: bool = true
var _tut_pulse: String = "" ## "" | hotspot | actor
var _tut_hold_walk: bool = false ## 引导全程停踱步
var _tut_tweens: Array = []
var _hz_centers: Array = [] ## Vector2 归一化热区中心，供踱步避让


func set_walk_frozen(on: bool) -> void:
	## 引导全程冻结小人，避免走出高亮洞。
	_tut_hold_walk = on


func _walk_locked() -> bool:
	return _tut_hold_walk or not _tut_pulse.is_empty()

## 踱步只走「地坪步道」：脚底 y≈0.74–0.82，躲开家具热区（约 y0.54–0.62）与底栏。
const PATHS := {
	"loc_01": [
		[Vector2(0.16, 0.76), Vector2(0.28, 0.80), Vector2(0.22, 0.74)],
		[Vector2(0.58, 0.78), Vector2(0.70, 0.74), Vector2(0.66, 0.82)],
		[Vector2(0.36, 0.82), Vector2(0.46, 0.76), Vector2(0.40, 0.80)],
	],
	"loc_02": [
		[Vector2(0.18, 0.76), Vector2(0.30, 0.80), Vector2(0.24, 0.74)],
		[Vector2(0.60, 0.78), Vector2(0.72, 0.74), Vector2(0.66, 0.82)],
		[Vector2(0.40, 0.80), Vector2(0.50, 0.76), Vector2(0.44, 0.82)],
	],
	"loc_03": [
		[Vector2(0.16, 0.76), Vector2(0.28, 0.80), Vector2(0.22, 0.74)],
		[Vector2(0.58, 0.78), Vector2(0.72, 0.74), Vector2(0.64, 0.82)],
		[Vector2(0.38, 0.82), Vector2(0.48, 0.76), Vector2(0.42, 0.80)],
	],
	"loc_04": [
		[Vector2(0.20, 0.76), Vector2(0.34, 0.80), Vector2(0.26, 0.74)],
		[Vector2(0.60, 0.78), Vector2(0.72, 0.74), Vector2(0.66, 0.82)],
	],
	"loc_05": [
		[Vector2(0.20, 0.76), Vector2(0.34, 0.80), Vector2(0.26, 0.74)],
		[Vector2(0.58, 0.78), Vector2(0.72, 0.74), Vector2(0.64, 0.82)],
	],
	"loc_06": [
		[Vector2(0.18, 0.76), Vector2(0.32, 0.80), Vector2(0.24, 0.74)],
		[Vector2(0.58, 0.78), Vector2(0.70, 0.74), Vector2(0.64, 0.82)],
	],
}


func _ready() -> void:
	KairoStyle.style_panel(loc_plate)
	loc_title.add_theme_color_override("font_color", KairoStyle.INK)
	loc_blurb.add_theme_color_override("font_color", KairoStyle.SOFT_INK)
	actor_layer.z_index = 1
	hotspot_layer.z_index = 5
	hotspot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.z_index = 8
	_start_ambience()


func _process(delta: float) -> void:
	## 对白/不可操作时停踱步，少做无用布局
	if _walk_locked() or not _interactive:
		return
	var t_bob := Time.get_ticks_msec() * 0.001
	for a in _actors:
		if not is_instance_valid(a.btn):
			continue
		var wps: Array = a.waypoints
		if wps.is_empty():
			continue
		a.t = float(a.t) + delta * float(a.speed)
		while float(a.t) >= 1.0:
			a.t = float(a.t) - 1.0
			a.wp_i = (int(a.wp_i) + 1) % wps.size()
		var i0 := int(a.wp_i) % wps.size()
		var i1 := (i0 + 1) % wps.size()
		var p0: Vector2 = wps[i0]
		var p1: Vector2 = wps[i1]
		var lerped: Vector2 = p0.lerp(p1, float(a.t))
		lerped.y = _feet_y_avoiding_hotspots(lerped.x, lerped.y)
		var bob := sin(t_bob * 3.0 + float(a.bob_phase)) * 2.0
		_place_actor(a.btn, lerped.x, lerped.y)
		a.btn.position.y += bob
		var going_right := p1.x >= p0.x
		var sprite: Control = a.get("sprite")
		if sprite != null and is_instance_valid(sprite):
			sprite.scale = Vector2(1.0 if going_right else -1.0, 1.0)
			sprite.pivot_offset = Vector2(sprite.custom_minimum_size.x * 0.5, sprite.custom_minimum_size.y)


func set_location(loc_id: String, force: bool = false) -> void:
	var same_stage := (not force) and loc_id == _loc_id and not _actors.is_empty()
	_loc_id = loc_id
	var path := "res://art/locations/anchao/%s.png" % loc_id
	if ResourceLoader.exists(path):
		bg.texture = load(path) as Texture2D
		bg.modulate = Color.WHITE
	else:
		bg.texture = null
		bg.modulate = _fallback_tint(loc_id)
	var row: Dictionary = PackDB.get_row_by_id("def_location", "loc_id", loc_id)
	loc_title.text = "【店】 " + L10n.t(String(row.get("loc_key", "")), loc_id)
	loc_blurb.text = L10n.t(String(row.get("blurb_key", "")), "")
	if same_stage:
		## 同地点刷新（如对白结束）保留踱步进度，别把小人弹回起点
		return
	_rebuild_hotspots(row)
	_rebuild_actors(loc_id)
	location_changed.emit(loc_id)


func current_loc() -> String:
	return _loc_id


func set_interactive(on: bool) -> void:
	_interactive = on
	hotspot_layer.modulate = Color(1, 1, 1, 1.0 if on else 0.4)
	## 层本身必须穿透，否则全屏挡死下层小人点击；只有热区按钮接鼠标
	hotspot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _tut_pulse.is_empty():
		_restore_layer_clicks()
	else:
		## 引导脉冲中保持当步点击规则
		set_tutorial_pulse(_tut_pulse)
	for a in _actors:
		if not is_instance_valid(a.btn):
			continue
		a.btn.modulate = Color(1, 1, 1, 1.0 if on else 0.55)


func tutorial_hotspot_rect() -> Rect2:
	for c in hotspot_layer.get_children():
		if c is Control and is_instance_valid(c):
			return (c as Control).get_global_rect()
	return Rect2()


func tutorial_actor_rect() -> Rect2:
	## 优先非玩家小人
	var fallback := Rect2()
	for a in _actors:
		if not is_instance_valid(a.btn):
			continue
		var r: Rect2 = (a.btn as Control).get_global_rect()
		if String(a.get("char_id", "")) == "char_lin_ruisheng":
			fallback = r
			continue
		return r
	return fallback


func set_tutorial_pulse(mode: String) -> void:
	_clear_tut_tweens()
	_tut_pulse = mode
	_restore_layer_clicks()
	## 复位外观
	for c in hotspot_layer.get_children():
		if c is Control:
			(c as Control).modulate = Color.WHITE
			(c as Control).scale = Vector2.ONE
			(c as Control).z_index = 0
	for a in _actors:
		if is_instance_valid(a.btn):
			a.btn.modulate = Color.WHITE
			a.btn.scale = Vector2.ONE
			a.btn.z_index = 0
	if mode.is_empty():
		return
	if mode == "hotspot":
		## 热区提到中上部；小人让路且不抢点击
		_set_actors_clickable(false)
		for a in _actors:
			if is_instance_valid(a.btn):
				_place_actor(a.btn as Control, 0.14 if String(a.get("char_id", "")) == "char_lin_ruisheng" else 0.86, 0.80)
		for c in hotspot_layer.get_children():
			if c is Control:
				_place_ctrl(c as Control, 0.50, 0.40)
				_pulse_tut(c as Control, Color(1.35, 1.15, 0.55))
				break
	elif mode == "actor":
		## 热区暂不接点击，目标小人抬到最前可点
		_set_hotspots_clickable(false)
		var parked := false
		for a in _actors:
			if not is_instance_valid(a.btn):
				continue
			if String(a.get("char_id", "")) == "char_lin_ruisheng":
				_place_actor(a.btn as Control, 0.18, 0.80)
				continue
			if parked:
				_place_actor(a.btn as Control, 0.88, 0.80)
				continue
			_place_actor(a.btn as Control, 0.50, 0.72)
			a.t = 0.0
			a.btn.z_index = 20
			var sprite: Control = a.get("sprite")
			if sprite != null and is_instance_valid(sprite):
				sprite.scale = Vector2.ONE
				if sprite is BaseButton:
					(sprite as BaseButton).disabled = false
			_pulse_tut(a.btn as Control, Color(1.4, 1.05, 0.7))
			parked = true


func _set_hotspots_clickable(on: bool) -> void:
	for c in hotspot_layer.get_children():
		if c is BaseButton:
			(c as BaseButton).disabled = not on
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE


func _set_actors_clickable(on: bool) -> void:
	for a in _actors:
		var sprite: Control = a.get("sprite")
		if sprite != null and is_instance_valid(sprite) and sprite is BaseButton:
			(sprite as BaseButton).disabled = not on
			sprite.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE


func _restore_layer_clicks() -> void:
	## 按当前 interactive 恢复；引导脉冲里会再临时改
	_set_hotspots_clickable(_interactive)
	_set_actors_clickable(_interactive)


func _pulse_tut(ctrl: Control, glow: Color) -> void:
	ctrl.pivot_offset = ctrl.size * 0.5
	## 绑到目标控件，避免舞台上堆积无限 Tween
	var tw := ctrl.create_tween()
	tw.set_loops()
	tw.tween_property(ctrl, "modulate", glow, 0.35)
	tw.tween_property(ctrl, "scale", Vector2(1.12, 1.12), 0.35)
	tw.tween_property(ctrl, "modulate", Color.WHITE, 0.35)
	tw.tween_property(ctrl, "scale", Vector2.ONE, 0.35)
	_tut_tweens.append(tw)


func _clear_tut_tweens() -> void:
	for tw in _tut_tweens:
		if tw != null:
			(tw as Tween).kill()
	_tut_tweens.clear()


func spawn_pop(kind: String, amount: int = 0) -> void:
	## kind: coin | heart | star
	var label := Label.new()
	match kind:
		"coin":
			label.text = "+%d两" % amount if amount != 0 else "+银"
			label.add_theme_color_override("font_color", KairoStyle.COIN)
		"heart":
			label.text = "♥"
			label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.4))
		_:
			label.text = "★"
			label.add_theme_color_override("font_color", KairoStyle.ACCENT)
	label.add_theme_font_size_override("font_size", 22)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(label)
	var sz := fx_layer.size
	if sz.x < 2.0:
		sz = get_viewport_rect().size
	label.position = Vector2(sz.x * (0.42 + randf() * 0.16), sz.y * 0.48)
	label.modulate.a = 1.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 70.0, 0.85)
	tw.tween_property(label, "modulate:a", 0.0, 0.85)
	tw.chain().tween_callback(label.queue_free)


func _rebuild_hotspots(row: Dictionary) -> void:
	for c in hotspot_layer.get_children():
		## 先杀掉挂在按钮上的呼吸动画，避免 Debug 里僵尸 Tween 刷错误
		if c is Control:
			var tws: Array = (c as Control).get_meta("_pulse_tweens", [])
			for tw in tws:
				if tw != null:
					(tw as Tween).kill()
		c.queue_free()
	_hz_centers.clear()
	var spots: Array = row.get("hotspots", [])
	if spots.is_empty():
		_add_hotspot("hz_main", L10n.t("hz.main", "此处"), 0.5, 0.58)
		return
	for spot in spots:
		if typeof(spot) == TYPE_STRING:
			_add_hotspot(String(spot), L10n.t("hz.%s" % String(spot), String(spot)), 0.5, 0.55)
			continue
		if typeof(spot) != TYPE_DICTIONARY:
			continue
		var s: Dictionary = spot
		var hid := String(s.get("id", ""))
		if hid.is_empty():
			continue
		var label := L10n.t(String(s.get("loc_key", "")), hid)
		_add_hotspot(hid, label, float(s.get("x", 0.5)), float(s.get("y", 0.55)))


func _add_hotspot(hid: String, label: String, nx: float, ny: float) -> void:
	var btn := Button.new()
	var icon := String(KairoStyle.HZ_ICON.get(hid, "【★】"))
	btn.text = "%s\n%s" % [icon, label]
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(108, 64)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	KairoStyle.style_button(btn, true)
	btn.set_meta("hotspot_id", hid)
	btn.set_meta("nx", nx)
	btn.set_meta("ny", ny)
	btn.pressed.connect(func(): hotspot_pressed.emit(hid))
	hotspot_layer.add_child(btn)
	btn.resized.connect(func(): _place_ctrl(btn, nx, ny), CONNECT_ONE_SHOT)
	call_deferred("_place_ctrl", btn, nx, ny)
	_hz_centers.append(Vector2(nx, ny))
	_pulse_btn(btn)


func _rebuild_actors(loc_id: String) -> void:
	for c in actor_layer.get_children():
		c.queue_free()
	_actors.clear()
	var cast: Array = KairoStyle.LOC_CAST.get(loc_id, ["char_lin_ruisheng"])
	var path_set: Array = PATHS.get(loc_id, PATHS["loc_01"])
	for i in range(cast.size()):
		var cid := String(cast[i])
		var wrap := Control.new()
		wrap.custom_minimum_size = Vector2(72, 96)
		wrap.size = Vector2(72, 96)
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.set_meta("char_id", cid)
		var btn := TextureButton.new()
		## 点击只吃身体，别用整块大框挡热区
		btn.custom_minimum_size = Vector2(52, 64)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.focus_mode = Control.FOCUS_NONE
		btn.ignore_texture_size = true
		btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
		btn.position = Vector2(10, 4)
		btn.size = Vector2(52, 64)
		var plate := KairoStyle.nameplate(cid)
		btn.tooltip_text = plate + L10n.t("ui.click_chat", "（左键闲聊 · 右键档案）")
		var spath := "res://art/sprites/anchao/%s.png" % cid
		if ResourceLoader.exists(spath):
			var tex := load(spath) as Texture2D
			btn.texture_normal = tex
			btn.texture_hover = tex
			btn.texture_pressed = tex
		btn.pressed.connect(_on_actor_pressed.bind(cid))
		btn.gui_input.connect(_on_actor_gui_input.bind(cid))
		wrap.add_child(btn)
		var tag := Label.new()
		tag.text = plate
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.autowrap_mode = TextServer.AUTOWRAP_OFF
		tag.add_theme_font_size_override("font_size", 11)
		tag.add_theme_color_override("font_color", Color(0.16, 0.1, 0.05))
		tag.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.82, 0.92))
		tag.add_theme_constant_override("outline_size", 4)
		tag.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		tag.offset_top = -20
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(tag)
		actor_layer.add_child(wrap)
		var wps_raw: Array = path_set[i % path_set.size()]
		var wps: Array = []
		for p in wps_raw:
			wps.append(p)
		_actors.append({
			"btn": wrap,
			"sprite": btn,
			"char_id": cid,
			"waypoints": wps,
			"wp_i": i % maxi(1, wps.size()),
			"t": randf() * 0.4,
			"speed": 0.18 + float(i) * 0.03,
			"bob_phase": float(i) * 1.4,
		})
		if not wps.is_empty():
			var p0: Vector2 = wps[0]
			call_deferred("_place_actor", wrap, p0.x, p0.y)
		btn.disabled = not _interactive


func _on_actor_pressed(char_id: String) -> void:
	if not _interactive:
		return
	actor_clicked.emit(char_id)


func _on_actor_gui_input(event: InputEvent, char_id: String) -> void:
	if not _interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		actor_inspected.emit(char_id)
		accept_event()


func _place_ctrl(ctrl: Control, nx: float, ny: float) -> void:
	if not is_instance_valid(ctrl):
		return
	var parent: Control = ctrl.get_parent() as Control
	var sz := parent.size if parent else size
	if sz.x <= 1.0 or sz.y <= 1.0:
		sz = get_viewport_rect().size
	var w := absf(ctrl.size.x) if ctrl.size.x != 0.0 else ctrl.custom_minimum_size.x
	var h := ctrl.size.y if ctrl.size.y != 0.0 else ctrl.custom_minimum_size.y
	ctrl.position = Vector2(sz.x * nx - w * 0.5, sz.y * ny - h * 0.5)
	ctrl.pivot_offset = Vector2(w * 0.5, h * 0.5)


func _place_actor(ctrl: Control, nx: float, ny_feet: float) -> void:
	## 脚底对齐步道线，身子往上长，少盖住中部热区按钮。
	if not is_instance_valid(ctrl):
		return
	var parent: Control = ctrl.get_parent() as Control
	var sz := parent.size if parent else size
	if sz.x <= 1.0 or sz.y <= 1.0:
		sz = get_viewport_rect().size
	var w := ctrl.custom_minimum_size.x
	var h := ctrl.custom_minimum_size.y
	ny_feet = clampf(ny_feet, 0.70, 0.86)
	ctrl.position = Vector2(sz.x * nx - w * 0.5, sz.y * ny_feet - h)
	ctrl.pivot_offset = Vector2(w * 0.5, h)


func _feet_y_avoiding_hotspots(nx: float, ny_feet: float) -> float:
	## 用缓存中心点避让，避免每帧 get_rect
	var y := clampf(ny_feet, 0.72, 0.84)
	for c in _hz_centers:
		var hx: float = (c as Vector2).x
		var hy: float = (c as Vector2).y
		if absf(nx - hx) < 0.14 and y - 0.12 < hy + 0.06:
			y = maxf(y, hy + 0.16)
	return clampf(y, 0.72, 0.86)


func _pulse_btn(btn: Control) -> void:
	## 只做两下入场呼吸；Tween 绑在按钮上，销毁时一起死，不再拖垮 Debug
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	var tw := btn.create_tween()
	tw.set_loops(2)
	tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.55)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.55)
	btn.set_meta("_pulse_tweens", [tw])


func _start_ambience() -> void:
	fog.color = Color(1, 1, 1, 0.0)
	lantern.color = Color(1.0, 0.9, 0.55, 0.05)
	if _fog_tween != null:
		_fog_tween.kill()
	## 灯晕慢一点，减轻每帧属性写
	_fog_tween = create_tween()
	_fog_tween.set_loops()
	_fog_tween.tween_property(lantern, "color:a", 0.10, 2.4)
	_fog_tween.tween_property(lantern, "color:a", 0.03, 2.6)


func _fallback_tint(loc_id: String) -> Color:
	match loc_id:
		"loc_01":
			return Color(0.9, 0.82, 0.7)
		"loc_02":
			return Color(0.75, 0.85, 0.7)
		"loc_03":
			return Color(0.95, 0.85, 0.65)
		"loc_04":
			return Color(0.8, 0.86, 0.9)
		"loc_05":
			return Color(0.75, 0.8, 0.92)
		_:
			return Color(0.9, 0.82, 0.76)
