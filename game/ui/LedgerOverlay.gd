extends CanvasLayer
## 账簿：本档 / 人物 / 往来 / 暗线。

@onready var root: Control = %Root
@onready var tab_bar: HBoxContainer = %TabBar
@onready var title_label: Label = %Title
@onready var body: RichTextLabel = %Body
@onready var side_list: ItemList = %SideList
@onready var close_btn: Button = %CloseBtn

var _tab: String = "self"
var _npc_ids: PackedStringArray = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	close_btn.pressed.connect(hide_ledger)
	_build_tabs()
	side_list.item_selected.connect(_on_side_selected)
	var panel: PanelContainer = root.get_node_or_null("Panel") as PanelContainer
	if panel:
		KairoStyle.style_panel(panel)
	title_label.add_theme_color_override("font_color", KairoStyle.INK)
	title_label.add_theme_font_size_override("font_size", 22)
	KairoStyle.style_readable_rich(body, 17, 19)
	side_list.add_theme_color_override("font_color", KairoStyle.INK)
	side_list.add_theme_font_size_override("font_size", 15)
	KairoStyle.style_button(close_btn)
	# 点遮罩也可收起
	var dim: ColorRect = root.get_node_or_null("Dim") as ColorRect
	if dim:
		dim.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				hide_ledger()
		)


func toggle() -> void:
	if visible:
		hide_ledger()
	else:
		show_ledger()


func open_self() -> void:
	show_ledger("self")


func open_char(char_id: String) -> void:
	if char_id.is_empty() or char_id == "char_lin_ruisheng" or char_id == "narrator":
		open_self()
		return
	var row: Dictionary = PackDB.get_row_by_id("def_char", "char_id", char_id)
	if not row.is_empty() and bool(row.get("is_player", false)):
		open_self()
		return
	_tab = "people"
	visible = true
	show()
	_refresh()
	_focus_npc(char_id)


func show_ledger(tab: String = "self") -> void:
	_tab = tab
	visible = true
	show()
	_refresh()


func _focus_npc(char_id: String) -> void:
	for i in range(_npc_ids.size()):
		if _npc_ids[i] == char_id:
			side_list.select(i)
			body.text = _npc_text(char_id)
			return
	body.text = _npc_text(char_id)


func hide_ledger() -> void:
	visible = false


func _build_tabs() -> void:
	for c in tab_bar.get_children():
		c.queue_free()
	for pair in [
		["self", "本档"],
		["meeting", "朝账"],
		["people", "人物"],
		["history", "往来"],
		["clues", "暗线"],
	]:
		var btn := Button.new()
		btn.text = L10n.t("ledger.tab.%s" % pair[0], pair[1])
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_meta("tab_id", String(pair[0]))
		KairoStyle.style_button(btn)
		btn.pressed.connect(_select_tab.bind(String(pair[0])))
		tab_bar.add_child(btn)


func _select_tab(tab: String) -> void:
	_tab = tab
	_refresh()


func _refresh() -> void:
	title_label.text = L10n.t("ledger.title", "账簿")
	close_btn.text = L10n.t("ui.close", "收起")
	for c in tab_bar.get_children():
		if c is Button:
			var b := c as Button
			b.set_pressed_no_signal(String(b.get_meta("tab_id", "")) == _tab)
	side_list.clear()
	side_list.visible = _tab == "people" or _tab == "history"
	match _tab:
		"self":
			body.text = _self_text()
		"meeting":
			body.text = _meeting_text()
		"people":
			_fill_people()
		"history":
			_fill_history()
		"clues":
			body.text = _clues_text()


