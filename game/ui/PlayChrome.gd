extends Control
## 暗潮 2D 玩法壳：地点舞台 + 对白 + 薄 HUD + 行动纸片 + 账簿快捷键。

signal return_to_title

@onready var stage: Control = %LocationStage
@onready var dialogue: Control = %DialogueBox
@onready var act_sheet: PanelContainer = %ActSheet
@onready var ledger: CanvasLayer = %LedgerOverlay
@onready var ladder_board: CanvasLayer = %LadderOverlay
@onready var settings: CanvasLayer = %SettingsOverlay
@onready var tutorial: CanvasLayer = %TutorialOverlay
@onready var help_layer: Control = %HelpLayer
@onready var help_title: Label = %HelpTitle
@onready var help_body: RichTextLabel = %HelpBody
@onready var day_label: Label = %DayLabel
@onready var hud_stats: HBoxContainer = %HudStats
@onready var tip_label: Label = %TipLabel
@onready var tip_banner: PanelContainer = %TipBanner
@onready var goal_label: Label = %GoalLabel
@onready var loc_nav: HBoxContainer = %LocNav
@onready var duty_rail: Panel = %DutyRail
@onready var duty_body: RichTextLabel = %DutyBody
@onready var duty_header: PanelContainer = %DutyHeader
@onready var duty_title: Label = %DutyTitle
@onready var duty_btn_collapse: Button = %DutyBtnCollapse
@onready var duty_btn_ladder: Button = %DutyBtnLadder
@onready var duty_resize: Button = %DutyResize
@onready var duty_scroll: ScrollContainer = %DutyScroll

var _selected_loc: String = "loc_01"
var _awaiting_continue: bool = false
var _tip_tween: Tween
var _nav_btns: Dictionary = {}
var _pending_howto: bool = false
var _pending_tutorial: bool = false
var _hud_chips: Dictionary = {} ## id -> Label
var _meeting_chrome_dimmed: bool = false
var _duty_collapsed: bool = false ## 默认展开，看得见内容
var _duty_dragging: bool = false
var _duty_resizing: bool = false
var _duty_drag_off: Vector2 = Vector2.ZERO
var _duty_resize_start: Vector2 = Vector2.ZERO
var _duty_size_start: Vector2 = Vector2.ZERO
var _duty_layout_ready: bool = false
var _duty_expanded_size: Vector2 = Vector2(240, 280)
var _duty_pos: Vector2 = Vector2(1020, 100)


func _ready() -> void:
	_apply_kairo_chrome()
	add_to_group("play_chrome")
	DomainBus.tip.connect(_on_tip)
	DomainBus.slot_changed.connect(_on_slot)
	DomainBus.stat_changed.connect(func(_a, _b, _c): _refresh_hud(); _refresh_choices())
	DomainBus.flag_changed.connect(func(_f, _v): _refresh_choices())
	DomainBus.rank_changed.connect(func(_o, _n): _refresh_hud(); _refresh_loc_nav(); _refresh_choices())
	DomainBus.grudge_changed.connect(func(_g, _s): _refresh_hud())
	DomainBus.domain_event.connect(_on_domain)
	DialogueRunner.node_presented.connect(_on_node_presented)
	DialogueRunner.choice_presented.connect(_on_choices)
	DialogueRunner.dialog_finished.connect(_on_dialog_finished)
	stage.hotspot_pressed.connect(_on_hotspot)
	stage.actor_clicked.connect(_on_actor_chat)
	stage.actor_inspected.connect(_on_actor_dossier)
	act_sheet.action_picked.connect(_on_action_picked)
	act_sheet.closed.connect(func(): pass)
	dialogue.continue_pressed.connect(_on_dialogue_continue)
	dialogue.choice_selected.connect(func(c): DialogueRunner.select_choice(c))
	dialogue.speaker_clicked.connect(_on_actor_dossier)
	%BtnRest.pressed.connect(_on_rest)
	%BtnSettings.pressed.connect(_open_settings)
	%BtnHelpClose.pressed.connect(_hide_help)
	settings.return_to_title_requested.connect(_on_return_title)
	settings.quit_requested.connect(func(): get_tree().quit())
	settings.load_done.connect(func(_s): boot_from_load())
	settings.help_requested.connect(_show_help)
	settings.tutorial_requested.connect(_restart_tutorial)
	DomainBus.stat_changed.connect(_on_stat_fx)
	_build_hud_chips()
	_build_loc_nav()
	_bind_duty_rail()
	call_deferred("_bind_tutorial")
	call_deferred("_bind_meeting_stage")


func boot_new_game() -> void:
	RunState.new_game()
	_duty_layout_ready = false
	TickPipeline.on_slot_enter()
	_set_interactive(true)
	_refresh_all()
	_on_tip(L10n.t("ui.new_game", "新的一局"))
	_pending_howto = false
	_pending_tutorial = not RunState.get_flag("flag_tutorial_done", false)
	_try_start_queued_event()
	if _pending_tutorial and not DialogueRunner.is_active() and RunState.queue.is_empty():
		_pending_tutorial = false
		_start_tutorial()
	elif _pending_tutorial:
		_on_tip(L10n.t("ui.tutorial_pending_tip", "开场对白后将出现操作引导（可跳过）"))


func _bind_tutorial() -> void:
	if tutorial == null:
		return
	tutorial.bind_host(self, {
		"hud": hud_stats,
		"goal": goal_label,
		"stage": stage,
		"loc": get_node_or_null("LocNavPanel"),
		"rest": %BtnRest,
		"settings": %BtnSettings,
	})
	if not tutorial.finished.is_connected(_on_tutorial_finished):
		tutorial.finished.connect(_on_tutorial_finished)


func _bind_meeting_stage() -> void:
	var ms := get_tree().get_first_node_in_group("meeting_stage")
	if ms == null:
		return
	if ms.has_signal("stage_opened") and not ms.stage_opened.is_connected(_on_meeting_stage_opened):
		ms.stage_opened.connect(_on_meeting_stage_opened)
	if ms.has_signal("stage_closed") and not ms.stage_closed.is_connected(_on_meeting_stage_closed):
		ms.stage_closed.connect(_on_meeting_stage_closed)


