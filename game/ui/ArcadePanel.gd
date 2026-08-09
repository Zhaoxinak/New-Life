extends CanvasLayer


const STAKE: = {
	"dice": 8, 
	"morra": 6, 
	"fish": 0, 
}

@onready var root: Control = %Root
@onready var title_label: Label = %Title
@onready var vendor_label: Label = %VendorLabel
@onready var hint_label: Label = %HintLabel
@onready var stage: Control = %Stage
@onready var result_label: Label = %ResultLabel
@onready var session_label: Label = %SessionLabel
@onready var primary_btn: Button = %PrimaryButton
@onready var again_btn: Button = %AgainButton
@onready var leave_btn: Button = %LeaveButton
@onready var choices_box: HBoxContainer = %ChoicesBox

var _mode: String = ""
var _action_id: String = ""
var _phase: String = "idle"
var _plays: int = 0
var _spent: int = 0
var _won: int = 0
var _busy: bool = false


var _die_a: Label
var _die_b: Label

var _morra_pick: int = -1

var _fish_bar: ColorRect
var _fish_cursor: ColorRect
var _fish_zone: ColorRect
var _fish_t: float = 0.0
var _fish_speed: float = 2.2
var _fish_dir: float = 1.0
var _fish_zone_x: float = 0.55


func _ready() -> void :
	visible = false
	root.visible = false
	primary_btn.pressed.connect(_on_primary)
	again_btn.pressed.connect(_on_again)
	leave_btn.pressed.connect(_on_leave)
	for b in [primary_btn, again_btn, leave_btn]:
		UiStyle.apply_cozy_button(b)
	if not ActionPipeline.minigame_requested.is_connected(_on_minigame_requested):
		ActionPipeline.minigame_requested.connect(_on_minigame_requested)
	set_process(false)


func _process(delta: float) -> void :
	if not visible or _mode != "fish" or _phase != "play":
		return
	_fish_t += delta * _fish_speed * _fish_dir
	if _fish_t >= 1.0:
		_fish_t = 1.0
		_fish_dir = -1.0
	elif _fish_t <= 0.0:
		_fish_t = 0.0
		_fish_dir = 1.0
	if _fish_cursor:
		var w: = maxf(8.0, stage.size.x - 40.0)
		_fish_cursor.position.x = 20.0 + w * _fish_t


func _on_minigame_requested(minigame_id: String, action_id: String) -> void :
	if minigame_id not in ["dice", "morra", "fish"]:
		return
	open(minigame_id, action_id)


func open(mode: String, action_id: String) -> void :
	_mode = mode
	_action_id = action_id
	_plays = 0
	_spent = 0
	_won = 0
	_busy = false
	_morra_pick = -1
	visible = true
	root.visible = true
	GameFlow.set_minigame_open(true)
	SfxPlayer.play_click()
	_clear_stage()
	_build_stage()
	_enter_ready(true)
	set_process(mode == "fish")


func _title_for_mode() -> String:
	match _mode:
		"dice":
			return L10n.t("arcade.dice.title", "棚下掷骰")
		"morra":
			return L10n.t("arcade.morra.title", "豁拳定输赢")
		"fish":
			return L10n.t("arcade.fish.title", "码头钓趣")
		_:
			return L10n.t("arcade.title", "消遣")


func _stake() -> int:
	return int(STAKE.get(_mode, 0))


func _enter_ready(first: bool) -> void :
	_phase = "ready"
	_busy = false
	title_label.text = _title_for_mode()
	result_label.text = ""
	_refresh_session()
	_clear_choices()
	again_btn.visible = false
	match _mode:
		"dice":
			vendor_label.text = L10n.t(
				"arcade.dice.intro" if first else "arcade.dice.again", 
				"八块一把，两颗骰。点数大赢，庄家吃零头。"
			)
			hint_label.text = L10n.t("arcade.dice.hint", "点「开盅」掷骰；可连玩，收工才过时段。")
			primary_btn.visible = true
			primary_btn.text = L10n.tf("arcade.btn.stake", {"n": _stake()}, "开盅（%d 银元）" % _stake())
			if _die_a:
				_die_a.text = "?"
				_die_b.text = "?"
		"morra":
			vendor_label.text = L10n.t(
				"arcade.morra.intro" if first else "arcade.morra.again", 
				"豁拳！出拳比大小。六块一局，平手退注。"
			)
			hint_label.text = L10n.t("arcade.morra.hint", "先选你要出的数（0～5），再开拳。")
			primary_btn.visible = false
			_build_morra_choices()
		"fish":
			vendor_label.text = L10n.t(
				"arcade.fish.intro" if first else "arcade.fish.again", 
				"堤边借杆：看准绿色区起竿。钓到换小费，空军只费时段里的一口气。"
			)
			hint_label.text = L10n.t("arcade.fish.hint", "点「抛竿」开始，光标进绿区时再点「起竿」。")
			primary_btn.visible = true
			primary_btn.text = L10n.t("arcade.fish.cast", "抛竿")
			_reset_fish_visual()
	leave_btn.visible = true
	leave_btn.text = (
		L10n.t("ui.common.cancel", "算了")
		if _plays == 0
		else L10n.t("arcade.btn.leave", "收工走人")
	)