func _self_text() -> String:
	var row: Dictionary = PackDB.get_row_by_id("def_char", "char_id", "char_lin_ruisheng")
	var rank := PromotionSystem.title_for(RunState.player_rank())
	var monthly := int(RunState.meta.get("monthly_stipend", PromotionSystem.monthly_for(RunState.player_rank())))
	var money := RunState.get_stat("stat_money")
	var trust := RunState.get_stat("stat_trust_firm")
	var sus := RunState.get_stat("stat_suspicion")
	var credit := RunState.get_stat("stat_credit_bank")
	var heat := float(RunState.get_org_field("org_qianji", "firm_heat", 0))
	var liq := float(RunState.get_org_field("org_qianji", "liquidity", 0))
	var route := L10n.t("ui.route_none", "未定")
	if RunState.get_flag("route_endure", false):
		route = L10n.t("route.endure", "隐忍")
	elif RunState.get_flag("route_defect", false):
		route = L10n.t("route.defect", "跳槽")
	elif RunState.get_flag("route_foreign", false):
		route = L10n.t("route.foreign", "洋行")
	var lines: PackedStringArray = []
	lines.append_array(_identity_block(row, L10n.t("char_lin_ruisheng", "林瑞生"), rank))
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.sec.livelihood", "生计与站位"))
	lines.append("%s：%s两 · %s：%d两" % [L10n.t("stat.money"), str(money), L10n.t("ui.monthly", "月例"), monthly])
	lines.append("%s：%s · %s：%s · %s：%s" % [
		L10n.t("stat.credit_bank"), str(credit),
		L10n.t("stat.trust_firm"), str(trust),
		L10n.t("stat.suspicion"), str(sus),
	])
	lines.append("%s：%.0f · %s：%.0f · %s：%s" % [
		L10n.t("ui.org_heat", "钱记热度"), heat,
		L10n.t("ui.org_liquidity", "周转"), liq,
		L10n.t("ui.route", "路线"), route,
	])
	var soft := String(row.get("money_soft", ""))
	if not soft.is_empty():
		lines.append("%s：%s" % [L10n.t("ledger.money_soft", "金钱软肋"), soft])
	var debt_id := FinanceService.find_active_debt("", "org_bank")
	if not debt_id.is_empty():
		var d: Dictionary = RunState.debts[debt_id]
		var interest := float(d.get("interest_per_day", 0))
		var debt_line := "%s：%.0f两（%s）" % [
			L10n.t("ui.debt_active", "票号债"),
			float(d.get("remaining", 0)),
			String(d.get("status", "")),
		]
		if interest != 0.0:
			debt_line += " · %s %.0f两/日" % [L10n.t("ui.interest_day", "日息"), interest]
		lines.append(debt_line)
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.sec.relations", "人物关系"))
	lines.append_array(_player_relation_lines())
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.sec.meeting_brief", "朝账摘记"))
	lines.append_array(_meeting_brief_lines())
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.sec.recent", "近期往来"))
	lines.append_array(_history_lines_for("", 6))
	return "\n".join(lines)


func _meeting_brief_lines() -> PackedStringArray:
	MeetingSystem.ensure_state()
	var lines: PackedStringArray = []
	var summary := String(RunState.meeting.get("last_summary_key", ""))
	if summary.is_empty():
		lines.append(L10n.t("ledger.meeting_none", "尚未落过朝账"))
	else:
		lines.append("· %s" % L10n.t(summary, summary))
	var policy := String(RunState.meeting.get("last_policy", ""))
	if not policy.is_empty():
		lines.append("· %s：%s" % [
			L10n.t("ledger.meeting_policy", "定调"),
			L10n.t("meeting.policy.%s" % policy, policy),
		])
	var days := int(RunState.meeting.get("days_until_next", 0))
	if MeetingSystem.is_meeting_day():
		lines.append("· %s" % L10n.t("ui.meeting_today", "今日朝账"))
	else:
		lines.append("· %s" % L10n.t("ui.meeting_in_days", "距朝账 %d日") % days)
	return lines


