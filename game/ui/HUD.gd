extends Control



@onready var day_label: Label = %DayLabel
@onready var period_label: Label = %PeriodLabel
@onready var weather_label: Label = %WeatherLabel
@onready var money_label: Label = %MoneyLabel
@onready var trust_label: Label = %TrustLabel
@onready var suspicion_label: Label = %SuspicionLabel
@onready var intel_label: Label = %IntelLabel
@onready var network_label: Label = %NetworkLabel
@onready var rank_label: Label = %RankLabel
@onready var mood_label: Label = %MoodLabel

var _clock_label: Label
var _speed_row: HBoxContainer
var _speed_btns: Dictionary = {} ## float speed -> Button

## Display order: rates first, pause last (matches player request).
const SPEED_BUTTONS: Array[float] = [0.5, 1.0, 2.0, 4.0, 0.0]

const NOVICE_UNTIL_DAY: = 3


func _ready() -> void :
	if not GameState.state_changed.is_connected(_refresh):
		GameState.state_changed.connect(_refresh)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)
	if WorldClock:
		if not WorldClock.speed_changed.is_connected(_on_speed):
			WorldClock.speed_changed.connect(_on_speed)
		if not WorldClock.clock_ticked.is_connected(_on_clock_tick):
			WorldClock.clock_ticked.connect(_on_clock_tick)
	if not GameFlow.block_changed.is_connected(_on_block):
		GameFlow.block_changed.connect(_on_block)
	_ensure_clock_controls()
	network_label.visible = false
	for lab in [trust_label, suspicion_label, intel_label, money_label, rank_label, mood_label]:
		lab.mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh()


func _ensure_clock_controls() -> void :
	var row: = day_label.get_parent() as HBoxContainer
	if row == null:
		return
	if _clock_label == null:
		_clock_label = Label.new()
		_clock_label.name = "ClockLabel"
		_clock_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78, 1))
		_clock_label.add_theme_font_size_override("font_size", 15)
		row.add_child(_clock_label)
		row.move_child(_clock_label, period_label.get_index() + 1)
	if _speed_row == null:
		_speed_row = HBoxContainer.new()
		_speed_row.name = "SpeedRow"
		_speed_row.add_theme_constant_override("separation", 3)
		row.add_child(_speed_row)
		row.move_child(_speed_row, _clock_label.get_index() + 1)
		for spd in SPEED_BUTTONS:
			var btn: = Button.new()
			btn.name = "Speed_%s" % _speed_key(spd)
			btn.focus_mode = Control.FOCUS_NONE
			btn.custom_minimum_size = Vector2(52 if spd <= 0.0 else 40, 26)
			btn.add_theme_font_size_override("font_size", 13)
			btn.text = _speed_label(spd)
			btn.pressed.connect(_on_speed_picked.bind(spd))
			_speed_row.add_child(btn)
			_speed_btns[spd] = btn


func _speed_key(spd: float) -> String:
	if spd <= 0.0:
		return "pause"
	if is_equal_approx(spd, floorf(spd)):
		return str(int(spd))
	return str(spd).replace(".", "_")


func _speed_label(spd: float) -> String:
	if spd <= 0.0:
		return L10n.t("ui.hud.speed_paused", "暂停")
	if is_equal_approx(spd, floorf(spd)):
		return "%dx" % int(spd)
	return "%.1fx" % spd


func _on_speed(_s: float) -> void :
	_refresh_speed_btns()


func _on_block(_blocked: bool) -> void :
	_refresh_speed_btns()


func _on_clock_tick() -> void :
	if _clock_label:
		_clock_label.text = WorldClock.clock_hhmm()


func _on_speed_picked(spd: float) -> void :
	SfxPlayer.play_click()
	if WorldClock:
		WorldClock.set_speed(spd)


