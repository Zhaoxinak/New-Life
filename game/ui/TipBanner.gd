extends CanvasLayer


@onready var root: PanelContainer = %Root
@onready var title_label: Label = %TitleLabel
@onready var label: RichTextLabel = %TipLabel
@onready var close_btn: Button = %CloseButton
@onready var skip_btn: Button = %SkipButton
@onready var progress_label: Label = %ProgressLabel

var _tween: Tween
var _held_visible: bool = false


func _ready() -> void :
	visible = false
	close_btn.pressed.connect(_on_close)
	skip_btn.pressed.connect(_on_skip)
	UiStyle.apply_cozy_button(close_btn)
	UiStyle.apply_cozy_button(skip_btn)
	if not TipSystem.tip_shown.is_connected(_on_tip):
		TipSystem.tip_shown.connect(_on_tip)
	if not GameFlow.block_changed.is_connected(_on_block):
		GameFlow.block_changed.connect(_on_block)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func _on_locale(_l: String) -> void :
	if visible:
		_refresh_chrome()


func _on_block(blocked: bool) -> void :
	if blocked:
		if visible:
			_held_visible = true
			visible = false
	elif _held_visible:
		_held_visible = false
		visible = true


func _on_tip(tip_id: String, text: String) -> void :
	label.text = text
	_refresh_chrome()
	var row: = PackDB.get_row("tips", tip_id)
	var is_tutorial: = str(row.get("category", "")) == "tutorial"
	skip_btn.visible = is_tutorial
	if GameFlow.is_blocked():
		_held_visible = true
		visible = false
		return
	visible = true
	root.modulate.a = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(root, "modulate:a", 1.0, 0.15)
	SfxPlayer.play_click()


func _refresh_chrome() -> void :
	title_label.text = L10n.t("ui.guide.title", "引导")
	var remain: = TipSystem.queue_remaining()
	if remain > 0:
		close_btn.text = L10n.t("ui.tip.next", "下一条")
		progress_label.text = L10n.tf("ui.guide.more", {"n": remain}, "还有 %d 条" % remain)
		progress_label.visible = true
	else:
		close_btn.text = L10n.t("ui.common.close", "关闭")
		progress_label.visible = false
	skip_btn.text = L10n.t("ui.tutorial.skip", "跳过提示")


func _on_close() -> void :
	visible = false
	_held_visible = false
	TipSystem.notify_closed()
	TipSystem.pulse_when_free()


func _on_skip() -> void :
	SfxPlayer.play_click()
	TipSystem.skip_tutorial()
	visible = false
	_held_visible = false
	TipSystem.notify_closed()
	TipSystem.pulse_when_free()