func _meeting_text() -> String:
	MeetingSystem.ensure_state()
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % L10n.t("ledger.tab.meeting", "朝账"))
	lines.append("")
	var cycle := int(RunState.meeting.get("cycle_index", 0))
	var tier := String(RunState.meeting.get("attendance_tier", "listen"))
	lines.append("%s：%d · %s：%s" % [
		L10n.t("ledger.meeting_cycle", "已过朝账"),
		cycle,
		L10n.t("ledger.meeting_tier", "席位"),
		L10n.t("meeting.tier.%s" % tier, tier),
	])
	var summary := String(RunState.meeting.get("last_summary_key", ""))
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.meeting_last", "上次朝账"))
	if summary.is_empty():
		lines.append(L10n.t("ledger.meeting_none", "尚未落过朝账"))
	else:
		lines.append(L10n.t(summary, summary))
	var policy := String(RunState.meeting.get("last_policy", ""))
	if not policy.is_empty():
		lines.append("%s：%s" % [
			L10n.t("ledger.meeting_policy", "定调"),
			L10n.t("meeting.policy.%s" % policy, policy),
		])
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.meeting_tasks", "本周差事"))
	var tasks: Array = RunState.meeting.get("weekly_tasks", [])
	if tasks.is_empty():
		lines.append(L10n.t("ledger.meeting_tasks_empty", "尚无摊派"))
	else:
		for t in tasks:
			if typeof(t) != TYPE_DICTIONARY:
				continue
			var prog := int(t.get("progress", 0))
			var target := int(t.get("target", 1))
			var mark := "✓" if prog >= target else "%d/%d" % [prog, target]
			lines.append("· %s 〔%s〕" % [
				L10n.t(String(t.get("label_key", "")), String(t.get("id", ""))),
				mark,
			])
	var days := int(RunState.meeting.get("days_until_next", 0))
	lines.append("")
	if MeetingSystem.is_meeting_day():
		lines.append(L10n.t("ui.meeting_today", "今日朝账"))
	else:
		lines.append(L10n.t("ui.meeting_in_days", "距朝账 %d日") % days)
	## 最近朝账履历
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.meeting_history", "朝账履历"))
	var any_m := false
	var hist: Array = RunState.history
	var n := 0
	for i in range(hist.size() - 1, -1, -1):
		var e: Dictionary = hist[i]
		if String(e.get("kind", "")) != "meeting":
			continue
		any_m = true
		n += 1
		lines.append("· D%d — %s" % [int(e.get("day", 0)), _history_summary(e)])
		if n >= 5:
			break
	if not any_m:
		lines.append(L10n.t("ledger.meeting_history_empty", "尚无朝账履历"))
	return "\n".join(lines)


func _npc_text(cid: String) -> String:
	var row: Dictionary = PackDB.get_row_by_id("def_char", "char_id", cid)
	var name := L10n.t(String(row.get("loc_key", "")), cid)
	var rank_label := String(row.get("rank_label", ""))
	var lines: PackedStringArray = []
	lines.append_array(_identity_block(row, name, rank_label))
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.sec.with_you", "与你"))
	lines.append_array(_edge_block(cid, "char_lin_ruisheng", true))
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.sec.web", "他与旁人"))
	var relate: Array = row.get("relate_chars", [])
	var any_rel := false
	for other in relate:
		var oid := String(other)
		if oid == "char_lin_ruisheng" or oid == cid:
			continue
		any_rel = true
		lines.append_array(_edge_block(cid, oid, false))
	if not any_rel:
		lines.append(L10n.t("ledger.unknown", "尚未摸清"))
	var related: Array = row.get("related_meters", [])
	if not related.is_empty():
		lines.append("")
		lines.append("[b]%s[/b]" % L10n.t("ledger.sec.meters", "情感暗线"))
		for mid in related:
			var mv := RunState.get_meter(String(mid))
			lines.append("· %s：%.0f（%s）" % [
				L10n.t("meter.%s" % String(mid), String(mid)),
				mv,
				_meter_feel(String(mid), mv),
			])
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ui.grudge_title", "恩怨账"))
	lines.append_array(_grudge_lines_for(cid))
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.sec.char_history", "与此人相关往来"))
	lines.append_array(_history_lines_for(cid, 8))
	return "\n".join(lines)


