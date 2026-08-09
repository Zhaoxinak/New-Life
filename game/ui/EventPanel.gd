extends CanvasLayer


@onready var root_panel: Control = %Root
@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var choices_box: VBoxContainer = %ChoicesBox
@onready var continue_label: Label = %ContinueLabel
@onready var accent_bar: ColorRect = %AccentBar

var _event_id: String = ""
var _segments: PackedStringArray = PackedStringArray()
var _segment_index: int = 0
var _preset: Dictionary = {}
var _awaiting_advance: bool = false
var _segment_ready_at_ms: int = 0
var _open_token: int = 0
var _backdrop_base: Color = Color(0.08, 0.06, 0.04, 0.55)


func _ready() -> void :
	visible = false
	root_panel.visible = false
	if continue_label:
		continue_label.visible = false
	if accent_bar:
		accent_bar.visible = false
	if not EventScheduler.event_available.is_connected(_on_event):
		EventScheduler.event_available.connect(_on_event)


func _input(event: InputEvent) -> void :
	if not visible or not _awaiting_advance:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_advance()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_try_advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_try_advance()
			get_viewport().set_input_as_handled()


func _on_event(event_id: String) -> void :
	open(event_id)


func open(event_id: String) -> void :
	_open_token += 1
	var token: = _open_token
	_event_id = event_id
	_preset = EventStaging.preset_for(event_id)
	_segment_index = 0
	_awaiting_advance = false
	EventScheduler.ensure_event_effects()
	SfxPlayer.play_event()
	var duck: = float(_preset.get("duck_ambience", 0.0))
	if duck > 0.0:
		SfxPlayer.duck_ambience(duck)
	title_label.text = L10n.t("events.%s.title" % event_id, event_id)
	title_label.add_theme_color_override("font_color", UiStyle.WOOD)
	var body: = _resolve_event_body(event_id)
	_segments = EventStaging.split_body(body)
	_clear_choices()
	if continue_label:
		continue_label.visible = false
	_reset_accent()
	_backdrop_base = EventStaging.BACKDROP_WARM
	if root_panel is ColorRect:
		(root_panel as ColorRect).color = _backdrop_base
	visible = true
	root_panel.visible = true
	GameFlow.set_event_open(true)
	layer = 25
	root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	await _play_segments(token)


func _play_segments(token: int) -> void :
	while token == _open_token and _segment_index < _segments.size():
		_show_segment(_segment_index)
		var is_last: = _segment_index >= _segments.size() - 1
		if is_last:
			_awaiting_advance = false
			if continue_label:
				continue_label.visible = false
			await _reveal_choices(token)
			return
		_awaiting_advance = true
		_segment_ready_at_ms = Time.get_ticks_msec() + int(EventStaging.MIN_SEGMENT_SEC * 1000.0)
		if continue_label:
			continue_label.text = L10n.t("ui.event.continue_hint", "点击继续…")
			continue_label.visible = true
		while token == _open_token and _awaiting_advance:
			await get_tree().process_frame
		if token != _open_token:
			return
		_segment_index += 1


func _show_segment(index: int) -> void :
	var text: = _segments[index] if index < _segments.size() else ""
	body_label.text = text
	var stinger: = EventStaging.stinger_for_segment(_preset, index)
	if stinger != "":
		SfxPlayer.play_stinger(stinger)
	_apply_backdrop_dim(index)
	_flash_accent(index)


func _reset_accent() -> void :
	if accent_bar == null:
		return
	accent_bar.visible = false
	accent_bar.modulate.a = 0.0


func _flash_accent(index: int) -> void :
	if accent_bar == null:
		return
	var speaker: = str(_preset.get("accent_speaker", "")).strip_edges()
	if speaker == "":
		accent_bar.visible = false
		return

	var dim_from: = int(_preset.get("dim_from_segment", 1))
	if index < maxi(0, dim_from):
		return
	var c: Color = UiStyle.portrait_color(speaker)
	accent_bar.color = c
	accent_bar.visible = true
	accent_bar.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(accent_bar, "modulate:a", 1.0, 0.18)
	tw.tween_property(accent_bar, "modulate:a", 0.55, 0.35)


func _apply_backdrop_dim(index: int) -> void :
	if not (root_panel is ColorRect):
		return
	var dim_from: = int(_preset.get("dim_from_segment", -1))
	var use_cold: = bool(_preset.get("backdrop_cold", false)) and dim_from >= 0 and index >= dim_from
	var target: = EventStaging.BACKDROP_COLD if use_cold else EventStaging.BACKDROP_WARM
	var rect: = root_panel as ColorRect
	var tw: = create_tween()
	tw.tween_property(rect, "color", target, 0.28)


