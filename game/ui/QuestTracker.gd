extends CanvasLayer
## Top-left quest tracker with multi-step how-to text.

@onready var root: PanelContainer = %Root
@onready var header: Label = %Header
@onready var title_label: Label = %TitleLabel
@onready var hint_label: RichTextLabel = %HintLabel
@onready var progress_label: Label = %ProgressLabel
@onready var toggle_button: Button = %QuestToggleButton

var _tween: Tween
var _visible: bool = true


func _ready() -> void:
	layer = 6
	if not QuestGuide.quest_changed.is_connected(_on_quest):
		QuestGuide.quest_changed.connect(_on_quest)
	if not QuestGuide.quest_advanced.is_connected(_on_advanced):
		QuestGuide.quest_advanced.connect(_on_advanced)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)
	toggle_button.pressed.connect(_on_toggle_pressed)
	header.text = L10n.t("quest.panel.header", "当前任务")
	call_deferred("_refresh_from_guide")


func _on_locale(_l: String) -> void:
	header.text = L10n.t("quest.panel.header", "当前任务")
	_refresh_from_guide()


func _refresh_from_guide() -> void:
	QuestGuide.refresh_ui()
	_refresh_visibility()


func _refresh_visibility() -> void:
	root.visible = _visible
	var key := "quest.panel.hide" if _visible else "quest.panel.show"
	var label := "隐藏任务" if _visible else "显示任务"
	toggle_button.text = L10n.t(key, label)


func _on_toggle_pressed() -> void:
	_visible = not _visible
	_refresh_visibility()


func _on_quest(_id: String, title: String, hint: String, index: int, total: int) -> void:
	title_label.text = title
	# Support "||" as line breaks for step lists in CSV (no raw newlines).
	hint_label.text = hint.replace("||", "\n")
	if total <= 0:
		progress_label.text = ""
	elif index >= total and _id == "":
		progress_label.text = L10n.t("quest.panel.complete", "已完成")
	else:
		progress_label.text = L10n.tf("quest.panel.progress", {"i": index, "n": total}, "%d / %d" % [index, total])
	root.visible = _visible


func _on_advanced(_done: String, _next: String) -> void:
	if _tween:
		_tween.kill()
	root.modulate = Color(1.2, 1.15, 0.85, 1)
	_tween = create_tween()
	_tween.tween_property(root, "modulate", Color.WHITE, 0.45)
	SfxPlayer.play_success()