func _identity_block(row: Dictionary, name: String, rank_label: String) -> PackedStringArray:
	var blurb := L10n.t(String(row.get("blurb_key", "")), L10n.t("ledger.unknown", "尚未摸清"))
	var title := L10n.t(String(row.get("title_key", "")), "")
	var lines: PackedStringArray = [
		"[b]%s[/b] · %s" % [name, rank_label],
	]
	if not title.is_empty():
		lines.append(title)
	lines.append(blurb)
	var age := int(row.get("age", 0))
	var gender := String(row.get("gender", ""))
	var org := String(row.get("org_id", ""))
	var home := String(row.get("home_loc", ""))
	var dark := String(row.get("dark_know", ""))
	var wealth := String(row.get("wealth", ""))
	var bits: PackedStringArray = []
	if age > 0:
		bits.append("%d岁" % age)
	if not gender.is_empty():
		bits.append(gender)
	if not org.is_empty() and org != "无":
		bits.append(L10n.t("org.%s" % org, org))
	if not home.is_empty():
		var hrow: Dictionary = PackDB.get_row_by_id("def_location", "loc_id", home)
		bits.append(L10n.t(String(hrow.get("loc_key", "")), home))
	if not bits.is_empty():
		lines.append(" · ".join(bits))
	if not dark.is_empty():
		lines.append("%s：%s" % [L10n.t("ledger.dark_know", "暗账知情"), dark])
	if not wealth.is_empty():
		lines.append("%s：%s" % [L10n.t("ledger.wealth", "财力"), wealth])
	var soft := String(row.get("money_soft", ""))
	if not soft.is_empty():
		lines.append("%s：%s" % [L10n.t("ledger.money_soft", "金钱软肋"), soft])
	var tags: Array = row.get("tags", [])
	if not tags.is_empty():
		var tb: PackedStringArray = []
		for t in tags:
			tb.append(String(t))
		lines.append("%s：%s" % [L10n.t("ledger.tags", "标签"), "、".join(tb)])
	return lines


func _edge_block(from_id: String, to_id: String, with_you: bool) -> PackedStringArray:
	var lines: PackedStringArray = []
	var e_ft := RunState.get_edge(from_id, to_id)
	var e_tf := RunState.get_edge(to_id, from_id)
	var name_f := _char_name(from_id)
	var name_t := _char_name(to_id)
	if with_you:
		# NPC → 你
		lines.append(_format_edge_line(name_f, L10n.t("ledger.you", "你"), e_ft))
		# 你 → NPC
		lines.append(_format_edge_line(L10n.t("ledger.you", "你"), name_f, e_tf))
	else:
		lines.append(_format_edge_line(name_f, name_t, e_ft))
		# only show reverse if non-default
		if float(e_tf.get("score", 0)) != 0.0 or int(e_tf.get("trust", 0)) > 0 \
			or int(e_tf.get("suspicion", 0)) > 0 or int(e_tf.get("fear", 0)) > 0:
			lines.append(_format_edge_line(name_t, name_f, e_tf))
	return lines


