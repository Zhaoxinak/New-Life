extends CanvasLayer



const UNLOCK_PATH: = "user://qa_forge.cfg"
const F3_BURST_NEED: = 5
const F3_BURST_WINDOW_MS: = 2200
const KONAMI: Array[int] = [
	KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, 
	KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, 
	KEY_B, KEY_A, 
]

const QUICK_STATS: = [
	"money", "network_elite", "network_base", "trust", "suspicion", "intel", 
	"father_son_tension", "company_share", "vehicle_tier", "home_tier", 
	"stock_price", 
]

const STAT_LABELS_ZH: = {
	"money": "金钱", 
	"network_elite": "声望", 
	"network_base": "基层人脉", 
	"trust": "公司信任度", 
	"suspicion": "嫌疑", 
	"intel": "情报", 
	"father_son_tension": "父子张力", 
	"company_share": "公司份额", 
	"vehicle_tier": "座驾档次", 
	"home_tier": "住所档次", 
	"stock_price": "股价", 
}
const STAT_LABELS_EN: = {
	"money": "Money", 
	"network_elite": "Reputation", 
	"network_base": "Street network", 
	"trust": "Company trust", 
	"suspicion": "Suspicion", 
	"intel": "Intel", 
	"father_son_tension": "Father–son tension", 
	"company_share": "Company share", 
	"vehicle_tier": "Vehicle tier", 
	"home_tier": "Home tier", 
	"stock_price": "Stock price", 
}

@onready var root: PanelContainer = %Root
@onready var content: VBoxContainer = %Content

var _unlocked: bool = false
var _konami_i: int = 0
var _f3_times: Array[int] = []

var _ui_locale: String = "zh_CN"
var _built: bool = false

var _title: Label
var _info: RichTextLabel
var _locale_btn: Button
var _day_spin: SpinBox
var _stat_pick: OptionButton
var _stat_spin: SpinBox
var _flag_edit: LineEdit
var _flag_spin: SpinBox
var _loc_pick: OptionButton
var _rel_npc: OptionButton
var _rel_spin: SpinBox
var _labels: Dictionary = {}


func _ready() -> void :
	visible = false
	root.visible = false
	layer = 50
	_ui_locale = L10n.locale if L10n.locale != "" else "zh_CN"
	_load_unlock()
	_build_ui()
	_apply_ui_texts()
	if not GameState.state_changed.is_connected(_refresh):
		GameState.state_changed.connect(_refresh)
	if not L10n.locale_changed.is_connected(_on_game_locale):
		L10n.locale_changed.connect(_on_game_locale)


func _on_game_locale(locale: String) -> void :

	_ui_locale = locale
	_apply_ui_texts()
	_refresh()


func _load_unlock() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(UNLOCK_PATH) == OK:
		_unlocked = bool(cfg.get_value("forge", "unlocked", false))


func _save_unlock() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("forge", "unlocked", true)
	cfg.save(UNLOCK_PATH)


func _grant_unlock(open_now: bool = false) -> void :
	var was: = _unlocked
	_unlocked = true
	_save_unlock()
	_konami_i = 0
	_f3_times.clear()
	if not was:
		SfxPlayer.play_success()
	if open_now:
		_set_open(true)


func _set_open(on: bool) -> void :
	if not _unlocked:
		return
	visible = on
	root.visible = on
	if on:
		_rebuild_dynamic_lists()
		_refresh()


func _tr(key: String, zh: String, en: String) -> String:

	if _ui_locale == L10n.locale:
		var pack: = L10n.t(key, "")
		if pack != "" and pack != key:
			return pack
	return en if _ui_locale == "en" else zh


