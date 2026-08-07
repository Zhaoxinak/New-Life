extends CanvasLayer
## Taikou-style location menus: enter building → facilities → actions.

@onready var prompt_label: Label = %PromptLabel
@onready var action_panel: PanelContainer = %ActionPanel
@onready var action_title: Label = %ActionTitle
@onready var action_list: VBoxContainer = %ActionList
@onready var result_label: RichTextLabel = %ResultLabel
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var menu_button: Button = %MenuButton
@onready var lang_button: Button = %LangButton
@onready var close_actions: Button = %CloseActions

var world: Node = null
var _menu_mode: String = "closed" # closed | facilities | actions
var _location_id: String = ""
var _hotspot_id: String = ""


func bind_world(host: Node) -> void:
	world = host
	if world.has_signal("prompt_changed"):
		world.prompt_changed.connect(_on_prompt)
	if world.has_signal("hotspot_opened"):
		world.hotspot_opened.connect(_open_actions)
	if world.has_signal("location_entered"):
		world.location_entered.connect(open_location_menu)
	if world.has_signal("request_result"):
		world.request_result.connect(func(t): result_label.text = t)


func _ready() -> void:
	layer = 10
	action_panel.visible = false
	prompt_label.text = ""
	result_label.text = ""
	# Center the location menu (太阁式)
	action_panel.set_anchors_preset(Control.PRESET_CENTER)
	action_panel.offset_left = -220.0
	action_panel.offset_right = 220.0
	action_panel.offset_top = -260.0
	action_panel.offset_bottom = 260.0
	UiStyle.apply_cozy_button(save_button)
	UiStyle.apply_cozy_button(load_button)
	UiStyle.apply_cozy_button(menu_button)
	UiStyle.apply_cozy_button(lang_button)
	UiStyle.apply_cozy_button(close_actions)
	action_panel.add_theme_stylebox_override("panel", UiStyle.make_parchment_style())
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	menu_button.pressed.connect(_on_menu)
	lang_button.pressed.connect(_on_lang)
	close_actions.pressed.connect(_on_close_pressed)
	if not ActionPipeline.action_resolved.is_connected(_on_action_resolved):
		ActionPipeline.action_resolved.connect(_on_action_resolved)
	if not EventScheduler.event_resolved.is_connected(_on_event_resolved):
		EventScheduler.event_resolved.connect(_on_event_resolved)
	if not GameFlow.block_changed.is_connected(_on_block):
		GameFlow.block_changed.connect(_on_block)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)
	_refresh_labels()


func _on_locale(_l: String) -> void:
	_refresh_labels()
	if _menu_mode == "facilities":
		open_location_menu(_location_id)
	elif _menu_mode == "actions":
		_open_actions(_hotspot_id)


func _refresh_labels() -> void:
	save_button.text = L10n.t("ui.save.save", "保存")
	load_button.text = L10n.t("ui.save.load", "读取")
	menu_button.text = L10n.t("ui.menu.title", "标题")
	lang_button.text = L10n.locale


func _on_prompt(text: String) -> void:
	# Indoor uses menu; only show outdoor door prompts.
	if _menu_mode != "closed":
		prompt_label.visible = false
		return
	prompt_label.text = text
	prompt_label.visible = text != ""


func _on_block(blocked: bool) -> void:
	if blocked and _menu_mode != "closed":
		action_panel.visible = false
	elif not blocked and _menu_mode == "facilities" and _location_id != "":
		open_location_menu(_location_id)


func _set_player_frozen(frozen: bool) -> void:
	if world and world.has_method("set_menu_open"):
		world.call("set_menu_open", frozen)


func open_location_menu(location_id: String) -> void:
	if GameFlow.is_blocked():
		return
	_location_id = location_id
	_hotspot_id = ""
	_menu_mode = "facilities"
	_set_player_frozen(true)
	_clear_list()
	action_panel.visible = true
	var loc_name := L10n.t("locations.%s.name" % location_id, location_id)
	action_title.text = loc_name
	close_actions.text = L10n.t("ui.world.exit", "出门")

	var any := false
	for row in PackDB.get_hotspots_for_location(location_id):
		var hid := str(row.get("id", ""))
		if not GameState.is_hotspot_unlocked(hid):
			continue
		var gate := ActionPipeline.can_show_hotspot(row)
		var name := L10n.t("hotspots.%s.name" % hid, hid)
		if not gate.get("ok", false):
			name = "%s（%s）" % [name, str(gate.get("reason", ""))]
		var btn := Button.new()
		btn.text = name
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = not gate.get("ok", false)
		UiStyle.apply_cozy_button(btn)
		if gate.get("ok", false):
			btn.pressed.connect(_open_actions.bind(hid))
		action_list.add_child(btn)
		any = true

	if not any:
		var empty := Label.new()
		empty.text = L10n.t("ui.empty.no_hotspots", "此地尚未开放")
		empty.add_theme_color_override("font_color", UiStyle.TEXT)
		action_list.add_child(empty)