func _format_edge_line(from_name: String, to_name: String, e: Dictionary) -> String:
	var score := float(e.get("score", 0))
	var tier := ConditionEval.score_to_tier(score)
	var trust := int(e.get("trust", 0))
	var sus := int(e.get("suspicion", 0))
	var fear := int(e.get("fear", 0))
	var line := "· %s→%s：〔%s〕%s%d" % [
		from_name, to_name,
		L10n.t("tier.%s" % tier, tier),
		L10n.t("ledger.score_abbr", "分"),
		int(score),
	]
	line += " ·%s%s ·%s%s ·%s%s" % [
		L10n.t("ledger.trust", "信"), _band3(trust),
		L10n.t("ledger.suspicion", "疑"), _band3(sus),
		L10n.t("ledger.fear", "惧"), _band3(fear),
	]
	var debt_s := String(e.get("debt", ""))
	var lev_s := String(e.get("leverage", ""))
	if not debt_s.is_empty() and debt_s != "无":
		line += " ·%s:%s" % [L10n.t("ui.favor_debt", "人情债"), debt_s]
	if not lev_s.is_empty() and lev_s != "无":
		line += " ·%s:%s" % [L10n.t("ui.leverage", "把柄"), lev_s]
	return line


func _band3(v: int) -> String:
	match clampi(v, 0, 4):
		0:
			return L10n.t("band.0", "低")
		1:
			return L10n.t("band.1", "中")
		2:
			return L10n.t("band.2", "高")
		3:
			return L10n.t("band.3", "极")
		_:
			return L10n.t("band.4", "杀")


func _player_relation_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	var seen: Dictionary = {}
	for row in PackDB.get_rows("def_char"):
		if bool(row.get("is_player", false)):
			continue
		if not bool(row.get("demo", true)):
			continue
		var cid := String(row.get("char_id", ""))
		seen[cid] = true
		var e := RunState.get_edge(cid, "char_lin_ruisheng")
		var tier := ConditionEval.score_to_tier(float(e.get("score", 0)))
		lines.append("· %s 〔%s〕 信%s疑%s" % [
			_char_name(cid),
			L10n.t("tier.%s" % tier, tier),
			_band3(int(e.get("trust", 0))),
			_band3(int(e.get("suspicion", 0))),
		])
	if lines.is_empty():
		lines.append(L10n.t("ledger.people_empty", "尚无人可记"))
	return lines


func _grudge_lines_for(cid: String) -> PackedStringArray:
	var lines: PackedStringArray = []
	for gid in RunState.grudges.keys():
		var g: Dictionary = RunState.grudges[gid]
		var defg: Dictionary = PackDB.get_row_by_id("def_grudge", "grudge_id", String(gid))
		var debtor := String(g.get("debtor", defg.get("debtor", "")))
		var creditor := String(defg.get("creditor", ""))
		if debtor != cid and creditor != cid and String(defg.get("debtor", "")) != cid:
			continue
		var st := String(g.get("status", ""))
		var name := L10n.t(String(defg.get("loc_key", "")), String(gid))
		lines.append("· %s 〔%s〕" % [name, L10n.t("grudge.status.%s" % st, st)])
	if lines.is_empty():
		lines.append(L10n.t("ui.grudge_empty", "尚无埋债"))
	return lines


func _history_lines_for(char_filter: String, limit: int) -> PackedStringArray:
	var lines: PackedStringArray = []
	var hist: Array = RunState.history
	for i in range(hist.size() - 1, -1, -1):
		var e: Dictionary = hist[i]
		if not char_filter.is_empty() and not _history_involves(e, char_filter):
			continue
		var day := int(e.get("day", 0))
		lines.append("· D%d %s — %s" % [day, _slot_name(String(e.get("slot", ""))), _history_summary(e)])
		if lines.size() >= limit:
			break
	if lines.is_empty():
		lines.append(L10n.t("ledger.history_empty", "往来尚未落笔"))
	return lines


func _history_involves(e: Dictionary, char_id: String) -> bool:
	var ref := String(e.get("ref", ""))
	if ref.find(char_id) >= 0:
		return true
	var p: Dictionary = e.get("payload", {})
	if String(p.get("from", "")) == char_id or String(p.get("to", "")) == char_id:
		return true
	# events that mention char in summary key rarely — also check grudge debtor
	if String(e.get("kind", "")) == "grudge":
		var defg: Dictionary = PackDB.get_row_by_id("def_grudge", "grudge_id", ref)
		if String(defg.get("debtor", "")) == char_id or String(defg.get("creditor", "")) == char_id:
			return true
	return false


