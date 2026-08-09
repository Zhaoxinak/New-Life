extends CanvasLayer


@onready var prompt_label: Label = %PromptLabel
@onready var action_panel: PanelContainer = %ActionPanel
@onready var action_title: Label = %ActionTitle
@onready var action_list: VBoxContainer = %ActionList
@onready var result_label: RichTextLabel = %ResultLabel
@onready var dossier_button: Button = %DossierButton
@onready var settings_button: Button = %SettingsButton
@onready var close_actions: Button = %CloseActions
@onready var people_strip: PanelContainer = %PeopleStrip
@onready var people_title: Label = %PeopleTitle
@onready var people_hint: Label = %PeopleHint
@onready var people_row: Control = %PeopleRow

const SettingsPanelScene: = preload("res://ui/SettingsPanel.tscn")
const NpcPortraitChipScript: = preload("res://ui/NpcPortraitChip.gd")

var world: Node = null
var _menu_mode: String = "closed"
var _location_id: String = ""
var _hotspot_id: String = ""
var _npc_id: String = ""
var _settings: CanvasLayer = null
var _people_chips: Array = []
var _people_step: float = 64.0
var _people_hover_i: int = -1


func bind_world(host: Node) -> void :
	world = host
	if world.has_signal("prompt_changed"):
		world.prompt_changed.connect(_on_prompt)
	if world.has_signal("hotspot_opened"):
		world.hotspot_opened.connect(_open_actions)
	if world.has_signal("location_entered"):
		world.location_entered.connect(open_location_menu)
	if world.has_signal("request_result"):
		world.request_result.connect( func(t): result_label.text = t)


func _ready() -> void :
	layer = 10
	action_panel.visible = false
	prompt_label.text = ""
	result_label.text = ""

	action_panel.set_anchors_preset(Control.PRESET_CENTER)
	action_panel.offset_left = -200.0
	action_panel.offset_right = 200.0
	action_panel.offset_top = -200.0
	action_panel.offset_bottom = 160.0
	UiStyle.apply_cozy_button(dossier_button)
	UiStyle.apply_cozy_button(settings_button)
	UiStyle.apply_cozy_button(close_actions)
	action_panel.add_theme_stylebox_override("panel", UiStyle.make_parchment_style())
	people_strip.add_theme_stylebox_override("panel", _people_strip_style())
	dossier_button.pressed.connect(_on_dossier)
	settings_button.pressed.connect(_on_settings)
	close_actions.pressed.connect(_on_close_pressed)
	_settings = SettingsPanelScene.instantiate()
	add_child(_settings)
	if _settings.has_signal("feedback"):
		_settings.feedback.connect( func(t: String): result_label.text = t)
	if _settings.has_signal("closed"):
		_settings.closed.connect(_on_settings_closed)
	if not ActionPipeline.action_resolved.is_connected(_on_action_resolved):
		ActionPipeline.action_resolved.connect(_on_action_resolved)
	if not EventScheduler.event_resolved.is_connected(_on_event_resolved):
		EventScheduler.event_resolved.connect(_on_event_resolved)
	if not GameFlow.block_changed.is_connected(_on_block):
		GameFlow.block_changed.connect(_on_block)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)
	if not GameState.state_changed.is_connected(_on_state_chrome):
		GameState.state_changed.connect(_on_state_chrome)
	_refresh_labels()


func _on_state_chrome() -> void :
	dossier_button.visible = GameState.day >= 2


func _on_locale(_l: String) -> void :
	_refresh_labels()
	if _menu_mode == "facilities":
		open_location_menu(_location_id)
	elif _menu_mode == "actions":
		_open_actions(_hotspot_id)
	elif _menu_mode == "npc" and _npc_id != "":
		_open_npc_menu(_npc_id)
		if _location_id != "":
			_refresh_people_strip(_location_id)


func _refresh_labels() -> void :
	settings_button.text = L10n.t("ui.menu.settings", "设置")
	dossier_button.text = L10n.t("ui.chrome.dossier", "人物")
	dossier_button.visible = GameState.day >= 2
	people_title.text = L10n.t("ui.location.people", "在场人物")
	people_hint.text = L10n.t("ui.location.people_hint", "点选人物")


func _people_strip_style() -> StyleBoxEmpty:

	var s: = StyleBoxEmpty.new()
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s