func _on_meeting_stage_opened() -> void:
	_set_meeting_chrome(true)


func _on_meeting_stage_closed() -> void:
	_set_meeting_chrome(false)


func _set_meeting_chrome(dim: bool) -> void:
	## 朝账中收起日常干扰：地点导航、歇息、目标条弱化；保留对白与会议芯片。
	_meeting_chrome_dimmed = dim
	var loc_panel: Control = get_node_or_null("LocNavPanel") as Control
	if loc_panel:
		loc_panel.visible = not dim
	%BtnRest.visible = not dim
	var goal_bar: Control = get_node_or_null("GoalBar") as Control
	if goal_bar:
		goal_bar.modulate.a = 0.7 if dim else 1.0
	## HUD：只强调 meeting / ladder，其余略淡但不糊
	for id in _hud_chips.keys():
		var lb: Label = _hud_chips[id] as Label
		if lb == null:
			continue
		if dim and id not in ["meeting", "ladder"]:
			lb.modulate.a = 0.65
		else:
			lb.modulate.a = 1.0
	act_sheet.visible = false
	if dim:
		stage.set_walk_frozen(true)
	else:
		stage.set_walk_frozen(DialogueRunner.is_active())
	_refresh_duty_rail()


func _start_tutorial() -> void:
	if help_layer.visible:
		_hide_help()
	if settings.visible:
		settings.close_settings()
	if ledger.visible:
		ledger.hide_ledger()
	act_sheet.visible = false
	## 引导强制可点场景；全程冻住踱步
	stage.set_interactive(true)
	stage.set_walk_frozen(true)
	tutorial.start_guide()


func _restart_tutorial() -> void:
	settings.close_settings()
	RunState.set_flag("flag_tutorial_done", false)
	_pending_tutorial = false
	_start_tutorial()


func _on_tutorial_finished() -> void:
	_pending_tutorial = false
	stage.set_tutorial_pulse("")
	stage.set_walk_frozen(false)
	act_sheet.visible = false
	act_sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_interactive(not RunState.ended and not DialogueRunner.is_active())
	_on_tip(L10n.t("ui.tutorial_done_tip", "引导结束。Esc 可开设置，随时可重开引导。"))


func tutorial_prepare_step(_step_id: String, awaiting: String) -> void:
	## 引导切步：必须收起纸片，否则高亮洞里只看见「收起」挡板。
	_force_hide_act_sheet()
	if dialogue.visible and not DialogueRunner.is_active():
		dialogue.visible = false
	stage.set_interactive(true)
	stage.set_walk_frozen(true)
	if awaiting.is_empty():
		stage.set_tutorial_pulse("")


func _force_hide_act_sheet() -> void:
	act_sheet.visible = false
	act_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE


func boot_from_load() -> void:
	act_sheet.visible = false
	dialogue.visible = false
	_awaiting_continue = false
	_duty_layout_ready = false
	_set_interactive(not RunState.ended and not DialogueRunner.is_active())
	_refresh_all()
	_try_start_queued_event()


func _apply_kairo_chrome() -> void:
	for panel_path in ["TopBar", "GoalBar", "LocNavPanel"]:
		var p: PanelContainer = get_node_or_null(panel_path) as PanelContainer
		if p:
			KairoStyle.style_panel(p)
	day_label.add_theme_color_override("font_color", KairoStyle.INK)
	day_label.add_theme_font_size_override("font_size", 15)
	goal_label.add_theme_color_override("font_color", KairoStyle.INK)
	goal_label.add_theme_font_size_override("font_size", 16)
	tip_label.add_theme_color_override("font_color", KairoStyle.INK)
	tip_label.add_theme_font_size_override("font_size", 16)
	if tip_banner:
		var tip_sb := StyleBoxFlat.new()
		tip_sb.bg_color = Color(1.0, 0.95, 0.84, 0.97)
		tip_sb.border_color = Color(0.55, 0.34, 0.16, 1)
		tip_sb.set_border_width_all(2)
		tip_sb.set_corner_radius_all(10)
		tip_sb.content_margin_left = 14
		tip_sb.content_margin_right = 14
		tip_sb.content_margin_top = 6
		tip_sb.content_margin_bottom = 6
		tip_sb.shadow_color = Color(0.12, 0.06, 0.04, 0.35)
		tip_sb.shadow_size = 6
		tip_sb.shadow_offset = Vector2(0, 2)
		tip_banner.add_theme_stylebox_override("panel", tip_sb)
		tip_banner.visible = false
	var brand: Label = get_node_or_null("TopBar/Margin/HBox/Brand") as Label
	if brand:
		brand.text = "暗潮 · 钱记"
		brand.add_theme_color_override("font_color", KairoStyle.WOOD_DARK)
	if duty_title:
		KairoStyle.style_readable_label(duty_title, 16)
	if duty_body:
		KairoStyle.style_readable_rich(duty_body, 15, 17)
	for btn in [%BtnRest, %BtnSettings, %BtnHelpClose]:
		KairoStyle.style_button(btn)
	%BtnRest.text = L10n.t("ui.rest", "歇一口气")
	%BtnSettings.text = L10n.t("ui.settings", "设置") + "(Esc)"
	_style_help_panel()


func _open_settings() -> void:
	if help_layer.visible:
		_hide_help()
	settings.open_settings(true)


func _on_return_title() -> void:
	settings.close_settings()
	if tutorial != null and tutorial.visible:
		tutorial.stop_guide(false)
	DialogueRunner.force_abort()
	act_sheet.visible = false
	dialogue.visible = false
	ledger.hide_ledger()
	if ladder_board:
		ladder_board.hide_board()
	var ms := get_tree().get_first_node_in_group("meeting_stage")
	if ms and ms.has_method("force_hide"):
		ms.force_hide()
	return_to_title.emit()