func _char_name(cid: String) -> String:
	if cid == "char_lin_ruisheng":
		return L10n.t("char_lin_ruisheng", "林瑞生")
	var row: Dictionary = PackDB.get_row_by_id("def_char", "char_id", cid)
	return L10n.t(String(row.get("loc_key", cid)), cid)


func _meter_feel(mid: String, v: float) -> String:
	match mid:
		"father_son":
			if v >= 70.0:
				return L10n.t("meter.feel.warm", "尚和")
			if v <= 30.0:
				return L10n.t("meter.feel.cold", "裂了")
			return L10n.t("meter.feel.mid", "平常")
		"pursuit":
			if v >= 50.0:
				return L10n.t("meter.feel.hot", "逼近")
			if v <= 10.0:
				return L10n.t("meter.feel.quiet", "未起")
			return L10n.t("meter.feel.mid", "平常")
		"impression_bradley", "impression_qing", "eval":
			if v >= 40.0:
				return L10n.t("meter.feel.noticed", "有数")
			return L10n.t("meter.feel.thin", "尚浅")
		_:
			return str(int(v))


func _fill_people() -> void:
	_npc_ids.clear()
	for row in PackDB.get_rows("def_char"):
		if not bool(row.get("demo", true)):
			continue
		if bool(row.get("is_player", false)):
			continue
		var cid := String(row.get("char_id", ""))
		_npc_ids.append(cid)
		side_list.add_item(L10n.t(String(row.get("loc_key", "")), cid))
	if _npc_ids.is_empty():
		body.text = L10n.t("ledger.people_empty", "尚无人可记")
		return
	side_list.select(0)
	body.text = _npc_text(_npc_ids[0])


func _fill_history() -> void:
	side_list.clear()
	var hist: Array = RunState.history
	if hist.is_empty():
		body.text = L10n.t("ledger.history_empty", "往来尚未落笔")
		return
	# newest first
	var idxs: Array = []
	for i in range(hist.size() - 1, -1, -1):
		idxs.append(i)
	for i in idxs:
		var e: Dictionary = hist[i]
		var day := int(e.get("day", 0))
		var kind := String(e.get("kind", ""))
		var summary := _history_summary(e)
		side_list.add_item("D%d · %s" % [day, summary])
		side_list.set_item_metadata(side_list.item_count - 1, i)
	side_list.select(0)
	_show_history_entry(int(idxs[0]))


func _show_history_entry(i: int) -> void:
	if i < 0 or i >= RunState.history.size():
		return
	var e: Dictionary = RunState.history[i]
	var slot := String(e.get("slot", ""))
	var kind := String(e.get("kind", ""))
	body.text = "[b]%s[/b]\n%s\n\n%s\n%s" % [
		_history_summary(e),
		L10n.t("ledger.history_kind.%s" % kind, kind),
		L10n.t("ui.day_slot", "第 %d 日 · %s") % [int(e.get("day", 0)), _slot_name(slot)],
		_history_extra(e),
	]