func _build_ui() -> void :
	if _built:
		return
	_built = true
	for c in content.get_children():
		c.queue_free()

	_title = _add_label("title", 18)
	_info = RichTextLabel.new()
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(0, 96)
	content.add_child(_info)

	var loc_row: = _row()
	_locale_btn = _btn("locale", loc_row)
	_locale_btn.pressed.connect(_toggle_ui_locale)
	var sync_btn: = _btn("sync_locale", loc_row)
	sync_btn.pressed.connect(_sync_game_locale)

	_section("sec_time")
	var day_row: = _row()
	_day_spin = SpinBox.new()
	_day_spin.min_value = 1
	_day_spin.max_value = GameState.MAX_DAY
	_day_spin.value = 1
	_day_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_row.add_child(_day_spin)
	_btn("set_day", day_row).pressed.connect(_on_set_day)
	_btn("period", content).pressed.connect( func(): GameState.advance_period();_refresh())
	_btn("weather", content).pressed.connect(_cycle_weather)

	_section("sec_stat")
	_stat_pick = OptionButton.new()
	content.add_child(_stat_pick)
	_rebuild_stat_pick()
	_stat_pick.item_selected.connect( func(_i): _pull_stat_spin())
	var stat_row: = _row()
	_stat_spin = SpinBox.new()
	_stat_spin.min_value = -99999
	_stat_spin.max_value = 99999
	_stat_spin.step = 1
	_stat_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stat_spin.rounded = true
	stat_row.add_child(_stat_spin)
	_btn("stat_set", stat_row).pressed.connect(_on_stat_set)
	var adj: = _row()
	_btn("stat_m10", adj).pressed.connect( func(): _stat_delta(-10))
	_btn("stat_p10", adj).pressed.connect( func(): _stat_delta(10))
	_btn("stat_p100", adj).pressed.connect( func(): _stat_delta(100))
	var presets: = _row()
	_btn("money_500", presets).pressed.connect( func(): GameState.set_stat("money", 500);_refresh())
	_btn("money_9999", presets).pressed.connect( func(): GameState.set_stat("money", 9999);_refresh())
	var presets2: = _row()
	_btn("fame_50", presets2).pressed.connect( func(): GameState.set_stat("network_elite", 50);_refresh())
	_btn("fame_100", presets2).pressed.connect( func(): GameState.set_stat("network_elite", 100);_refresh())
	var presets3: = _row()
	_btn("sus_0", presets3).pressed.connect( func(): GameState.set_stat("suspicion", 0);_refresh())
	_btn("sus_40", presets3).pressed.connect( func(): GameState.set_stat("suspicion", 40);_refresh())
	_btn("tension_75", presets3).pressed.connect( func(): GameState.set_stat("father_son_tension", 75);_refresh())

	_section("sec_vehicle")
	var vrow: = _row()
	_btn("vehicle_up", vrow).pressed.connect(_cycle_vehicle)
	_btn("mount", vrow).pressed.connect(_toggle_mount)

	_section("sec_world")
	_loc_pick = OptionButton.new()
	content.add_child(_loc_pick)
	var wrow: = _row()
	_btn("goto_loc", wrow).pressed.connect(_goto_location)
	_btn("unlock_all", wrow).pressed.connect(_unlock_all)

	_section("sec_flag")
	_flag_edit = LineEdit.new()
	_flag_edit.placeholder_text = "flag_id"
	content.add_child(_flag_edit)
	var frow: = _row()
	_flag_spin = SpinBox.new()
	_flag_spin.min_value = 0
	_flag_spin.max_value = 99
	_flag_spin.value = 1
	_flag_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frow.add_child(_flag_spin)
	_btn("flag_set", frow).pressed.connect(_on_flag_set)
	_btn("flag_get", frow).pressed.connect(_on_flag_get)

	_section("sec_rel")
	_rel_npc = OptionButton.new()
	content.add_child(_rel_npc)
	var rrow: = _row()
	_rel_spin = SpinBox.new()
	_rel_spin.min_value = 0
	_rel_spin.max_value = 100
	_rel_spin.value = 50
	_rel_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rrow.add_child(_rel_spin)
	_btn("rel_set", rrow).pressed.connect(_on_rel_set)

	_section("sec_story")
	_btn("pulse", content).pressed.connect( func(): EventScheduler.pulse();_refresh())
	_btn("force_b", content).pressed.connect(_force_b)

	_pull_stat_spin()


