extends CanvasLayer


## Queued beats: period veil, consequence card; chatter is a non-blocking toast.

enum Kind { PERIOD, RESULT, CHATTER }

var _queue: Array = []
var _busy: bool = false
var _toast_queue: Array = []
var _toast_busy: bool = false
var _veil: ColorRect
var _period_label: Label
var _period_sub: Label
var _card: PanelContainer
var _card_title: Label
var _card_body: RichTextLabel
var _card_gain: Label
var _card_loss: Label
var _card_btn: Button
var _card_alt_btn: Button
var _card_btn_row: HBoxContainer
var _chatter_root: PanelContainer
var _chatter_title: Label
var _chatter_body: Label
var _awaiting_card: bool = false
var _curfew_pick: String = ""
var _choice_mode: String = "" ## "" | "curfew"


func _ready() -> void :
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("beat_feed")
	_build_ui()
	visible = true
	if not GameState.period_advanced.is_connected(_on_period):
		GameState.period_advanced.connect(_on_period)
	if not ActionPipeline.action_resolved.is_connected(_on_action):
		ActionPipeline.action_resolved.connect(_on_action)
	if not EventScheduler.event_resolved.is_connected(_on_event):
		EventScheduler.event_resolved.connect(_on_event)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func push_notice(title: String, text: String) -> void :
	_enqueue_toast({
		"title": title if title != "" else L10n.t("ui.period.night_title", "夜色"), 
		"text": text, 
	})


## Modal: 回家休息 / 先不回去. Returns "home" or "linger".
func ask_curfew() -> String:
	_curfew_pick = ""
	_choice_mode = "curfew"
	GameFlow.set_transition_open(true)
	_card_title.text = L10n.t("ui.period.curfew_ask_title", "夜深了")
	_card_body.text = L10n.t(
		"ui.period.curfew_ask_body", 
		"已近凌晨两点。现在回家休息？若先不回去，今晚不会再强制送你回家。"
	)
	_card_gain.visible = false
	_card_loss.visible = false
	_card_btn.text = L10n.t("ui.period.curfew_go_home", "回家休息")
	_card_alt_btn.text = L10n.t("ui.period.curfew_linger", "先不回去")
	_card_alt_btn.visible = true
	_card.visible = true
	_card.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.18)
	await tw.finished
	while _curfew_pick == "":
		await get_tree().process_frame
	var tw2: = create_tween()
	tw2.tween_property(_card, "modulate:a", 0.0, 0.15)
	await tw2.finished
	_card.visible = false
	_card_alt_btn.visible = false
	_choice_mode = ""
	_card_btn.text = L10n.t("ui.common.confirm", "确定")
	return _curfew_pick


## Blocking wake card after sleep / curfew. Caller owns transition_open.
func show_wake_card(forced: bool) -> void :
	GameFlow.set_transition_open(true)
	var body: = ""
	var situation: = ""
	if forced:
		body = L10n.t(
			"ui.period.curfew_wake", 
			"昨晚熬到深夜，倦意把你拽回出租屋。一觉醒来，天光已经亮了。"
		)
		situation = L10n.t(
			"ui.period.wake_speed_tip", 
			"新的一天开始了。时间倍速已恢复为 1×，可在顶栏再调。"
		)
	else:
		body = L10n.t("ui.period.rest_ok", "你回家睡了一觉。天光重新亮起。")
		situation = L10n.t(
			"ui.period.wake_speed_tip", 
			"新的一天开始了。时间倍速已恢复为 1×，可在顶栏再调。"
		)
	await _show_result({
		"body": body, 
		"situation": situation, 
		"gains": PackedStringArray(), 
		"losses": PackedStringArray(), 
		"title": L10n.t("ui.period.wake_title", "天亮了"), 
	})
	GameFlow.set_transition_open(false)


func _on_locale(_l: String) -> void :
	_card_btn.text = L10n.t("ui.common.confirm", "确定")
	_chatter_title.text = L10n.t("ui.chatter.title", "耳边闲话")
	if _card_alt_btn:
		_card_alt_btn.text = L10n.t("ui.period.curfew_linger", "先不回去")


