extends CanvasLayer
## 升职四件套 / 清算闪回的 2D 演出层。

signal ceremony_finished

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = %TitleLabel
@onready var beat_label: Label = %BeatLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var next_btn: Button = %NextBtn
@onready var title_splash: Label = %TitleSplash
@onready var unlock_label: Label = %UnlockLabel
@onready var strike: ColorRect = %Strike

var _beats: Array = []
var _idx: int = 0
var _mode: String = ""
var _payload: Dictionary = {}


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	next_btn.pressed.connect(_on_next)
	if title_splash:
		title_splash.visible = false
	if unlock_label:
		unlock_label.visible = false
	if strike:
		strike.visible = false
	if not DomainBus.domain_event.is_connected(_on_domain):
		DomainBus.domain_event.connect(_on_domain)


func force_hide() -> void:
	visible = false
	_beats.clear()
	_idx = 0
	_mode = ""
	_payload.clear()
	if title_splash:
		title_splash.visible = false
	if unlock_label:
		unlock_label.visible = false
	if strike:
		strike.visible = false


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
	var land := L10n.t("ui.reckon.land.punish", "落点：仇人失态的脸。") if mode == "punish" \
		else L10n.t("ui.reckon.land.forgive", "落点：你收势的手。")
	_beats = [
		{
			"id": "flash",
			"title": L10n.t("ui.flashback", "【闪回】"),
			"body": L10n.t(fb, fb),
		},
		{
			"id": "address",
			"title": L10n.t("ui.reckon_address", "称呼一变"),
			"body": L10n.t("ui.reckon.address_body", "看客改口的一瞬，比银子响。"),
		},
		{
			"id": "resolve",
			"title": L10n.t("ui.reckon_title", "清算"),
			"body": L10n.t(
				"ui.reckon.%s" % mode,
				"罚：当众夺脸。" if mode == "punish" else "恕：能杀而收刀。"
			) + "\n" + land + "\n" + L10n.t("ui.reckon.status", "恩怨状态 → %s") % status,
		},
	]
	_idx = 0
	_open()
	_show_beat()


func _open() -> void:
	visible = true
	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.2)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)


func _show_beat() -> void:
	if _idx >= _beats.size():
		visible = false
		if title_splash:
			title_splash.visible = false
		if unlock_label:
			unlock_label.visible = false
		if strike:
			strike.visible = false
		ceremony_finished.emit()
		return
	var beat: Dictionary = _beats[_idx]
	beat_label.text = "%d / %d" % [_idx + 1, _beats.size()]
	if title_splash:
		title_splash.visible = false
	if unlock_label:
		unlock_label.visible = false
	if strike:
		strike.visible = false
	if _mode == "promo":
		var loc := String(beat.get("loc_key", ""))
		title_label.text = L10n.t("promo.overlay_title", "升职")
		var body := L10n.t(loc, loc)
		var bid := String(beat.get("id", ""))
		if bid == "title" and beat.has("title"):
			body = L10n.t(loc, "称呼：%s") % String(beat.get("title", ""))
			_splash_title(String(beat.get("title", "")))
		elif bid == "permission":
			var unlocks: Array = beat.get("unlocks", _payload.get("unlocks", []))
			if unlocks.is_empty():
				body = L10n.t(loc, loc)
			else:
				body = L10n.t("promo.beat.permission_list", "权限亮起：\n· %s") % "\n· ".join(unlocks)
			if unlock_label:
				unlock_label.visible = true
				unlock_label.text = body
				unlock_label.modulate = Color(1.4, 1.4, 1.4, 1)
				var twu := create_tween()
				twu.tween_property(unlock_label, "modulate", Color(1, 1, 1, 1), 0.35)
		elif bid == "pay" and beat.has("monthly"):
			body = L10n.t(loc, "月例档上跳：%d 两") % int(beat.get("monthly", 0))
		body_label.text = body
	else:
		title_label.text = String(beat.get("title", ""))
		body_label.text = String(beat.get("body", ""))
		if String(beat.get("id", "")) == "resolve" and strike:
			strike.visible = true
			strike.scale = Vector2(0.05, 1)
			strike.modulate.a = 1.0
			var tws := create_tween()
			tws.tween_property(strike, "scale:x", 1.0, 0.28)
	next_btn.text = L10n.t("ui.continue_hint", "继续（空格）") if _idx < _beats.size() - 1 else L10n.t("ui.done", "收势")
	body_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(body_label, "modulate:a", 1.0, 0.18)


func _splash_title(title: String) -> void:
	if title_splash == null:
		return
	title_splash.visible = true
	title_splash.text = title
	title_splash.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(title_splash, "modulate:a", 1.0, 0.35)


func _on_next() -> void:
	_idx += 1
	_show_beat()