func _history_summary(e: Dictionary) -> String:
	var kind := String(e.get("kind", ""))
	var p: Dictionary = e.get("payload", {})
	match kind:
		"edge":
			var from_n := _char_name(String(p.get("from", "")))
			var to_n := _char_name(String(p.get("to", "")))
			var tier := String(p.get("tier", ""))
			var key := String(p.get("key", "score"))
			if key == "score" and not tier.is_empty():
				return L10n.t("history.edge.named", "%s→%s 交情变为〔%s〕") % [
					from_n, to_n, L10n.t("tier.%s" % tier, tier)
				]
			return L10n.t("history.edge.named_shift", "%s→%s 关系有了变化") % [from_n, to_n]
		"rank":
			var title := String(p.get("title", e.get("ref", "")))
			return L10n.t(String(e.get("summary_key", "")), title)
		"event":
			var key := String(e.get("summary_key", ""))
			return L10n.t(key, String(e.get("ref", key)))
		"grudge":
			return L10n.t(String(e.get("summary_key", "")), String(e.get("ref", "")))
		"clue":
			return L10n.t(String(e.get("summary_key", "")), String(e.get("ref", "")))
		"debt":
			return L10n.t(String(e.get("summary_key", "")), L10n.t("history.debt.opened", "票号债开立"))
		"route":
			return L10n.t(String(e.get("summary_key", "")), String(e.get("ref", "")))
		"meeting":
			return L10n.t(String(e.get("summary_key", "")), L10n.t("ledger.tab.meeting", "朝账"))
		_:
			var fallback := String(e.get("ref", e.get("summary_key", "")))
			return L10n.t(String(e.get("summary_key", "")), fallback)


func _history_extra(e: Dictionary) -> String:
	var p: Dictionary = e.get("payload", {})
	var kind := String(e.get("kind", ""))
	if kind == "edge" and not p.is_empty():
		return L10n.t("history.edge.detail", "信%s · 疑%s · 惧%s · 分%d") % [
			_band3(int(p.get("trust", 0))),
			_band3(int(p.get("suspicion", 0))),
			_band3(int(p.get("fear", 0))),
			int(float(p.get("score", 0))),
		]
	if kind == "rank" and p.has("monthly"):
		return L10n.t("history.rank.detail", "月例档 %d 两") % int(p.get("monthly", 0))
	if kind == "grudge" and p.has("status"):
		return L10n.t("grudge.status.%s" % String(p.get("status", "")), String(p.get("status", "")))
	if kind == "meeting":
		var bits: PackedStringArray = []
		var pol := String(p.get("policy", ""))
		if not pol.is_empty():
			bits.append("%s：%s" % [L10n.t("ledger.meeting_policy", "定调"), L10n.t("meeting.policy.%s" % pol, pol)])
		bits.append("%s %s / %s %s" % [
			L10n.t("ledger.meeting_spoke", "言"), str(int(p.get("spoke", 0))),
			L10n.t("ledger.meeting_pass", "默"), str(int(p.get("pass", 0))),
		])
		return " · ".join(bits)
	if p.is_empty():
		return ""
	var bits: PackedStringArray = []
	for k in p.keys():
		if String(k) in ["from", "to", "tier", "score", "trust", "suspicion", "fear", "key", "op"]:
			continue
		bits.append("%s=%s" % [String(k), str(p[k])])
	return " · ".join(bits)


func _clues_text() -> String:
	var lines: PackedStringArray = ["[b]%s[/b]" % L10n.t("ledger.tab.clues", "暗线"), ""]
	if RunState.clues.is_empty():
		lines.append(L10n.t("ledger.clues_empty", "尚未握住任何线索"))
	else:
		for cid in RunState.clues.keys():
			var defc: Dictionary = PackDB.get_row_by_id("def_clue", "clue_id", String(cid))
			var name := L10n.t(String(defc.get("loc_key", "")), String(cid))
			var q := String(RunState.clues[cid].get("quality", ""))
			lines.append("· %s（%s）" % [name, q])
	lines.append("")
	lines.append("[b]%s[/b]" % L10n.t("ledger.items", "信物"))
	if RunState.items.is_empty():
		lines.append(L10n.t("ledger.items_empty", "囊中无信物"))
	else:
		for iid in RunState.items.keys():
			lines.append("· %s" % L10n.t(String(iid), String(iid)))
	return "\n".join(lines)


func _on_side_selected(index: int) -> void:
	if _tab == "people":
		if index >= 0 and index < _npc_ids.size():
			body.text = _npc_text(_npc_ids[index])
	elif _tab == "history":
		var i := int(side_list.get_item_metadata(index))
		_show_history_entry(i)


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
