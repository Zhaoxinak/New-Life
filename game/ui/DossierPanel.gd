extends CanvasLayer


const STORY_NPCS: PackedStringArray = ["su_qing", "zhou_shaoting", "zhou_hongye", "chen_manager"]
const HARBOR_NPCS: PackedStringArray = ["dock_foreman", "stall_aunt", "tea_waiter", "garage_hand"]
const PLAYER_STATS: PackedStringArray = [
	"money", "trust", "tongyang_trust", "suspicion", "intel", "network_base", "network_elite", 
	"vehicle_tier", "home_tier", "father_son_tension", 
]

@onready var root: Control = %Root
@onready var title_label: Label = %Title
@onready var hint_label: Label = %Hint
@onready var tab_self: Button = %TabSelf
@onready var tab_people: Button = %TabPeople
@onready var close_btn: Button = %CloseButton
@onready var self_page: Control = %SelfPage
@onready var people_page: Control = %PeoplePage
@onready var self_body: VBoxContainer = %SelfBody
@onready var people_list: VBoxContainer = %PeopleList
@onready var detail_body: VBoxContainer = %DetailBody
@onready var portrait_slot: Control = %PortraitSlot

var _open: bool = false
var _tab: String = "self"
var _selected_npc: String = "su_qing"
var _portrait: PortraitView
var _list_buttons: Dictionary = {}


func _ready() -> void :
	add_to_group("dossier_panel")
	visible = false
	root.visible = false
	close_btn.pressed.connect(close)
	tab_self.pressed.connect( func(): _set_tab("self"))
	tab_people.pressed.connect( func(): _set_tab("people"))
	UiStyle.apply_cozy_button(close_btn)
	UiStyle.apply_cozy_button(tab_self)
	UiStyle.apply_cozy_button(tab_people)
	%Panel.add_theme_stylebox_override("panel", UiStyle.make_parchment_style())
	_portrait = PortraitView.new()
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.custom_minimum_size = Vector2(140, 180)
	portrait_slot.add_child(_portrait)
	set_process_unhandled_input(true)
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("toggle_dossier") or (
		event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C
	):
		if _open:
			close()
		else:
			if GameFlow.is_blocked():
				return
			open()
		get_viewport().set_input_as_handled()
		return
	if _open and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open(npc_id: String = "") -> void :
	_open = true
	visible = true
	root.visible = true
	GameFlow.set_minigame_open(true)
	SfxPlayer.play_click()
	TipSystem.queue_tip("tip_dossier")
	if npc_id != "":
		_selected_npc = npc_id
		_set_tab("people")
	else:
		_set_tab(_tab)
	_refresh_all()


func close() -> void :
	if not _open:
		return
	_open = false
	visible = false
	root.visible = false
	GameFlow.set_minigame_open(false)


func _on_state() -> void :
	if _open:
		_refresh_all()


func _on_locale(_l: String) -> void :
	if _open:
		_refresh_all()
	else:
		_refresh_chrome_labels()


func _set_tab(tab: String) -> void :
	_tab = tab
	self_page.visible = tab == "self"
	people_page.visible = tab == "people"
	tab_self.disabled = tab == "self"
	tab_people.disabled = tab == "people"
	_refresh_all()


func _refresh_chrome_labels() -> void :
	title_label.text = L10n.t("ui.dossier.title", "人物档案")
	hint_label.text = L10n.t("ui.dossier.hint", "C 开关 · Esc 关闭")
	close_btn.text = L10n.t("ui.dossier.close", "关闭")
	tab_self.text = L10n.t("ui.dossier.tab_self", "我")
	tab_people.text = L10n.t("ui.dossier.tab_people", "人物录")


func _refresh_all() -> void :
	_refresh_chrome_labels()
	if _tab == "self":
		_rebuild_self()
	else:
		_rebuild_people_list()
		_rebuild_detail()


func _clear(box: Node) -> void :
	for c in box.get_children():
		c.queue_free()


