extends CanvasLayer
## F3 作弊台：时间 / 数值 / 职级朝账 / 事件 / 旗标。仅开发测试用。

const STAT_IDS: PackedStringArray = [
	"stat_money", "stat_trust_firm", "stat_suspicion", "stat_intel",
	"stat_credit_bank", "stat_credit_market", "stat_heat_self",
]

const RANK_IDS: PackedStringArray = ["apprentice", "waichang", "paojie", "houtang"]
const SLOT_IDS: PackedStringArray = ["morning", "noon", "afternoon", "evening", "late_night"]
const LOC_IDS: PackedStringArray = ["loc_01", "loc_02", "loc_03", "loc_04", "loc_05", "loc_06"]
const TIER_IDS: PackedStringArray = ["listen", "report", "decide"]

const FLAG_PRESETS: PackedStringArray = [
	"flag_tutorial_done",
	"flag_zian_arrived",
	"flag_meeting_report_eligible",
	"flag_rank_waichang_ceremony",
	"flag_grudge_window_light",
	"flag_route_defect",
	"flag_route_foreign",
	"flag_ending_a",
	"flag_ending_b",
	"flag_ending_c",
	"flag_ending_c_ready",
	"flag_bradley_invite",
	"flag_demoted",
]

var _root: Control
var _panel: PanelContainer
var _tabs: TabContainer
var _status: Label
var _stat_labels: Dictionary = {}
var _flag_edits: Dictionary = {}
var _day_spin: SpinBox
var _event_opt: OptionButton
var _dialog_edit: LineEdit
var _flag_edit: LineEdit
var _flag_val: LineEdit
var _money_spin: SpinBox


func _ready() -> void:
	layer = 90
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	if not DomainBus.domain_event.is_connected(_on_domain):
		DomainBus.domain_event.connect(_on_domain)
	if not DomainBus.stat_changed.is_connected(_on_stat):
		DomainBus.stat_changed.connect(_on_stat)
	if not DomainBus.rank_changed.is_connected(_on_rank):
		DomainBus.rank_changed.connect(_on_rank)
	if not DomainBus.slot_changed.is_connected(_on_slot):
		DomainBus.slot_changed.connect(_on_slot)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		hide_cheat()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		hide_cheat()
	else:
		show_cheat()


func show_cheat() -> void:
	visible = true
	_refresh_all()
	_log("作弊台已开（F3 / Esc 关闭）")


func hide_cheat() -> void:
	visible = false


func _on_domain(_n: String, _p: Dictionary) -> void:
	if visible:
		_refresh_status()


func _on_stat(_a, _b, _c) -> void:
	if visible:
		_refresh_stats()
		_refresh_status()


func _on_rank(_o, _n) -> void:
	if visible:
		_refresh_status()


func _on_slot(_d, _s) -> void:
	if visible:
		_refresh_status()
		if _day_spin:
			_day_spin.value = RunState.day()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.03, 0.02, 0.55)
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			hide_cheat()
	)
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -460
	_panel.offset_top = -300
	_panel.offset_right = 460
	_panel.offset_bottom = 300
	_root.add_child(_panel)
	KairoStyle.style_panel(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := Label.new()
	title.text = "作弊台 · F3"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", KairoStyle.INK)
	head.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	KairoStyle.style_button(close_btn)
	close_btn.pressed.connect(hide_cheat)
	head.add_child(close_btn)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", KairoStyle.INK)
	_status.add_theme_font_size_override("font_size", 15)
	v.add_child(_status)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.custom_minimum_size = Vector2(0, 420)
	v.add_child(_tabs)

	_tabs.add_child(_build_tab_presets())
	_tabs.add_child(_build_tab_time())
	_tabs.add_child(_build_tab_stats())
	_tabs.add_child(_build_tab_rank_meeting())
	_tabs.add_child(_build_tab_events())
	_tabs.add_child(_build_tab_flags())
	_tabs.set_tab_title(0, "快捷")
	_tabs.set_tab_title(1, "时间")
	_tabs.set_tab_title(2, "数值")
	_tabs.set_tab_title(3, "职级朝账")
	_tabs.set_tab_title(4, "事件")
	_tabs.set_tab_title(5, "旗标")


func _scroll_box() -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return sc


func _inner_col(sc: ScrollContainer) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	sc.add_child(col)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 4)
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_right", 4)
	pad.add_theme_constant_override("margin_bottom", 6)
	## put content in pad via returning col directly for simplicity
	return col


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	KairoStyle.style_button(b)
	b.pressed.connect(cb)
	return b