func _input(event: InputEvent) -> void:
	## 差事条拖动/缩放：全局跟踪，离开标题栏也不丢
	if not visible or duty_rail == null or not duty_rail.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _duty_dragging or _duty_resizing:
			if _duty_resizing and not _duty_collapsed:
				_duty_expanded_size = duty_rail.size
			_duty_pos = duty_rail.position
			_duty_dragging = false
			_duty_resizing = false
			_clamp_duty_rail()
			_persist_duty_layout()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		if _duty_dragging:
			duty_rail.global_position = duty_rail.get_global_mouse_position() - _duty_drag_off
			_duty_pos = duty_rail.position
			_clamp_duty_rail()
			get_viewport().set_input_as_handled()
		elif _duty_resizing and not _duty_collapsed:
			var delta: Vector2 = duty_rail.get_global_mouse_position() - _duty_resize_start
			duty_rail.size = Vector2(
				clampf(_duty_size_start.x + delta.x, 200.0, 480.0),
				clampf(_duty_size_start.y + delta.y, 160.0, 560.0)
			)
			_duty_expanded_size = duty_rail.size
			_clamp_duty_rail()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if tutorial != null and tutorial.visible:
		return
	if settings.visible:
		return
	if ladder_board != null and ladder_board.visible:
		if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
			ladder_board.hide_board()
			get_viewport().set_input_as_handled()
		return
	if ledger.visible:
		if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_J or event.keycode == KEY_C or event.keycode == KEY_ESCAPE):
			ledger.hide_ledger()
			get_viewport().set_input_as_handled()
		return
	if help_layer.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE):
			_hide_help()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_open_settings()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_H:
			_toggle_help()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_L:
			if ladder_board:
				ladder_board.toggle()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_J:
			ledger.toggle()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_C:
			ledger.open_self()
			get_viewport().set_input_as_handled()
			return
	if not _awaiting_continue:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo \
		and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		_awaiting_continue = false
		DialogueRunner.continue_linear()
		get_viewport().set_input_as_handled()


func _on_domain(event_name: String, payload: Dictionary) -> void:
	match event_name:
		"promotion_ceremony", "demotion_applied":
			_refresh_hud()
			_refresh_loc_nav()
			if event_name == "promotion_ceremony" and dialogue:
				## 仪典期间压住底部对白，避免双「继续」
				dialogue.visible = false
		"ceremony_finished":
			_refresh_hud()
			_refresh_duty_rail()
		"grudge_resolved":
			_refresh_hud()
		"ladder_rank_changed", "meeting_changed", "meeting_tasks_changed", "meeting_report_finalized":
			_refresh_hud()
			_refresh_duty_rail()
			if event_name == "ladder_rank_changed":
				var delta := int(payload.get("last_delta", 0))
				if delta > 0:
					_on_tip(L10n.t("ui.ladder_up", "序位上升"))
				elif delta < 0:
					_on_tip(L10n.t("ui.ladder_down", "序位下滑"))
		"run_over":
			_on_tip(L10n.t("ui.run_ended", "本局结束：%s") % String(payload.get("reason", "")))
			_set_interactive(false)
			_refresh_all()
		"ending_reached":
			_refresh_hud()
			_refresh_goal()
		"failure_queued", "random_queued":
			_refresh_all()
			_try_start_queued_event()
		"event_finished":
			_refresh_hud()
			_refresh_goal()


func _on_new() -> void:
	boot_new_game()


func _toggle_help() -> void:
	if help_layer.visible:
		_hide_help()
	else:
		_show_help()


func _show_help() -> void:
	help_title.text = L10n.t("ui.help_title", "暗潮 · 试玩说明")
	help_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body := L10n.t("ui.help_body", "点地点 → 点热区 → 选行动。J 打开账簿。H 说明。")
	## 兼容旧档把 \\n 写成字面量的情况
	body = body.replace("\\n", "\n")
	help_body.text = body
	%BtnHelpClose.text = L10n.t("ui.help_close", "合上")
	_style_help_panel()
	help_layer.visible = true
	RunState.set_flag("flag_howto_seen", true)
	_pending_howto = false


func _style_help_panel() -> void:
	var panel: PanelContainer = help_layer.get_node_or_null("HelpPanel") as PanelContainer
	if panel:
		KairoStyle.style_panel(panel)
	## 奶油底必须配深墨字，否则看不清
	help_title.add_theme_color_override("font_color", KairoStyle.INK)
	help_title.add_theme_font_size_override("font_size", 24)
	help_body.add_theme_color_override("default_color", KairoStyle.INK)
	help_body.add_theme_color_override("font_selected_color", KairoStyle.INK)
	help_body.add_theme_font_size_override("normal_font_size", 16)
	help_body.add_theme_font_size_override("bold_font_size", 17)
	help_body.add_theme_constant_override("line_separation", 4)
	KairoStyle.style_button(%BtnHelpClose, true)


func _hide_help() -> void:
	help_layer.visible = false


func _on_rest() -> void:
	if DialogueRunner.is_active():
		_on_tip(L10n.t("ui.dialog_busy", "对话进行中"))
		return
	if RunState.ended:
		_on_tip(L10n.t("ui.run_ended", "本局结束：%s") % RunState.end_reason)
		return
	if not RunState.queue.is_empty():
		_try_start_queued_event()
		return
	act_sheet.visible = false
	TickPipeline.advance_after_idle()
	_refresh_all()
	_try_start_queued_event()


func _build_loc_nav() -> void:
	for c in loc_nav.get_children():
		c.queue_free()
	_nav_btns.clear()
	for row in PackDB.get_rows("def_location"):
		var lid := String(row.get("loc_id", ""))
		var btn := Button.new()
		btn.text = L10n.t(String(row.get("loc_key", "")), lid)
		btn.focus_mode = Control.FOCUS_NONE
		KairoStyle.style_button(btn)
		btn.pressed.connect(_select_loc.bind(lid))
		loc_nav.add_child(btn)
		_nav_btns[lid] = btn


func _select_loc(lid: String) -> void:
	if DialogueRunner.is_active():
		return
	if RunState.ended:
		return
	_selected_loc = lid
	RunState.set_current_loc(lid)
	act_sheet.visible = false
	stage.set_location(lid)
	_refresh_loc_nav()
	_refresh_goal()
	_on_tip(L10n.t(String(PackDB.get_row_by_id("def_location", "loc_id", lid).get("blurb_key", "")), ""))