func _section_label(text: String, dim: bool = false) -> Label:
	var lab: = Label.new()
	lab.text = text
	lab.add_theme_font_size_override("font_size", 15 if not dim else 12)
	lab.add_theme_color_override("font_color", UiStyle.WOOD if not dim else UiStyle.TEXT_DIM)
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lab


func _body_label(text: String) -> Label:
	var lab: = Label.new()
	lab.text = text
	lab.add_theme_font_size_override("font_size", 13)
	lab.add_theme_color_override("font_color", UiStyle.TEXT)
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lab


func _rebuild_self() -> void :
	_clear(self_body)
	_portrait.set_speaker("player")
	var pname: = L10n.t("npcs.player.name", "林阿海")
	var ptitle: = L10n.t("npcs.player.title", "")
	var rank_id: = GameState.get_rank_id()
	var rank_name: = L10n.t("ui.hud.unemployed", "无职级") if rank_id.is_empty()\
	else L10n.t("ranks.%s.name" % rank_id, rank_id)
	var emp_name: = L10n.t("ui.employer.%s" % GameState.employer_id, GameState.employer_id)
	var period_name: = L10n.t("periods.%s" % GameState.period, GameState.period)
	self_body.add_child(_section_label(pname if ptitle == "" else "%s · %s" % [pname, ptitle]))
	self_body.add_child(_body_label(L10n.tf(
		"ui.dossier.day_period", 
		{"day": GameState.day, "period": period_name}, 
		"第%d日 · %s" % [GameState.day, period_name]
	)))
	self_body.add_child(_body_label("%s：%s" % [L10n.t("ui.dossier.employer", "雇主"), emp_name]))
	self_body.add_child(_body_label("%s：%s" % [L10n.t("ui.dossier.rank", "职级"), rank_name]))
	var role: = L10n.t("npcs.player.role", "")
	if role != "":
		self_body.add_child(_body_label("%s：%s" % [L10n.t("ui.dossier.field_role", "身份"), role]))
	self_body.add_child(_section_label(L10n.t("ui.dossier.section_promo", "晋升进度")))
	self_body.add_child(_promo_block())
	self_body.add_child(_section_label(L10n.t("ui.dossier.section_company", "公司与身家")))
	self_body.add_child(_section_label(L10n.t("ui.dossier.section_company_note", ""), true))
	for sid in PLAYER_STATS:
		var row: = PackDB.get_row("stats", sid)
		if row.is_empty():
			continue
		if str(row.get("hidden", "0")) in ["1", "true", "True"]:
			continue
		var label: = L10n.t("stats.%s.name" % sid, sid)

		if sid == "trust" or sid == "suspicion":
			label = L10n.tf("ui.dossier.stat_firm", {"name": label}, "%s（公司）" % label)
		var val: = GameState.get_stat(sid)
		var line: = "%s  %s" % [label, _fmt_stat(sid, val)]

		var bar_max: = 200.0 if sid == "money" else _stat_max(sid)
		self_body.add_child(_meter_row(line, val, bar_max, _stat_color(sid)))
	self_body.add_child(_section_label(L10n.t("ui.dossier.section_profile", "档案")))
	self_body.add_child(_field_block("personality", "player"))
	self_body.add_child(_field_block("motive", "player"))
	self_body.add_child(_field_block("bio", "player"))
	self_body.add_child(_field_block("background", "player"))


