extends CanvasLayer
## 升职四件套 / 清算闪回的 2D 演出层。

signal ceremony_finished

const BEAT_LABELS := {
	"ritual": "仪式",
	"title": "称呼",
	"standing": "站位",
	"permission": "权限",
	"pay": "月例",
	"grudge_window": "恩怨",
	"flash": "闪回",
	"address": "称呼",
	"crowd": "看客",
	"shame": "失态",
	"resolve": "落点",
}

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = %TitleLabel
@onready var beat_label: Label = %BeatLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var next_btn: Button = %NextBtn
@onready var title_splash: Label = %TitleSplash
@onready var unlock_label: Label = %UnlockLabel
@onready var strike: ColorRect = %Strike
@onready var rank_path: Label = %RankPath
@onready var rank_path_banner: PanelContainer = %RankPathBanner
@onready var step_dots: HBoxContainer = %StepDots
@onready var seal: Label = %Seal
@onready var glow: ColorRect = %Glow
@onready var bottom_veil: ColorRect = %BottomVeil

var _beats: Array = []
var _idx: int = 0
var _mode: String = ""
var _payload: Dictionary = {}
var _dot_nodes: Array = []
var _open_tween: Tween


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 32
	next_btn.pressed.connect(_on_next)
	_apply_chrome()
	if title_splash:
		title_splash.visible = false
	if unlock_label:
		unlock_label.visible = false
	if strike:
		strike.visible = false
	if rank_path:
		rank_path.visible = false
	if rank_path_banner:
		rank_path_banner.visible = false
	if glow:
		glow.visible = false
	if not DomainBus.domain_event.is_connected(_on_domain):
		DomainBus.domain_event.connect(_on_domain)


func _apply_chrome() -> void:
	## 暖木仪典卡，告别系统白框。
	if panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 0.95, 0.86, 0.98)
		sb.border_color = Color(0.72, 0.48, 0.22, 1)
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(18)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		sb.shadow_color = Color(0.35, 0.18, 0.08, 0.45)
		sb.shadow_size = 14
		sb.shadow_offset = Vector2(0, 6)
		panel.add_theme_stylebox_override("panel", sb)
	KairoStyle.style_button(next_btn, true)
	if body_label:
		KairoStyle.style_readable_rich(body_label, 20, 26)
		body_label.custom_minimum_size = Vector2(0, 120)
	if title_label:
		KairoStyle.style_readable_label(title_label, 26)
	if beat_label:
		KairoStyle.style_readable_label(beat_label, 16, true)
	if unlock_label:
		KairoStyle.style_readable_label(unlock_label, 18)
	if rank_path:
		rank_path.add_theme_color_override("font_color", KairoStyle.INK)
		rank_path.add_theme_font_size_override("font_size", 18)
	if rank_path_banner:
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color(1.0, 0.94, 0.8, 0.98)
		rsb.border_color = Color(0.62, 0.38, 0.16, 1)
		rsb.set_border_width_all(3)
		rsb.set_corner_radius_all(12)
		rsb.content_margin_left = 16
		rsb.content_margin_right = 16
		rsb.content_margin_top = 8
		rsb.content_margin_bottom = 8
		rsb.shadow_color = Color(0.1, 0.05, 0.02, 0.45)
		rsb.shadow_size = 8
		rsb.shadow_offset = Vector2(0, 3)
		rank_path_banner.add_theme_stylebox_override("panel", rsb)


func force_hide() -> void:
	visible = false
	_beats.clear()
	_idx = 0
	_mode = ""
	_payload.clear()
	_clear_dots()
	if title_splash:
		title_splash.visible = false
	if unlock_label:
		unlock_label.visible = false
	if strike:
		strike.visible = false
	if rank_path:
		rank_path.visible = false
	if rank_path_banner:
		rank_path_banner.visible = false
	if glow:
		glow.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo \
		and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		_on_next()
		get_viewport().set_input_as_handled()


func _on_domain(event_name: String, payload: Dictionary) -> void:
	match event_name:
		"promotion_ceremony":
			_start_ceremony(payload)
		"grudge_resolved":
			_flash_resolve(payload)