func _build_ui() -> void :
	_veil = ColorRect.new()
	_veil.name = "PeriodVeil"
	_veil.color = Color(0.04, 0.03, 0.02, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_veil)

	var period_box: = VBoxContainer.new()
	period_box.name = "PeriodBox"
	period_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	period_box.set_anchors_preset(Control.PRESET_CENTER)
	period_box.offset_left = -220
	period_box.offset_right = 220
	period_box.offset_top = -48
	period_box.offset_bottom = 48
	period_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_veil.add_child(period_box)

	_period_label = Label.new()
	_period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_period_label.add_theme_font_size_override("font_size", 34)
	_period_label.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	period_box.add_child(_period_label)

	_period_sub = Label.new()
	_period_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_period_sub.add_theme_font_size_override("font_size", 16)
	_period_sub.add_theme_color_override("font_color", UiStyle.BRASS)
	period_box.add_child(_period_sub)

	_card = PanelContainer.new()
	_card.name = "ResultCard"
	_card.visible = false
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.offset_left = -260
	_card.offset_right = 260
	_card.offset_top = -150
	_card.offset_bottom = 150
	_card.add_theme_stylebox_override("panel", UiStyle.make_parchment_style())
	add_child(_card)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_card.add_child(margin)

	var vbox: = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_card_title = Label.new()
	_card_title.add_theme_font_size_override("font_size", 20)
	_card_title.add_theme_color_override("font_color", UiStyle.WOOD)
	_card_title.text = L10n.t("ui.beat.result_title", "这一步之后")
	vbox.add_child(_card_title)

	_card_body = RichTextLabel.new()
	_card_body.fit_content = true
	_card_body.scroll_active = false
	_card_body.custom_minimum_size = Vector2(0, 48)
	_card_body.add_theme_color_override("default_color", UiStyle.TEXT)
	vbox.add_child(_card_body)

	_card_gain = Label.new()
	_card_gain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_gain.add_theme_color_override("font_color", UiStyle.OK)
	vbox.add_child(_card_gain)

	_card_loss = Label.new()
	_card_loss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_loss.add_theme_color_override("font_color", UiStyle.DANGER)
	vbox.add_child(_card_loss)

	_card_btn_row = HBoxContainer.new()
	_card_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(_card_btn_row)

	_card_alt_btn = Button.new()
	_card_alt_btn.custom_minimum_size = Vector2(120, 40)
	_card_alt_btn.text = L10n.t("ui.period.curfew_linger", "先不回去")
	_card_alt_btn.visible = false
	UiStyle.apply_cozy_button(_card_alt_btn)
	_card_alt_btn.pressed.connect(_on_card_alt)
	_card_btn_row.add_child(_card_alt_btn)

	_card_btn = Button.new()
	_card_btn.custom_minimum_size = Vector2(120, 40)
	_card_btn.text = L10n.t("ui.common.confirm", "确定")
	UiStyle.apply_cozy_button(_card_btn)
	_card_btn.pressed.connect(_on_card_confirm)
	_card_btn_row.add_child(_card_btn)

	_chatter_root = PanelContainer.new()
	_chatter_root.name = "ChatterBanner"
	_chatter_root.visible = false
	_chatter_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chatter_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_chatter_root.offset_left = -380
	_chatter_root.offset_right = 380
	_chatter_root.offset_top = 72
	_chatter_root.offset_bottom = 148
	var chatter_style: = StyleBoxFlat.new()
	chatter_style.bg_color = Color(0.18, 0.11, 0.07, 0.94)
	chatter_style.border_color = Color(0.78, 0.58, 0.28, 1)
	chatter_style.set_border_width_all(2)
	chatter_style.set_corner_radius_all(8)
	chatter_style.content_margin_left = 16
	chatter_style.content_margin_right = 16
	chatter_style.content_margin_top = 10
	chatter_style.content_margin_bottom = 10
	_chatter_root.add_theme_stylebox_override("panel", chatter_style)
	add_child(_chatter_root)

	var cv: = VBoxContainer.new()
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_theme_constant_override("separation", 4)
	_chatter_root.add_child(cv)

	_chatter_title = Label.new()
	_chatter_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chatter_title.text = L10n.t("ui.chatter.title", "耳边闲话")
	_chatter_title.add_theme_font_size_override("font_size", 15)
	_chatter_title.add_theme_color_override("font_color", UiStyle.BRASS)
	cv.add_child(_chatter_title)

	_chatter_body = Label.new()
	_chatter_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chatter_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chatter_body.add_theme_font_size_override("font_size", 16)
	_chatter_body.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86))
	cv.add_child(_chatter_body)