func _promo_block() -> Control:
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var st: Dictionary = PromotionSystem.get_status()
	if not bool(st.get("employed", false)):
		box.add_child(_body_label(str(st.get("hint", ""))))
		return box
	if bool(st.get("at_max", false)):
		box.add_child(_body_label(str(st.get("hint", ""))))
		return box
	box.add_child(_body_label(str(st.get("title", ""))))
	var cur: = float(st.get("current", 0))
	var need: = float(st.get("need", 1))
	var sname: = L10n.t("stats.%s.name" % str(st.get("stat_id", "")), str(st.get("stat_id", "")))
	box.add_child(_meter_row(
		L10n.tf(
			"ui.promo.bar_label", 
			{"stat": sname, "cur": int(cur), "need": int(need)}, 
			"%s  %d / %d" % [sname, int(cur), int(need)]
		), 
		cur, 
		maxi(need, 1.0), 
		UiStyle.BRASS if cur + 0.0001 >= need else UiStyle.WOOD_LIGHT
	))
	for c in st.get("checks", []):
		if bool(c.get("is_main", false)):
			continue
		var ok: = bool(c.get("ok", false))
		var mark: = "■" if ok else "□"
		var lab: = Label.new()
		lab.text = "%s  %s" % [mark, str(c.get("label", ""))]
		lab.add_theme_font_size_override("font_size", 12)
		lab.add_theme_color_override("font_color", UiStyle.OK if ok else UiStyle.TEXT_DIM)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(lab)
	var ready: = bool(st.get("ready", false))
	var ready_lab: = Label.new()
	if ready:
		ready_lab.text = "■  " + L10n.t("ui.promo.ready_line", "可申请晋升（条件已齐）")
		ready_lab.add_theme_color_override("font_color", UiStyle.OK)
	else:
		ready_lab.text = "□  " + str(st.get("hint", ""))
		ready_lab.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	ready_lab.add_theme_font_size_override("font_size", 12)
	ready_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(ready_lab)
	return box


func _fmt_stat(stat_id: String, v: float) -> String:
	var tier: = int(v)
	if stat_id == "vehicle_tier":
		return L10n.t("vehicle.tier.%d" % tier, str(tier))
	if stat_id == "home_tier":
		var ht: = clampi(tier, 1, 4)
		return L10n.t("locations.home.t%d" % ht, str(ht))
	if absf(v - roundf(v)) < 0.05:
		return "%d" % int(round(v))
	return "%.1f" % v


func _stat_max(stat_id: String) -> float:
	var row: = PackDB.get_row("stats", stat_id)
	if row.is_empty():
		return 100.0
	return maxf(1.0, float(row.get("max", 100)))


func _stat_color(stat_id: String) -> Color:
	if stat_id == "suspicion" or stat_id == "father_son_tension":
		return UiStyle.DANGER
	if stat_id == "money":
		return UiStyle.BRASS
	return UiStyle.WOOD_LIGHT


func _rebuild_people_list() -> void :
	_clear(people_list)
	_list_buttons.clear()
	_add_group_header(L10n.t("ui.dossier.group_story", "主线人物"))
	for id in STORY_NPCS:
		_add_npc_button(id)
	_add_group_header(L10n.t("ui.dossier.group_harbor", "港区人物"))
	for id in HARBOR_NPCS:
		_add_npc_button(id)
	if not _list_buttons.has(_selected_npc):
		_selected_npc = STORY_NPCS[0]
	_highlight_list()


func _add_group_header(text: String) -> void :
	var lab: = Label.new()
	lab.text = text
	lab.add_theme_font_size_override("font_size", 12)
	lab.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	people_list.add_child(lab)


func _add_npc_button(npc_id: String) -> void :
	var btn: = Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 36)
	var favor: = GameState.get_relation(npc_id, "player", "favor")
	var nm: = L10n.t("npcs.%s.name" % npc_id, npc_id)
	btn.text = "●  %s" % nm
	btn.add_theme_color_override("font_color", _favor_dot_color(favor))
	UiStyle.apply_cozy_button(btn)
	btn.pressed.connect(_select_npc.bind(npc_id))
	people_list.add_child(btn)
	_list_buttons[npc_id] = btn


func _favor_dot_color(favor: float) -> Color:
	if favor < 20.0:
		return Color("7a7068")
	if favor < 40.0:
		return Color("9a8060")
	if favor < 60.0:
		return UiStyle.WOOD_LIGHT
	if favor < 80.0:
		return Color("c4a060")
	return UiStyle.BRASS


func _select_npc(npc_id: String) -> void :
	_selected_npc = npc_id
	_highlight_list()
	_rebuild_detail()
	SfxPlayer.play_click()


func _highlight_list() -> void :
	for id in _list_buttons.keys():
		var btn: Button = _list_buttons[id]
		btn.disabled = str(id) == _selected_npc