func _refresh_session() -> void :
	if _plays <= 0:
		session_label.text = L10n.t("arcade.session.empty", "还没开局 · 想玩几把玩几把")
		return
	var net: = _won - _spent
	var sign: = "+" if net >= 0 else ""
	session_label.text = L10n.tf(
		"arcade.session.stats", 
		{"n": _plays, "spent": _spent, "won": _won, "net": "%s%d" % [sign, net]}, 
		"已玩 %d 局 · 花 %d / 赢 %d · 盈亏 %s%d" % [_plays, _spent, _won, sign, net]
	)


func _clear_stage() -> void :
	for c in stage.get_children():
		c.queue_free()
	_die_a = null
	_die_b = null
	_fish_bar = null
	_fish_cursor = null
	_fish_zone = null
	_clear_choices()


func _clear_choices() -> void :
	for c in choices_box.get_children():
		c.queue_free()
	choices_box.visible = false


func _build_stage() -> void :
	match _mode:
		"dice":
			var row: = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 28)
			row.set_anchors_preset(Control.PRESET_FULL_RECT)
			stage.add_child(row)
			_die_a = _make_die_label()
			_die_b = _make_die_label()
			row.add_child(_die_a)
			row.add_child(_die_b)
		"morra":
			var big: = Label.new()
			big.name = "MorraShow"
			big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			big.set_anchors_preset(Control.PRESET_FULL_RECT)
			big.add_theme_font_size_override("font_size", 42)
			big.add_theme_color_override("font_color", UiStyle.WOOD)
			big.text = L10n.t("arcade.morra.idle", "出拳…")
			stage.add_child(big)
		"fish":
			_fish_bar = ColorRect.new()
			_fish_bar.color = Color(0.25, 0.2, 0.14, 1)
			_fish_bar.position = Vector2(20, stage.size.y * 0.45 if stage.size.y > 0 else 80)
			_fish_bar.size = Vector2(maxf(200, stage.size.x - 40), 28)
			stage.add_child(_fish_bar)
			_fish_zone = ColorRect.new()
			_fish_zone.color = Color(0.35, 0.65, 0.35, 0.85)
			_fish_zone.size = Vector2(70, 28)
			_fish_bar.add_child(_fish_zone)
			_fish_cursor = ColorRect.new()
			_fish_cursor.color = UiStyle.BRASS
			_fish_cursor.size = Vector2(10, 36)
			_fish_cursor.position = Vector2(0, -4)
			_fish_bar.add_child(_fish_cursor)
			call_deferred("_layout_fish")


func _layout_fish() -> void :
	if _fish_bar == null:
		return
	_fish_bar.position = Vector2(20, maxf(60.0, stage.size.y * 0.42))
	_fish_bar.size = Vector2(maxf(200.0, stage.size.x - 40.0), 28)
	_fish_zone_x = GameState.rng.randf_range(0.35, 0.7)
	_fish_zone.position.x = (_fish_bar.size.x - 70.0) * _fish_zone_x
	_fish_zone.position.y = 0
	_reset_fish_visual()


func _reset_fish_visual() -> void :
	_fish_t = 0.0
	_fish_dir = 1.0
	_fish_speed = GameState.rng.randf_range(1.8, 2.8)
	if _fish_zone and _fish_bar:
		_fish_zone_x = GameState.rng.randf_range(0.3, 0.72)
		_fish_zone.position.x = (_fish_bar.size.x - 70.0) * _fish_zone_x


func _make_die_label() -> Label:
	var lab: = Label.new()
	lab.custom_minimum_size = Vector2(96, 96)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 48)
	lab.add_theme_color_override("font_color", UiStyle.WOOD)
	lab.text = "?"
	return lab