func _on_hotspot(hotspot_id: String) -> void:
	if tutorial != null and tutorial.is_awaiting("hotspot"):
		## 引导步不真开纸片——开了会挡住下一步小人高亮
		_force_hide_act_sheet()
		_on_tip(L10n.t("tut.hotspot_ok", "对，热区点开后会出行动纸片。"))
		tutorial.notify_player_action("hotspot")
		return
	if DialogueRunner.is_active() or RunState.ended:
		return
	if tutorial != null and tutorial.is_running():
		## 引导其它步期间也不弹纸片抢焦点
		return
	if not RunState.queue.is_empty():
		_try_start_queued_event()
		return
	act_sheet.open_for(_selected_loc, hotspot_id)
	act_sheet.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_actor_chat(char_id: String) -> void:
	if tutorial != null and tutorial.is_awaiting("npc_left"):
		if char_id == "char_lin_ruisheng":
			_on_tip(L10n.t("tut.npc_not_self", "点别人——左键闲聊。"))
			return
		act_sheet.visible = false
		_on_tip(L10n.t("tut.npc_ok", "左键闲聊；右键才是档案。"))
		tutorial.notify_player_action("npc_left")
		return
	## 左键小人：闲聊（不推进时段）。
	if DialogueRunner.is_active() or RunState.ended:
		return
	act_sheet.visible = false
	var name := L10n.t(char_id, char_id)
	if ChatterSystem.try_start(char_id):
		_on_tip(L10n.t("ui.chatter_start", "与%s闲谈…") % name)
	else:
		pass


func _on_actor_dossier(char_id: String) -> void:
	## 右键小人 / 对话头像姓名：翻档案（对话中也可）。
	act_sheet.visible = false
	ledger.open_char(char_id)
	var name := L10n.t(char_id, char_id)
	_on_tip(L10n.t("ui.opened_dossier", "翻开档案：%s") % name)


func _on_stat_fx(stat_id: String, old_v: Variant, new_v: Variant) -> void:
	if old_v == null:
		return
	if stat_id == "stat_money":
		var delta := int(round(float(new_v) - float(old_v)))
		if delta > 0:
			stage.spawn_pop("coin", delta)
	elif stat_id == "stat_trust_firm" or stat_id == "stat_intel":
		if float(new_v) > float(old_v):
			stage.spawn_pop("heart", 0)


func _on_action_picked(act_id: String) -> void:
	if DialogueRunner.is_active() or RunState.ended:
		return
	if not RunState.queue.is_empty():
		act_sheet.visible = false
		_try_start_queued_event()
		return
	var ok := TickPipeline.try_player_action(act_id)
	if not ok:
		## 条件刚失效：就地刷掉不可用项
		act_sheet.refresh_if_open()
		return
	stage.spawn_pop("star", 0)
	if DialogueRunner.is_active():
		act_sheet.visible = false
		return
	_refresh_all()
	_try_start_queued_event()
	## 仍可自由行动时，纸片留着并立刻刷新列表（不必再点一遍热区）
	if not DialogueRunner.is_active() and RunState.queue.is_empty() and not RunState.ended:
		act_sheet.refresh_if_open()
	else:
		act_sheet.visible = false


func _refresh_choices() -> void:
	if DialogueRunner.is_active() or RunState.ended:
		return
	_refresh_loc_nav()
	act_sheet.refresh_if_open()


func _try_start_queued_event() -> void:
	if DialogueRunner.is_active():
		return
	if RunState.queue.is_empty():
		return
	TickPipeline.begin_queued_event()


func _refresh_all() -> void:
	_selected_loc = RunState.current_loc()
	stage.set_location(_selected_loc)
	_on_slot(RunState.day(), RunState.slot())
	_refresh_hud()
	_refresh_loc_nav()
	_refresh_goal()
	if DialogueRunner.is_active():
		return
	_awaiting_continue = false
	if not RunState.queue.is_empty():
		dialogue.show_pending_event(String(RunState.queue[0]))
		_set_interactive(false)
	else:
		dialogue.visible = false
		_set_interactive(not RunState.ended)


func _build_hud_chips() -> void:
	for c in hud_stats.get_children():
		c.queue_free()
	_hud_chips.clear()
	var ids: PackedStringArray = ["money", "rank", "ladder", "meeting", "heat", "sus"]
	for i in range(ids.size()):
		if i > 0:
			var sep := Label.new()
			sep.text = "·"
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sep.add_theme_color_override("font_color", KairoStyle.WOOD_DARK)
			sep.add_theme_font_size_override("font_size", 15)
			hud_stats.add_child(sep)
		var id := String(ids[i])
		var lb := Label.new()
		lb.mouse_filter = Control.MOUSE_FILTER_STOP
		lb.mouse_default_cursor_shape = Control.CURSOR_HELP
		lb.add_theme_color_override("font_color", KairoStyle.INK)
		lb.add_theme_font_size_override("font_size", 15)
		lb.mouse_entered.connect(_on_hud_chip_hover.bind(id, true))
		lb.mouse_exited.connect(_on_hud_chip_hover.bind(id, false))
		if id == "ladder":
			lb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			lb.gui_input.connect(_on_ladder_chip_input)
		hud_stats.add_child(lb)
		_hud_chips[id] = lb


func _on_ladder_chip_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ladder_board:
			ladder_board.toggle()
		get_viewport().set_input_as_handled()


func _on_hud_chip_hover(id: String, on: bool) -> void:
	var lb: Label = _hud_chips.get(id) as Label
	if lb == null:
		return
	lb.add_theme_color_override("font_color", KairoStyle.ACCENT_INK if on else KairoStyle.INK)


