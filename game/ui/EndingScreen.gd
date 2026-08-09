extends CanvasLayer


@onready var root_panel: Control = %Root
@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var close_button: Button = %CloseButton

const DEFAULT_VEIL: = Color(0.1, 0.07, 0.04, 0.72)

var _open_token: int = 0


func _ready() -> void :
	visible = false
	root_panel.visible = false
	close_button.pressed.connect(_on_close)
	UiStyle.apply_cozy_button(close_button)
	if not GameState.game_ended.is_connected(_on_ended):
		GameState.game_ended.connect(_on_ended)


func _on_ended(ending_id: String) -> void :
	open(ending_id)


func open(ending_id: String) -> void :
	_open_token += 1
	var token: = _open_token
	var win: = true
	var row: = PackDB.get_row("endings", ending_id)
	if not row.is_empty():
		win = str(row.get("win", "1")) == "1"
	var stage: Dictionary = EventStaging.ending_stage(ending_id, win)
	title_label.text = "%s · %s" % [
		L10n.t("ui.ending.win", "阶段目标达成") if win else L10n.t("ui.ending.fail", "失败"), 
		L10n.t("endings.%s.name" % ending_id, ending_id), 
	]
	title_label.add_theme_color_override("font_color", UiStyle.BRASS if win else UiStyle.DANGER)
	body_label.text = L10n.t("endings.%s.description" % ending_id, "")
	close_button.text = L10n.t("ui.common.close", "关闭")
	visible = true
	root_panel.visible = true
	GameFlow.set_ending_open(true)
	TipSystem.queue_tip("tip_ending_show")
	if bool(stage.get("staged", false)):
		await _reveal_staged(token, stage)
	else:
		SfxPlayer.play_ending()
		title_label.modulate.a = 1.0
		body_label.modulate.a = 1.0
		close_button.visible = true
		close_button.disabled = false
		close_button.modulate.a = 1.0
		if root_panel is ColorRect:
			(root_panel as ColorRect).color = DEFAULT_VEIL


func _reveal_staged(token: int, stage: Dictionary) -> void :
	title_label.modulate.a = 0.0
	body_label.modulate.a = 0.0
	close_button.visible = false
	close_button.disabled = true
	var veil: Color = stage.get("veil", Color(0.04, 0.05, 0.1, 0.88))
	if root_panel is ColorRect:
		(root_panel as ColorRect).color = veil
	var stinger: = str(stage.get("stinger", "")).strip_edges()
	if bool(stage.get("use_fail_sfx", false)):
		SfxPlayer.play_fail()
	elif stinger != "":
		SfxPlayer.play_stinger(stinger)
	await get_tree().create_timer(1.0).timeout
	if token != _open_token:
		return
	if not bool(stage.get("use_fail_sfx", false)):
		SfxPlayer.play_ending()
	var tw: = create_tween()
	tw.set_parallel(true)
	tw.tween_property(title_label, "modulate:a", 1.0, 0.45)
	tw.tween_property(body_label, "modulate:a", 1.0, 0.55).set_delay(0.15)
	await tw.finished
	if token != _open_token:
		return
	await get_tree().create_timer(0.35).timeout
	if token != _open_token:
		return
	close_button.visible = true
	close_button.disabled = false
	close_button.modulate.a = 0.0
	var tw2: = create_tween()
	tw2.tween_property(close_button, "modulate:a", 1.0, 0.25)
	if root_panel is ColorRect and not bool(stage.get("use_fail_sfx", false)):
		var back: = root_panel as ColorRect
		var tw3: = create_tween()
		tw3.tween_property(back, "color", DEFAULT_VEIL, 0.4)


func _on_close() -> void :
	_open_token += 1
	visible = false
	root_panel.visible = false
	title_label.modulate.a = 1.0
	body_label.modulate.a = 1.0
	close_button.modulate.a = 1.0
	close_button.disabled = false
	close_button.visible = true
	if root_panel is ColorRect:
		(root_panel as ColorRect).color = DEFAULT_VEIL
	GameFlow.set_ending_open(false)