func _refresh_speed_btns() -> void :
	if _speed_btns.is_empty() or WorldClock == null:
		return
	var cur: = WorldClock.time_speed
	var soft_pause: = WorldClock.effective_speed() <= 0.0 and cur > 0.0
	var tip_base: = L10n.t("ui.hud.speed_tip", "点选时间倍速；小键盘 +/- 也可调")
	for spd in SPEED_BUTTONS:
		var btn: Button = _speed_btns.get(spd)
		if btn == null:
			continue
		btn.text = _speed_label(spd)
		var selected: = is_equal_approx(spd, cur)
		_apply_speed_btn_style(btn, selected)
		if spd <= 0.0:
			btn.tooltip_text = L10n.t("ui.hud.speed_pause_pick_tip", "暂停世界时间")
		elif soft_pause and selected:
			btn.tooltip_text = L10n.t("ui.hud.speed_paused_tip", "对话/事件中，时间暂停。")
		else:
			btn.tooltip_text = tip_base


func _apply_speed_btn_style(btn: Button, selected: bool) -> void :
	var normal: = UiStyle.make_button_style(true)
	var hover: = UiStyle.make_button_style(false)
	for s in [normal, hover]:
		s.content_margin_left = 6
		s.content_margin_right = 6
		s.content_margin_top = 3
		s.content_margin_bottom = 3
		s.set_corner_radius_all(4)
		s.set_border_width_all(2)
	if selected:
		normal.bg_color = Color("8a5a32")
		normal.border_color = UiStyle.BRASS
		hover.bg_color = Color("9a6a3c")
		hover.border_color = Color("ffe08a")
		btn.add_theme_color_override("font_color", Color("fff4d0"))
	else:
		normal.bg_color = Color("3d2a1c")
		normal.border_color = Color("6a5638")
		hover.bg_color = Color("5a3a28")
		hover.border_color = Color("9a8060")
		btn.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_hover_color", Color("fff4d0"))
	btn.add_theme_color_override("font_pressed_color", UiStyle.BRASS)


func _is_novice_hud() -> bool:
	return GameState.day <= NOVICE_UNTIL_DAY


func _on_locale(_locale: String) -> void :
	_refresh()


func _refresh() -> void :
	var novice: = _is_novice_hud()
	day_label.text = L10n.tf("ui.hud.day", {"day": GameState.day}, "第 %d 天" % GameState.day)
	var period_key: = "ui.hud.period_%s" % GameState.period
	period_label.text = "%s：%s" % [
		L10n.t("ui.hud.period", "时段"), 
		L10n.t(period_key, L10n.t("periods.%s.name" % GameState.period, GameState.period)), 
	]
	if _clock_label:
		_clock_label.text = WorldClock.clock_hhmm() if WorldClock else "--:--"
		if WorldClock and WorldClock.day_phase01() >= 0.92:
			_clock_label.add_theme_color_override("font_color", UiStyle.DANGER)
		else:
			_clock_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78, 1))
	_refresh_speed_btns()
	var wid: = str(GameState.weather)
	if wid == "":
		wid = "clear"
	weather_label.text = "%s：%s" % [
		L10n.t("ui.hud.weather", "天气"), 
		L10n.t("weather.%s.name" % wid, wid), 
	]
	match wid:
		"storm":
			weather_label.add_theme_color_override("font_color", UiStyle.DANGER)
		"rain":
			weather_label.add_theme_color_override("font_color", Color(0.65, 0.78, 0.95))
		_:
			weather_label.add_theme_color_override("font_color", UiStyle.TEXT_ON_DARK)

	money_label.text = "%s %d" % [L10n.t("ui.hud.money", "金钱"), int(GameState.get_stat("money"))]
	money_label.tooltip_text = L10n.t("ui.hud.money_tip", "口袋里的钱。归零会破产收场。")

	_refresh_rank()
	_refresh_firm_standing()
	_refresh_heat_standing()
	_refresh_next_step()
	_refresh_mood()

	# First days: only clock + money + today's goal.
	rank_label.visible = not novice
	trust_label.visible = not novice
	suspicion_label.visible = not novice
	mood_label.visible = not novice
	network_label.visible = false
	intel_label.visible = true
	money_label.visible = true


