extends Control
## 地点枢纽：地点 / 行动 / 对话舞台。

@onready var day_label: Label = %DayLabel
@onready var tip_label: Label = %TipLabel
@onready var stats_label: Label = %StatsLabel
@onready var grudge_label: Label = %GrudgeLabel
@onready var loc_list: ItemList = %LocList
@onready var act_list: ItemList = %ActList
@onready var body_row: HBoxContainer = %Body
@onready var stage_panel: PanelContainer = %StagePanel
@onready var event_box: VBoxContainer = %EventBox
@onready var speaker_label: Label = %SpeakerLabel
@onready var stage_tag: Label = %StageTag
@onready var event_text: RichTextLabel = %EventText
@onready var choice_row: VBoxContainer = %ChoiceRow
@onready var help_layer: Control = %HelpLayer
@onready var help_title: Label = %HelpTitle
@onready var help_body: RichTextLabel = %HelpBody
@onready var portrait_plate: ColorRect = %PortraitPlate
@onready var portrait_tex: TextureRect = %PortraitTex
@onready var portrait_glyph: Label = %PortraitGlyph
@onready var stage_accent: ColorRect = %StageAccent

var _selected_loc: String = "loc_01"
var _act_ids: PackedStringArray = []
var _choice_cache: Array = []
var _awaiting_continue: bool = false
var _tip_tween: Tween
var _stage_tween: Tween

const SPEAKER_COLORS := {
	"narrator": Color(0.52, 0.48, 0.42),
	"char_qian_demao": Color(0.72, 0.42, 0.28),
	"char_qian_zian": Color(0.55, 0.35, 0.48),
	"char_liu_ruyan": Color(0.58, 0.42, 0.55),
	"char_lin_ruisheng": Color(0.42, 0.5, 0.58),
	"char_bradley": Color(0.35, 0.45, 0.62),
	"char_zhao_hongyun": Color(0.62, 0.48, 0.28),
	"char_wang_pangzi": Color(0.55, 0.4, 0.28),
	"char_zhou_guanshi": Color(0.48, 0.45, 0.38),
	"char_qing_daren": Color(0.45, 0.28, 0.32),
	"char_msg_broker": Color(0.5, 0.42, 0.32),
	"char_bank_clerk": Color(0.42, 0.48, 0.45),
	"char_firm_hand": Color(0.48, 0.4, 0.34),
}


func _ready() -> void:
	DomainBus.tip.connect(_on_tip)
	DomainBus.slot_changed.connect(_on_slot)
	DomainBus.stat_changed.connect(func(_a, _b, _c): _refresh_stats())
	DomainBus.grudge_changed.connect(func(_g, _s): _refresh_grudges())
	DomainBus.domain_event.connect(_on_domain)
	DialogueRunner.node_presented.connect(_on_node_presented)
	DialogueRunner.choice_presented.connect(_on_choices)
	DialogueRunner.dialog_finished.connect(_on_dialog_finished)
	%BtnNew.pressed.connect(_on_new)
	%BtnSave.pressed.connect(func(): SaveSystem.save_slot(0); _on_tip(L10n.t("ui.save_ok", "已保存")))
	%BtnLoad.pressed.connect(func(): SaveSystem.load_slot(0); _refresh_all(); _on_tip(L10n.t("ui.load_ok", "已读档")))
	%BtnRest.pressed.connect(_on_rest)
	%BtnHelp.pressed.connect(_toggle_help)
	%BtnHelpClose.pressed.connect(_hide_help)
	loc_list.item_selected.connect(_on_loc_selected)
	act_list.item_selected.connect(_on_act_selected)
	_build_loc_list()
	if not RunState.is_running():
		_on_new()
	else:
		_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if help_layer.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE):
			_hide_help()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		_toggle_help()
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
		"promotion_ceremony":
			var title := String(payload.get("title", ""))
			var monthly := int(payload.get("monthly", 0))
			_on_tip(L10n.t("promo.tip", "升任%s · 月例档 %d 两") % [title, monthly])
			_refresh_stats()
			_refresh_grudges()
			_refresh_actions()
		"demotion_applied":
			var title2 := String(payload.get("title", ""))
			var monthly2 := int(payload.get("monthly", 0))
			_on_tip(L10n.t("promo.demote_tip", "降为%s · 月例档 %d 两") % [title2, monthly2])
			_refresh_stats()
			_refresh_actions()
		"grudge_resolved":
			_refresh_grudges()
		"run_over":
			_on_tip(L10n.t("ui.run_ended", "本局结束：%s") % String(payload.get("reason", "")))
			_set_hub_interactive(false)
			_refresh_all()
		"ending_reached":
			_refresh_stats()
			_refresh_grudges()
		"failure_queued", "random_queued":
			_refresh_all()
			_try_start_queued_event()


