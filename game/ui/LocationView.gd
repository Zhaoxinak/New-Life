extends Control


@onready var stage = %SceneStage
@onready var hotspot_layer: Control = %HotspotLayer
@onready var loc_nav: HBoxContainer = %LocNav
@onready var action_panel: PanelContainer = %ActionPanel
@onready var action_title: Label = %ActionTitle
@onready var action_list: VBoxContainer = %ActionList
@onready var result_label: RichTextLabel = %ResultLabel
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var menu_button: Button = %MenuButton
@onready var lang_button: Button = %LangButton
@onready var banner_title: Label = %BannerTitle
@onready var banner_desc: Label = %BannerDesc

var _location_ids: PackedStringArray = []
var _hotspot_ids: PackedStringArray = []
var _selected_hotspot_id: String = ""
var _markers: Dictionary = {}
var _input_blocked: bool = false


func _ready() -> void :
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	lang_button.pressed.connect(_on_lang_pressed)
	resized.connect(_relayout_markers)
	UiStyle.apply_cozy_button(save_button)
	UiStyle.apply_cozy_button(load_button)
	UiStyle.apply_cozy_button(menu_button)
	UiStyle.apply_cozy_button(lang_button)
	action_panel.add_theme_stylebox_override("panel", UiStyle.make_parchment_style())
	if not GameState.period_advanced.is_connected(_on_period_advanced):
		GameState.period_advanced.connect(_on_period_advanced)
	if not ActionPipeline.action_resolved.is_connected(_on_action_resolved):
		ActionPipeline.action_resolved.connect(_on_action_resolved)
	if not EventScheduler.event_resolved.is_connected(_on_event_resolved):
		EventScheduler.event_resolved.connect(_on_event_resolved)
	if not GameFlow.block_changed.is_connected(_on_block_changed):
		GameFlow.block_changed.connect(_on_block_changed)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)
	_refresh_labels()
	_rebuild_locations()
	_select_location(GameState.location_id)


func _on_block_changed(blocked: bool) -> void :
	_input_blocked = blocked
	hotspot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in _markers:
		var m = _markers[id]
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE if blocked else Control.MOUSE_FILTER_STOP
	for child in loc_nav.get_children():
		if child is Button:
			(child as Button).disabled = blocked
	for child in action_list.get_children():
		if child is Button:
			(child as Button).disabled = blocked or not bool(child.get_meta("runnable", true))


func _on_event_resolved(_event_id: String, _choice_id: String) -> void :
	_rebuild_locations(false)
	_rebuild_hotspots(GameState.location_id)
	TipSystem.on_flags_changed()
	TipSystem.on_unlock_pulse()
	TipSystem.pulse_when_free()


func _on_locale(_locale: String) -> void :
	_refresh_labels()
	_rebuild_locations()
	_select_location(GameState.location_id)


func _on_period_advanced(_day: int, _period: String) -> void :
	SfxPlayer.play_period()
	_rebuild_locations(false)
	_rebuild_hotspots(GameState.location_id)
	TipSystem.on_unlock_pulse()


func _refresh_labels() -> void :
	action_title.text = L10n.t("ui.action.select", "选择行动")
	save_button.text = L10n.t("ui.save.save", "保存")
	load_button.text = L10n.t("ui.save.load", "读取")
	menu_button.text = L10n.t("ui.menu.title", "标题")
	lang_button.text = L10n.locale
	_refresh_banner(GameState.location_id)


func _refresh_banner(location_id: String) -> void :
	banner_title.text = L10n.t("locations.%s.name" % location_id, location_id)
	banner_desc.text = L10n.t("locations.%s.description" % location_id, "")
	stage.set_location(location_id)