func _row_btns(parent: Control, items: Array) -> void:
	var row: HBoxContainer = null
	for i in range(items.size()):
		if i % 3 == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			parent.add_child(row)
		var it: Array = items[i]
		row.add_child(_btn(String(it[0]), it[1]))


func _section(parent: Control, title: String) -> void:
	var lb := Label.new()
	lb.text = title
	lb.add_theme_color_override("font_color", KairoStyle.ACCENT_INK)
	lb.add_theme_font_size_override("font_size", 16)
	parent.add_child(lb)


func _build_tab_presets() -> Control:
	var sc := _scroll_box()
	var col := _inner_col(sc)
	sc.name = "Presets"
	_section(col, "一键跳转（会清对白并入队事件）")
	_row_btns(col, [
		["满资源", func(): _preset_rich()],
		["跳 Day1 朝账 M001", func(): _jump_day_event(1, "morning", "M001")],
		["跳 Day8 朝账 M002", func(): _jump_day_event(8, "morning", "M002")],
		["跳 Day15 例行 M000", func(): _jump_day_event(15, "morning", "M000")],
		["跳 Day17 升外场 M003", func(): _jump_day_event(17, "morning", "M003")],
		["直接升外场+仪式", func(): _cheat_set_rank("waichang", true)],
		["直接升跑街+仪式", func(): _cheat_set_rank("paojie", true)],
		["E020 升职爽", func(): _queue_and_play("E020")],
		["E021 轻清算", func(): _queue_and_play("E021")],
		["E022 主清算", func(): _queue_and_play("E022")],
		["E018A 章终", func(): _queue_and_play("E018")],
		["外座聚丰仪式", func(): _ext_ceremony("jufeng_paojie")],
		["外座洋行仪式", func(): _ext_ceremony("foreign_agent")],
		["强制今日朝账", func(): _force_meeting_today()],
		["摊派本周差事", func(): _assign_default_tasks()],
		["差事全完成", func(): _complete_all_tasks()],
		["序位拉到第一", func(): _ladder_to_top()],
		["劲敌拉超你", func(): _ladder_rival_ahead()],
		["中止对白", func(): _abort_dialog()],
		["解冻互动", func(): _unfreeze()],
	])
	return sc


func _build_tab_time() -> Control:
	var sc := _scroll_box()
	var col := _inner_col(sc)
	sc.name = "Time"
	_section(col, "日程")
	var day_row := HBoxContainer.new()
	col.add_child(day_row)
	var dl := Label.new()
	dl.text = "日"
	day_row.add_child(dl)
	_day_spin = SpinBox.new()
	_day_spin.min_value = 1
	_day_spin.max_value = 99
	_day_spin.value = 1
	_day_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_row.add_child(_day_spin)
	day_row.add_child(_btn("跳到该日清晨", func(): _set_day_slot(int(_day_spin.value), "morning")))

	_section(col, "时段")
	var slot_items: Array = []
	for s in SLOT_IDS:
		var sid := String(s)
		slot_items.append([sid, func(ss := sid): _set_day_slot(RunState.day(), ss)])
	_row_btns(col, slot_items)
	col.add_child(_btn("歇一口气（推进时段）", func(): _rest_once()))
	col.add_child(_btn("连推 1 日", func(): _rest_n(5)))
	col.add_child(_btn("连推到下次朝账日", func(): _rest_to_meeting()))

	_section(col, "地点")
	var loc_items: Array = []
	for loc in LOC_IDS:
		var lid := String(loc)
		loc_items.append([lid, func(ll := lid): _set_loc(ll)])
	_row_btns(col, loc_items)
	return sc