func _refresh_hud() -> void:
	if _hud_chips.is_empty():
		return
	var money := RunState.get_stat("stat_money")
	var rank_id := RunState.player_rank()
	var address := String(RunState.meta.get("rank_address", ""))
	if address.is_empty():
		address = PromotionSystem.address_for(rank_id)
	var monthly := int(RunState.meta.get("monthly_stipend", PromotionSystem.monthly_for(rank_id)))
	var heat := float(RunState.get_org_field("org_qianji", "firm_heat", 0))
	var liq := float(RunState.get_org_field("org_qianji", "liquidity", 0))
	var sus := RunState.get_stat("stat_suspicion")
	var trust := RunState.get_stat("stat_trust_firm")
	var credit := RunState.get_stat("stat_credit_bank")
	var intel := RunState.get_stat("stat_intel")

	_set_chip("money", "%s %s两" % [L10n.t("stat.money"), _fmt_num(money)], _tip_money(money, monthly, credit))
	_set_chip("rank", "%s【%s】" % [L10n.t("ui.rank", "职级"), address], _tip_rank(rank_id, address, monthly))
	var ladder_txt := MeetingSystem.hud_ladder_text()
	if ladder_txt.is_empty():
		ladder_txt = L10n.t("ui.ladder_pending", "序位 —")
	_set_chip("ladder", ladder_txt, _tip_ladder())
	_set_chip("meeting", MeetingSystem.hud_meeting_text(), _tip_meeting())
	_set_chip("heat", "%s %s" % [L10n.t("ui.org_heat", "热度"), _fmt_num(heat)], _tip_heat(heat, liq))
	_set_chip("sus", "%s %s" % [L10n.t("stat.suspicion"), _fmt_num(sus)], _tip_sus(sus, trust, intel))
	if RunState.ended:
		day_label.tooltip_text = L10n.t("ui.run_ended", "本局结束：%s") % RunState.end_reason
	_refresh_duty_rail()


func _refresh_duty_rail() -> void:
	if duty_rail == null or duty_body == null:
		return
	if _meeting_chrome_dimmed or RunState.ended:
		duty_rail.visible = false
		return
	if not MeetingSystem.should_show_duty_rail():
		duty_rail.visible = false
		return
	if not _duty_layout_ready:
		_restore_duty_layout()
	duty_body.text = MeetingSystem.duty_rail_bbcode()
	duty_rail.visible = true
	_apply_duty_chrome()
	## 刷新只改文案，不重置尺寸（避免拖动/缩放被顶掉）
	_sync_duty_collapse_widgets()
	_update_duty_title()


func _bind_duty_rail() -> void:
	if duty_rail == null:
		return
	duty_rail.mouse_filter = Control.MOUSE_FILTER_STOP
	if duty_header:
		## 标题条整条可拖（按钮自己拦点击）
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color(0.92, 0.82, 0.62, 0.95)
		hsb.border_color = Color(0.62, 0.42, 0.22, 0.9)
		hsb.set_border_width_all(2)
		hsb.set_corner_radius_all(8)
		hsb.content_margin_left = 8
		hsb.content_margin_right = 6
		hsb.content_margin_top = 4
		hsb.content_margin_bottom = 4
		duty_header.add_theme_stylebox_override("panel", hsb)
		duty_header.mouse_filter = Control.MOUSE_FILTER_STOP
		duty_header.mouse_default_cursor_shape = Control.CURSOR_MOVE
		if not duty_header.gui_input.is_connected(_on_duty_header_input):
			duty_header.gui_input.connect(_on_duty_header_input)
	if duty_title:
		duty_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		duty_title.tooltip_text = L10n.t("ui.duty_drag_hint", "按住此处拖动窗口")
	if duty_btn_collapse and not duty_btn_collapse.pressed.is_connected(_toggle_duty_collapse):
		duty_btn_collapse.pressed.connect(_toggle_duty_collapse)
		KairoStyle.style_button(duty_btn_collapse)
	if duty_btn_ladder and not duty_btn_ladder.pressed.is_connected(_open_duty_ladder):
		duty_btn_ladder.pressed.connect(_open_duty_ladder)
		KairoStyle.style_button(duty_btn_ladder)
	if duty_resize:
		duty_resize.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		if not duty_resize.button_down.is_connected(_on_duty_resize_down):
			duty_resize.button_down.connect(_on_duty_resize_down)
		KairoStyle.style_button(duty_resize)
	if not duty_rail.gui_input.is_connected(_on_duty_rail_collapsed_click):
		duty_rail.gui_input.connect(_on_duty_rail_collapsed_click)


func _apply_duty_chrome() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.96, 0.88, 0.97)
	sb.border_color = Color(0.55, 0.36, 0.18, 1)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.12, 0.06, 0.04, 0.35)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	var days := int(RunState.meeting.get("days_until_next", 0))
	if days <= 2:
		sb.border_color = Color(0.78, 0.28, 0.2)
		sb.bg_color = Color(1.0, 0.94, 0.88, 0.97)
	duty_rail.add_theme_stylebox_override("panel", sb)


func _update_duty_title() -> void:
	if duty_title == null:
		return
	MeetingSystem.ensure_state()
	if _duty_collapsed:
		var head := MeetingSystem.hud_meeting_text()
		var rank := int(RunState.ladder.get("player_rank", 0))
		var total := int(RunState.ladder.get("player_total", 0))
		if total > 0 and rank > 0:
			duty_title.text = "%s · %d/%d" % [head, rank, total]
		else:
			duty_title.text = head
	else:
		duty_title.text = L10n.t("ui.duty_rail_title", "差事 · 序位")
	duty_rail.tooltip_text = L10n.t(
		"ui.duty_rail_tip",
		"拖标题栏移动 · 右下角◢改大小 · 「序」开榜 · 「收起/展开」"
	)


func _sync_duty_collapse_widgets() -> void:
	## 只切换显隐与按钮字，不改 size（刷新时调用）
	if duty_scroll:
		duty_scroll.visible = not _duty_collapsed
	if duty_body:
		duty_body.visible = not _duty_collapsed
	if duty_resize:
		duty_resize.visible = not _duty_collapsed
	if duty_btn_collapse:
		duty_btn_collapse.text = L10n.t("ui.duty_expand", "展开") if _duty_collapsed else L10n.t("ui.duty_collapse", "收起")
	var margin := duty_rail.get_node_or_null("DutyMargin") as MarginContainer
	if margin:
		margin.add_theme_constant_override("margin_bottom", 4 if _duty_collapsed else 24)
		margin.add_theme_constant_override("margin_top", 4 if _duty_collapsed else 6)