func _on_period(day: int, period: String) -> void :
	if ActionPipeline.suppress_period_feed:
		return
	if GameFlow.event_open or GameFlow.dialogue_open or GameFlow.ending_open:
		return
	_enqueue({
		"kind": Kind.PERIOD, 
		"day": day, 
		"period": period, 
		"new_day": period == "morning", 
		"flavor": L10n.t_if("ui.period.to_%s" % period), 
	})


func _on_action(result: Dictionary) -> void :
	if not bool(result.get("ok", false)) or bool(result.get("cancelled", false)):
		return
	## Bed rest uses WorldClock wake card — skip duplicate period/result beats.
	if str(result.get("action_id", "")) == "home_rest":
		var bed_chatter: = str(result.get("chatter", "")).strip_edges()
		if bed_chatter != "":
			_enqueue_toast({"text": bed_chatter})
		return
	var consequence: Dictionary = result.get("consequence", {})
	var message: = str(result.get("message", "")).strip_edges()
	var first_line: = message.split("\n")[0] if message != "" else ""
	var gains: Variant = consequence.get("gains", PackedStringArray())
	var losses: Variant = consequence.get("losses", PackedStringArray())
	var has_delta: bool = _count_bits(gains) > 0 or _count_bits(losses) > 0
	var show_card: bool = (
		has_delta
		or str(result.get("choice_id", "")) != ""
		or str(result.get("check_id", "")) != ""
	)
	if show_card:
		_enqueue({
			"kind": Kind.RESULT, 
			"body": first_line, 
			"situation": str(consequence.get("situation", "")), 
			"gains": gains, 
			"losses": losses, 
		})
	if bool(result.get("period_changed", false)):
		_enqueue({
			"kind": Kind.PERIOD, 
			"day": GameState.day, 
			"period": GameState.period, 
			"new_day": int(result.get("prev_day", GameState.day)) != GameState.day, 
			"flavor": L10n.t_if("ui.period.to_%s" % GameState.period), 
		})
	elif bool(result.get("time_skip", false)) and not bool(result.get("curfew", false)):
		_enqueue_toast({
			"title": L10n.t("ui.period.time_skip_title", "时间飞逝"), 
			"text": L10n.t("ui.period.time_skip_hint", "做事花掉了一段时间。"), 
		})
	var chatter: = str(result.get("chatter", "")).strip_edges()
	if chatter != "":
		_enqueue_toast({"text": chatter})


func _on_event(event_id: String, choice_id: String, applied: Array = []) -> void :
	if event_id == "ev_day1_intro":
		return
	var consequence: Dictionary = ConsequenceText.summarize(applied, 0.0)
	if not bool(consequence.get("has_weight", false)):
		return
	var title: = L10n.t("events.%s.title" % event_id, event_id)
	_enqueue({
		"kind": Kind.RESULT, 
		"body": title, 
		"situation": str(consequence.get("situation", "")), 
		"gains": consequence.get("gains", PackedStringArray()), 
		"losses": consequence.get("losses", PackedStringArray()), 
	})


func _count_bits(v: Variant) -> int:
	if v is PackedStringArray:
		return (v as PackedStringArray).size()
	if v is Array:
		return (v as Array).size()
	return 0


func _enqueue(item: Dictionary) -> void :
	if int(item.get("kind", -1)) == Kind.CHATTER:
		_enqueue_toast(item)
		return
	_queue.append(item)
	_pump()


func _enqueue_toast(item: Dictionary) -> void :
	_toast_queue.append(item)
	_pump_toast()


func _pump() -> void :
	if _busy:
		return
	if _queue.is_empty():
		_release_transition_gate()
		return
	_busy = true
	var item: Dictionary = _queue.pop_front()
	match int(item.get("kind", -1)):
		Kind.PERIOD:
			await _show_period(item)
		Kind.RESULT:
			await _show_result(item)
		_:
			pass
	_busy = false
	_pump()


func _pump_toast() -> void :
	if _toast_busy:
		return
	if _toast_queue.is_empty():
		return
	_toast_busy = true
	var item: Dictionary = _toast_queue.pop_front()
	await _show_chatter(item)
	_toast_busy = false
	_pump_toast()


func _release_transition_gate() -> void :
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_awaiting_card = false
	if _card and _choice_mode == "":
		_card.visible = false
	if not GameFlow.transition_open:
		return
	if _choice_mode != "":
		return
	GameFlow.set_transition_open(false)
	EventScheduler.pulse()
	TipSystem.pulse_when_free()