func _build_tab_stats() -> Control:
	var sc := _scroll_box()
	var col := _inner_col(sc)
	sc.name = "Stats"
	_section(col, "常用数值")
	for sid in STAT_IDS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		col.add_child(row)
		var name_lb := Label.new()
		name_lb.custom_minimum_size = Vector2(150, 0)
		name_lb.text = sid
		row.add_child(name_lb)
		var val_lb := Label.new()
		val_lb.custom_minimum_size = Vector2(60, 0)
		val_lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(val_lb)
		_stat_labels[sid] = val_lb
		var id_copy := String(sid)
		row.add_child(_btn("-10", func(): _add_stat(id_copy, -10)))
		row.add_child(_btn("+10", func(): _add_stat(id_copy, 10)))
		row.add_child(_btn("=50", func(): _set_stat(id_copy, 50)))
		row.add_child(_btn("=0", func(): _set_stat(id_copy, 0)))

	_section(col, "银两速设")
	var mrow := HBoxContainer.new()
	col.add_child(mrow)
	_money_spin = SpinBox.new()
	_money_spin.min_value = 0
	_money_spin.max_value = 9999
	_money_spin.value = 100
	_money_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mrow.add_child(_money_spin)
	mrow.add_child(_btn("设银两", func(): _set_stat("stat_money", int(_money_spin.value))))
	_row_btns(col, [
		["银两+100", func(): _add_stat("stat_money", 100)],
		["信任+20", func(): _add_stat("stat_trust_firm", 20)],
		["嫌疑+20", func(): _add_stat("stat_suspicion", 20)],
		["嫌疑清零", func(): _set_stat("stat_suspicion", 0)],
		["情报+20", func(): _add_stat("stat_intel", 20)],
		["钱记热度+20", func(): _org_add("firm_heat", 20)],
	])
	return sc


func _build_tab_rank_meeting() -> Control:
	var sc := _scroll_box()
	var col := _inner_col(sc)
	sc.name = "RankMeeting"
	_section(col, "职级（带仪式）")
	var rank_items: Array = []
	for r in RANK_IDS:
		var rr := String(r)
		rank_items.append([rr, func(x := rr): _cheat_set_rank(x, true)])
	_row_btns(col, rank_items)
	_section(col, "职级（静默，无仪式）")
	var silent_items: Array = []
	for r in RANK_IDS:
		var rr2 := String(r)
		silent_items.append([rr2 + "·静", func(x := rr2): _cheat_set_rank(x, false)])
	_row_btns(col, silent_items)
	_row_btns(col, [
		["外座聚丰", func(): _ext_ceremony("jufeng_paojie")],
		["外座洋行", func(): _ext_ceremony("foreign_agent")],
	])

	_section(col, "朝账参与等级")
	var tier_items: Array = []
	for t in TIER_IDS:
		var tt := String(t)
		tier_items.append([tt, func(x := tt): _set_meeting_tier(x)])
	_row_btns(col, tier_items)

	_section(col, "朝账 / 序位")
	_row_btns(col, [
		["今日朝账", func(): _force_meeting_today()],
		["距朝账=1", func(): _set_days_until(1)],
		["距朝账=0", func(): _set_days_until(0)],
		["摊派差事", func(): _assign_default_tasks()],
		["差事全完成", func(): _complete_all_tasks()],
		["推进差事+1", func(): _bump_tasks()],
		["结算汇报分", func(): MeetingSystem.finalize_meeting_report(); _log("已结算汇报分")],
		["完成朝账周", func(): MeetingSystem.complete_meeting_cycle("meeting.summary.m000"); _log("complete_meeting_cycle")],
		["序位+20", func(): MeetingSystem.add_ladder_score("char_lin_ruisheng", 20.0); _log("ladder +20")],
		["序位第一", func(): _ladder_to_top()],
		["劲敌超你", func(): _ladder_rival_ahead()],
		["开议场层", func(): _open_meeting_stage()],
		["关议场层", func(): _close_meeting_stage()],
	])
	return sc