func _section(id: String) -> void :
	var lab: = _add_label(id, 14)
	lab.add_theme_color_override("font_color", Color(0.55, 0.42, 0.28))


func _add_label(id: String, size: int) -> Label:
	var lab: = Label.new()
	lab.add_theme_font_size_override("font_size", size)
	content.add_child(lab)
	_labels[id] = lab
	return lab


func _row() -> HBoxContainer:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)
	return row


func _btn(id: String, parent: Node) -> Button:
	var b: = Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 30)
	parent.add_child(b)
	_labels[id] = b
	UiStyle.apply_cozy_button(b)
	return b


func _apply_ui_texts() -> void :
	_set_text("title", "调试工坊 (F3)", "Debug Forge (F3)")
	var loc_btn: Button = _labels.get("locale") as Button
	if loc_btn:
		loc_btn.text = "Panel: EN → 中文" if _ui_locale == "en" else "面板: 中文 → EN"
	_set_text("sync_locale", "同步游戏语言", "Sync game locale")
	_set_text("sec_time", "— 时间 / Time —", "— Time —")
	_set_text("set_day", "设日期", "Set day")
	_set_text("period", "推进时段 (F5)", "Advance period (F5)")
	_set_text("weather", "切换天气 (F4)", "Cycle weather (F4)")
	_set_text("sec_stat", "— 数值 / Stats —", "— Stats —")
	_set_text("stat_set", "写入", "Set")
	_set_text("stat_m10", "-10", "-10")
	_set_text("stat_p10", "+10", "+10")
	_set_text("stat_p100", "+100", "+100")
	_set_text("money_500", "银元500", "Money 500")
	_set_text("money_9999", "银元9999", "Money 9999")
	_set_text("fame_50", "声望50", "Rep 50")
	_set_text("fame_100", "声望100", "Rep 100")
	_set_text("sus_0", "嫌疑0", "Sus 0")
	_set_text("sus_40", "嫌疑40", "Sus 40")
	_set_text("tension_75", "张力75", "Tension 75")
	_set_text("sec_vehicle", "— 载具 / Ride —", "— Ride —")
	_set_text("vehicle_up", "座驾+1档", "Vehicle +1")
	_set_text("mount", "上车/下车", "Mount / Dismount")
	_set_text("sec_world", "— 地图 / World —", "— World —")
	_set_text("goto_loc", "传送到地点", "Go to location")
	_set_text("unlock_all", "解锁全部", "Unlock all")
	_set_text("sec_flag", "— 旗标 / Flags —", "— Flags —")
	_set_text("flag_set", "设旗标", "Set flag")
	_set_text("flag_get", "读旗标", "Read flag")
	_set_text("sec_rel", "— 好感 / Favor —", "— Favor —")
	_set_text("rel_set", "设对玩家好感", "Set favor→player")
	_set_text("sec_story", "— 剧情 / Story —", "— Story —")
	_set_text("pulse", "脉冲事件", "Pulse events")
	_set_text("force_b", "强制B线对立就绪", "Force B clash ready")
	if _flag_edit:
		_flag_edit.placeholder_text = _tr("debug.flag_ph", "旗标 id", "flag id")
	_rebuild_stat_pick()
	_rebuild_dynamic_lists()


func _set_text(id: String, zh: String, en: String) -> void :
	var node: Control = _labels.get(id)
	if node == null:
		return
	var text: = _tr("debug.%s" % id, zh, en)
	if node is Button:
		(node as Button).text = text
	elif node is Label:
		(node as Label).text = text


func _toggle_ui_locale() -> void :
	_ui_locale = "en" if _ui_locale == "zh_CN" else "zh_CN"
	_apply_ui_texts()
	_refresh()