func _on_dossier() -> void :
	if GameFlow.is_blocked():
		return
	var panel: = get_tree().get_first_node_in_group("dossier_panel")
	if panel != null and panel.has_method("open"):
		panel.open()


func _on_prompt(text: String) -> void :

	if _menu_mode != "closed":
		prompt_label.visible = false
		return
	prompt_label.text = text
	prompt_label.visible = text != ""


func _on_block(blocked: bool) -> void :
	dossier_button.disabled = blocked
	if blocked and _menu_mode != "closed":
		action_panel.visible = false
		if people_strip:
			people_strip.visible = false
	elif not blocked and _location_id != "":
		## Restore whichever menu was open; "actions" used to be skipped and
		## left the player frozen with a hidden panel after time-skip beats.
		if _menu_mode == "facilities" or _menu_mode == "npc":
			open_location_menu(_location_id)
		elif _menu_mode == "actions" and _hotspot_id != "":
			_open_actions(_hotspot_id)


func _set_player_frozen(frozen: bool) -> void :
	if world and world.has_method("set_menu_open"):
		world.call("set_menu_open", frozen)


func open_location_menu(location_id: String) -> void :
	if GameFlow.is_blocked():
		return
	_location_id = location_id
	_hotspot_id = ""
	_npc_id = ""
	_menu_mode = "facilities"
	_set_player_frozen(true)
	_clear_list()
	action_panel.visible = true
	var loc_name: = L10n.t("locations.%s.name" % location_id, location_id)
	action_title.text = loc_name
	close_actions.text = L10n.t("ui.world.exit", "出门")

	_refresh_people_strip(location_id)

	var any: = false
	var any_open: = false
	for row in PackDB.get_hotspots_for_location(location_id):
		if str(row.get("enabled", "1")) == "0":
			continue
		var hid: = str(row.get("id", ""))
		var unlocked: = GameState.is_hotspot_unlocked(hid)
		var name: = L10n.t("hotspots.%s.name" % hid, hid)
		var tip: = L10n.t("hotspots.%s.description" % hid, "")
		var can_enter: = false
		if not unlocked:
			name = UnlockScheduler.hotspot_button_text(hid, name)
			var reason: = UnlockScheduler.pending_reason("hotspot", hid)
			if reason != "":
				tip = reason if tip == "" or tip.begins_with("hotspots.") else "%s\n%s" % [tip, reason]
		else:
			var gate: = ActionPipeline.can_show_hotspot(row)
			if not gate.get("ok", false):
				name = "%s（%s）" % [name, str(gate.get("reason", ""))]
				tip = str(gate.get("reason", tip))
			else:
				can_enter = true
				any_open = true
		var btn: = Button.new()
		btn.text = name
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = not can_enter
		btn.tooltip_text = tip if tip != "" and not tip.begins_with("hotspots.") else ""
		UiStyle.apply_cozy_button(btn)
		if can_enter:
			btn.pressed.connect(_open_actions.bind(hid))
		action_list.add_child(btn)
		any = true

	if not any:
		var empty: = Label.new()
		empty.text = L10n.t("ui.empty.no_hotspots", "此地尚未开放")
		empty.add_theme_color_override("font_color", UiStyle.TEXT)
		action_list.add_child(empty)
	elif not any_open:
		var hint: = Label.new()
		hint.text = L10n.t("ui.empty.hotspots_locked_hint", "灰色项为未解锁设施，括号内是开放条件")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color", UiStyle.TEXT)
		action_list.add_child(hint)


func _open_actions(hotspot_id: String) -> void :
	if GameFlow.is_blocked():
		return
	_hotspot_id = hotspot_id
	_menu_mode = "actions"
	_set_player_frozen(true)
	_clear_list()
	action_panel.visible = true

	if _location_id != "":
		_refresh_people_strip(_location_id)
	var hs_name: = L10n.t("hotspots.%s.name" % hotspot_id, hotspot_id)
	action_title.text = hs_name
	close_actions.text = L10n.t("ui.settings.back", "返回")

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
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = not gate.get("ok", false) or GameFlow.is_blocked()
		UiStyle.apply_cozy_button(btn)
		if gate.get("ok", false):
			var desc: = L10n.t("actions.%s.description" % id, "")
			if desc != "" and desc != "actions.%s.description" % id:
				btn.tooltip_text = desc
			btn.pressed.connect(_run_action.bind(id))
		action_list.add_child(btn)
		any = true

	if not any:
		result_label.text = L10n.t("ui.empty.no_actions", "此处暂时无事可做")
		var empty: = Label.new()
		empty.text = L10n.t("ui.empty.no_actions", "此处暂时无事可做")
		empty.add_theme_color_override("font_color", UiStyle.TEXT)
		action_list.add_child(empty)