func _rebuild_locations(reselect: bool = true) -> void :
	var prev: = GameState.location_id
	for c in loc_nav.get_children():
		c.queue_free()
	_location_ids.clear()
	for row in PackDB.get_enabled_locations():
		var id: = str(row.get("id", ""))
		if not GameState.is_location_unlocked(id):
			continue
		_location_ids.append(id)
		var btn: = Button.new()
		btn.text = L10n.t("locations.%s.name" % id, id)
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(100, 44)
		UiStyle.apply_cozy_button(btn)
		btn.pressed.connect(_on_location_button.bind(id))
		btn.set_meta("location_id", id)
		loc_nav.add_child(btn)
	if reselect:
		_select_location(prev)
	else:
		_sync_loc_nav(GameState.location_id)


func _sync_loc_nav(id: String) -> void :
	for child in loc_nav.get_children():
		if child is Button:
			var bid: = str(child.get_meta("location_id", ""))
			(child as Button).set_pressed_no_signal(bid == id)


func _select_location(id: String) -> void :
	var idx: = _location_ids.find(id)
	if idx < 0 and _location_ids.size() > 0:
		idx = 0
		id = _location_ids[0]
	if idx < 0:
		return
	GameState.set_location(id)
	_sync_loc_nav(id)
	_refresh_banner(id)
	_rebuild_hotspots(id)


func _on_location_button(id: String) -> void :
	if _input_blocked:
		return
	SfxPlayer.play_click()
	GameState.set_location(id)
	_sync_loc_nav(id)
	_refresh_banner(id)
	_rebuild_hotspots(id)
	IdleChatter.pick_for_current("")
	if GameState.last_chatter_text != "":
		result_label.text = "[%s] %s" % [L10n.t("ui.chatter.title", "耳边闲话"), GameState.last_chatter_text]
		TipSystem.queue_tip("tip_idle_listen")


func _clear_markers() -> void :
	for c in hotspot_layer.get_children():
		c.queue_free()
	_markers.clear()
	_hotspot_ids.clear()
	_selected_hotspot_id = ""
	action_panel.visible = false
	_clear_action_buttons()


func _rebuild_hotspots(location_id: String) -> void :
	_clear_markers()
	var rows: Array = []
	for row in PackDB.get_hotspots_for_location(location_id):
		var id: = str(row.get("id", ""))
		if not GameState.is_hotspot_unlocked(id):
			continue
		rows.append(row)
	if rows.is_empty():
		result_label.text = L10n.t("ui.empty.no_hotspots", "此地尚未开放")
		return
	var auto_i: = 0
	for row in rows:
		var id: = str(row.get("id", ""))
		var gate: = ActionPipeline.can_show_hotspot(row)
		_hotspot_ids.append(id)
		var name: = L10n.t("hotspots.%s.name" % id, id)
		var marker = HotspotMarker.new()
		hotspot_layer.add_child(marker)
		var reason: = str(gate.get("reason", ""))
		marker.setup(id, name, not gate.get("ok", false), reason)
		marker.activated.connect(_on_hotspot_activated)
		_markers[id] = marker
		_place_marker(marker, row, auto_i, rows.size())
		auto_i += 1
	call_deferred("_relayout_markers")


func _hotspot_norm_pos(row: Dictionary, index: int, total: int) -> Vector2:
	var px: = _to_float(row.get("pos_x", ""), -1.0)
	var py: = _to_float(row.get("pos_y", ""), -1.0)
	if px < 0.0 or py < 0.0:

		var t: = 0.5 if total <= 1 else float(index) / float(total - 1)
		px = 180.0 + t * 640.0
		py = 520.0 + float(index % 2) * 80.0
	return Vector2(clampf(px, 40.0, 960.0), clampf(py, 80.0, 900.0))


func _to_float(v: Variant, fallback: float) -> float:
	var s: = str(v).strip_edges()
	if s == "":
		return fallback
	return float(s)


func _place_marker(marker, row: Dictionary, index: int, total: int) -> void :
	var norm: = _hotspot_norm_pos(row, index, total)
	var sz: = hotspot_layer.size
	if sz.x < 2.0 or sz.y < 2.0:
		sz = size
	marker.position = Vector2(sz.x * (norm.x / 1000.0) - 60.0, sz.y * (norm.y / 1000.0) - 18.0)
	marker.size = Vector2(120, 56)