func _show_period(item: Dictionary) -> void :
	GameFlow.set_transition_open(true)
	var day: = int(item.get("day", GameState.day))
	var period: = str(item.get("period", GameState.period))
	var period_name: = L10n.t("periods.%s.name" % period, period)
	if bool(item.get("new_day", false)):
		_period_label.text = L10n.tf("ui.beat.day_title", {"day": day}, "第 %d 天" % day)
		_period_sub.text = period_name
	else:
		_period_label.text = L10n.tf(
			"ui.beat.period_title", 
			{"day": day, "period": period_name}, 
			"第 %d 天 · %s" % [day, period_name]
		)
		var flavor: = str(item.get("flavor", "")).strip_edges()
		_period_sub.text = flavor if flavor != "" else L10n.t("ui.period.advance", "时间流逝……")
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	_veil.color = Color(0.04, 0.03, 0.02, 0.0)
	_period_label.modulate.a = 0.0
	_period_sub.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(_veil, "color:a", 0.72, 0.28)
	tw.parallel().tween_property(_period_label, "modulate:a", 1.0, 0.28)
	tw.parallel().tween_property(_period_sub, "modulate:a", 1.0, 0.35)
	await tw.finished
	await get_tree().create_timer(1.05).timeout
	var tw2: = create_tween()
	tw2.tween_property(_veil, "color:a", 0.0, 0.3)
	tw2.parallel().tween_property(_period_label, "modulate:a", 0.0, 0.25)
	tw2.parallel().tween_property(_period_sub, "modulate:a", 0.0, 0.25)
	await tw2.finished
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _show_result(item: Dictionary) -> void :
	GameFlow.set_transition_open(true)
	var custom_title: = str(item.get("title", "")).strip_edges()
	_card_title.text = custom_title if custom_title != "" else L10n.t("ui.beat.result_title", "这一步之后")
	var body: = str(item.get("body", "")).strip_edges()
	var situation: = str(item.get("situation", "")).strip_edges()
	if situation != "" and situation != body:
		_card_body.text = situation if body == "" else "%s\n%s" % [body, situation]
	else:
		_card_body.text = body if body != "" else situation
	var gains = item.get("gains", PackedStringArray())
	var losses = item.get("losses", PackedStringArray())
	var gain_bits: PackedStringArray = PackedStringArray()
	for g in gains:
		gain_bits.append(str(g))
	var loss_bits: PackedStringArray = PackedStringArray()
	for l in losses:
		loss_bits.append(str(l))
	if gain_bits.size() > 0:
		_card_gain.text = "%s %s" % [L10n.t("ui.beat.gain", "得："), " · ".join(gain_bits)]
		_card_gain.visible = true
	else:
		_card_gain.visible = false
	if loss_bits.size() > 0:
		_card_loss.text = "%s %s" % [L10n.t("ui.beat.loss", "失："), " · ".join(loss_bits)]
		_card_loss.visible = true
	else:
		_card_loss.visible = false
	_card_alt_btn.visible = false
	_card_btn.text = L10n.t("ui.common.confirm", "确定")
	_card.visible = true
	_card.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.18)
	await tw.finished
	_awaiting_card = true
	while _awaiting_card:
		await get_tree().process_frame
	var tw2: = create_tween()
	tw2.tween_property(_card, "modulate:a", 0.0, 0.15)
	await tw2.finished
	_card.visible = false


func _on_card_confirm() -> void :
	SfxPlayer.play_click()
	if _choice_mode == "curfew":
		_curfew_pick = "home"
		return
	if _awaiting_card:
		_awaiting_card = false


func _on_card_alt() -> void :
	SfxPlayer.play_click()
	if _choice_mode == "curfew":
		_curfew_pick = "linger"


func _show_chatter(item: Dictionary) -> void :
	var text: = str(item.get("text", "")).strip_edges()
	if text == "":
		return
	## Non-blocking toast: never toggles GameFlow.transition_open.
	var title: = str(item.get("title", "")).strip_edges()
	_chatter_title.text = title if title != "" else L10n.t("ui.chatter.title", "耳边闲话")
	_chatter_body.text = text
	_chatter_root.visible = true
	_chatter_root.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(_chatter_root, "modulate:a", 1.0, 0.2)
	await tw.finished
	await get_tree().create_timer(2.6).timeout
	var tw2: = create_tween()
	tw2.tween_property(_chatter_root, "modulate:a", 0.0, 0.25)
	await tw2.finished
	_chatter_root.visible = false