func _sync_game_locale() -> void :
	L10n.set_locale(_ui_locale)
	_apply_ui_texts()
	_refresh()


func _stat_label(sid: String) -> String:

	if sid == "network_elite":
		return _tr("ui.hud.network", "声望", "Reputation")
	var pack_key: = "stats.%s.name" % sid
	if _ui_locale == L10n.locale:
		var pack: = L10n.t(pack_key, "")
		if pack != "" and pack != pack_key:
			return pack
	if _ui_locale == "en":
		return str(STAT_LABELS_EN.get(sid, sid))
	return str(STAT_LABELS_ZH.get(sid, sid))


func _rebuild_stat_pick() -> void :
	if _stat_pick == null:
		return
	var prev: = _selected_stat_id()
	_stat_pick.clear()
	var i: = 0
	var sel: = 0
	for sid in QUICK_STATS:
		var label: = "%s  ·  %s" % [_stat_label(sid), sid]
		_stat_pick.add_item(label, i)
		_stat_pick.set_item_metadata(i, sid)
		if sid == prev:
			sel = i
		i += 1
	if _stat_pick.item_count > 0:
		_stat_pick.select(sel)


func _selected_stat_id() -> String:
	if _stat_pick == null or _stat_pick.item_count <= 0:
		return "money"
	var meta = _stat_pick.get_item_metadata(_stat_pick.selected)
	if meta == null:
		return "money"
	return str(meta)


func _rebuild_dynamic_lists() -> void :
	if _loc_pick == null:
		return
	_rebuild_stat_pick()
	var loc_sel: = _loc_pick.selected if _loc_pick.item_count > 0 else 0
	_loc_pick.clear()
	var i: = 0
	for row in PackDB.get_enabled_locations():
		var id: = str(row.get("id", ""))
		if id == "":
			continue
		var nm: = _loc_label(id)
		_loc_pick.add_item("%s  ·  %s" % [nm, id], i)
		_loc_pick.set_item_metadata(i, id)
		i += 1
	if _loc_pick.item_count > 0:
		_loc_pick.select(clampi(loc_sel, 0, _loc_pick.item_count - 1))

	var rel_sel: = _rel_npc.selected if _rel_npc.item_count > 0 else 0
	_rel_npc.clear()
	var j: = 0
	for row in PackDB.get_table("npcs"):
		var nid: = str(row.get("id", ""))
		if nid == "" or nid == "player":
			continue
		var nn: = L10n.t("npcs.%s.name" % nid, nid)
		if _ui_locale == "en" and L10n.locale != "en":
			nn = nid
		_rel_npc.add_item("%s  ·  %s" % [nn, nid], j)
		_rel_npc.set_item_metadata(j, nid)
		j += 1
	if _rel_npc.item_count > 0:
		_rel_npc.select(clampi(rel_sel, 0, _rel_npc.item_count - 1))
	_pull_stat_spin()


func _loc_label(id: String) -> String:
	return L10n.t("locations.%s.name" % id, id)


func _pull_stat_spin() -> void :
	if _stat_pick == null or _stat_spin == null:
		return
	var sid: = _selected_stat_id()
	_stat_spin.value = GameState.get_stat(sid)
	var row: = PackDB.get_row("stats", sid)
	if not row.is_empty():
		_stat_spin.min_value = float(row.get("min", -99999))
		_stat_spin.max_value = float(row.get("max", 99999))