func _on_new() -> void:
	if DialogueRunner.is_active():
		return
	RunState.new_game()
	TickPipeline.on_slot_enter()
	_set_hub_interactive(true)
	_refresh_all()
	_on_tip(L10n.t("ui.new_game", "新的一局"))
	_try_start_queued_event()
	if not RunState.get_flag("flag_howto_seen", false):
		_show_help()
		RunState.set_flag("flag_howto_seen", true)


func _toggle_help() -> void:
	if help_layer.visible:
		_hide_help()
	else:
		_show_help()


func _show_help() -> void:
	help_title.text = L10n.t("ui.help_title", "暗潮 · 试玩说明")
	help_body.text = L10n.t("ui.help_body", "选地点 → 点行动 → 处理事件。空格继续。H 打开说明。")
	%BtnHelpClose.text = L10n.t("ui.help_close", "合上（Esc）")
	help_layer.visible = true


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
	TickPipeline.advance_after_idle()
	_refresh_all()
	_try_start_queued_event()


func _build_loc_list() -> void:
	loc_list.clear()
	for row in PackDB.get_rows("def_location"):
		var lid := String(row.get("loc_id", ""))
		var name := L10n.t(String(row.get("loc_key", "")), lid)
		loc_list.add_item(name)
		loc_list.set_item_metadata(loc_list.item_count - 1, lid)
	if loc_list.item_count > 0:
		loc_list.select(0)
		_selected_loc = String(loc_list.get_item_metadata(0))


func _on_loc_selected(index: int) -> void:
	if DialogueRunner.is_active():
		return
	_selected_loc = String(loc_list.get_item_metadata(index))
	RunState.set_current_loc(_selected_loc)
	_refresh_actions()


func _on_act_selected(index: int) -> void:
	if index < 0 or index >= _act_ids.size():
		return
	if DialogueRunner.is_active():
		return
	if RunState.ended:
		return
	if not RunState.queue.is_empty():
		_try_start_queued_event()
		return
	var ok := TickPipeline.try_player_action(_act_ids[index])
	if ok and not DialogueRunner.is_active():
		_refresh_all()
		_try_start_queued_event()


func _try_start_queued_event() -> void:
	if DialogueRunner.is_active():
		return
	if RunState.queue.is_empty():
		return
	TickPipeline.begin_queued_event()


func _refresh_all() -> void:
	_on_slot(RunState.day(), RunState.slot())
	_refresh_stats()
	_refresh_grudges()
	_refresh_actions()
	if DialogueRunner.is_active():
		return
	_awaiting_continue = false
	if not RunState.queue.is_empty():
		_show_stage(true)
		speaker_label.text = L10n.t("ui.event_pending", "有事件待处理")
		stage_tag.text = String(RunState.queue[0])
		event_text.text = L10n.t("ui.event_pending_hint", "点击下方按钮，或选「处理事件」继续。")
		_clear_choices()
		var btn := Button.new()
		btn.text = L10n.t("ui.resolve_event", "处理事件")
		btn.pressed.connect(_try_start_queued_event)
		choice_row.add_child(btn)
	else:
		_show_stage(false)


