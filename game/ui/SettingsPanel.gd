extends CanvasLayer


signal closed
signal feedback(text: String)

enum Mode{TITLE, INGAME}

@export var mode: Mode = Mode.INGAME

var _root: Control
var _panel: PanelContainer
var _title: Label
var _body: VBoxContainer
var _status: Label
var _close_btn: Button
var _window_btn: Button
var _sfx_slider: HSlider
var _sfx_value: Label
var _music_slider: HSlider
var _music_value: Label
var _music_toggle: Button
var _voice_toggle: Button
var _lang_btn: Button
var _save_btn: Button
var _load_btn: Button
var _to_title_btn: Button
var _quit_btn: Button
var _sfx_name: Label
var _music_name: Label
var _section_labels: Array[Label] = []
var _slots: CanvasLayer = null

const SaveSlotPanelScene: = preload("res://ui/SaveSlotPanel.tscn")


func _ready() -> void :
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	_slots = SaveSlotPanelScene.instantiate()
	add_child(_slots)
	if _slots.has_signal("feedback"):
		_slots.feedback.connect( func(t: String): _set_status(t))
	if _slots.has_signal("loaded_and_ready"):
		_slots.loaded_and_ready.connect(_on_loaded_ready)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func open(p_mode: Mode = Mode.INGAME) -> void :
	mode = p_mode
	visible = true
	_refresh()


func close() -> void :
	if not visible:
		return
	visible = false
	closed.emit()


func _on_locale(_l: String) -> void :
	if visible:
		_refresh()


func _unhandled_input(event: InputEvent) -> void :
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		SfxPlayer.play_click()
		close()
		get_viewport().set_input_as_handled()


func _build() -> void :
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim: = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.05, 0.03, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	_root.add_child(dim)

	var center: = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(460, 0)
	_panel.add_theme_stylebox_override("panel", UiStyle.make_parchment_style())
	center.add_child(_panel)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_panel.add_child(margin)

	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", UiStyle.WOOD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	var scroll: = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)

	_add_section("display")
	_window_btn = _make_button()
	_window_btn.pressed.connect(_on_window)
	_body.add_child(_window_btn)

	_add_section("audio")
	var sfx_row: = _make_slider_row()
	_sfx_slider = sfx_row["slider"]
	_sfx_value = sfx_row["value"]
	_sfx_name = sfx_row["name"]
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_body.add_child(sfx_row["row"])

	var music_row: = _make_slider_row()
	_music_slider = music_row["slider"]
	_music_value = music_row["value"]
	_music_name = music_row["name"]
	_music_slider.value_changed.connect(_on_music_vol_changed)
	_body.add_child(music_row["row"])

	_music_toggle = _make_button()
	_music_toggle.pressed.connect(_on_music_toggle)
	_body.add_child(_music_toggle)

	_voice_toggle = _make_button()
	_voice_toggle.pressed.connect(_on_voice_toggle)
	_body.add_child(_voice_toggle)

	_add_section("language")
	_lang_btn = _make_button()
	_lang_btn.pressed.connect(_on_lang)
	_body.add_child(_lang_btn)

	_add_section("save")
	_save_btn = _make_button()
	_save_btn.pressed.connect(_on_save)
	_body.add_child(_save_btn)
	_load_btn = _make_button()
	_load_btn.pressed.connect(_on_load)
	_body.add_child(_load_btn)

	_add_section("leave")
	_to_title_btn = _make_button()
	_to_title_btn.pressed.connect(_on_to_title)
	_body.add_child(_to_title_btn)
	_quit_btn = _make_button()
	_quit_btn.pressed.connect(_on_quit)
	_body.add_child(_quit_btn)

	_status = Label.new()
	_status.add_theme_color_override("font_color", UiStyle.WOOD)
	_status.add_theme_font_size_override("font_size", 13)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_status)

	_close_btn = _make_button()
	_close_btn.pressed.connect(_on_close)
	col.add_child(_close_btn)


func _add_section(kind: String) -> void :
	var lbl: = Label.new()
	lbl.set_meta("section_kind", kind)
	lbl.add_theme_color_override("font_color", UiStyle.WOOD)
	lbl.add_theme_font_size_override("font_size", 14)
	_body.add_child(lbl)
	_section_labels.append(lbl)


func _make_button() -> Button:
	var btn: = Button.new()
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_cozy_button(btn)
	return btn


func _make_slider_row() -> Dictionary:
	var row: = VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var top: = HBoxContainer.new()
	var name_lbl: = Label.new()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", UiStyle.TEXT)
	name_lbl.add_theme_font_size_override("font_size", 14)
	var value_lbl: = Label.new()
	value_lbl.add_theme_color_override("font_color", UiStyle.WOOD)
	value_lbl.add_theme_font_size_override("font_size", 14)
	value_lbl.custom_minimum_size = Vector2(48, 0)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(name_lbl)
	top.add_child(value_lbl)
	row.add_child(top)
	var slider: = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 22)
	row.add_child(slider)
	return {
		"row": row, 
		"name": name_lbl, 
		"value": value_lbl, 
		"slider": slider, 
	}