func _build_tab_events() -> Control:
	var sc := _scroll_box()
	var col := _inner_col(sc)
	sc.name = "Events"
	_section(col, "入队并播放")
	_event_opt = OptionButton.new()
	_event_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_event_opt)
	_fill_event_options()
	var erow := HBoxContainer.new()
	col.add_child(erow)
	erow.add_child(_btn("入队", func(): _queue_selected(false)))
	erow.add_child(_btn("入队并播", func(): _queue_selected(true)))
	erow.add_child(_btn("播队首", func(): _play_queue_head()))

	_section(col, "主线速点")
	var main_ids: PackedStringArray = [
		"E001", "E002", "E003", "E004", "E005", "E006", "E007", "E008", "E009",
		"E010", "E013", "E015", "E018", "E019", "E020", "E020B", "E020C",
		"E021", "E021B", "E021C", "E022", "E022B", "E022C",
		"M001", "M002", "M003", "M000",
		"F001", "F003", "F005", "R005", "R006",
	]
	var main_items: Array = []
	for eid in main_ids:
		var e := String(eid)
		main_items.append([e, func(x := e): _queue_and_play(x)])
	_row_btns(col, main_items)

	_section(col, "自由对话 ID")
	_dialog_edit = LineEdit.new()
	_dialog_edit.placeholder_text = "dialog_id …"
	_dialog_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_dialog_edit)
	col.add_child(_btn("播放对话", func(): _play_dialog(_dialog_edit.text.strip_edges())))

	_section(col, "队列")
	col.add_child(_btn("清空事件队列", func(): RunState.queue.clear(); _log("queue cleared")))
	col.add_child(_btn("中止对白", func(): _abort_dialog()))
	return sc


func _build_tab_flags() -> Control:
	var sc := _scroll_box()
	var col := _inner_col(sc)
	sc.name = "Flags"
	_section(col, "常用旗标开关")
	for fid in FLAG_PRESETS:
		var row := HBoxContainer.new()
		col.add_child(row)
		var lb := Label.new()
		lb.text = fid
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.add_theme_font_size_override("font_size", 14)
		row.add_child(lb)
		_flag_edits[fid] = lb
		var f := String(fid)
		row.add_child(_btn("开", func(): RunState.set_flag(f, true); _log("flag %s=true" % f); _refresh_flags()))
		row.add_child(_btn("关", func(): RunState.set_flag(f, false); _log("flag %s=false" % f); _refresh_flags()))

	_section(col, "自定义旗标")
	var frow := HBoxContainer.new()
	col.add_child(frow)
	_flag_edit = LineEdit.new()
	_flag_edit.placeholder_text = "flag_id"
	_flag_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frow.add_child(_flag_edit)
	_flag_val = LineEdit.new()
	_flag_val.placeholder_text = "true / false / 文本"
	_flag_val.text = "true"
	_flag_val.custom_minimum_size = Vector2(120, 0)
	frow.add_child(_flag_val)
	col.add_child(_btn("写入旗标", func(): _set_custom_flag()))

	_section(col, "恩怨")
	_row_btns(col, [
		["打开婚事债", func(): _grudge("grudge_zian_fiancee", "open")],
		["罚婚事债", func(): _resolve_grudge("grudge_zian_fiancee", "punish")],
		["恕婚事债", func(): _resolve_grudge("grudge_zian_fiancee", "forgive")],
		["打开轻债窗", func(): RunState.set_flag("flag_grudge_window_light", true); _log("light window")],
	])
	return sc


func _fill_event_options() -> void:
	if _event_opt == null:
		return
	_event_opt.clear()
	var ids: PackedStringArray = []
	for row in PackDB.get_rows("def_event"):
		var eid := String(row.get("event_id", ""))
		if not eid.is_empty():
			ids.append(eid)
	ids.sort()
	for eid in ids:
		_event_opt.add_item(eid)


func _refresh_all() -> void:
	_refresh_status()
	_refresh_stats()
	_refresh_flags()
	if _day_spin:
		_day_spin.value = RunState.day()
	_fill_event_options()


