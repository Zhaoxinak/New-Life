extends CanvasLayer


const COLS: = 14
const ROWS: = 9
const REVEAL_AT: = 0.52
const TICKET_COST: = 10


const PRIZES: = [
	{"id": "none", "w": 55, "choice": "dch_plaza_scratch_none", "payout": 0}, 
	{"id": "small", "w": 28, "choice": "dch_plaza_scratch_small", "payout": 6}, 
	{"id": "mid", "w": 12, "choice": "dch_plaza_scratch_mid", "payout": 18}, 
	{"id": "big", "w": 4, "choice": "dch_plaza_scratch_big", "payout": 50}, 
	{"id": "jackpot", "w": 1, "choice": "dch_plaza_scratch_jackpot", "payout": 120}, 
]

@onready var root: Control = %Root
@onready var title_label: Label = %Title
@onready var vendor_label: Label = %VendorLabel
@onready var hint_label: Label = %HintLabel
@onready var progress_label: Label = %ProgressLabel
@onready var prize_title: Label = %PrizeTitle
@onready var prize_body: Label = %PrizeBody
@onready var card_face: Control = %CardFace
@onready var foil_layer: Control = %FoilLayer
@onready var spark_layer: Control = %SparkLayer
@onready var buy_btn: Button = %BuyButton
@onready var auto_btn: Button = %AutoButton
@onready var collect_btn: Button = %CollectButton
@onready var cancel_btn: Button = %CancelButton
@onready var card_frame: PanelContainer = %CardFrame

var _action_id: String = ""
var _phase: String = "idle"
var _prize: Dictionary = {}
var _cells: Array = []
var _cleared: int = 0
var _scratching: bool = false
var _sfx_cooldown: float = 0.0
var _shimmer_t: float = 0.0
var _tickets: int = 0
var _spent: int = 0
var _won: int = 0
var _best_id: String = "none"


func _ready() -> void :
	visible = false
	root.visible = false
	buy_btn.pressed.connect(_on_buy)
	auto_btn.pressed.connect(_on_auto)
	collect_btn.pressed.connect(_on_again)
	cancel_btn.pressed.connect(_on_leave)
	for b in [buy_btn, auto_btn, collect_btn, cancel_btn]:
		UiStyle.apply_cozy_button(b)
	if not ActionPipeline.minigame_requested.is_connected(_on_minigame_requested):
		ActionPipeline.minigame_requested.connect(_on_minigame_requested)
	set_process(true)


func _process(delta: float) -> void :
	if not visible:
		return
	_sfx_cooldown = maxf(0.0, _sfx_cooldown - delta)
	_shimmer_t += delta
	if _phase == "scratch":
		for i in _cells.size():
			var cell: ColorRect = _cells[i]
			if cell == null or not is_instance_valid(cell) or cell.modulate.a < 0.05:
				continue
			var wave: = 0.86 + 0.08 * sin(_shimmer_t * 6.0 + float(i) * 0.35)
			cell.modulate = Color(wave, wave * 0.95, wave * 0.75, cell.modulate.a)


func _on_minigame_requested(minigame_id: String, action_id: String) -> void :
	if minigame_id != "scratch":
		return
	open(action_id)


func open(action_id: String) -> void :
	_action_id = action_id
	_tickets = 0
	_spent = 0
	_won = 0
	_best_id = "none"
	visible = true
	root.visible = true
	GameFlow.set_minigame_open(true)
	SfxPlayer.play_click()
	TipSystem.queue_tip("tip_plaza_scratch")
	title_label.text = L10n.t("scratch.title", "港彩刮刮乐")
	_enter_ready(true)


