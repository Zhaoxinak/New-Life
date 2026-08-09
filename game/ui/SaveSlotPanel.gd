extends CanvasLayer



signal closed
signal feedback(text: String)
signal loaded_and_ready

enum Mode{SAVE, LOAD}

@export var mode: Mode = Mode.LOAD

var _root: Control
var _title: Label
var _list: VBoxContainer
var _status: Label
var _close_btn: Button
var _slot_rows: Array = []
var _confirm_slot: int = -999


func _ready() -> void :
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)
	if not SaveSystem.slots_changed.is_connected(_on_slots_changed):
		SaveSystem.slots_changed.connect(_on_slots_changed)


func open(p_mode: Mode = Mode.LOAD) -> void :
	mode = p_mode
	_confirm_slot = -999
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


func _on_slots_changed() -> void :
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

	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", UiStyle.make_parchment_style())
	center.add_child(panel)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

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

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	for s in range(SaveSystem.SLOT_COUNT):
		_slot_rows.append(_make_slot_row(s))

	_status = Label.new()
	_status.add_theme_color_override("font_color", UiStyle.WOOD)
	_status.add_theme_font_size_override("font_size", 13)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_status)

	_close_btn = Button.new()
	_close_btn.custom_minimum_size = Vector2(0, 44)
	UiStyle.apply_cozy_button(_close_btn)
	_close_btn.pressed.connect(_on_close)
	col.add_child(_close_btn)


func _make_slot_row(slot: int) -> Dictionary:
	var box: = PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner: = MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 10)
	inner.add_theme_constant_override("margin_right", 10)
	inner.add_theme_constant_override("margin_top", 8)
	inner.add_theme_constant_override("margin_bottom", 8)
	box.add_child(inner)

	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	inner.add_child(row)

	var text_col: = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)

	var title: = Label.new()
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", UiStyle.WOOD)
	text_col.add_child(title)

	var detail: = Label.new()
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", UiStyle.TEXT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(detail)

	var action: = Button.new()
	action.custom_minimum_size = Vector2(96, 40)
	UiStyle.apply_cozy_button(action)
	action.pressed.connect(_on_slot_action.bind(slot))
	row.add_child(action)

	var del: = Button.new()
	del.custom_minimum_size = Vector2(72, 40)
	UiStyle.apply_cozy_button(del)
	del.pressed.connect(_on_slot_delete.bind(slot))
	row.add_child(del)

	_list.add_child(box)
	return {
		"slot": slot, 
		"box": box, 
		"title": title, 
		"detail": detail, 
		"action": action, 
		"del": del, 
	}


func _refresh() -> void :
	if mode == Mode.SAVE:
		_title.text = L10n.t("ui.save.save_game", "保存游戏")
	else:
		_title.text = L10n.t("ui.save.load_game", "读取游戏")
	_close_btn.text = L10n.t("ui.settings.close", "关闭")
	if _confirm_slot < -100:
		_status.text = L10n.t("ui.save.autosave_hint", "游玩中约每 20 秒自动存档，也可手动多档保存。")
	for row in _slot_rows:
		var slot: int = int(row["slot"])
		var summary: = SaveSystem.read_slot_summary(slot)
		var title_lbl: Label = row["title"]
		var detail_lbl: Label = row["detail"]
		var action: Button = row["action"]
		var del: Button = row["del"]
		title_lbl.text = SaveSystem.slot_title(slot)
		detail_lbl.text = SaveSystem.format_slot_line(summary)
		var exists: = bool(summary.get("exists", false))
		if mode == Mode.SAVE:
			if SaveSystem.is_autosave_slot(slot):
				action.text = L10n.t("ui.save.write_autosave", "写入")
			else:
				action.text = L10n.t("ui.save.save", "保存")
			action.disabled = false
		else:
			action.text = L10n.t("ui.save.load", "读取")
			action.disabled = not exists
		del.text = L10n.t("ui.save.delete", "删除")
		del.disabled = not exists
		del.visible = exists


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


func _on_slot_action(slot: int) -> void :
	SfxPlayer.play_click()
	if mode == Mode.SAVE:
		_try_save(slot)
	else:
		_try_load(slot)


func _try_save(slot: int) -> void :
	var exists: = SaveSystem.has_save(slot)
	if exists and _confirm_slot != slot and not SaveSystem.is_autosave_slot(slot):
		_confirm_slot = slot
		_set_status(L10n.t("ui.save.overwrite_confirm", "覆盖此存档？") + " " + L10n.t("ui.save.overwrite_again", "再点一次确认。"))
		return
	_confirm_slot = -999
	var ok: = SaveSystem.save_to_slot(slot)
	if ok:
		_set_status(L10n.t("ui.save.success", "已保存"))
		_refresh()
	else:
		_set_status(L10n.t("ui.save.failed", "保存失败"))


func _try_load(slot: int) -> void :
	if not SaveSystem.has_save(slot):
		_set_status(L10n.t("ui.save.slot_empty", "空存档"))
		return
	if SaveSystem.load_slot(slot):
		_set_status(L10n.t("ui.save.load_success", "已读取"))
		close()
		loaded_and_ready.emit()
	else:
		_set_status(L10n.t("ui.save.load_failed", "读取失败"))


func _on_slot_delete(slot: int) -> void :
	SfxPlayer.play_click()
	if not SaveSystem.has_save(slot):
		return
	if _confirm_slot != slot + 1000:
		_confirm_slot = slot + 1000
		_set_status(L10n.t("ui.save.delete_confirm", "删除此存档？") + " " + L10n.t("ui.save.overwrite_again", "再点一次确认。"))
		return
	_confirm_slot = -999
	if SaveSystem.delete_slot(slot):
		_set_status(L10n.t("ui.save.deleted", "已删除"))
		_refresh()
	else:
		_set_status(L10n.t("ui.save.delete_failed", "删除失败"))