func _apply_duty_layout_size() -> void:
	## 展开/收起时真正改尺寸
	_sync_duty_collapse_widgets()
	if _duty_collapsed:
		duty_rail.custom_minimum_size = Vector2(200, 40)
		duty_rail.size = Vector2(maxi(200, int(_duty_expanded_size.x)), 48)
	else:
		duty_rail.custom_minimum_size = Vector2(200, 160)
		duty_rail.size = _duty_expanded_size
	duty_rail.position = _duty_pos
	_clamp_duty_rail()
	_duty_pos = duty_rail.position


func _toggle_duty_collapse() -> void:
	if not _duty_collapsed:
		## 收起前记住展开尺寸
		_duty_expanded_size = duty_rail.size
		_duty_pos = duty_rail.position
	_duty_collapsed = not _duty_collapsed
	_apply_duty_layout_size()
	_update_duty_title()
	_persist_duty_layout()


func _open_duty_ladder() -> void:
	if ladder_board:
		ladder_board.show_board()


func _on_duty_header_input(event: InputEvent) -> void:
	if duty_rail == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		## 点在「序 / 收起」上不拖
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered is BaseButton and duty_header.is_ancestor_of(hovered):
			return
		_duty_dragging = true
		_duty_drag_off = duty_rail.get_global_mouse_position() - duty_rail.global_position
		get_viewport().set_input_as_handled()


func _on_duty_rail_collapsed_click(event: InputEvent) -> void:
	## 收起态点条身（非按钮）→ 展开
	if not _duty_collapsed or duty_rail == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered is BaseButton:
			return
		_duty_collapsed = false
		_apply_duty_layout_size()
		_update_duty_title()
		_persist_duty_layout()
		get_viewport().set_input_as_handled()


func _on_duty_resize_down() -> void:
	if _duty_collapsed or duty_rail == null:
		return
	_duty_resizing = true
	_duty_resize_start = duty_rail.get_global_mouse_position()
	_duty_size_start = duty_rail.size


func _clamp_duty_rail() -> void:
	if duty_rail == null:
		return
	var vp := get_viewport_rect().size
	var sz := duty_rail.size
	duty_rail.position = Vector2(
		clampf(duty_rail.position.x, 4.0, maxf(4.0, vp.x - sz.x - 4.0)),
		clampf(duty_rail.position.y, 88.0, maxf(88.0, vp.y - sz.y - 72.0))
	)


func _persist_duty_layout() -> void:
	if duty_rail == null:
		return
	if not _duty_collapsed:
		_duty_expanded_size = duty_rail.size
	_duty_pos = duty_rail.position
	RunState.meta["duty_rail_layout"] = {
		"x": _duty_pos.x,
		"y": _duty_pos.y,
		"w": _duty_expanded_size.x,
		"h": _duty_expanded_size.y,
		"collapsed": _duty_collapsed,
	}


func _restore_duty_layout() -> void:
	if duty_rail == null:
		return
	_duty_layout_ready = true
	var lay: Variant = RunState.meta.get("duty_rail_layout", {})
	var vp := get_viewport_rect().size
	if typeof(lay) == TYPE_DICTIONARY and not (lay as Dictionary).is_empty():
		var d: Dictionary = lay
		_duty_collapsed = bool(d.get("collapsed", false))
		_duty_pos = Vector2(float(d.get("x", vp.x - 260)), float(d.get("y", 100)))
		_duty_expanded_size = Vector2(
			clampf(float(d.get("w", 240)), 200.0, 480.0),
			clampf(float(d.get("h", 280)), 160.0, 560.0)
		)
	else:
		## 默认：右上角展开，不挡左上闲话
		_duty_collapsed = false
		_duty_expanded_size = Vector2(240, 280)
		_duty_pos = Vector2(maxi(10.0, vp.x - 260.0), 100.0)
	_apply_duty_layout_size()
	_update_duty_title()


func _tip_ladder() -> String:
	MeetingSystem.ensure_state()
	var pool := String(RunState.ladder.get("pool_id", ""))
	var rank := int(RunState.ladder.get("player_rank", 0))
	var total := int(RunState.ladder.get("player_total", 0))
	var lines: PackedStringArray = [
		L10n.t("hud.tip.ladder.title", "【序位】同池明面排名，朝账③段按序升降"),
		L10n.t("hud.tip.ladder.rank", "当前：%d / %d") % [rank, total],
	]
	if not pool.is_empty():
		lines.append(L10n.t("hud.tip.ladder.pool", "池：%s") % L10n.t("ladder.%s.name" % pool, pool))
	var entries: Array = RunState.ladder.get("entries", [])
	var sorted: Array = entries.duplicate()
	sorted.sort_custom(func(a, b): return float(a.get("score", 0)) > float(b.get("score", 0)))
	for i in range(mini(5, sorted.size())):
		var e: Dictionary = sorted[i]
		var cid := String(e.get("char_id", ""))
		var name := L10n.t(cid, cid)
		var mark := "★" if bool(e.get("is_player", false)) else " "
		lines.append("%s%d. %s  %.0f" % [mark, i + 1, name, float(e.get("score", 0))])
	return "\n".join(lines)


func _tip_meeting() -> String:
	MeetingSystem.ensure_state()
	var tier := String(RunState.meeting.get("attendance_tier", "listen"))
	var tier_label := L10n.t("meeting.tier.%s" % tier, tier)
	var days := int(RunState.meeting.get("days_until_next", 0))
	var score := int(RunState.meeting.get("report_score", 0))
	var lines: PackedStringArray = [
		L10n.t("hud.tip.meeting.title", "【朝账】每周晨会：汇报·赏罚·建言·摊派"),
		L10n.t("hud.tip.meeting.tier", "参与：%s") % tier_label,
		L10n.t("hud.tip.meeting.days", "距下次：%d 日") % days,
		L10n.t("hud.tip.meeting.score", "本周汇报分：%d") % score,
	]
	var tasks: Array = RunState.meeting.get("weekly_tasks", [])
	if tasks.is_empty():
		lines.append(L10n.t("hud.tip.meeting.no_tasks", "本周差事：无"))
	else:
		for t in tasks:
			if typeof(t) != TYPE_DICTIONARY:
				continue
			var label := L10n.t(String(t.get("label_key", "")), String(t.get("id", "")))
			lines.append("%s %d/%d" % [label, int(t.get("progress", 0)), int(t.get("target", 1))])
	return "\n".join(lines)