func _refresh() -> void :
	if not visible or not _unlocked or _info == null:
		return
	var vt: = int(GameState.get_stat("vehicle_tier"))
	var ride: = L10n.t("vehicle.tier.%d" % vt, str(vt))
	var mounted: = false
	var host: = get_tree().get_first_node_in_group("world_host")
	if host and host.has_method("is_mounted"):
		mounted = host.is_mounted()
	var hint: = _tr(
		"debug.hotkeys", 
		"[F3]开关  [F4]天气  [F5]时段", 
		"[F3] toggle  [F4] weather  [F5] period"
	)
	var fame_n: = _stat_label("network_elite")
	_info.text = (
		"day=%d %s wx=%s loc=%s\n"
		+ "money=%d %s=%d trust=%d tyT=%d sus=%d intel=%d\n"
		+ "emp=%s ride=%s mounted=%s rank=%s ending=%s\n%s"
	) % [
		GameState.day, GameState.period, GameState.weather, GameState.location_id, 
		int(GameState.get_stat("money")), fame_n, int(GameState.get_stat("network_elite")), 
		int(GameState.get_stat("trust")), int(GameState.get_stat("tongyang_trust")), 
		int(GameState.get_stat("suspicion")), int(GameState.get_stat("intel")), 
		GameState.employer_id, ride, str(mounted), 
		GameState.get_rank_id(), GameState.active_ending_id, 
		hint, 
	]
	_day_spin.value = GameState.day
	_pull_stat_spin()


func _unhandled_input(event: InputEvent) -> void :
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: = event as InputEventKey
	var code: = k.keycode if k.keycode != KEY_NONE else k.physical_keycode


	if k.ctrl_pressed and k.shift_pressed and code == KEY_F3:
		_grant_unlock(true)
		get_viewport().set_input_as_handled()
		return

	if code == KEY_F3 and not k.ctrl_pressed and not k.shift_pressed and not k.alt_pressed:
		if _unlocked:
			_set_open( not visible)
		else:
			_note_f3_burst()
		get_viewport().set_input_as_handled()
		return

	if _feed_konami(code):
		get_viewport().set_input_as_handled()
		return

	if not _unlocked:
		return

	match code:
		KEY_F4:
			_cycle_weather()
			get_viewport().set_input_as_handled()
		KEY_F5:
			GameState.advance_period()
			_refresh()
			get_viewport().set_input_as_handled()


func _note_f3_burst() -> void :
	var now: = Time.get_ticks_msec()
	_f3_times.append(now)
	while not _f3_times.is_empty() and now - _f3_times[0] > F3_BURST_WINDOW_MS:
		_f3_times.remove_at(0)
	if _f3_times.size() >= F3_BURST_NEED:
		_grant_unlock(true)


func _feed_konami(code: int) -> bool:
	var normalized: = code
	match code:
		KEY_UP, KEY_KP_8:
			normalized = KEY_UP
		KEY_DOWN, KEY_KP_2:
			normalized = KEY_DOWN
		KEY_LEFT, KEY_KP_4:
			normalized = KEY_LEFT
		KEY_RIGHT, KEY_KP_6:
			normalized = KEY_RIGHT
		KEY_B:
			normalized = KEY_B
		KEY_A:
			normalized = KEY_A
		_:
			if _konami_i > 0:
				_konami_i = 0
			return false
	if normalized == KONAMI[_konami_i]:
		_konami_i += 1
		if _konami_i >= KONAMI.size():
			_grant_unlock(true)
			return true
		return true
	if normalized == KONAMI[0]:
		_konami_i = 1
		return true
	_konami_i = 0
	return false


func _on_set_day() -> void :
	GameState.day = int(_day_spin.value)
	UnlockScheduler.apply_up_to_day(GameState.day)
	WeatherSystem.apply_for_current(false)
	_refresh()


func _on_stat_set() -> void :
	var sid: = _selected_stat_id()
	GameState.set_stat(sid, float(_stat_spin.value))
	_after_vehicle_stat(sid)
	_refresh()


func _stat_delta(d: float) -> void :
	var sid: = _selected_stat_id()
	GameState.add_stat(sid, d)
	_after_vehicle_stat(sid)
	_refresh()


func _after_vehicle_stat(sid: String) -> void :
	if sid != "vehicle_tier":
		return
	var host: = get_tree().get_first_node_in_group("world_host")
	if host and host.has_method("is_mounted") and host.is_mounted() and int(GameState.get_stat("vehicle_tier")) < 1:
		host.dismount_vehicle()
	if host and host.outdoor and host.outdoor.has_method("_refresh_vehicle_prop"):
		host.outdoor._refresh_vehicle_prop()