func _rebuild_detail() -> void :
	_clear(detail_body)
	var id: = _selected_npc
	_portrait.set_speaker(id)
	var nm: = L10n.t("npcs.%s.name" % id, id)
	var title: = L10n.t("npcs.%s.title" % id, "")
	var role: = L10n.t("npcs.%s.role" % id, "")
	detail_body.add_child(_section_label(nm if title == "" else "%s · %s" % [nm, title]))
	if role != "":
		detail_body.add_child(_body_label("%s：%s" % [L10n.t("ui.dossier.field_role", "身份"), role]))
	var faction: = GameState.get_npc_faction(id)
	if faction != "":
		var fac_name: = L10n.t("ui.dossier.faction_%s" % faction, faction)
		detail_body.add_child(_body_label("%s：%s" % [L10n.t("ui.dossier.faction", "阵营"), fac_name]))


	detail_body.add_child(_section_label(L10n.t("ui.dossier.section_traits", "人物属性")))
	for trait_id in ["influence", "nerve", "gossip", "temper", "means"]:
		var tv: = GameState.get_npc_trait(id, trait_id)
		var tlabel: = L10n.t("ui.dossier.trait_%s" % trait_id, trait_id)
		var col: = UiStyle.WOOD_LIGHT
		if trait_id == "temper":
			col = UiStyle.DANGER
		elif trait_id == "gossip":
			col = Color("6a8a70")
		elif trait_id == "influence":
			col = UiStyle.BRASS
		detail_body.add_child(_meter_row("%s  %d" % [tlabel, int(round(tv))], tv, 100.0, col))

	detail_body.add_child(_section_label(L10n.t("ui.dossier.section_relations", "对你的态度")))
	detail_body.add_child(_section_label(L10n.t("ui.dossier.section_relations_note", ""), true))
	detail_body.add_child(_relation_meter(id, "favor"))
	detail_body.add_child(_relation_meter(id, "trust"))
	detail_body.add_child(_relation_meter(id, "suspicion"))


	detail_body.add_child(_section_label(L10n.t("ui.dossier.section_web", "人物关系")))
	detail_body.add_child(_section_label(L10n.t("ui.dossier.section_web_note", ""), true))
	var web: = GameState.list_npc_web(id)
	if web.is_empty():
		detail_body.add_child(_section_label("—", true))
	else:
		for edge in web:
			var other: = str(edge.get("other_id", ""))
			var rkey: = str(edge.get("relation_key", ""))
			var val: = float(edge.get("value", 0))
			var other_name: = L10n.t("npcs.%s.name" % other, other)
			var rel_name: = L10n.t("ui.dossier.rel_%s" % rkey, rkey)
			if rkey == "intimacy":
				rel_name = L10n.t("ui.dossier.rel_intimacy", "亲密")
			elif rkey == "father_son_trust":
				rel_name = L10n.t("ui.dossier.rel_father_son", "父子信任")
			var line: = L10n.tf(
				"ui.dossier.web_edge", 
				{"name": other_name, "rel": rel_name, "n": int(round(val))}, 
				"%s · %s %d" % [other_name, rel_name, int(round(val))]
			)
			var wcol: = UiStyle.DANGER if rkey == "suspicion" else (Color("8a6a7a") if rkey == "intimacy" else UiStyle.WOOD)
			detail_body.add_child(_meter_row(line, val, 100.0, wcol))

	detail_body.add_child(_section_label(L10n.t("ui.dossier.section_profile", "档案")))
	detail_body.add_child(_field_block("disposition", id))
	detail_body.add_child(_field_block("personality", id))
	detail_body.add_child(_field_block("motive", id))
	detail_body.add_child(_field_block("bio", id))
	detail_body.add_child(_field_block("background", id))

	detail_body.add_child(_section_label(L10n.t("ui.dossier.section_log", "往来记录")))
	var logs: = GameState.get_relation_log_for(id)
	if logs.is_empty():
		detail_body.add_child(_section_label(L10n.t("ui.dossier.log_empty", "尚未留下可载入册的往来。"), true))
	else:
		for e in logs:
			var period_name: = L10n.t("periods.%s" % str(e.get("period", "")), str(e.get("period", "")))
			var head: = L10n.tf(
				"ui.dossier.day_period", 
				{"day": int(e.get("day", 1)), "period": period_name}, 
				"第%d日 · %s" % [int(e.get("day", 1)), period_name]
			)
			var params: Dictionary = e.get("params", {})
			var body: = L10n.tf(str(e.get("text_key", "")), params, str(e.get("text_key", "")))
			var kind: = str(e.get("kind", ""))
			var prefix: = ""
			if kind == "world":
				prefix = "〔巷闻〕"
			elif kind == "street":
				prefix = "〔街访〕"
			elif kind == "flag":
				prefix = "〔私账〕"
			var entry: = Label.new()
			entry.text = "· [%s] %s%s" % [head, prefix, body]
			entry.add_theme_font_size_override("font_size", 12)
			entry.add_theme_color_override("font_color", UiStyle.TEXT if kind != "world" else Color("5a4a38"))
			entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			detail_body.add_child(entry)