func _set_chip(id: String, text: String, tip: String) -> void:
	var lb: Label = _hud_chips.get(id) as Label
	if lb == null:
		return
	lb.text = text
	lb.tooltip_text = tip


func _tip_money(money: Variant, monthly: int, credit: Variant) -> String:
	var lines: PackedStringArray = [
		L10n.t("hud.tip.money.title", "【现银】身上能立刻拿出来的钱"),
		L10n.t("hud.tip.money.cash", "现银：%s两") % _fmt_num(money),
		L10n.t("hud.tip.money.monthly", "月例档：%d两（按职级发）") % monthly,
		L10n.t("hud.tip.money.credit", "票号信用：%s") % _fmt_num(credit),
	]
	var debt_id := FinanceService.find_active_debt("", "org_bank")
	if not debt_id.is_empty():
		var d: Dictionary = RunState.debts.get(debt_id, {})
		var rem := float(d.get("remaining", 0))
		var interest := float(d.get("interest_per_day", 0))
		var due_day := int(d.get("due_day", 0))
		var status := String(d.get("status", "active"))
		lines.append(L10n.t("hud.tip.money.debt", "票号债未清：%.0f两") % rem)
		if interest != 0.0:
			lines.append(L10n.t("hud.tip.money.interest", "日息：%.0f两/日（日末滚进本金）") % interest)
		if due_day > 0:
			var left := due_day - RunState.day()
			if status == "overdue" or left < 0:
				lines.append(L10n.t("hud.tip.money.overdue", "已逾期（原定第%d日）") % due_day)
			else:
				lines.append(L10n.t("hud.tip.money.due", "约期：第%d日（还剩%d日）") % [due_day, left])
	var soft := String(PackDB.get_row_by_id("def_char", "char_id", "char_lin_ruisheng").get("money_soft", ""))
	if not soft.is_empty():
		lines.append(L10n.t("hud.tip.money.soft", "软肋：%s") % soft)
	if float(money) <= 15.0:
		lines.append(L10n.t("hud.tip.money.low", "手头紧：婚事、体面都会逼人开口。"))
	return "\n".join(lines)


func _tip_rank(rank_id: String, rank: String, monthly: int) -> String:
	var seat_line := L10n.t("hud.tip.rank.seat", "站位：钱记门内 · 前堂后院都看着你")
	if bool(RunState.get_flag("flag_rank_jufeng_paojie", false)):
		seat_line = L10n.t("hud.tip.rank.seat_jufeng", "站位：聚丰柜前 · 钱记屋檐外的名字")
	elif bool(RunState.get_flag("flag_rank_foreign_agent", false)):
		seat_line = L10n.t("hud.tip.rank.seat_foreign", "站位：洋行往来 · 华界闲话里的靠山")
	var lines: PackedStringArray = [
		L10n.t("hud.tip.rank.title", "【职级】号里叫你什么、你能碰什么钱"),
		L10n.t("hud.tip.rank.now", "当前：%s") % rank,
		L10n.t("hud.tip.rank.ladder", "钱记阶：%s") % PromotionSystem.title_for(rank_id),
		L10n.t("hud.tip.rank.monthly", "月例档：%d两") % monthly,
		seat_line,
		"",
	]
	lines.append_array(PromotionSystem.next_gate_lines(rank_id))
	var flavor := _next_rank_hint(rank_id)
	if not flavor.is_empty():
		lines.append(flavor)
	return "\n".join(lines)


func _next_rank_hint(rank_id: String) -> String:
	match rank_id:
		"apprentice":
			return L10n.t("hud.tip.rank.next_waichang", "下一阶：外场——能更公开地跑街市、碰外线。")
		"waichang":
			return L10n.t("hud.tip.rank.next_paojie", "下一阶：跑街——外头认你名字，也更惹眼。")
		"paojie":
			return L10n.t("hud.tip.rank.next_houtang", "下一阶：后堂——账与门路更深，退路更窄。")
		_:
			return L10n.t("hud.tip.rank.next_top", "此阶已近号内高位，一步错便是满盘热。")


func _tip_heat(heat: float, liq: float) -> String:
	var band := _heat_band(heat)
	return "\n".join(PackedStringArray([
		L10n.t("hud.tip.heat.title", "【钱记热度】暗账与风声烫不烫"),
		L10n.t("hud.tip.heat.val", "热度：%s（%s）") % [_fmt_num(heat), band],
		L10n.t("hud.tip.heat.liq", "字号周转：%s") % _fmt_num(liq),
		L10n.t("hud.tip.heat.note", "越高：东家眼色越紧，官面与对家也越容易闻见味。"),
	]))


func _heat_band(heat: float) -> String:
	if heat < 20.0:
		return L10n.t("hud.band.heat.cool", "尚稳")
	if heat < 35.0:
		return L10n.t("hud.band.heat.warm", "渐烫")
	if heat < 50.0:
		return L10n.t("hud.band.heat.hot", "烫手")
	return L10n.t("hud.band.heat.danger", "危局")


func _tip_sus(sus: Variant, trust: Variant, intel: Variant) -> String:
	var band := _sus_band(float(sus))
	return "\n".join(PackedStringArray([
		L10n.t("hud.tip.sus.title", "【嫌疑】别人看你清不清白"),
		L10n.t("hud.tip.sus.val", "嫌疑：%s（%s）") % [_fmt_num(sus), band],
		L10n.t("hud.tip.sus.trust", "商行信任：%s") % _fmt_num(trust),
		L10n.t("hud.tip.sus.intel", "手头情报：%s") % _fmt_num(intel),
		L10n.t("hud.tip.sus.note", "嫌疑抬高：闲聊变短、行动变堵，清算时也更难翻身。"),
	]))