func _refresh_stats() -> void:
	var parts: PackedStringArray = []
	parts.append("%s %s" % [L10n.t("stat.money"), str(RunState.get_stat("stat_money"))])
	parts.append("%s %s" % [L10n.t("stat.intel"), str(RunState.get_stat("stat_intel"))])
	parts.append("%s %s" % [L10n.t("stat.trust_firm"), str(RunState.get_stat("stat_trust_firm"))])
	parts.append("%s %s" % [L10n.t("stat.suspicion"), str(RunState.get_stat("stat_suspicion"))])
	parts.append("%s %s" % [L10n.t("stat.credit_bank"), str(RunState.get_stat("stat_credit_bank"))])
	var heat := float(RunState.get_org_field("org_qianji", "firm_heat", 0))
	var liq := float(RunState.get_org_field("org_qianji", "liquidity", 0))
	parts.append("%s %.0f" % [L10n.t("ui.org_heat", "钱记热度"), heat])
	parts.append("%s %.0f" % [L10n.t("ui.org_liquidity", "周转"), liq])
	parts.append("%s %s" % [L10n.t("ui.rank", "职级"), PromotionSystem.title_for(RunState.player_rank())])
	var monthly := int(RunState.meta.get("monthly_stipend", PromotionSystem.monthly_for(RunState.player_rank())))
	parts.append("%s %d" % [L10n.t("ui.monthly", "月例"), monthly])
	var debt_id := FinanceService.find_active_debt("", "org_bank")
	if not debt_id.is_empty():
		var d: Dictionary = RunState.debts[debt_id]
		var tag := L10n.t("ui.debt_overdue", "逾期") if String(d.get("status", "")) == "overdue" \
			else L10n.t("ui.debt_active", "票号债")
		parts.append("%s %.0f" % [tag, float(d.get("remaining", 0))])
	var route := ""
	if RunState.get_flag("route_endure", false):
		route = L10n.t("route.endure", "隐忍")
	elif RunState.get_flag("route_defect", false):
		route = L10n.t("route.defect", "跳槽")
	elif RunState.get_flag("route_foreign", false):
		route = L10n.t("route.foreign", "洋行")
	if not route.is_empty():
		parts.append("%s %s" % [L10n.t("ui.route", "路线"), route])
	if RunState.ended:
		parts.append(L10n.t("ui.ended_tag", "已终局"))
	stats_label.text = " · ".join(parts)


func _refresh_grudges() -> void:
	var open_bits: PackedStringArray = []
	for gid in RunState.grudges.keys():
		var g: Dictionary = RunState.grudges[gid]
		if String(g.get("status", "")) != "open":
			continue
		var def: Dictionary = PackDB.get_row_by_id("def_grudge", "grudge_id", String(gid))
		var name := L10n.t(String(def.get("loc_key", "")), String(gid))
		var by := String(g.get("buried_by", ""))
		if by.is_empty():
			open_bits.append(name)
		else:
			open_bits.append("%s(%s)" % [name, by])
	var demao := RunState.get_edge("char_qian_demao", "char_lin_ruisheng")
	var tier := ConditionEval.score_to_tier(float(demao.get("score", 0)))
	var edge_bit := "%s %s→你〔%s〕" % [
		L10n.t("ui.edge_title", "交情"),
		L10n.t("char_qian_demao", "钱德茂"),
		L10n.t("tier.%s" % tier, tier),
	]
	var debt_s := String(demao.get("debt", ""))
	var lev_s := String(demao.get("leverage", ""))
	if not debt_s.is_empty() and debt_s != "无":
		edge_bit += " ·债:%s" % debt_s
	if not lev_s.is_empty() and lev_s != "无":
		edge_bit += " ·柄:%s" % lev_s
	if open_bits.is_empty():
		grudge_label.text = "%s ｜ %s：%s" % [
			edge_bit,
			L10n.t("ui.grudge_title", "恩怨账"),
			L10n.t("ui.grudge_empty", "尚无埋债"),
		]
	else:
		grudge_label.text = "%s ｜ %s〔%s〕：%s" % [
			edge_bit,
			L10n.t("ui.grudge_title", "恩怨账"),
			L10n.t("ui.grudge_open", "未清算"),
			"、".join(open_bits),
		]


func _refresh_actions() -> void:
	act_list.clear()
	_act_ids.clear()
	for row in TickPipeline.available_actions():
		if String(row.get("loc_id", "")) != _selected_loc:
			continue
		var aid := String(row.get("act_id", ""))
		var name := L10n.t(String(row.get("loc_key", "")), aid)
		act_list.add_item(name)
		_act_ids.append(aid)


func _on_node_presented(node: Dictionary) -> void:
	_show_stage(true)
	_set_hub_interactive(false)
	var speaker_id := String(node.get("speaker", "narrator"))
	var body := L10n.t(String(node.get("loc_key", "")), String(node.get("dialog_id", "")))
	var tags: Array = node.get("tags", [])
	speaker_label.text = _speaker_name(speaker_id)
	_apply_speaker_style(speaker_id, tags)
	if tags.has("flashback"):
		stage_tag.text = L10n.t("ui.flashback", "【闪回】")
		event_text.text = "[i]%s[/i]" % body
	elif tags.has("failure"):
		stage_tag.text = L10n.t("ui.tag_failure", "风波")
		event_text.text = body
	elif tags.has("ending"):
		stage_tag.text = L10n.t("ui.tag_ending", "结局")
		event_text.text = body
	elif tags.has("random"):
		stage_tag.text = L10n.t("ui.tag_random", "街市风声")
		event_text.text = body
	elif speaker_id == "narrator":
		stage_tag.text = ""
		event_text.text = "[i]%s[/i]" % body
	else:
		stage_tag.text = ""
		event_text.text = body
	_clear_choices()
	_awaiting_continue = false
	var choices: Array = node.get("choices", node.get("options", []))
	var visible: Array = []
	for ch in choices:
		if typeof(ch) == TYPE_DICTIONARY and ConditionEval.eval_all((ch as Dictionary).get("require", [])):
			visible.append(ch)
	if visible.is_empty():
		_awaiting_continue = true
		var btn := Button.new()
		btn.text = L10n.t("ui.continue_hint", "继续（空格）")
		btn.pressed.connect(func():
			_awaiting_continue = false
			DialogueRunner.continue_linear()
		)
		choice_row.add_child(btn)
	_fade_stage_text()