func _build_morra_choices() -> void :
	_clear_choices()
	choices_box.visible = true
	for n in 6:
		var btn: = Button.new()
		btn.text = str(n)
		btn.custom_minimum_size = Vector2(56, 44)
		UiStyle.apply_cozy_button(btn)
		btn.pressed.connect(_on_morra_pick.bind(n))
		choices_box.add_child(btn)


func _on_morra_pick(n: int) -> void :
	if _phase != "ready" or _busy:
		return
	_morra_pick = n
	var show: Label = stage.get_node_or_null("MorraShow")
	if show:
		show.text = L10n.tf("arcade.morra.picked", {"n": n}, "你出：%d" % n)
	primary_btn.visible = true
	primary_btn.text = L10n.tf("arcade.btn.stake", {"n": _stake()}, "开拳（%d 银元）" % _stake())


func _on_primary() -> void :
	if _busy:
		return
	match _mode:
		"dice":
			if _phase == "ready":
				_play_dice()
		"morra":
			if _phase == "ready":
				_play_morra()
		"fish":
			if _phase == "ready":
				_start_fish()
			elif _phase == "play":
				_hook_fish()


func _on_again() -> void :
	if _busy:
		return
	_enter_ready(false)


func _pay_stake() -> bool:
	var s: = _stake()
	if s <= 0:
		return true
	if int(GameState.get_stat("money")) < s:
		vendor_label.text = L10n.t("arcade.broke", "口袋空了。先去码头扛两箱，或收工走人。")
		SfxPlayer.play_stinger("hush")
		return false
	GameState.add_stat("money", - float(s))
	_spent += s
	return true


func _play_dice() -> void :
	if not _pay_stake():
		return
	_busy = true
	_phase = "play"
	_plays += 1
	primary_btn.visible = false
	leave_btn.visible = false
	vendor_label.text = L10n.t("arcade.dice.rolling", "盅里乱响——")
	SfxPlayer.play_stinger("tick")
	var tw: = create_tween()
	for i in 10:
		tw.tween_callback( func():
			if _die_a:
				_die_a.text = str(GameState.rng.randi_range(1, 6))
				_die_b.text = str(GameState.rng.randi_range(1, 6))
			SfxPlayer.play_click()
		)
		tw.tween_interval(0.06)
	tw.tween_callback(_finish_dice)


func _finish_dice() -> void :
	var a: = GameState.rng.randi_range(1, 6)
	var b: = GameState.rng.randi_range(1, 6)

	var ha: = GameState.rng.randi_range(1, 6)
	var hb: = GameState.rng.randi_range(1, 6)
	if ha + hb <= 3:
		ha = GameState.rng.randi_range(2, 6)
	if _die_a:
		_die_a.text = str(a)
		_die_b.text = str(b)
	var you: = a + b
	var house: = ha + hb
	var payout: = 0
	var line: = ""
	if you > house:
		payout = 14
		line = L10n.tf("arcade.dice.win", {"you": you, "house": house, "pay": payout}, "你 %d 大于庄 %d · 赢得 %d" % [you, house, payout])
		SfxPlayer.play_stinger("bell")
	elif you == house:
		payout = 8
		line = L10n.tf("arcade.dice.tie", {"you": you}, "打平 %d · 退回本金" % you)
		SfxPlayer.play_stinger("paper")
	else:
		line = L10n.tf("arcade.dice.lose", {"you": you, "house": house}, "你 %d 小于庄 %d · 庄家笑纳" % [you, house])
		SfxPlayer.play_stinger("hush")
	if payout > 0:
		GameState.add_stat("money", float(payout))
		_won += payout
	result_label.text = line
	vendor_label.text = L10n.t("arcade.dice.result_vendor", "再来？还是收手？")
	_end_round()