func _refresh_rank() -> void :
	var emp: = L10n.t("ui.employer.%s" % GameState.employer_id, GameState.employer_id)
	var rid: = GameState.get_rank_id()
	if GameState.employer_id == GameState.EMPLOYER_NONE or rid.is_empty():
		rank_label.text = "%s · %s" % [emp, L10n.t("ui.hud.unemployed", "无职级")]
		rank_label.tooltip_text = L10n.t(
			"ui.hud.rank_tip_jobless", 
			"你现在没有公司编制。靠码头/广场赚钱，或去通洋找机会。"
		)
	else:
		rank_label.text = "%s · %s" % [emp, L10n.t("ranks.%s.name" % rid, rid)]
		var promo: Dictionary = PromotionSystem.get_status()
		var tip_lines: PackedStringArray = [
			L10n.t("ui.hud.rank_tip_head", "你在这家公司的位子。"), 
		]
		if bool(promo.get("at_max", false)):
			tip_lines.append(L10n.t("ui.hud.rank_max", "已在当前职涯顶端"))
		elif bool(promo.get("employed", false)):
			tip_lines.append(str(promo.get("title", "")))
			tip_lines.append(str(promo.get("hint", "")))
			tip_lines.append(L10n.t("ui.hud.rank_tip_dossier", "打开档案可看晋升进度条与条件。"))
		rank_label.tooltip_text = "\n".join(tip_lines)
	rank_label.add_theme_color_override("font_color", UiStyle.BRASS)


func _refresh_firm_standing() -> void :

	var unemployed: bool = GameState.employer_id == GameState.EMPLOYER_NONE
	var at_ty: bool = GameState.employer_id == GameState.EMPLOYER_TONGYANG
	var trust_stat: = "tongyang_trust" if at_ty else "trust"
	var v: = int(GameState.get_stat(trust_stat))

	if unemployed:
		trust_label.text = L10n.t("ui.hud.firm_jobless", "公司：自谋生路")
		trust_label.tooltip_text = L10n.tf(
			"ui.hud.firm_jobless_tip", 
			{"n": v}, 
			"你不在任何公司名册上。旧部信任残留 %d，不影响码头吃饭。" % v
		)
		trust_label.add_theme_color_override("font_color", Color(0.78, 0.7, 0.58))
		return

	var standing: = _firm_standing_word(v, at_ty)
	var firm_name: = L10n.t("ui.employer.tongyang", "通洋") if at_ty\
	else L10n.t("ui.employer.hongyuan", "宏远")
	trust_label.text = L10n.tf(
		"ui.hud.firm_line", 
		{"firm": firm_name, "standing": standing}, 
		"公司：%s" % standing
	)
	var how: = L10n.t(
		"ui.hud.firm_how_ty", 
		"通洋办公、卖情报、挖人会让掌柜更认你。"
	) if at_ty else L10n.t(
		"ui.hud.firm_how_hy", 
		"日常办公、替老板办事/顶锅会涨；偷听、违逆、跳槽会掉。"
	)
	trust_label.tooltip_text = L10n.tf(
		"ui.hud.firm_tip", 
		{"firm": firm_name, "standing": standing, "n": v, "how": how}, 
		"%s里别人把你当「%s」。\n内部信任 %d（越高越好）。\n%s\n详细晋升条件见档案。" % [firm_name, standing, v, how]
	)
	trust_label.add_theme_color_override("font_color", UiStyle.TEXT_ON_DARK)