func _field_block(field: String, npc_id: String) -> Control:
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var key_map: = {
		"personality": "ui.dossier.field_personality", 
		"motive": "ui.dossier.field_motive", 
		"bio": "ui.dossier.field_bio", 
		"background": "ui.dossier.field_background", 
		"disposition": "ui.dossier.field_disposition", 
	}
	var label_key: = str(key_map.get(field, field))
	var fallbacks: = {
		"personality": "性情", 
		"motive": "所求", 
		"bio": "简介", 
		"background": "背景", 
		"disposition": "对你", 
	}
	var head: = _section_label(L10n.t(label_key, str(fallbacks.get(field, field))), true)
	box.add_child(head)
	var text: = L10n.t("npcs.%s.%s" % [npc_id, field], "")
	if text == "" and field == "disposition":
		text = L10n.t("npcs.%s.initial_relation_to_player" % npc_id, "")
	if text == "":
		text = "—"
	box.add_child(_body_label(text))
	return box


func _relation_meter(npc_id: String, key: String) -> Control:
	var v: = GameState.get_relation(npc_id, "player", key)
	var name_key: = "ui.dossier.rel_%s" % key
	var fallback: = key
	match key:
		"favor":
			fallback = "好感"
		"trust":
			fallback = "信任"
		"suspicion":
			fallback = "疑心"
	var label: = "%s  %d · %s" % [
		L10n.t(name_key, fallback), 
		int(round(v)), 
		_tier_label(key, v), 
	]
	var col: = UiStyle.BRASS if key == "favor" else (UiStyle.WOOD_LIGHT if key == "trust" else UiStyle.DANGER)
	return _meter_row(label, v, 100.0, col)


func _tier_label(kind: String, v: float) -> String:
	var idx: = 0
	if v >= 80.0:
		idx = 4
	elif v >= 60.0:
		idx = 3
	elif v >= 40.0:
		idx = 2
	elif v >= 20.0:
		idx = 1
	else:
		idx = 0
	var prefix: = "favor"
	if kind == "trust":
		prefix = "trust"
	elif kind == "suspicion":
		prefix = "suspicion"
	return L10n.t("ui.dossier.%s_tier_%d" % [prefix, idx], str(idx))


func _meter_row(label: String, value: float, max_v: float, fill: Color) -> Control:
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var lab: = Label.new()
	lab.text = label
	lab.add_theme_font_size_override("font_size", 13)
	lab.add_theme_color_override("font_color", UiStyle.TEXT)
	box.add_child(lab)
	var track: = ProgressBar.new()
	track.min_value = 0
	track.max_value = max_v
	track.value = clampf(value, 0.0, max_v)
	track.show_percentage = false
	track.custom_minimum_size = Vector2(0, 12)
	var bg: = StyleBoxFlat.new()
	bg.bg_color = Color(0.85, 0.78, 0.65, 1)
	bg.set_corner_radius_all(4)
	var fg: = StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(4)
	track.add_theme_stylebox_override("background", bg)
	track.add_theme_stylebox_override("fill", fg)
	box.add_child(track)
	return box
