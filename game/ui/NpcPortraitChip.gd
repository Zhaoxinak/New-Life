extends Control
class_name NpcPortraitChip


signal selected(npc_id: String)

const FRAME: = Vector2(56, 72)
const CHIP_SIZE: = Vector2(72, 96)

var npc_id: String = ""
var stack_index: int = 0
var _portrait: PortraitView
var _name: Label
var _name_plate: PanelContainer
var _badge: Label
var _frame_panel: PanelContainer
var _rest_pos: Vector2 = Vector2.ZERO
var _highlighted: bool = false
var _tween: Tween


func setup(id: String) -> void :
	npc_id = id
	custom_minimum_size = CHIP_SIZE
	size = CHIP_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = L10n.t("npcs.%s.name" % id, id)
	_build()
	refresh()


func place_in_stack(index: int, step_y: float, rail_width: float) -> void :
	stack_index = index
	z_index = index
	var rest_x: = maxf(0.0, rail_width - CHIP_SIZE.x - 2.0)
	_rest_pos = Vector2(rest_x, float(index) * step_y)
	_kill_tween()
	position = _rest_pos
	scale = Vector2.ONE
	_highlighted = false
	if _name_plate:
		_name_plate.visible = false
	_apply_frame_style(false)


func refresh() -> void :
	if _name:
		_name.text = L10n.t("npcs.%s.name" % npc_id, npc_id)
	if _badge:
		var talked: = not NpcScheduler.can_talk(npc_id)
		_badge.visible = talked
		_badge.text = L10n.t("ui.location.talked_badge", "已谈")
	if _portrait:
		_portrait.set_speaker(npc_id)
		_portrait.set_cold( not NpcScheduler.can_talk(npc_id))


func set_highlighted(on: bool) -> void :
	if _highlighted == on:
		return
	_highlighted = on
	z_index = (200 + stack_index) if on else stack_index
	if _name_plate:
		_name_plate.visible = on
	_apply_frame_style(on)
	_kill_tween()

	var target: = _rest_pos + Vector2(-18.0, 0.0) if on else _rest_pos
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target, 0.08)


func band_y0() -> float:
	return _rest_pos.y


func band_height(step_y: float, is_last: bool) -> float:
	if is_last:
		return CHIP_SIZE.y
	return maxf(28.0, step_y)


func _kill_tween() -> void :
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_tween = null


func _build() -> void :
	for c in get_children():
		c.queue_free()

	_frame_panel = PanelContainer.new()
	_frame_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_panel)
	_apply_frame_style(false)

	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_panel.add_child(col)

	var frame: = Control.new()
	frame.custom_minimum_size = FRAME
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(frame)

	_portrait = PortraitView.new()
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.custom_minimum_size = FRAME
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_portrait)


	_name_plate = PanelContainer.new()
	_name_plate.visible = false
	_name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var plate: = StyleBoxFlat.new()
	plate.bg_color = Color(0.18, 0.11, 0.06, 0.94)
	plate.border_color = UiStyle.BRASS
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(3)
	plate.content_margin_left = 4
	plate.content_margin_right = 4
	plate.content_margin_top = 2
	plate.content_margin_bottom = 2
	_name_plate.add_theme_stylebox_override("panel", plate)
	col.add_child(_name_plate)

	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.custom_minimum_size = Vector2(56, 18)
	_name.add_theme_font_size_override("font_size", 13)
	_name.add_theme_color_override("font_color", UiStyle.TEXT_ON_DARK)
	_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	_name.add_theme_constant_override("outline_size", 1)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_plate.add_child(_name)

	_badge = Label.new()
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.add_theme_font_size_override("font_size", 10)
	_badge.add_theme_color_override("font_color", UiStyle.BRASS)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.visible = false
	col.add_child(_badge)


func _apply_frame_style(hi: bool) -> void :
	if _frame_panel == null:
		return
	var s: = StyleBoxFlat.new()
	if hi:
		s.bg_color = Color(1.0, 0.97, 0.88, 1.0)
		s.border_color = UiStyle.BRASS
		s.set_border_width_all(3)
		s.shadow_size = 5
	else:
		s.bg_color = Color(0.95, 0.9, 0.78, 0.96)
		s.border_color = UiStyle.WOOD
		s.set_border_width_all(2)
		s.shadow_size = 2
	s.set_corner_radius_all(6)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 4
	s.content_margin_bottom = 3
	s.shadow_color = Color(0, 0, 0, 0.22)
	_frame_panel.add_theme_stylebox_override("panel", s)
