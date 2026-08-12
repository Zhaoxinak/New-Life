extends Control
## 暗潮 2D 玩法壳：地点舞台 + 对白 + 薄 HUD + 行动纸片 + 账簿快捷键。

signal return_to_title

@onready var stage: Control = %LocationStage
@onready var dialogue: Control = %DialogueBox
@onready var act_sheet: PanelContainer = %ActSheet
@onready var ledger: CanvasLayer = %LedgerOverlay
@onready var settings: CanvasLayer = %SettingsOverlay
@onready var tutorial: CanvasLayer = %TutorialOverlay
@onready var help_layer: Control = %HelpLayer
@onready var help_title: Label = %HelpTitle
@onready var help_body: RichTextLabel = %HelpBody
@onready var day_label: Label = %DayLabel
@onready var hud_stats: HBoxContainer = %HudStats
@onready var tip_label: Label = %TipLabel
@onready var goal_label: Label = %GoalLabel
@onready var loc_nav: HBoxContainer = %LocNav

var _selected_loc: String = "loc_01"
var _awaiting_continue: bool = false
var _tip_tween: Tween
var _nav_btns: Dictionary = {}
var _pending_howto: bool = false
var _pending_tutorial: bool = false
var _hud_chips: Dictionary = {} ## id -> Label


func _ready() -> void:
	_apply_kairo_chrome()
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
	call_deferred("_bind_tutorial")


func boot_new_game() -> void:
	RunState.new_game()
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
	_set_interactive(not RunState.ended and not DialogueRunner.is_active())
	_refresh_all()
	_try_start_queued_event()


func _apply_kairo_chrome() -> void:
	for panel_path in ["TopBar", "GoalBar", "LocNavPanel"]:
		var p: PanelContainer = get_node_or_null(panel_path) as PanelContainer
		if p:
			KairoStyle.style_panel(p)
	day_label.add_theme_color_override("font_color", KairoStyle.INK)
	goal_label.add_theme_color_override("font_color", KairoStyle.WOOD_DARK)
	tip_label.add_theme_color_override("font_color", KairoStyle.ACCENT)
	var brand: Label = get_node_or_null("TopBar/Margin/HBox/Brand") as Label
	if brand:
		brand.text = "暗潮 · 钱记"
		brand.add_theme_color_override("font_color", KairoStyle.ACCENT)
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
	return_to_title.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if tutorial != null and tutorial.visible:
		return
	if settings.visible:
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
		"grudge_resolved":
			_refresh_hud()
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
	var ids: PackedStringArray = ["money", "rank", "heat", "sus"]
	for i in range(ids.size()):
		if i > 0:
			var sep := Label.new()
			sep.text = "·"
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sep.add_theme_color_override("font_color", Color(0.55, 0.45, 0.35, 0.7))
			hud_stats.add_child(sep)
		var id := String(ids[i])
		var lb := Label.new()
		lb.mouse_filter = Control.MOUSE_FILTER_STOP
		lb.mouse_default_cursor_shape = Control.CURSOR_HELP
		lb.add_theme_color_override("font_color", KairoStyle.SOFT_INK)
		lb.mouse_entered.connect(_on_hud_chip_hover.bind(id, true))
		lb.mouse_exited.connect(_on_hud_chip_hover.bind(id, false))
		hud_stats.add_child(lb)
		_hud_chips[id] = lb


func _on_hud_chip_hover(id: String, on: bool) -> void:
	var lb: Label = _hud_chips.get(id) as Label
	if lb == null:
		return
	lb.add_theme_color_override("font_color", KairoStyle.ACCENT if on else KairoStyle.SOFT_INK)


func _refresh_hud() -> void:
	if _hud_chips.is_empty():
		return
	var money := RunState.get_stat("stat_money")
	var rank_id := RunState.player_rank()
	var rank := PromotionSystem.title_for(rank_id)
	var monthly := int(RunState.meta.get("monthly_stipend", PromotionSystem.monthly_for(rank_id)))
	var heat := float(RunState.get_org_field("org_qianji", "firm_heat", 0))
	var liq := float(RunState.get_org_field("org_qianji", "liquidity", 0))
	var sus := RunState.get_stat("stat_suspicion")
	var trust := RunState.get_stat("stat_trust_firm")
	var credit := RunState.get_stat("stat_credit_bank")
	var intel := RunState.get_stat("stat_intel")

	_set_chip("money", "%s %s两" % [L10n.t("stat.money"), _fmt_num(money)], _tip_money(money, monthly, credit))
	_set_chip("rank", "%s【%s】" % [L10n.t("ui.rank", "职级"), rank], _tip_rank(rank_id, rank, monthly))
	_set_chip("heat", "%s %s" % [L10n.t("ui.org_heat", "热度"), _fmt_num(heat)], _tip_heat(heat, liq))
	_set_chip("sus", "%s %s" % [L10n.t("stat.suspicion"), _fmt_num(sus)], _tip_sus(sus, trust, intel))
	if RunState.ended:
		day_label.tooltip_text = L10n.t("ui.run_ended", "本局结束：%s") % RunState.end_reason


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
	var lines: PackedStringArray = [
		L10n.t("hud.tip.rank.title", "【职级】号里叫你什么、你能碰什么钱"),
		L10n.t("hud.tip.rank.now", "当前：%s") % rank,
		L10n.t("hud.tip.rank.monthly", "月例档：%d两") % monthly,
		L10n.t("hud.tip.rank.seat", "站位：钱记门内 · 前堂后院都看着你"),
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
	tip_label.modulate = Color(1, 1, 1, 1)
	if _tip_tween != null:
		_tip_tween.kill()
	_tip_tween = create_tween()
	_tip_tween.tween_interval(2.8)
	_tip_tween.tween_property(tip_label, "modulate:a", 0.35, 0.6)