func _relayout_markers() -> void :
	var i: = 0
	var total: = _hotspot_ids.size()
	for id in _hotspot_ids:
		var marker = _markers.get(id)
		if marker == null:
			continue
		var row: Dictionary = PackDB.get_row("hotspots", id)
		_place_marker(marker, row, i, total)
		i += 1


func _on_hotspot_activated(hotspot_id: String) -> void :
	if _input_blocked:
		return
	SfxPlayer.play_click()
	_selected_hotspot_id = hotspot_id
	for id in _markers:
		_markers[id].set_selected(id == hotspot_id)
	_rebuild_actions(hotspot_id)


func _clear_action_buttons() -> void :
	for c in action_list.get_children():
		c.queue_free()


func _rebuild_actions(hotspot_id: String) -> void :
	_clear_action_buttons()
	action_panel.visible = true
	var any: = false
	for row in PackDB.get_actions_for_hotspot(hotspot_id):
		var id: = str(row.get("id", ""))
		var gate: = ActionPipeline.can_run(row)
		var name: = L10n.t("actions.%s.name" % id, id)
		var check_id: = str(row.get("check_id", "")).strip_edges()
		if check_id != "" and gate.get("ok", false):
			var pct: = int(round(CheckResolver.preview_chance(check_id) * 100.0))
			name = "%s  ~%d%%" % [name, pct]
		if not gate.get("ok", false):
			name = "%s（%s）" % [name, str(gate.get("reason", ""))]
		var btn: = Button.new()
		btn.text = name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = not gate.get("ok", false) or _input_blocked
		btn.set_meta("runnable", gate.get("ok", false))
		btn.set_meta("action_id", id)
		UiStyle.apply_cozy_button(btn)
		if gate.get("ok", false):
			btn.pressed.connect(_on_action_pressed.bind(id))
			var desc: = L10n.t("actions.%s.description" % id, "")
			if desc != "" and desc != "actions.%s.description" % id:
				btn.tooltip_text = desc
		action_list.add_child(btn)
		any = true
	if not any:
		result_label.text = L10n.t("ui.empty.no_actions", "此处暂时无事可做")
		action_panel.visible = false


func _on_action_pressed(action_id: String) -> void :
	if _input_blocked or action_id.is_empty():
		return
	SfxPlayer.play_click()
	var desc: = L10n.t("actions.%s.description" % action_id, "")
	if desc != "" and desc != "actions.%s.description" % action_id:
		result_label.text = desc
	ActionPipeline.run(action_id)


func _on_action_resolved(result: Dictionary) -> void :
	result_label.text = str(result.get("message", ""))
	if result.get("ok", false) and str(result.get("check_id", "")) != "":
		TipSystem.on_first_check()
		if bool(result.get("check_passed", true)):
			SfxPlayer.play_success()
		else:
			SfxPlayer.play_fail()
	_rebuild_locations(false)
	_rebuild_hotspots(GameState.location_id)
	TipSystem.on_flags_changed()
	TipSystem.pulse_when_free()


func _on_save_pressed() -> void :
	SfxPlayer.play_click()
	if SaveSystem.save_game():
		result_label.text = L10n.t("ui.save.success", "已保存")
	else:
		result_label.text = L10n.t("ui.save.failed", "保存失败")


func _on_load_pressed() -> void :
	SfxPlayer.play_click()
	if SaveSystem.load_game():
		result_label.text = L10n.t("ui.save.load_success", "已读取")
		_rebuild_locations()
		_select_location(GameState.location_id)
		if GameState.last_result_text != "":
			result_label.text = GameState.last_result_text
	else:
		result_label.text = L10n.t("ui.save.slot_empty", "空存档")


func _on_menu_pressed() -> void :
	SfxPlayer.play_click()
	get_tree().change_scene_to_file("res://ui/TitleMenu.tscn")


func _on_lang_pressed() -> void :
	SfxPlayer.play_click()
	L10n.set_locale("en" if L10n.locale == "zh_CN" else "zh_CN")