func _sus_band(sus: float) -> String:
	if sus < 15.0:
		return L10n.t("hud.band.sus.clean", "干净")
	if sus < 35.0:
		return L10n.t("hud.band.sus.watch", "惹眼")
	if sus < 55.0:
		return L10n.t("hud.band.sus.marked", "刺眼")
	return L10n.t("hud.band.sus.hot", "已红")


func _fmt_num(v: Variant) -> String:
	var f := float(v)
	if is_equal_approx(f, roundf(f)):
		return str(int(roundf(f)))
	return "%.1f" % f


func _refresh_loc_nav() -> void:
	for lid in _nav_btns.keys():
		var btn: Button = _nav_btns[lid]
		var open := _loc_open(String(lid))
		btn.disabled = not open or DialogueRunner.is_active() or RunState.ended
		btn.modulate = Color(1.15, 1.05, 0.85) if String(lid) == _selected_loc else Color(1, 1, 1)


func _loc_open(loc_id: String) -> bool:
	var row: Dictionary = PackDB.get_row_by_id("def_location", "loc_id", loc_id)
	if row.is_empty():
		return false
	var slots: Array = row.get("open_slots", [])
	return slots.has(RunState.slot())


func _refresh_goal() -> void:
	if RunState.ended:
		goal_label.text = L10n.t("ui.goal_ended", "本局已终 · %s") % RunState.end_reason
		return
	if not RunState.queue.is_empty():
		goal_label.text = L10n.t("ui.goal_event", "待办：处理事件 %s") % String(RunState.queue[0])
		return
	# next calendar linear hint
	var hint := ""
	for row in PackDB.get_rows("def_calendar"):
		if int(row.get("day", -1)) != RunState.day():
			continue
		var eid := String(row.get("event_id", ""))
		if eid.is_empty():
			continue
		if RunState.get_flag("seen_event_%s" % eid, false):
			continue
		var erow: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		hint = L10n.t(String(erow.get("loc_key", "")), eid)
		break
	if hint.is_empty():
		MeetingSystem.ensure_state()
		var days := int(RunState.meeting.get("days_until_next", 0))
		if days <= 2 and MeetingSystem.has_incomplete_weekly_tasks():
			goal_label.text = L10n.t("ui.goal_duty_urgent", "⚠ 距朝账 %d 日 · 差事未完") % maxi(days, 0)
		elif days <= 2:
			goal_label.text = L10n.t("ui.goal_meeting_soon", "⚠ 距朝账 %d 日 · 看序位") % maxi(days, 0)
		else:
			goal_label.text = L10n.t("ui.goal_explore", "点热区行事，或歇一口气推进时辰")
	else:
		goal_label.text = L10n.t("ui.goal_next", "今日暗流：%s") % hint


func _on_node_presented(node: Dictionary) -> void:
	act_sheet.visible = false
	_set_interactive(false)
	dialogue.present_node(node)
	_awaiting_continue = false
	var choices: Array = node.get("choices", node.get("options", []))
	var visible_choices: Array = []
	for ch in choices:
		if typeof(ch) == TYPE_DICTIONARY and ConditionEval.eval_all((ch as Dictionary).get("require", [])):
			visible_choices.append(ch)
	if visible_choices.is_empty():
		_awaiting_continue = true
		dialogue.show_continue_button()


func _on_choices(choices: Array) -> void:
	_awaiting_continue = false
	dialogue.show_choices(choices)


func _on_dialogue_continue() -> void:
	if not RunState.queue.is_empty() and not DialogueRunner.is_active():
		_try_start_queued_event()
		return
	_awaiting_continue = false
	DialogueRunner.continue_linear()


func _on_dialog_finished(_event_id: String) -> void:
	_awaiting_continue = false
	_set_meeting_chrome(false)
	_set_interactive(not RunState.ended)
	## 只刷 HUD / 目标，别整场重建（会重置小人位置）
	_refresh_hud()
	_refresh_loc_nav()
	_refresh_goal()
	_try_start_queued_event()
	if _pending_tutorial and not DialogueRunner.is_active():
		_pending_tutorial = false
		_start_tutorial()
	elif _pending_howto and not DialogueRunner.is_active():
		_pending_howto = false
		_show_help()
	elif not RunState.queue.is_empty() and not DialogueRunner.is_active():
		dialogue.show_pending_event(String(RunState.queue[0]))
		_set_interactive(false)
	elif not DialogueRunner.is_active():
		dialogue.visible = false


func _set_interactive(on: bool) -> void:
	stage.set_interactive(on)
	%BtnRest.disabled = (not on and not RunState.ended) or RunState.ended
	_refresh_loc_nav()


func _on_slot(day: int, slot: String) -> void:
	day_label.text = L10n.t("ui.day_slot", "第 %d 日 · %s") % [day, _slot_name(slot)]
	_refresh_loc_nav()
	_refresh_goal()
	_refresh_duty_rail()
	if act_sheet.visible and not _loc_open(_selected_loc):
		act_sheet.visible = false
	else:
		act_sheet.refresh_if_open()


func _slot_name(slot: String) -> String:
	match slot:
		"morning":
			return L10n.t("slot.morning", "清晨")
		"noon":
			return L10n.t("slot.noon", "正午")
		"afternoon":
			return L10n.t("slot.afternoon", "午后")
		"evening":
			return L10n.t("slot.evening", "傍晚")
		"late_night":
			return L10n.t("slot.late_night", "深夜")
		_:
			return slot


func _on_tip(text: String) -> void:
	if text.is_empty():
		return
	tip_label.text = text
	if tip_banner:
		tip_banner.visible = true
		tip_banner.modulate = Color(1, 1, 1, 1)
	tip_label.modulate = Color(1, 1, 1, 1)
	if _tip_tween != null:
		_tip_tween.kill()
	_tip_tween = create_tween()
	_tip_tween.tween_interval(2.8)
	var fade_target: CanvasItem = tip_banner if tip_banner else tip_label
	_tip_tween.tween_property(fade_target, "modulate:a", 0.0, 0.45)
	_tip_tween.tween_callback(func():
		if tip_banner:
			tip_banner.visible = false
			tip_banner.modulate = Color(1, 1, 1, 1)
		tip_label.text = ""
	)