func _try_advance() -> void :
	if not _awaiting_advance:
		return
	if Time.get_ticks_msec() < _segment_ready_at_ms:
		return
	_awaiting_advance = false
	SfxPlayer.play_click()


func _reveal_choices(token: int) -> void :
	if token != _open_token:
		return
	var delay: = float(_preset.get("choice_delay", 0.0))
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if token != _open_token:
		return
	var buttons: = _build_choice_buttons()
	var stagger: = bool(_preset.get("choice_stagger", false))
	if stagger and buttons.size() > 0:
		for btn in buttons:
			btn.modulate.a = 0.0
			choices_box.add_child(btn)
		for i in buttons.size():
			if token != _open_token:
				return
			var b: Button = buttons[i]
			var tw: = create_tween()
			tw.tween_property(b, "modulate:a", 1.0, 0.18)
			if i < buttons.size() - 1:
				await get_tree().create_timer(EventStaging.CHOICE_STAGGER_SEC).timeout
	else:
		for btn in buttons:
			choices_box.add_child(btn)


func _build_choice_buttons() -> Array:
	var buttons: Array = []
	var choices: = PackDB.get_event_choices(_event_id)
	if choices.is_empty():
		buttons.append(_make_choice_button(L10n.t("ui.common.confirm", "确定"), ""))
		return buttons
	for row in choices:
		var cid: = str(row.get("id", ""))
		if PackDB.get_conditions("event_choice", cid).size() > 0:
			if not ConditionEval.eval_owner("event_choice", cid).get("ok", false):
				continue
		if PackDB.get_conditions("choice", cid).size() > 0:
			if not ConditionEval.eval_owner("choice", cid).get("ok", false):
				continue
		buttons.append(_make_choice_button(L10n.t("event_choices.%s.label" % cid, cid), cid))
	if buttons.is_empty():
		buttons.append(_make_choice_button(L10n.t("ui.common.confirm", "确定"), ""))
	return buttons


func _make_choice_button(label: String, choice_id: String) -> Button:
	var btn: = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 44)
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	if bool(_preset.get("route_choice_styles", false)) and choice_id != "":
		var weight: = EventStaging.route_choice_weight(choice_id)
		UiStyle.apply_choice_button(btn, weight)
	else:
		UiStyle.apply_cozy_button(btn)
	btn.pressed.connect(_on_choice.bind(choice_id))
	return btn


func _on_choice(choice_id: String) -> void :
	if not visible or _event_id == "":
		return
	_awaiting_advance = false
	var resolving_id: = _event_id
	for c in choices_box.get_children():
		if c is BaseButton:
			(c as BaseButton).disabled = true
	var cs: = EventStaging.choice_stinger(_preset, choice_id)
	if cs != "":
		SfxPlayer.play_stinger(cs)
	else:
		SfxPlayer.play_click()
	var pause: = float(_preset.get("post_choice_pause", 0.0))
	if pause > 0.0:
		choices_box.modulate.a = 0.35
		await get_tree().create_timer(pause).timeout
		if _event_id != resolving_id:
			return
	_open_token += 1
	visible = false
	root_panel.visible = false
	if continue_label:
		continue_label.visible = false
	_reset_accent()
	choices_box.modulate.a = 1.0
	if root_panel is ColorRect:
		(root_panel as ColorRect).color = EventStaging.BACKDROP_WARM
	GameFlow.set_event_open(false)
	EventScheduler.resolve_choice(choice_id)
	_event_id = ""
	TipSystem.pulse_when_free()


func _clear_choices() -> void :
	for c in choices_box.get_children():
		c.queue_free()


func _resolve_event_body(event_id: String) -> String:
	var body: = L10n.t("events.%s.body" % event_id, "")
	if GameState.get_flag("divorced_su") != 0:
		var add: = L10n.t("events.%s.body_divorced" % event_id, "")
		if add != "":
			body = "%s|||%s" % [body, add]
	if GameState.get_flag("divorce_as_weapon") != 0:
		var add_w: = L10n.t("events.%s.body_divorce_weapon" % event_id, "")
		if add_w != "":
			body = "%s|||%s" % [body, add_w]

	if GameState.get_flag("su_reconcile_path") != 0 and GameState.get_flag("divorce_as_weapon") == 0\
	and GameState.get_flag("su_used_as_tool") == 0:
		var add_r: = L10n.t("events.%s.body_reconcile" % event_id, "")
		if add_r != "":
			body = "%s|||%s" % [body, add_r]
	if GameState.get_flag("su_let_go") != 0:
		var add_lg: = L10n.t("events.%s.body_let_go" % event_id, "")
		if add_lg != "":
			body = "%s|||%s" % [body, add_lg]
	return body
