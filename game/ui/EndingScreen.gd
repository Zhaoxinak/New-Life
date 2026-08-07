extends CanvasLayer
## Ending overlay.

@onready var root_panel: Control = %Root
@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	root_panel.visible = false
	close_button.pressed.connect(_on_close)
	UiStyle.apply_cozy_button(close_button)
	if not GameState.game_ended.is_connected(_on_ended):
		GameState.game_ended.connect(_on_ended)


func _on_ended(ending_id: String) -> void:
	open(ending_id)


func open(ending_id: String) -> void:
	var win := true
	var row := PackDB.get_row("endings", ending_id)
	if not row.is_empty():
		win = str(row.get("win", "1")) == "1"
	SfxPlayer.play_ending()
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


func _on_close() -> void:
	visible = false
	root_panel.visible = false
	GameFlow.set_ending_open(false)