func _refresh_status() -> void:
	if _status == null:
		return
	if not RunState.active:
		_status.text = "未开局 — 请先新游戏 / 读档"
		return
	MeetingSystem.ensure_state()
	_status.text = "D%d · %s · %s · 银%s · 序%s · 朝账%s · 队%s · 对白%s" % [
		RunState.day(),
		RunState.slot(),
		PromotionSystem.address_for(),
		str(RunState.get_stat("stat_money", 0)),
		MeetingSystem.hud_ladder_text() if not MeetingSystem.hud_ladder_text().is_empty() else "—",
		MeetingSystem.hud_meeting_text(),
		str(RunState.queue),
		"ON" if DialogueRunner.is_active() else "off",
	]


func _refresh_stats() -> void:
	for sid in _stat_labels.keys():
		var lb: Label = _stat_labels[sid]
		if lb:
			lb.text = str(RunState.get_stat(String(sid), 0))


func _refresh_flags() -> void:
	for fid in _flag_edits.keys():
		var lb: Label = _flag_edits[fid]
		if lb == null:
			continue
		var on := bool(RunState.get_flag(String(fid), false))
		lb.text = "%s  [%s]" % [fid, "ON" if on else "off"]
		lb.add_theme_color_override("font_color", KairoStyle.ACCENT_INK if on else KairoStyle.INK)


func _ensure_run() -> bool:
	if RunState.active and not RunState.ended:
		return true
	_log("需要先进入游戏（新开局/读档）")
	return false


func _log(msg: String) -> void:
	DomainBus.tip.emit("[作弊] %s" % msg)
	_refresh_status()


func _abort_dialog() -> void:
	DialogueRunner.force_abort()
	_log("对白已中止")


func _unfreeze() -> void:
	var chrome := get_tree().get_first_node_in_group("play_chrome")
	if chrome and chrome.has_method("_set_interactive"):
		chrome._set_interactive(true)
	_log("尝试解冻互动")


func _add_stat(sid: String, delta: float) -> void:
	if not _ensure_run():
		return
	RunState.add_stat(sid, delta)
	_log("%s %+d" % [sid, int(delta)])


func _set_stat(sid: String, value: Variant) -> void:
	if not _ensure_run():
		return
	RunState.set_stat(sid, value)
	_log("%s = %s" % [sid, str(value)])


func _org_add(key: String, delta: float) -> void:
	if not _ensure_run():
		return
	RunState.add_org_field("org_qianji", key, delta)
	_log("org_qianji.%s %+d" % [key, int(delta)])


func _set_day_slot(day: int, slot: String) -> void:
	if not _ensure_run():
		return
	_abort_dialog()
	RunState.meta["day"] = maxi(1, day)
	RunState.meta["slot"] = slot if slot in SLOT_IDS else "morning"
	DomainBus.slot_changed.emit(RunState.day(), RunState.slot())
	TickPipeline.on_slot_enter()
	_log("跳到 第%d日 · %s" % [RunState.day(), RunState.slot()])
	_refresh_all()


func _set_loc(loc_id: String) -> void:
	if not _ensure_run():
		return
	RunState.set_current_loc(loc_id)
	var chrome := get_tree().get_first_node_in_group("play_chrome")
	if chrome and chrome.has_method("_refresh_all"):
		chrome._refresh_all()
	_log("地点 → %s" % loc_id)


func _rest_once() -> void:
	if not _ensure_run():
		return
	if DialogueRunner.is_active():
		_abort_dialog()
	TickPipeline.advance_after_idle()
	_log("推进一时段")
	_refresh_all()


func _rest_n(n: int) -> void:
	if not _ensure_run():
		return
	_abort_dialog()
	for _i in range(n):
		TickPipeline.advance_after_idle()
	_log("连推 %d 时段" % n)
	_refresh_all()


func _rest_to_meeting() -> void:
	if not _ensure_run():
		return
	_abort_dialog()
	for _i in range(40):
		if MeetingSystem.is_meeting_day() and RunState.slot() == "morning":
			break
		TickPipeline.advance_after_idle()
	_log("已推到朝账日附近 D%d %s" % [RunState.day(), RunState.slot()])
	_refresh_all()