func _on_choices(choices: Array) -> void:
	_choice_cache = choices
	_awaiting_continue = false
	_clear_choices()
	for ch in choices:
		if typeof(ch) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = ch
		var b := Button.new()
		var label_key := String(c.get("loc_key", ""))
		var cid := String(c.get("id", c.get("choice_id", "…")))
		b.text = "%s. %s" % [cid, L10n.t(label_key, cid)]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_select_choice.bind(c))
		choice_row.add_child(b)


func _select_choice(choice: Dictionary) -> void:
	DialogueRunner.select_choice(choice)


func _on_dialog_finished(_event_id: String) -> void:
	_awaiting_continue = false
	_set_hub_interactive(not RunState.ended)
	_refresh_all()
	_try_start_queued_event()


func _clear_choices() -> void:
	for c in choice_row.get_children():
		c.queue_free()


func _show_stage(on: bool) -> void:
	stage_panel.visible = on
	event_box.visible = on


func _set_hub_interactive(on: bool) -> void:
	body_row.modulate = Color(1, 1, 1, 1 if on else 0.45)
	loc_list.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	act_list.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	%BtnRest.disabled = not on and not RunState.ended
	if RunState.ended:
		%BtnRest.disabled = true


func _speaker_name(speaker_id: String) -> String:
	if speaker_id.is_empty() or speaker_id == "narrator":
		return L10n.t("char.narrator", "旁白")
	return L10n.t(speaker_id, speaker_id)


func _apply_speaker_style(speaker_id: String, tags: Array) -> void:
	var col: Color = SPEAKER_COLORS.get(speaker_id, Color(0.62, 0.55, 0.42))
	if tags.has("flashback"):
		col = Color(0.45, 0.42, 0.55)
	elif tags.has("failure"):
		col = Color(0.65, 0.28, 0.22)
	portrait_plate.color = col
	stage_accent.color = col
	if speaker_id == "narrator":
		speaker_label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	else:
		speaker_label.add_theme_color_override("font_color", col.lightened(0.35))
	_apply_portrait_face(speaker_id, col)


func _apply_portrait_face(speaker_id: String, col: Color) -> void:
	var path := "res://art/portraits/anchao/%s.png" % speaker_id
	if ResourceLoader.exists(path):
		portrait_tex.texture = load(path) as Texture2D
		portrait_tex.visible = true
		portrait_glyph.visible = false
	else:
		portrait_tex.texture = null
		portrait_tex.visible = false
		portrait_glyph.visible = true
		portrait_glyph.text = _speaker_glyph(speaker_id)
		portrait_glyph.add_theme_color_override("font_color", col.lightened(0.55))


func _speaker_glyph(speaker_id: String) -> String:
	var name := _speaker_name(speaker_id)
	if name.is_empty():
		return "·"
	return name.substr(0, 1)


func _fade_stage_text() -> void:
	event_text.modulate.a = 0.0
	portrait_plate.modulate.a = 0.55
	if _stage_tween != null:
		_stage_tween.kill()
	_stage_tween = create_tween()
	_stage_tween.set_parallel(true)
	_stage_tween.tween_property(event_text, "modulate:a", 1.0, 0.18)
	_stage_tween.tween_property(portrait_plate, "modulate:a", 1.0, 0.22)


func _on_slot(day: int, slot: String) -> void:
	day_label.text = L10n.t("ui.day_slot", "第 %d 日 · %s") % [day, _slot_name(slot)]


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
	tip_label.text = text
	tip_label.modulate = Color(1, 1, 1, 1)
	if _tip_tween != null:
		_tip_tween.kill()
	_tip_tween = create_tween()
	_tip_tween.tween_interval(2.8)
	_tip_tween.tween_property(tip_label, "modulate:a", 0.35, 0.6)