func _enter_ready(first: bool) -> void :
	_phase = "ready"
	_prize = {}
	_cleared = 0
	_scratching = false
	_clear_sparks()
	card_frame.modulate = Color.WHITE
	prize_title.text = L10n.t("scratch.card.hidden_title", "？？？")
	prize_title.add_theme_color_override("font_color", UiStyle.TEXT)
	prize_body.text = L10n.t("scratch.card.hidden_body", "银箔底下藏着运气。")
	if first:
		vendor_label.text = L10n.t(
			"scratch.vendor.intro", 
			"摊主把一张银箔票拍在木板上：十块一张——想刮几张刮几张，刮爽了再说。"
		)
		hint_label.text = L10n.t(
			"scratch.hint.buy", 
			"买一张就刮；揭晓后可连刮，收工才过时段。"
		)
	else:
		vendor_label.text = L10n.t(
			"scratch.vendor.again", 
			"摊主又抽出一张：手还热着？接着刮——银元还在桌上响。"
		)
		hint_label.text = L10n.t(
			"scratch.hint.again", 
			"再买一张继续刮，或点「收工走人」结束这一时段。"
		)
	_refresh_session_label()
	buy_btn.visible = true
	buy_btn.text = L10n.tf(
		"scratch.btn.buy" if first else "scratch.btn.again", 
		{"cost": TICKET_COST}, 
		("买一张（%d 银元）" if first else "再刮一张（%d 银元）") % TICKET_COST
	)
	auto_btn.visible = false
	collect_btn.visible = false
	cancel_btn.visible = true
	cancel_btn.text = (
		L10n.t("ui.common.cancel", "算了")
		if _tickets == 0
		else L10n.t("scratch.btn.leave", "收工走人")
	)
	call_deferred("_build_card")


func _session_net() -> int:
	return _won - _spent


func _refresh_session_label() -> void :
	if _tickets <= 0:
		progress_label.text = L10n.t("scratch.session.empty", "还没开刮 · 想刮几张刮几张")
		return
	var net: = _session_net()
	var sign: = "+" if net >= 0 else ""
	progress_label.text = L10n.tf(
		"scratch.session.stats", 
		{"n": _tickets, "spent": _spent, "won": _won, "net": "%s%d" % [sign, net]}, 
		"已刮 %d 张 · 花 %d / 中 %d · 盈亏 %s%d" % [_tickets, _spent, _won, sign, net]
	)


func _build_card() -> void :
	for c in foil_layer.get_children():
		c.queue_free()
	_cells.clear()
	var size: = foil_layer.size
	if size.x < 8.0 or size.y < 8.0:
		size = Vector2(700, 240)
		foil_layer.custom_minimum_size = size
	var cw: = size.x / float(COLS)
	var ch: = size.y / float(ROWS)
	for r in ROWS:
		for c in COLS:
			var cell: = ColorRect.new()
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.position = Vector2(c * cw, r * ch)
			cell.size = Vector2(cw + 0.5, ch + 0.5)
			var shade: = 0.72 + 0.18 * float((r + c) % 3) / 2.0
			cell.color = Color(shade, shade * 0.92, shade * 0.68, 1.0)
			foil_layer.add_child(cell)
			_cells.append(cell)
	foil_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	if not foil_layer.gui_input.is_connected(_on_foil_input):
		foil_layer.gui_input.connect(_on_foil_input)


func _on_buy() -> void :
	if _phase != "ready":
		return
	if int(GameState.get_stat("money")) < TICKET_COST:
		vendor_label.text = L10n.t(
			"scratch.vendor.broke", 
			"摊主撇嘴：口袋空空还想碰运气？先去码头扛两箱——或先收工。"
		)
		SfxPlayer.play_stinger("hush")
		cancel_btn.visible = true
		cancel_btn.text = (
			L10n.t("scratch.btn.leave", "收工走人")
			if _tickets > 0
			else L10n.t("ui.common.cancel", "算了")
		)
		return
	GameState.add_stat("money", - float(TICKET_COST))
	_spent += TICKET_COST
	_tickets += 1

	prize_title.text = L10n.t("scratch.card.hidden_title", "？？？")
	prize_title.add_theme_color_override("font_color", UiStyle.TEXT)
	prize_body.text = L10n.t("scratch.card.hidden_body", "银箔底下藏着运气。")
	card_frame.modulate = Color.WHITE
	_build_card()
	_prize = _roll_prize()
	_apply_prize_face()
	_phase = "scratch"
	_cleared = 0
	_scratching = false
	buy_btn.visible = false
	auto_btn.visible = true
	auto_btn.text = L10n.t("scratch.btn.auto", "性急？一键刮开")
	collect_btn.visible = false
	cancel_btn.visible = false
	hint_label.text = L10n.t("scratch.hint.scratch", "按住左键来回刮银箔——刮开一半就会揭晓。")
	vendor_label.text = L10n.t(
		"scratch.vendor.start", 
		"银箔沙沙响。摊主笑：轻一点——刮爽了再停。"
	)
	_refresh_session_label()
	SfxPlayer.play_stinger("paper")
	SfxPlayer.play_click()