func _start_ceremony(payload: Dictionary) -> void:
	_mode = "promo"
	_payload = payload
	_beats = payload.get("beats", [])
	_idx = 0
	if _beats.is_empty():
		return
	_open()
	_show_beat()


func _flash_resolve(payload: Dictionary) -> void:
	_mode = "reckon"
	_payload = payload
	var fb := String(payload.get("flashback_key", ""))
	var mode := String(payload.get("mode", "punish"))
	var status := String(payload.get("status", ""))
	var window := String(payload.get("window", "light"))
	var address := String(payload.get("address", ""))
	if address.is_empty():
		address = PromotionSystem.address_for()
	var is_main := window == "main"
	var land := L10n.t("ui.reckon.land.punish", "落点：仇人失态的脸。") if mode == "punish" \
		else L10n.t("ui.reckon.land.forgive", "落点：你收势的手。")
	if is_main:
		land = L10n.t("ui.reckon.land.main.punish", "落点：婚事主动权回到你嘴里；新位子当众坐实。") if mode == "punish" \
			else L10n.t("ui.reckon.land.main.forgive", "落点：你收势的手；旁人敬「能收住」的人。")
	var standing := L10n.t("ui.reckon.standing.punish", "你站中线。对方退到侧光或门边。看客围成见证场。") \
		if mode == "punish" \
		else L10n.t("ui.reckon.standing.forgive", "你仍站高位。对方保住站位，却失去主动——看客知道是你收了手。")
	var crowd := L10n.t("ui.reckon.crowd.punish", "闲话倒戈：这一回，笑的人换了边。") if mode == "punish" \
		else L10n.t("ui.reckon.crowd.forgive", "闲话变短：不是他没输，是你准他留脸。")
	var shame := L10n.t("ui.reckon.shame.punish", "失态：对方想笑，笑不出来。话头从他嘴里掉到地上。") if mode == "punish" \
		else L10n.t("ui.reckon.shame.forgive", "失态压住了——不是他没输，是你准他不在当场崩盘。")
	_beats = [
		{
			"id": "flash",
			"title": L10n.t("ui.flashback", "【闪回】"),
			"body": L10n.t(fb, fb),
		},
		{
			"id": "address",
			"title": L10n.t("ui.reckon_address", "称呼一变"),
			"body": L10n.t("ui.reckon.address_named", "看客改口：%s") % address if not address.is_empty() \
				else L10n.t("ui.reckon.address_body", "看客改口的一瞬，比银子响。"),
			"splash": address,
		},
		{
			"id": "standing",
			"title": L10n.t("ui.reckon_standing", "站位"),
			"body": standing,
		},
		{
			"id": "crowd",
			"title": L10n.t("ui.reckon_crowd", "看客"),
			"body": crowd,
		},
	]
	if is_main:
		_beats.append({
			"id": "shame",
			"title": L10n.t("ui.reckon_shame", "失态"),
			"body": shame,
		})
	_beats.append({
		"id": "resolve",
		"title": L10n.t("ui.reckon.main_title", "主清算") if is_main else L10n.t("ui.reckon_title", "清算"),
		"body": L10n.t(
			"ui.reckon.%s" % mode,
			"罚：当众夺脸。" if mode == "punish" else "恕：能杀而收刀。"
		) + "\n" + land + "\n" + L10n.t("ui.reckon.status", "恩怨状态 → %s") % status,
	})
	_idx = 0
	_open()
	_show_beat()