func _refresh_heat_standing() -> void :

	var v: = int(GameState.get_stat("suspicion"))
	var word: = L10n.t("ui.hud.heat_safe", "安全")
	var color: = UiStyle.TEXT_ON_DARK
	if v >= 95:
		word = L10n.t("ui.hud.heat_fire", "要被开了")
		color = UiStyle.DANGER
	elif v >= 70:
		word = L10n.t("ui.hud.heat_hot", "危险")
		color = UiStyle.DANGER
	elif v >= 40:
		word = L10n.t("ui.hud.heat_watch", "有人留意")
		color = UiStyle.BRASS
	suspicion_label.text = L10n.tf("ui.hud.heat_line", {"word": word}, "风声：%s" % word)
	suspicion_label.add_theme_color_override("font_color", color)
	var room: = 40 - v if v < 40 else (70 - v if v < 70 else (95 - v if v < 95 else 0))
	var warn: = ""
	if v < 40:
		warn = L10n.tf("ui.hud.heat_room_safe", {"n": room}, "再抬 %d 点才会开始被敲打。" % room)
	elif v < 70:
		warn = L10n.tf("ui.hud.heat_room_mid", {"n": room}, "再抬 %d 点就有开除风险。" % room)
	elif v < 95:
		warn = L10n.tf("ui.hud.heat_room_high", {"n": room}, "再抬 %d 点宏远会请你出门。" % room)
	else:
		warn = L10n.t("ui.hud.heat_room_max", "已经站在门口了——降嫌疑或另谋生路。")
	suspicion_label.tooltip_text = L10n.tf(
		"ui.hud.heat_tip", 
		{"word": word, "n": v, "warn": warn}, 
		"风声：%s（嫌疑 %d）。\n偷听、偷单、跳槽会变热；回家休息可降温。\n%s" % [word, v, warn]
	)


func _refresh_next_step() -> void :

	var goal: = _pick_next_step()
	intel_label.text = L10n.tf(
		"ui.hud.next_line", 
		{"text": str(goal.get("text", ""))}, 
		"今日目标：%s" % str(goal.get("text", ""))
	)
	intel_label.tooltip_text = str(goal.get("tip", ""))
	intel_label.add_theme_color_override("font_color", UiStyle.BRASS)