func _roll_prize() -> Dictionary:
	var total: = 0
	for p in PRIZES:
		total += int(p["w"])
	var roll: = GameState.rng.randi_range(1, total)
	var acc: = 0
	for p in PRIZES:
		acc += int(p["w"])
		if roll <= acc:
			return p
	return PRIZES[0]


func _apply_prize_face() -> void :
	var pid: = str(_prize.get("id", "none"))
	prize_title.text = L10n.t("scratch.prize.%s.title" % pid, pid)
	prize_body.text = L10n.t("scratch.prize.%s.body" % pid, "")
	match pid:
		"jackpot":
			prize_title.add_theme_color_override("font_color", Color("b8860b"))
		"big":
			prize_title.add_theme_color_override("font_color", UiStyle.DANGER)
		"mid":
			prize_title.add_theme_color_override("font_color", UiStyle.WOOD)
		"small":
			prize_title.add_theme_color_override("font_color", UiStyle.OK)
		_:
			prize_title.add_theme_color_override("font_color", UiStyle.TEXT_DIM)


func _on_foil_input(event: InputEvent) -> void :
	if _phase != "scratch":
		return
	if event is InputEventMouseButton:
		var mb: = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_scratching = mb.pressed
			if mb.pressed:
				_scratch_at(mb.position)
	elif event is InputEventMouseMotion and _scratching:
		_scratch_at((event as InputEventMouseMotion).position)


func _scratch_at(local_pos: Vector2) -> void :
	var size: = foil_layer.size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var cw: = size.x / float(COLS)
	var ch: = size.y / float(ROWS)
	var radius: = 1.35
	var cx: = local_pos.x / cw
	var cy: = local_pos.y / ch
	var any: = false
	for r in ROWS:
		for c in COLS:
			var idx: = r * COLS + c
			if idx >= _cells.size():
				continue
			var cell: ColorRect = _cells[idx]
			if cell == null or not is_instance_valid(cell) or cell.modulate.a < 0.05:
				continue
			var dx: = (float(c) + 0.5) - cx
			var dy: = (float(r) + 0.5) - cy
			if dx * dx + dy * dy <= radius * radius:
				_clear_cell(cell)
				any = true
	if any:
		_on_progress()
		if _sfx_cooldown <= 0.0:
			SfxPlayer.play_click()
			_sfx_cooldown = 0.045
			_spawn_spark(local_pos)


func _clear_cell(cell: ColorRect) -> void :
	if cell.modulate.a < 0.05:
		return
	cell.modulate.a = 0.0
	cell.visible = false
	_cleared += 1


func _on_progress() -> void :
	var total: = COLS * ROWS
	var pct: = int(round(100.0 * float(_cleared) / float(total)))
	var net: = _session_net()
	var sign: = "+" if net >= 0 else ""
	progress_label.text = L10n.tf(
		"scratch.progress.session", 
		{"pct": pct, "n": _tickets, "net": "%s%d" % [sign, net]}, 
		"刮开 %d%% · 第 %d 张 · 盈亏 %s%d" % [pct, _tickets, sign, net]
	)
	if pct >= 18 and pct < 40:
		vendor_label.text = L10n.t("scratch.vendor.mid1", "嗯……有点亮边。别停，手气怕冷场。")
	elif pct >= 40 and pct < 52:
		vendor_label.text = L10n.t("scratch.vendor.mid2", "箔屑掉进碗里。摊主凑近：再两下，揭晓了。")
	if float(_cleared) / float(total) >= REVEAL_AT:
		_reveal()


func _on_auto() -> void :
	if _phase != "scratch":
		return
	for cell in _cells:
		if cell != null and is_instance_valid(cell):
			_clear_cell(cell)
	_on_progress()