func _open() -> void:
	visible = true
	_apply_chrome()
	_rebuild_dots()
	_refresh_rank_path()
	if glow:
		glow.visible = _mode == "promo"
		glow.modulate.a = 0.0
	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	if bottom_veil:
		bottom_veil.modulate.a = 0.0
	if _open_tween and _open_tween.is_valid():
		_open_tween.kill()
	_open_tween = create_tween()
	_open_tween.set_parallel(true)
	_open_tween.tween_property(dim, "modulate:a", 1.0, 0.28)
	_open_tween.tween_property(panel, "modulate:a", 1.0, 0.32)
	_open_tween.tween_property(panel, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if glow:
		_open_tween.tween_property(glow, "modulate:a", 1.0, 0.4)
	if bottom_veil:
		_open_tween.tween_property(bottom_veil, "modulate:a", 1.0, 0.25)


func _refresh_rank_path() -> void:
	if rank_path == null:
		return
	if _mode != "promo":
		rank_path.visible = false
		if rank_path_banner:
			rank_path_banner.visible = false
		return
	var old_r := String(_payload.get("old_rank", ""))
	var new_r := String(_payload.get("new_rank", ""))
	var address := String(_payload.get("address", _payload.get("title", "")))
	var old_name := PromotionSystem.address_for(old_r) if not old_r.is_empty() else L10n.t("rank.apprentice", "瑞生")
	var new_name := address if not address.is_empty() else PromotionSystem.address_for(new_r)
	rank_path.text = L10n.t("promo.rank_path", "%s  →  %s") % [old_name, new_name]
	if rank_path_banner:
		rank_path_banner.visible = true
		rank_path_banner.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(rank_path_banner, "modulate:a", 1.0, 0.35)
	else:
		rank_path.visible = true
		rank_path.modulate.a = 0.0
		var tw2 := create_tween()
		tw2.tween_property(rank_path, "modulate:a", 1.0, 0.35)


func _rebuild_dots() -> void:
	_clear_dots()
	if step_dots == null:
		return
	for i in range(_beats.size()):
		var dot := Label.new()
		dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.custom_minimum_size = Vector2(56, 26)
		dot.add_theme_font_size_override("font_size", 15)
		step_dots.add_child(dot)
		_dot_nodes.append(dot)
	_paint_dots()


func _clear_dots() -> void:
	for d in _dot_nodes:
		if is_instance_valid(d):
			d.queue_free()
	_dot_nodes.clear()
	if step_dots:
		for c in step_dots.get_children():
			c.queue_free()


func _paint_dots() -> void:
	for i in range(_dot_nodes.size()):
		var dot: Label = _dot_nodes[i]
		var beat: Dictionary = _beats[i] if i < _beats.size() and typeof(_beats[i]) == TYPE_DICTIONARY else {}
		var bid := String(beat.get("id", ""))
		var label := String(BEAT_LABELS.get(bid, "·"))
		dot.text = label
		if i < _idx:
			## 已过：深褐可读
			dot.add_theme_color_override("font_color", Color(0.42, 0.28, 0.16, 1))
			dot.add_theme_font_size_override("font_size", 15)
		elif i == _idx:
			## 当前：朱红加粗
			dot.add_theme_color_override("font_color", Color(0.72, 0.22, 0.12, 1))
			dot.add_theme_font_size_override("font_size", 17)
		else:
			## 未到：仍要够深，别融进奶油底
			dot.add_theme_color_override("font_color", Color(0.42, 0.32, 0.22, 1))
			dot.add_theme_font_size_override("font_size", 15)


func _show_beat() -> void:
	if _idx >= _beats.size():
		visible = false
		if title_splash:
			title_splash.visible = false
		if unlock_label:
			unlock_label.visible = false
		if strike:
			strike.visible = false
		if rank_path:
			rank_path.visible = false
		if rank_path_banner:
			rank_path_banner.visible = false
		if glow:
			glow.visible = false
		_clear_dots()
		ceremony_finished.emit()
		DomainBus.emit_domain("ceremony_finished", {
			"mode": _mode,
			"old_rank": String(_payload.get("old_rank", "")),
			"new_rank": String(_payload.get("new_rank", "")),
		})
		return
	var beat: Dictionary = _beats[_idx]
	var bid := String(beat.get("id", ""))
	_paint_dots()
	beat_label.text = String(BEAT_LABELS.get(bid, "%d / %d" % [_idx + 1, _beats.size()]))
	if seal:
		seal.text = "印" if _mode == "promo" else "断"
		seal.add_theme_color_override("font_color", Color(0.72, 0.28, 0.18, 1) if _mode == "promo" else Color(0.55, 0.2, 0.18, 1))
	if title_splash:
		title_splash.visible = false
	if unlock_label:
		unlock_label.visible = false
	if strike:
		strike.visible = false
	if _mode == "promo":
		var loc := String(beat.get("loc_key", ""))
		var seat := String(_payload.get("seat", ""))
		title_label.text = L10n.t("promo.overlay_title_external", "外座仪典") if not seat.is_empty() \
			else L10n.t("promo.overlay_title_ritual", "升职仪典")
		var body := L10n.t(loc, loc)
		var address := String(_payload.get("address", _payload.get("title", "")))
		match bid:
			"ritual":
				## 标题单独放大加色，避免 [b] 在缺粗体时看起来又细又小
				body = "[center][font_size=28][color=#2a160c]%s[/color][/font_size][/center]\n\n[center][font_size=18][color=#4a3424]%s[/color][/font_size][/center]" % [
					L10n.t("promo.beat.ritual_head", "前堂落槌 · 当众点名"),
					L10n.t(loc, loc),
				]
			"title":
				body = "[center][font_size=24][color=#2a160c]%s[/color][/font_size][/center]" % (
					L10n.t(loc, "称呼：%s") % String(beat.get("title", address))
				)
				_splash_title(String(beat.get("title", address)))
			"standing":
				body = "[center][font_size=20][color=#2a160c]%s[/color][/font_size][/center]" % L10n.t(loc, loc)
				if not address.is_empty():
					_splash_title(address)
				_pulse_panel_rise()
			"permission":
				var unlocks: Array = beat.get("unlocks", _payload.get("unlocks", []))
				if unlocks.is_empty():
					body = "[center][font_size=20][color=#2a160c]%s[/color][/font_size][/center]" % L10n.t(loc, loc)
				else:
					var plain := L10n.t("promo.beat.permission_list", "权限亮起：\n· %s") % "\n· ".join(unlocks)
					body = "[font_size=20][color=#2a160c]%s[/color][/font_size]" % plain
					if unlock_label:
						unlock_label.visible = true
						unlock_label.text = plain
						unlock_label.add_theme_font_size_override("font_size", 20)
						unlock_label.add_theme_color_override("font_color", KairoStyle.INK)
						unlock_label.modulate = Color(1.25, 1.15, 0.9, 1)
						var twu := create_tween()
						twu.tween_property(unlock_label, "modulate", Color(1, 1, 1, 1), 0.4)
						body = "[center][font_size=18][color=#4a3424]%s[/color][/font_size][/center]" % L10n.t(
							"promo.beat.permission_note", "新差事进你的名册——堂上人看在眼里。"
						)
			"pay":
				var monthly := int(beat.get("monthly", _payload.get("monthly", 0)))
				body = "[center][font_size=28][b][color=#8a5a18]%s[/color][/b][/font_size]\n[font_size=18][color=#4a3424]%s[/color][/font_size][/center]" % [
					L10n.t("promo.beat.pay_amount", "月例档 · %d 两") % monthly,
					L10n.t(loc, "月例档上跳"),
				]
			"grudge_window":
				body = "[center][font_size=20][color=#2a160c]%s[/color][/font_size][/center]" % L10n.t(loc, loc)
		body_label.text = body
	else:
		title_label.text = String(beat.get("title", ""))
		body_label.text = String(beat.get("body", ""))
		var splash := String(beat.get("splash", ""))
		if not splash.is_empty():
			_splash_title(splash)
		if bid == "resolve" and strike:
			strike.visible = true
			strike.scale = Vector2(0.05, 1)
			strike.modulate.a = 1.0
			var tws := create_tween()
			tws.tween_property(strike, "scale:x", 1.0, 0.28)
	next_btn.text = L10n.t("ui.continue_hint", "继续（空格）") if _idx < _beats.size() - 1 else L10n.t("ui.done", "收势")
	body_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(body_label, "modulate:a", 1.0, 0.22)


func _pulse_panel_rise() -> void:
	if panel == null:
		return
	panel.scale = Vector2(0.96, 0.96)
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2(1.02, 1.02), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.18)


func _splash_title(title: String) -> void:
	if title_splash == null or title.is_empty():
		return
	title_splash.visible = true
	title_splash.text = title
	title_splash.modulate.a = 0.0
	title_splash.scale = Vector2(0.72, 0.72)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(title_splash, "modulate:a", 1.0, 0.28)
	tw.tween_property(title_splash, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	## 金光闪一下
	if glow:
		glow.visible = true
		glow.modulate = Color(1.2, 1.05, 0.7, 0.35)
		tw.tween_property(glow, "modulate", Color(1, 1, 1, 1), 0.5)


func _on_next() -> void:
	_idx += 1
	_show_beat()