func _pick_next_step() -> Dictionary:
	var unemployed: bool = GameState.employer_id == GameState.EMPLOYER_NONE
	var at_ty: bool = GameState.employer_id == GameState.EMPLOYER_TONGYANG
	var sus: = int(GameState.get_stat("suspicion"))
	var money: = int(GameState.get_stat("money"))
	var intel: = int(GameState.get_stat("intel"))
	var fame: = int(GameState.get_stat("network_elite"))

	if money <= 20:
		return {
			"text": L10n.t("ui.hud.goal.money", "先去码头/广场赚点钱"), 
			"tip": L10n.t("ui.hud.goal.money_tip", "钱太少时日子发紧。搬货、加班、帮摊都能回血。"), 
		}
	if sus >= 70:
		return {
			"text": L10n.t("ui.hud.goal.cool", "风声太紧，先回家休息降温"), 
			"tip": L10n.t("ui.hud.goal.cool_tip", "嫌疑偏高时少碰偷听/偷单。回家休息、少惹事。"), 
		}

	var home_tier: = int(GameState.get_stat("home_tier"))
	if money >= 120 and home_tier < 3:
		return {
			"text": L10n.t("ui.hud.goal.face", "有钱了，去宅基撑场面"), 
			"tip": L10n.t(
				"ui.hud.goal.face_tip", 
				"钱≥120 且房子还能升时：回家→宅基包工。升级涨声望，比干囤钱更有脸。"
			), 
		}

	if GameState.get_flag("divorced_su") == 0 and GameState.day >= 6\
	and GameState.get_flag("divorce_snooze") == 0\
	and _divorce_crack_ready():
		return {
			"text": L10n.t("ui.hud.goal.divorce_talk", "今晚或许该回家谈清楚"), 
			"tip": L10n.t(
				"ui.hud.goal.divorce_talk_tip", 
				"手帕裂痕、好感崩、辞职跳槽之后，客厅可谈散伙／退婚；也可等摊牌夜。"
			), 
		}
	if unemployed:
		if GameState.is_location_unlocked("rival") or GameState.get_flag("resigned_hongyuan") != 0\
		or GameState.get_flag("hongyuan_fired") != 0:
			if GameState.get_flag("can_join_tongyang") != 0:
				return {
					"text": L10n.t("ui.hud.goal.ty_accept", "通洋大堂：接受通洋职位，开始上班"), 
					"tip": L10n.t(
						"ui.hud.goal.ty_accept_tip", 
						"资格已有。进通洋商行 → 接待大堂 →「接受通洋职位」。入职后才能「通洋办公」。"
					), 
				}
			return {
				"text": L10n.t("ui.hud.goal.ty_apply", "去通洋大堂找陈掌柜应聘"), 
				"tip": L10n.t(
					"ui.hud.goal.ty_apply_tip", 
					"辞职/被开后通洋会提前开门。大堂「询问招聘」拉近陈掌柜；够资格后同一大堂「接受通洋职位」，再点「通洋办公」上班。"
				), 
			}
		return {
			"text": L10n.t("ui.hud.goal.jobless", "码头打工维生，或等通洋开门"), 
			"tip": L10n.t("ui.hud.goal.jobless_tip", "无业时宏远公事做不了。码头搬货保命；通洋默认第7天开门（辞职会提前）。"), 
		}


	var promo: Dictionary = PromotionSystem.get_status()
	if bool(promo.get("ready", false)):
		var where: = L10n.t("ui.hud.goal.ask_ty", "去通洋办公室申请晋升") if at_ty\
		else L10n.t("ui.hud.goal.ask_hy", "去老板办公室申请晋升")
		return {
			"text": where, 
			"tip": L10n.t("ui.hud.goal.ask_tip", "档案里晋升条件已齐。去对应办公室点「申请晋升」。"), 
		}
	if bool(promo.get("employed", false)) and not bool(promo.get("at_max", false)):
		var need: = int(promo.get("need", 0))
		var cur: = int(promo.get("current", 0))
		if need > cur:
			var rank_name: = L10n.t(
				"ranks.%s.name" % str(promo.get("next_rank_id", "")), 
				str(promo.get("next_rank_id", ""))
			)
			var gap: = need - cur
			return {
				"text": L10n.tf(
					"ui.hud.goal.promo", 
					{"rank": rank_name, "gap": gap}, 
					"再办 %d 次公事，冲「%s」名分" % [maxi(1, int(ceil(gap / 3.0))), rank_name]
				), 
				"tip": str(promo.get("hint", "")) + "\n" + L10n.t(
					"ui.hud.goal.promo_tip", 
					"打开档案看勾选条件。宏远：办公/老板任务；通洋：通洋办公/情报。"
				), 
			}

	if not at_ty:
		var trust: = int(GameState.get_stat("trust"))
		if trust < 55:
			var gap2: = 55 - trust
			return {
				"text": L10n.tf(
					"ui.hud.goal.boss_door", 
					{"gap": gap2}, 
					"再攒点信任就能进老板办公室（大约差 %d）" % gap2
				), 
				"tip": L10n.t(
					"ui.hud.goal.boss_door_tip", 
					"公司「日常办公」、替老板办事/顶锅最涨信任。打开档案看晋升进度。"
				), 
			}

	if intel < 10:
		return {
			"text": L10n.t("ui.hud.goal.intel", "消息还少：去听壁脚或码头闲聊"), 
			"tip": L10n.t(
				"ui.hud.goal.intel_tip", 
				"情报用来传谣、挖人、布局。公司听壁脚、码头闲聊、广场买消息都能涨。"
			), 
		}
	if fame < 20 and GameState.is_location_unlocked("rival"):
		return {
			"text": L10n.t("ui.hud.goal.fame", "想走通洋线：先把声望做起来"), 
			"tip": L10n.t("ui.hud.goal.fame_tip", "通洋接头大约要声望 20。细节在档案「公司与身家」。"), 
		}

	return {
		"text": L10n.t("ui.hud.goal.free", "自由活动：打工、见人，或推主线裂缝"), 
		"tip": L10n.t(
			"ui.hud.goal.free_tip", 
			"没有紧急门槛。可升职、搞钱，或跟任务栏的主线（可收起）。"
		), 
	}