func _reveal() -> void :
	if _phase != "scratch":
		return
	_phase = "reveal"
	_scratching = false
	for cell in _cells:
		if cell != null and is_instance_valid(cell):
			cell.visible = false
			cell.modulate.a = 0.0
	auto_btn.visible = false

	var choice: = str(_prize.get("choice", "dch_plaza_scratch_none"))
	var payout: = int(_prize.get("payout", 0))
	EffectApplier.apply_owner("dialogue_choice", choice)
	_won += payout
	var pid: = str(_prize.get("id", "none"))
	if _prize_rank(pid) > _prize_rank(_best_id):
		_best_id = pid
	vendor_label.text = L10n.t("scratch.vendor.%s" % pid, vendor_label.text)
	hint_label.text = L10n.t(
		"scratch.hint.done_chain", 
		"奖金已入袋。再刮一张，或收工走人（才过时段）。"
	)

	_phase = "ready"
	buy_btn.visible = true
	buy_btn.text = L10n.tf(
		"scratch.btn.again", 
		{"cost": TICKET_COST}, 
		"再刮一张（%d 银元）" % TICKET_COST
	)
	collect_btn.visible = true
	collect_btn.text = L10n.t("scratch.btn.again_quick", "再来！")
	cancel_btn.visible = true
	cancel_btn.text = L10n.t("scratch.btn.leave", "收工走人")
	_refresh_session_label()
	_punch_card()
	_float_prize_burst(pid)
	match pid:
		"jackpot":
			SfxPlayer.play_stinger("bell")
			card_frame.modulate = Color(1.15, 1.05, 0.75)
		"big":
			SfxPlayer.play_stinger("bell")
		"mid":
			SfxPlayer.play_stinger("paper")
		"small":
			SfxPlayer.play_stinger("tick")
		_:
			SfxPlayer.play_stinger("hush")


func _prize_rank(pid: String) -> int:
	match pid:
		"jackpot":
			return 5
		"big":
			return 4
		"mid":
			return 3
		"small":
			return 2
		_:
			return 1


func _on_again() -> void :

	if _phase != "ready":
		return
	_on_buy()


func _punch_card() -> void :
	var tw: = create_tween()
	card_face.scale = Vector2(1.0, 1.0)
	card_face.pivot_offset = card_face.size * 0.5
	tw.tween_property(card_face, "scale", Vector2(1.06, 1.06), 0.12)
	tw.tween_property(card_face, "scale", Vector2(1.0, 1.0), 0.16)


func _float_prize_burst(pid: String) -> void :
	var text: = L10n.t("scratch.burst.%s" % pid, "")
	if text == "" or text.begins_with("scratch.burst."):
		return
	for i in 5:
		var lab: = Label.new()
		lab.text = text
		lab.add_theme_font_size_override("font_size", 18)
		lab.add_theme_color_override("font_color", UiStyle.BRASS if pid == "jackpot" else UiStyle.WOOD)
		lab.position = Vector2(40 + i * 70, 90 + (i % 2) * 20)
		lab.z_index = 20
		spark_layer.add_child(lab)
		var tw: = create_tween()
		tw.tween_property(lab, "position:y", lab.position.y - 70.0, 0.85)
		tw.parallel().tween_property(lab, "modulate:a", 0.0, 0.85)
		tw.tween_callback(lab.queue_free)


func _spawn_spark(local_pos: Vector2) -> void :
	var spark: = ColorRect.new()
	spark.size = Vector2(4, 4)
	spark.position = local_pos + Vector2(GameState.rng.randf_range(-6, 6), GameState.rng.randf_range(-6, 6))
	spark.color = Color(0.95, 0.88, 0.55, 0.9)
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark_layer.add_child(spark)
	var tw: = create_tween()
	tw.tween_property(spark, "position", spark.position + Vector2(0, -18), 0.28)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.28)
	tw.tween_callback(spark.queue_free)


func _clear_sparks() -> void :
	for c in spark_layer.get_children():
		c.queue_free()


func _on_leave() -> void :

	if _phase == "scratch":
		return
	if _tickets <= 0:
		_close_ui()
		ActionPipeline.cancel_pending()
		_action_id = ""
		TipSystem.pulse_when_free()
		return
	var net: = _session_net()
	var sign: = "+" if net >= 0 else ""
	var best_name: = L10n.t("scratch.prize.%s.title" % _best_id, _best_id)
	var note: = L10n.tf(
		"scratch.session.summary", 
		{
			"n": _tickets, 
			"spent": _spent, 
			"won": _won, 
			"net": "%s%d" % [sign, net], 
			"best": best_name, 
		}, 
		"连刮 %d 张：花 %d、中 %d、盈亏 %s%d。最佳：%s" % [_tickets, _spent, _won, sign, net, best_name]
	)
	ActionPipeline.set_result_note(note)
	var act: = _action_id
	_close_ui()
	ActionPipeline.finish_action(act, "")
	_action_id = ""
	TipSystem.pulse_when_free()


func _close_ui() -> void :
	visible = false
	root.visible = false
	GameFlow.set_minigame_open(false)
	_phase = "idle"
	_scratching = false
	_clear_sparks()