func _open_actions(hotspot_id: String) -> void:
	if GameFlow.is_blocked():
		return
	_hotspot_id = hotspot_id
	_menu_mode = "actions"
	_set_player_frozen(true)
	_clear_list()
	action_panel.visible = true
	var hs_name := L10n.t("hotspots.%s.name" % hotspot_id, hotspot_id)
	action_title.text = hs_name
	close_actions.text = L10n.t("ui.settings.back", "返回")

	var any := false
	for row in PackDB.get_actions_for_hotspot(hotspot_id):
		var id := str(row.get("id", ""))
		var gate := ActionPipeline.can_run(row)
		var name := L10n.t("actions.%s.name" % id, id)
		var check_id := str(row.get("check_id", "")).strip_edges()
		if check_id != "" and gate.get("ok", false):
			var pct := int(round(CheckResolver.preview_chance(check_id) * 100.0))
			name = "%s  ~%d%%" % [name, pct]
		if not gate.get("ok", false):
			name = "%s（%s）" % [name, str(gate.get("reason", ""))]
		var btn := Button.new()
		btn.text = name
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = not gate.get("ok", false) or GameFlow.is_blocked()
		UiStyle.apply_cozy_button(btn)
		if gate.get("ok", false):
			var desc := L10n.t("actions.%s.description" % id, "")
			if desc != "" and desc != "actions.%s.description" % id:
				btn.tooltip_text = desc
			btn.pressed.connect(_run_action.bind(id))
		action_list.add_child(btn)
		any = true

	if not any:
		result_label.text = L10n.t("ui.empty.no_actions", "此处暂时无事可做")
		var empty := Label.new()
		empty.text = L10n.t("ui.empty.no_actions", "此处暂时无事可做")
		empty.add_theme_color_override("font_color", UiStyle.TEXT)
		action_list.add_child(empty)


func _clear_list() -> void:
	for c in action_list.get_children():
		c.queue_free()


func _on_close_pressed() -> void:
	SfxPlayer.play_click()
	if _menu_mode == "actions":
		open_location_menu(_location_id)
		return
	if _menu_mode == "facilities":
		_leave_location()
		return
	_hide_actions()


func _leave_location() -> void:
	_hide_actions()
	if world and world.has_method("exit_interior"):
		world.call("exit_interior")


func _hide_actions() -> void:
	_menu_mode = "closed"
	_hotspot_id = ""
	action_panel.visible = false
	_clear_list()
	_set_player_frozen(false)


func _run_action(action_id: String) -> void:
	SfxPlayer.play_click()
	ActionPipeline.run(action_id)


func _on_action_resolved(result: Dictionary) -> void:
	result_label.text = str(result.get("message", ""))
	if result.get("ok", false) and str(result.get("check_id", "")) != "":
		TipSystem.on_first_check()
		if bool(result.get("check_passed", true)):
			SfxPlayer.play_success()
		else:
			SfxPlayer.play_fail()
	TipSystem.on_flags_changed()
	TipSystem.pulse_when_free()
	if world and world.has_method("refresh_after_action"):
		world.refresh_after_action()
	# Stay inside: reopen facility list after an action (太阁循环)
	if world and str(world.get("mode")) == "interior" and _location_id != "" and not GameFlow.is_blocked():
		open_location_menu(_location_id)
	else:
		_hide_actions()


func _on_event_resolved(_e: String, _c: String) -> void:
	TipSystem.on_flags_changed()
	TipSystem.on_unlock_pulse()
	TipSystem.pulse_when_free()
	if world and world.has_method("refresh_after_action"):
		world.refresh_after_action()
	if world and str(world.get("mode")) == "interior" and _location_id != "" and not GameFlow.is_blocked():
		open_location_menu(_location_id)


func _on_save() -> void:
	SfxPlayer.play_click()
	result_label.text = L10n.t("ui.save.success", "已保存") if SaveSystem.save_game() else L10n.t("ui.save.failed", "保存失败")


func _on_load() -> void:
	SfxPlayer.play_click()
	if SaveSystem.load_game():
		result_label.text = L10n.t("ui.save.load_success", "已读取")
		get_tree().reload_current_scene()
	else:
		result_label.text = L10n.t("ui.save.slot_empty", "空存档")


func _on_menu() -> void:
	SfxPlayer.play_click()
	get_tree().change_scene_to_file("res://ui/TitleMenu.tscn")


func _on_lang() -> void:
	SfxPlayer.play_click()
	L10n.set_locale("en" if L10n.locale == "zh_CN" else "zh_CN")