func _clear_list() -> void :
	for c in action_list.get_children():
		c.queue_free()


func _clear_people_strip() -> void :
	_people_chips.clear()
	_people_hover_i = -1
	if people_row == null:
		return
	if people_row.gui_input.is_connected(_on_people_row_gui):
		people_row.gui_input.disconnect(_on_people_row_gui)
	if people_row.mouse_exited.is_connected(_on_people_row_exit):
		people_row.mouse_exited.disconnect(_on_people_row_exit)
	for c in people_row.get_children():
		c.queue_free()
	if people_strip:
		people_strip.visible = false


func _refresh_people_strip(location_id: String) -> void :
	_clear_people_strip()
	var ids: Array = NpcScheduler.npcs_at_building(location_id)
	if ids.is_empty():
		return
	_refresh_labels()

	_people_step = 58.0 if ids.size() >= 4 else 68.0
	var rail_w: = 100.0
	people_row.custom_minimum_size = Vector2(
		rail_w, 
		maxf(120.0, float(ids.size() - 1) * _people_step + 100.0)
	)
	people_row.mouse_filter = Control.MOUSE_FILTER_STOP
	people_row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not people_row.gui_input.is_connected(_on_people_row_gui):
		people_row.gui_input.connect(_on_people_row_gui)
	if not people_row.mouse_exited.is_connected(_on_people_row_exit):
		people_row.mouse_exited.connect(_on_people_row_exit)
	var i: = 0
	for nid_v in ids:
		var nid: = str(nid_v)
		var chip = NpcPortraitChipScript.new()
		people_row.add_child(chip)
		chip.setup(nid)
		chip.place_in_stack(i, _people_step, rail_w)
		_people_chips.append(chip)
		i += 1
	people_strip.visible = true


func _on_people_row_exit() -> void :
	_set_people_hover(-1)


func _on_people_row_gui(event: InputEvent) -> void :
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var local_y: = people_row.get_local_mouse_position().y
		var idx: = _people_index_at_y(local_y)
		_set_people_hover(idx)
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if idx >= 0 and idx < _people_chips.size():
				var chip = _people_chips[idx]
				_on_people_chip_pressed(str(chip.npc_id))
				people_row.accept_event()


func _people_index_at_y(local_y: float) -> int:
	if _people_chips.is_empty():
		return -1

	for i in range(_people_chips.size() - 1, -1, -1):
		var chip = _people_chips[i]
		var y0: float = chip.band_y0()
		var is_last: = i == _people_chips.size() - 1
		var h: float = chip.band_height(_people_step, is_last)
		if local_y >= y0 and local_y < y0 + h:
			return i
	return -1


func _set_people_hover(idx: int) -> void :
	if idx == _people_hover_i:
		return
	_people_hover_i = idx
	for i in _people_chips.size():
		var chip = _people_chips[i]
		if chip != null and is_instance_valid(chip) and chip.has_method("set_highlighted"):
			chip.set_highlighted(i == idx)


func _on_people_chip_pressed(npc_id: String) -> void :
	SfxPlayer.play_click()
	_open_npc_menu(npc_id)