func _divorce_crack_ready() -> bool:
	if GameState.get_flag("su_accepts_son_gifts") != 0:
		return true
	if GameState.get_flag("resigned_hongyuan") != 0:
		return true
	if GameState.get_flag("joined_tongyang") != 0:
		return true
	if GameState.get_flag("su_may_betray") != 0:
		return true
	if int(GameState.get_relation("su_qing", "player", "favor")) <= 40:
		return true
	return false


func _firm_standing_word(v: int, at_ty: bool) -> String:
	if at_ty:
		if v < 30:
			return L10n.t("ui.hud.firm_ty_new", "还是新人")
		if v < 60:
			return L10n.t("ui.hud.firm_ty_mid", "开始被用了")
		return L10n.t("ui.hud.firm_ty_core", "快进核心圈")
	if v < 25:
		return L10n.t("ui.hud.firm_hy_low", "刚站稳")
	if v < 45:
		return L10n.t("ui.hud.firm_hy_fore", "小组里说得上话")
	if v < 65:
		return L10n.t("ui.hud.firm_hy_chief", "还算受用")
	if v < 85:
		return L10n.t("ui.hud.firm_hy_mgr", "快到经理那档")
	return L10n.t("ui.hud.firm_hy_inner", "快摸到核心")


func _refresh_mood() -> void :
	var sus: = GameState.get_stat("suspicion")
	var tension: = GameState.get_stat("father_son_tension")
	var favor: = GameState.get_relation("su_qing", "player", "favor")
	var score: = favor - sus * 0.45 - tension * 0.55
	var band: = "steady"
	var color: = UiStyle.TEXT_ON_DARK
	if score >= 45.0 and tension < 40.0 and sus < 45.0:
		band = "ease"
		color = UiStyle.OK
	elif tension >= 70.0 or sus >= 70.0 or score < 10.0:
		band = "crack"
		color = UiStyle.DANGER
	elif tension >= 40.0 or sus >= 45.0 or score < 28.0:
		band = "tight"
		color = UiStyle.BRASS
	var band_text: = L10n.t("ui.hud.mood_%s" % band, band)
	mood_label.text = "%s %s" % [L10n.t("ui.hud.mood", "局势"), band_text]
	mood_label.add_theme_color_override("font_color", color)
	var vt: = int(GameState.get_stat("vehicle_tier"))
	var ht: = clampi(int(GameState.get_stat("home_tier")), 1, 4)
	var ride: = L10n.t("vehicle.tier.%d" % vt, str(vt))
	var home_name: = L10n.t("locations.home.t%d" % ht, "自宅")
	mood_label.tooltip_text = L10n.t(
		"ui.hud.mood_explain", 
		"局势看晚晴好感、周家父子张力、你的嫌疑——不是赚钱进度。"
	) + "\n" + L10n.tf(
		"ui.hud.mood_tip", 
		{
			"favor": int(favor), 
			"tension": int(tension), 
			"suspicion": int(sus), 
		}, 
		"晚晴好感 %d · 父子张力 %d · 嫌疑 %d" % [int(favor), int(tension), int(sus)]
	) + "\n%s %s · %s %s" % [
		L10n.t("ui.hud.vehicle", "座驾"), 
		ride, 
		L10n.t("ui.hud.home_tier", "住所"), 
		home_name, 
	]