func _cheat_set_rank(rank: String, ceremony: bool) -> void:
	if not _ensure_run():
		return
	if not ceremony:
		PromotionSystem.suppress_ceremony = true
	EffectApplier.apply_one({"op": "set_rank", "value": rank}, "cheat")
	if MeetingSystem.has_method("_on_rank_changed"):
		MeetingSystem._on_rank_changed("", rank)
	_log("职级 → %s%s" % [rank, "（仪式）" if ceremony else "（静默）"])
	_refresh_all()


func _ext_ceremony(seat: String) -> void:
	if not _ensure_run():
		return
	EffectApplier.apply_one({"op": "external_rank_ceremony", "value": seat}, "cheat")
	_log("外座仪式 %s" % seat)


func _set_meeting_tier(tier: String) -> void:
	if not _ensure_run():
		return
	MeetingSystem.set_meeting_tier(tier)
	RunState.set_flag("flag_meeting_report_eligible", tier != "listen")
	_log("朝账 tier → %s" % tier)


func _force_meeting_today() -> void:
	if not _ensure_run():
		return
	RunState.meeting["days_until_next"] = 0
	## 对齐到朝账日公式：day % 7 == 1
	var d := RunState.day()
	var target := d
	while target % 7 != 1:
		target += 1
	_set_day_slot(target, "morning")
	RunState.meeting["days_until_next"] = 0
	DomainBus.emit_domain("meeting_changed", {})
	_log("强制朝账日 D%d" % target)


func _set_days_until(n: int) -> void:
	if not _ensure_run():
		return
	MeetingSystem.ensure_state()
	RunState.meeting["days_until_next"] = maxi(0, n)
	DomainBus.emit_domain("meeting_changed", {"days_until_next": n})
	_log("距朝账 = %d" % n)


func _assign_default_tasks() -> void:
	if not _ensure_run():
		return
	MeetingSystem.assign_weekly_tasks(MeetingSystem.default_tasks_for_rank())
	_log("已摊派差事")


func _complete_all_tasks() -> void:
	if not _ensure_run():
		return
	MeetingSystem.ensure_state()
	for t in RunState.meeting.get("weekly_tasks", []):
		if typeof(t) == TYPE_DICTIONARY:
			t["progress"] = int(t.get("target", 1))
	DomainBus.emit_domain("meeting_tasks_changed", {})
	_log("差事全完成")


func _bump_tasks() -> void:
	if not _ensure_run():
		return
	## 尝试各 act 推一次
	for act in ["act_01", "act_02", "act_03", "act_05", "act_07", "act_09", "act_12"]:
		MeetingSystem.on_player_action(act)
	_log("差事尝试推进")


func _ladder_to_top() -> void:
	if not _ensure_run():
		return
	MeetingSystem.ensure_state()
	if String(RunState.ladder.get("pool_id", "")).is_empty():
		MeetingSystem.init_ladder_pool(MeetingSystem.pool_for_rank())
	var best := 0.0
	for e in RunState.ladder.get("entries", []):
		if typeof(e) == TYPE_DICTIONARY:
			best = maxf(best, float(e.get("score", 0)))
	MeetingSystem.add_ladder_score("char_lin_ruisheng", best + 20.0)
	_log("序位拉到第一附近")


func _ladder_rival_ahead() -> void:
	if not _ensure_run():
		return
	MeetingSystem.ensure_state()
	if String(RunState.ladder.get("pool_id", "")).is_empty():
		MeetingSystem.init_ladder_pool(MeetingSystem.pool_for_rank())
	var rival := MeetingSystem.primary_rival()
	if rival.is_empty():
		rival = MeetingSystem.pick_meeting_rival()
	if rival.is_empty():
		rival = "char_apprentice_sun_liu"
		if String(RunState.ladder.get("pool_id", "")) == "pool_waichang":
			rival = "char_li_waichang"
		elif String(RunState.ladder.get("pool_id", "")) == "pool_paojie":
			rival = "char_qian_zian"
	MeetingSystem.add_ladder_score(rival, 25.0)
	_log("劲敌 %s +25" % rival)