func _cycle_weather() -> void :
	var order: Array[String] = ["clear", "cloudy", "rain", "storm"]
	var idx: = order.find(str(GameState.weather))
	if idx < 0:
		idx = 0
	WeatherSystem.set_weather_now(order[(idx + 1) % order.size()])
	_refresh()


func _cycle_vehicle() -> void :
	var vt: = (int(GameState.get_stat("vehicle_tier")) + 1) % 5
	GameState.set_stat("vehicle_tier", float(vt))
	_after_vehicle_stat("vehicle_tier")
	_refresh()


func _toggle_mount() -> void :
	var host: = get_tree().get_first_node_in_group("world_host")
	if host == null:
		return
	if host.has_method("is_mounted") and host.is_mounted():
		host.dismount_vehicle()
	elif host.has_method("mount_vehicle"):
		if str(host.get("mode")) != "outdoor" and host.has_method("exit_interior"):
			host.exit_interior()
		host.mount_vehicle()
	_refresh()


func _goto_location() -> void :
	if _loc_pick.item_count <= 0:
		return
	var id: = str(_loc_pick.get_item_metadata(_loc_pick.selected))
	if id == "":
		return
	GameState.unlocked_locations[id] = true
	var host: = get_tree().get_first_node_in_group("world_host")
	if host == null:
		return
	if host.has_method("is_mounted") and host.is_mounted():
		host.dismount_vehicle()
	if str(host.get("mode")) == "interior" and host.has_method("exit_interior"):
		host.exit_interior()
	if host.outdoor == null:
		return
	var dest: = Vector2.ZERO
	if host.outdoor.has_method("get_spawn_for"):
		dest = host.outdoor.get_spawn_for(id)
	elif host.outdoor.has_method("get_default_spawn"):
		dest = host.outdoor.get_default_spawn()
	if host.player:
		host.player.global_position = dest
	GameState.location_id = ""
	GameState.state_changed.emit()
	if host.has_method("refresh_after_action"):
		host.refresh_after_action()
	_refresh()


func _unlock_all() -> void :
	UnlockScheduler.apply_up_to_day(GameState.MAX_DAY)
	for row in PackDB.get_table("locations"):
		var id: = str(row.get("id", ""))
		if id != "":
			GameState.unlocked_locations[id] = true
	for row in PackDB.get_table("hotspots"):
		var id2: = str(row.get("id", ""))
		if id2 != "":
			GameState.unlocked_hotspots[id2] = true
	GameState.state_changed.emit()
	var host: = get_tree().get_first_node_in_group("world_host")
	if host and host.has_method("refresh_after_action"):
		host.refresh_after_action()
	_rebuild_dynamic_lists()
	_refresh()


func _on_flag_set() -> void :
	var fid: = _flag_edit.text.strip_edges()
	if fid == "":
		return
	GameState.set_flag(fid, int(_flag_spin.value))
	_refresh()


func _on_flag_get() -> void :
	var fid: = _flag_edit.text.strip_edges()
	if fid == "":
		return
	_flag_spin.value = GameState.get_flag(fid, 0)
	_refresh()


func _on_rel_set() -> void :
	if _rel_npc.item_count <= 0:
		return
	var nid: = str(_rel_npc.get_item_metadata(_rel_npc.selected))
	if nid == "":
		return
	GameState.set_relation(nid, "player", "favor", float(_rel_spin.value))
	_refresh()


func _force_b() -> void :
	GameState.set_flag("route_focus_b", 1)
	GameState.set_stat("father_son_tension", 75.0)
	GameState.set_relation("su_qing", "player", "favor", 60.0)
	GameState.set_flag("ending_show_b", 0)
	EventScheduler.pulse()
	_refresh()