func _play_morra() -> void :
	if _morra_pick < 0:
		vendor_label.text = L10n.t("arcade.morra.need_pick", "先选你要出的数。")
		return
	if not _pay_stake():
		return
	_busy = true
	_phase = "play"
	_plays += 1
	_clear_choices()
	primary_btn.visible = false
	leave_btn.visible = false
	var foe: = GameState.rng.randi_range(0, 5)

	if GameState.rng.randf() < 0.15:
		foe = mini(5, _morra_pick + 1)
	var show: Label = stage.get_node_or_null("MorraShow")
	var tw: = create_tween()
	for i in 8:
		tw.tween_callback( func():
			if show:
				show.text = str(GameState.rng.randi_range(0, 5))
			SfxPlayer.play_click()
		)
		tw.tween_interval(0.05)
	tw.tween_callback( func():
		if show:
			show.text = L10n.tf(
				"arcade.morra.show", 
				{"you": _morra_pick, "foe": foe}, 
				"你 %d ｜ 对方 %d" % [_morra_pick, foe]
			)
		var payout: = 0
		if _morra_pick > foe:
			payout = 11
			result_label.text = L10n.tf("arcade.morra.win", {"pay": payout}, "你大！赢得 %d" % payout)
			SfxPlayer.play_stinger("bell")
		elif _morra_pick == foe:
			payout = 6
			result_label.text = L10n.t("arcade.morra.tie", "打平 · 退注")
			SfxPlayer.play_stinger("paper")
		else:
			result_label.text = L10n.t("arcade.morra.lose", "你小 · 酒钱归对面")
			SfxPlayer.play_stinger("hush")
		if payout > 0:
			GameState.add_stat("money", float(payout))
			_won += payout
		vendor_label.text = L10n.t("arcade.morra.result_vendor", "喉咙还热着？再豁一拳？")
		_morra_pick = -1
		_end_round()
	)


func _start_fish() -> void :
	_busy = false
	_phase = "play"
	_plays += 1
	_reset_fish_visual()
	call_deferred("_layout_fish")
	primary_btn.text = L10n.t("arcade.fish.hook", "起竿！")
	leave_btn.visible = false
	again_btn.visible = false
	vendor_label.text = L10n.t("arcade.fish.waiting", "浮子在跳——看准绿区！")
	result_label.text = ""
	SfxPlayer.play_stinger("tide")
	_refresh_session()


func _hook_fish() -> void :
	if _phase != "play" or _mode != "fish":
		return
	_busy = true
	_phase = "result"

	var local_x: = _fish_cursor.position.x
	var zl: = _fish_zone.position.x
	var zr: = zl + _fish_zone.size.x
	var hit: = local_x + 5.0 >= zl and local_x <= zr
	var payout: = 0
	if hit:

		var mid: = (zl + zr) * 0.5
		var dist: = absf(local_x + 5.0 - mid)
		if dist < 12.0:
			payout = 16
			result_label.text = L10n.t("arcade.fish.perfect", "正口！鲜鱼换 16 银元")
			SfxPlayer.play_stinger("bell")
		else:
			payout = 10
			result_label.text = L10n.t("arcade.fish.ok", "上钩了 · 换 10 银元")
			SfxPlayer.play_stinger("paper")
		GameState.add_stat("money", float(payout))
		_won += payout
		GameState.add_stat("network_base", 1.0)
	else:
		result_label.text = L10n.t("arcade.fish.miss", "空军。水花笑你。")
		SfxPlayer.play_stinger("hush")
	vendor_label.text = L10n.t("arcade.fish.result_vendor", "堤边风还在。再抛一竿？")
	_end_round()


func _end_round() -> void :
	_busy = false
	_phase = "result"
	_refresh_session()
	primary_btn.visible = false
	again_btn.visible = true
	again_btn.text = L10n.t("arcade.btn.again", "再来一局")
	leave_btn.visible = true
	leave_btn.text = L10n.t("arcade.btn.leave", "收工走人")


func _on_leave() -> void :
	if _busy and _phase == "play" and _mode != "fish":
		return
	if _mode == "fish" and _phase == "play":

		_phase = "ready"
	if _plays <= 0:
		_close()
		ActionPipeline.cancel_pending(L10n.t("arcade.cancel", "没玩成，摊子收了。"))
		_action_id = ""
		TipSystem.pulse_when_free()
		return
	var net: = _won - _spent
	var sign: = "+" if net >= 0 else ""
	var note: = L10n.tf(
		"arcade.session.summary", 
		{"n": _plays, "spent": _spent, "won": _won, "net": "%s%d" % [sign, net], "mode": _title_for_mode()}, 
		"%s：玩了 %d 局，花 %d / 赢 %d，盈亏 %s%d" % [_title_for_mode(), _plays, _spent, _won, sign, net]
	)
	ActionPipeline.set_result_note(note)
	var act: = _action_id
	_close()
	ActionPipeline.finish_action(act, "")
	_action_id = ""
	TipSystem.pulse_when_free()


func _close() -> void :
	set_process(false)
	visible = false
	root.visible = false
	GameFlow.set_minigame_open(false)
	_phase = "idle"
	_busy = false
	_clear_stage()