func _open_meeting_stage() -> void:
	var ms := get_tree().get_first_node_in_group("meeting_stage")
	if ms == null:
		_log("无 MeetingStage")
		return
	if ms.has_method("_open_stage"):
		ms.call("_open_stage")
		_log("议场开")
	else:
		ms.visible = true
		_log("议场 visible")


func _close_meeting_stage() -> void:
	var ms := get_tree().get_first_node_in_group("meeting_stage")
	if ms and ms.has_method("force_hide"):
		ms.force_hide()
	elif ms:
		ms.visible = false
	_log("议场关")


func _queue_selected(play: bool) -> void:
	if not _ensure_run() or _event_opt == null:
		return
	var eid := _event_opt.get_item_text(_event_opt.selected)
	if eid.is_empty():
		return
	if play:
		_queue_and_play(eid)
	else:
		RunState.enqueue_event(eid)
		_log("入队 %s" % eid)


func _queue_and_play(eid: String) -> void:
	if not _ensure_run():
		return
	_abort_dialog()
	## 避免队列堵塞：插到队首
	var q: Array = [eid]
	for old in RunState.queue:
		if String(old) != eid:
			q.append(old)
	RunState.queue = q
	hide_cheat()
	TickPipeline.begin_queued_event()
	DomainBus.tip.emit("[作弊] 播放 %s" % eid)


func _play_queue_head() -> void:
	if not _ensure_run():
		return
	if RunState.queue.is_empty():
		_log("队列空")
		return
	hide_cheat()
	TickPipeline.begin_queued_event()


func _play_dialog(did: String) -> void:
	if not _ensure_run():
		return
	if did.is_empty():
		_log("dialog_id 空")
		return
	_abort_dialog()
	hide_cheat()
	DialogueRunner.start_loose(did)
	DomainBus.tip.emit("[作弊] 对话 %s" % did)


func _jump_day_event(day: int, slot: String, eid: String) -> void:
	if not _ensure_run():
		return
	_set_day_slot(day, slot)
	_queue_and_play(eid)


func _preset_rich() -> void:
	if not _ensure_run():
		return
	RunState.set_stat("stat_money", 200)
	RunState.set_stat("stat_trust_firm", 60)
	RunState.set_stat("stat_suspicion", 0)
	RunState.set_stat("stat_intel", 40)
	RunState.set_stat("stat_credit_bank", 40)
	RunState.set_stat("stat_credit_market", 30)
	RunState.set_flag("flag_tutorial_done", true)
	_log("满资源")


func _set_custom_flag() -> void:
	if not _ensure_run():
		return
	var fid := _flag_edit.text.strip_edges()
	if fid.is_empty():
		_log("flag 空")
		return
	var raw := _flag_val.text.strip_edges()
	var val: Variant = raw
	if raw.to_lower() in ["true", "1", "yes", "on"]:
		val = true
	elif raw.to_lower() in ["false", "0", "no", "off"]:
		val = false
	elif raw.is_valid_int():
		val = int(raw)
	RunState.set_flag(fid, val)
	_log("flag %s=%s" % [fid, str(val)])
	_refresh_flags()


func _grudge(gid: String, status: String) -> void:
	if not _ensure_run():
		return
	EffectApplier.apply_one({"op": "open_grudge" if status == "open" else "unlock_grudge", "id": gid}, "cheat")
	if RunState.grudges.has(gid):
		RunState.grudges[gid]["status"] = status
	_log("恩怨 %s → %s" % [gid, status])


func _resolve_grudge(gid: String, mode: String) -> void:
	if not _ensure_run():
		return
	EffectApplier.apply_one({
		"op": "resolve_grudge",
		"id": gid,
		"mode": mode,
		"window": "main" if gid == "grudge_zian_fiancee" else "light",
	}, "cheat")
	_log("清算 %s %s" % [gid, mode])