func _open_npc_menu(npc_id: String) -> void :
	if GameFlow.is_blocked() or npc_id == "":
		return
	_npc_id = npc_id
	_menu_mode = "npc"
	_set_player_frozen(true)
	_clear_list()
	action_panel.visible = true
	people_strip.visible = true
	var nm: = L10n.t("npcs.%s.name" % npc_id, npc_id)
	action_title.text = nm
	close_actions.text = L10n.t("ui.settings.back", "返回")


	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_list.add_child(row)

	var bust: = CenterContainer.new()
	bust.custom_minimum_size = Vector2(104, 128)
	bust.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bust)
	var pv: = PortraitView.new()
	pv.custom_minimum_size = Vector2(92, 118)
	bust.add_child(pv)
	pv.custom_minimum_size = Vector2(92, 118)
	pv.size = Vector2(92, 118)
	pv.set_speaker(npc_id)

	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(col)

	var talk: = Button.new()
	talk.text = L10n.t("ui.location.talk", "交谈")
	talk.custom_minimum_size = Vector2(0, 48)
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk.disabled = not NpcScheduler.can_talk(npc_id)
	if talk.disabled:
		talk.tooltip_text = L10n.t("ui.location.talked_today", "（今日已谈）")
	UiStyle.apply_cozy_button(talk)
	talk.pressed.connect(_on_indoor_talk.bind(npc_id))
	col.add_child(talk)

	var dossier: = Button.new()
	dossier.text = L10n.t("ui.location.view_dossier", "查看档案")
	dossier.custom_minimum_size = Vector2(0, 48)
	dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_cozy_button(dossier)
	dossier.pressed.connect(_on_view_npc_dossier.bind(npc_id))
	col.add_child(dossier)


func _on_indoor_talk(npc_id: String) -> void :
	SfxPlayer.play_click()
	if NpcScheduler.try_start_indoor_talk(npc_id):

		result_label.text = ""
	else:
		result_label.text = L10n.t("ui.location.talk_fail", "此刻不便交谈")
		_open_npc_menu(npc_id)


func _on_view_npc_dossier(npc_id: String) -> void :
	SfxPlayer.play_click()
	var panel: = get_tree().get_first_node_in_group("dossier_panel")
	if panel != null and panel.has_method("open"):
		panel.open(npc_id)


func _on_close_pressed() -> void :
	SfxPlayer.play_click()
	if _menu_mode == "actions" or _menu_mode == "npc":
		open_location_menu(_location_id)
		return
	if _menu_mode == "facilities":
		_leave_location()
		return
	_hide_actions()


func _leave_location() -> void :
	_hide_actions()
	if world and world.has_method("exit_interior"):
		world.call("exit_interior")


func _hide_actions() -> void :
	_menu_mode = "closed"
	_hotspot_id = ""
	_npc_id = ""
	action_panel.visible = false
	_clear_list()
	_clear_people_strip()
	_set_player_frozen(false)


func _run_action(action_id: String) -> void :
	SfxPlayer.play_click()
	ActionPipeline.run(action_id)


func _on_action_resolved(result: Dictionary) -> void :
	result_label.text = str(result.get("message", ""))
	if result.get("ok", false) and str(result.get("check_id", "")) != "":
		TipSystem.on_first_check()
		if bool(result.get("check_passed", true)):
			SfxPlayer.play_success()
		else:
			SfxPlayer.play_fail()
	if result.get("ok", false) and not result.get("cancelled", false):
		TipSystem.on_action_done()
	TipSystem.on_flags_changed()
	TipSystem.pulse_when_free()
	if world and world.has_method("refresh_after_action"):
		world.refresh_after_action()
	_reopen_interior_menu_when_free()


func _on_event_resolved(_e: String, _c: String, _applied: Array = []) -> void :
	TipSystem.on_flags_changed()
	TipSystem.on_unlock_pulse()
	TipSystem.pulse_when_free()
	if world and world.has_method("refresh_after_action"):
		world.refresh_after_action()
	_reopen_interior_menu_when_free()


func _reopen_interior_menu_when_free() -> void :
	var want_interior: = world != null and str(world.get("mode")) == "interior" and _location_id != ""
	if not want_interior:
		_hide_actions()
		return
	## Keep freeze + location id while BeatFeed/events hold the gate, then restore.
	if _menu_mode == "closed":
		_menu_mode = "facilities"
	_set_player_frozen(true)
	action_panel.visible = false
	call_deferred("_wait_and_reopen_interior_menu")


func _wait_and_reopen_interior_menu() -> void :
	var loc: = _location_id
	while is_instance_valid(self) and GameFlow.is_blocked():
		await get_tree().process_frame
	if not is_instance_valid(self):
		return
	if world == null or str(world.get("mode")) != "interior" or loc == "" or loc != _location_id:
		return
	if GameFlow.is_blocked():
		return
	open_location_menu(loc)


func _on_settings() -> void :
	SfxPlayer.play_click()
	_set_player_frozen(true)
	if _settings and _settings.has_method("open"):
		_settings.open(1)


func _on_settings_closed() -> void :

	if _menu_mode == "closed":
		_set_player_frozen(false)