func _refresh() -> void :
	_title.text = L10n.t("ui.menu.settings", "设置")
	_close_btn.text = L10n.t("ui.settings.close", "关闭")
	_status.text = ""

	for lbl in _section_labels:
		var kind: = str(lbl.get_meta("section_kind", ""))
		match kind:
			"display":
				lbl.text = L10n.t("ui.settings.section.display", "—— 画面 ——")
			"audio":
				lbl.text = L10n.t("ui.settings.section.audio", "—— 声音 ——")
			"language":
				lbl.text = L10n.t("ui.settings.section.language", "—— 语言 ——")
			"save":
				lbl.text = L10n.t("ui.settings.section.save", "—— 存档 ——")
			"leave":
				lbl.text = L10n.t("ui.settings.section.leave", "—— 离开 ——")

	_window_btn.text = "%s：%s" % [
		L10n.t("ui.settings.window_size", "窗口大小"), 
		GameSettings.window_preset_label(), 
	]

	_sfx_name.text = L10n.t("ui.settings.volume_sfx", "音效")
	_sfx_slider.set_value_no_signal(GameSettings.sfx_volume * 100.0)
	_sfx_value.text = "%d%%" % int(round(GameSettings.sfx_volume * 100.0))

	_music_name.text = L10n.t("ui.settings.volume_bgm", "音乐")
	_music_slider.set_value_no_signal(GameSettings.music_volume * 100.0)
	_music_value.text = "%d%%" % int(round(GameSettings.music_volume * 100.0))

	var music_on: = GameSettings.music_enabled
	_music_toggle.text = "%s：%s" % [
		L10n.t("ui.settings.music_toggle", "背景音乐"), 
		L10n.t("ui.settings.on", "开") if music_on else L10n.t("ui.settings.off", "关"), 
	]

	var voice_on: = GameSettings.voice_enabled
	_voice_toggle.text = "%s：%s" % [
		L10n.t("ui.settings.voice_toggle", "对话语音"), 
		L10n.t("ui.settings.on", "开") if voice_on else L10n.t("ui.settings.off", "关"), 
	]

	var lang_name: = "简体中文" if L10n.locale == "zh_CN" else "English"
	_lang_btn.text = "%s：%s" % [L10n.t("ui.settings.language", "语言"), lang_name]

	_save_btn.text = L10n.t("ui.save.save_game", "保存游戏")
	_load_btn.text = L10n.t("ui.save.load_game", "读取游戏")
	_to_title_btn.text = L10n.t("ui.menu.to_title", "返回主界面")
	_quit_btn.text = L10n.t("ui.menu.quit_game", "退出游戏")

	var ingame: = mode == Mode.INGAME
	_save_btn.visible = ingame
	_load_btn.visible = ingame
	_to_title_btn.visible = ingame
	_quit_btn.visible = ingame
	for lbl in _section_labels:
		var kind: = str(lbl.get_meta("section_kind", ""))
		if kind == "save" or kind == "leave":
			lbl.visible = ingame


func _set_status(text: String) -> void :
	_status.text = text
	feedback.emit(text)


func _on_dim_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SfxPlayer.play_click()
		close()


func _on_close() -> void :
	SfxPlayer.play_click()
	close()


func _on_window() -> void :
	SfxPlayer.play_click()
	GameSettings.cycle_window_preset()
	_refresh()


func _on_sfx_changed(v: float) -> void :
	GameSettings.set_sfx_volume(v / 100.0)
	_sfx_value.text = "%d%%" % int(round(v))


func _on_music_vol_changed(v: float) -> void :
	GameSettings.set_music_volume(v / 100.0)
	_music_value.text = "%d%%" % int(round(v))


func _on_music_toggle() -> void :
	SfxPlayer.play_click()
	GameSettings.set_music_enabled( not GameSettings.music_enabled)
	_refresh()


func _on_voice_toggle() -> void :
	SfxPlayer.play_click()
	GameSettings.set_voice_enabled( not GameSettings.voice_enabled)
	_refresh()


func _on_lang() -> void :
	SfxPlayer.play_click()
	var next: = "en" if L10n.locale == "zh_CN" else "zh_CN"
	GameSettings.set_locale_pref(next)
	_refresh()


func _on_save() -> void :
	SfxPlayer.play_click()
	if _slots and _slots.has_method("open"):
		_slots.open(0)


func _on_load() -> void :
	SfxPlayer.play_click()
	if _slots and _slots.has_method("open"):
		_slots.open(1)


func _on_loaded_ready() -> void :
	close()
	get_tree().reload_current_scene()


func _on_to_title() -> void :
	SfxPlayer.play_click()
	SaveSystem.autosave()
	SaveSystem.set_session_active(false)
	close()
	get_tree().change_scene_to_file("res://ui/TitleMenu.tscn")


func _on_quit() -> void :
	SfxPlayer.play_click()
	SaveSystem.autosave()
	SaveSystem.set_session_active(false)
	get_tree().quit()
