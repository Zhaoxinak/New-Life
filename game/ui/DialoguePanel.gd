extends CanvasLayer
## Modal dialogue player with line variants + choices + portrait view.

signal finished(dialogue_id: String, choice_id: String)

@onready var root_panel: Control = %Root
@onready var speaker_label: Label = %SpeakerLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var next_button: Button = %NextButton
@onready var choices_box: VBoxContainer = %ChoicesBox
@onready var portrait = %Portrait
@onready var panel: PanelContainer = %Panel

var _dialogue_id: String = ""
var _action_id: String = ""
var _lines: Array = []
var _line_index: int = 0
var _awaiting_choice: bool = false


func _ready() -> void:
	visible = false
	root_panel.visible = false
	next_button.pressed.connect(_on_next)
	UiStyle.apply_cozy_button(next_button)
	if not ActionPipeline.dialogue_requested.is_connected(_on_dialogue_requested):
		ActionPipeline.dialogue_requested.connect(_on_dialogue_requested)


func _on_dialogue_requested(dialogue_id: String, action_id: String) -> void:
	open(dialogue_id, action_id)


func open(dialogue_id: String, action_id: String = "") -> void:
	_dialogue_id = dialogue_id
	_action_id = action_id
	_lines = PackDB.get_dialogue_lines(dialogue_id)
	_line_index = 0
	_awaiting_choice = false
	_clear_choices()
	visible = true
	root_panel.visible = true
	GameFlow.set_dialogue_open(true)
	SfxPlayer.play_click()
	if _lines.is_empty():
		_finish("")
		return
	_show_current_line()


func _show_current_line() -> void:
	if _line_index >= _lines.size():
		_show_choices_for_last()
		return
	var line: Dictionary = _lines[_line_index]
	var line_id := str(line.get("id", ""))
	var speaker := str(line.get("speaker_id", ""))
	speaker_label.text = L10n.t("npcs.%s.name" % speaker, speaker)
	speaker_label.add_theme_color_override("font_color", UiStyle.WOOD)
	body_label.text = _resolve_line_text(line_id)
	portrait.set_speaker(speaker)
	next_button.visible = true
	next_button.text = L10n.t("ui.common.confirm", "确定")
	_clear_choices()
	_awaiting_choice = false


func _resolve_line_text(line_id: String) -> String:
	for variant in PackDB.get_line_variants(line_id):
		var vid := str(variant.get("id", ""))
		var ok := ConditionEval.eval_owner("line_variant", vid)
		if ok.get("ok", false):
			return L10n.t("dialogue_line_variants.%s.text" % vid, L10n.t("dialogue_lines.%s.text" % line_id, line_id))
	return L10n.t("dialogue_lines.%s.text" % line_id, line_id)


func _on_next() -> void:
	if _awaiting_choice:
		return
	SfxPlayer.play_click()
	var line: Dictionary = _lines[_line_index]
	var line_id := str(line.get("id", ""))
	var choices := _choices_after(line_id)
	if not choices.is_empty():
		_show_choices(choices)
		return
	_line_index += 1
	if _line_index >= _lines.size():
		_finish("")
		return
	_show_current_line()


func _choices_after(line_id: String) -> Array:
	var out: Array = []
	for row in PackDB.get_dialogue_choices(_dialogue_id):
		if str(row.get("after_line_id", "")) != line_id:
			continue
		var cid := str(row.get("id", ""))
		var gate := ConditionEval.eval_owner("dialogue_choice", cid)
		if not gate.get("ok", false):
			continue
		out.append(row)
	return out


func _show_choices_for_last() -> void:
	if _lines.is_empty():
		_finish("")
		return
	var last_id := str(_lines[_lines.size() - 1].get("id", ""))
	var choices := _choices_after(last_id)
	if choices.is_empty():
		_finish("")
	else:
		_show_choices(choices)


func _show_choices(choices: Array) -> void:
	_awaiting_choice = true
	next_button.visible = false
	_clear_choices()
	TipSystem.queue_tip("tip_dialogue_branch")
	for row in choices:
		var cid := str(row.get("id", ""))
		var btn := Button.new()
		btn.text = L10n.t("dialogue_choices.%s.label" % cid, cid)
		UiStyle.apply_cozy_button(btn)
		btn.pressed.connect(_on_choice.bind(cid))
		choices_box.add_child(btn)


func _on_choice(choice_id: String) -> void:
	SfxPlayer.play_click()
	_finish(choice_id)


func _finish(choice_id: String) -> void:
	visible = false
	root_panel.visible = false
	GameFlow.set_dialogue_open(false)
	var dlg := _dialogue_id
	var act := _action_id
	_dialogue_id = ""
	finished.emit(dlg, choice_id)
	if act != "":
		ActionPipeline.finish_after_dialogue(act, choice_id)
	_action_id = ""
	TipSystem.pulse_when_free()


func _clear_choices() -> void:
	for c in choices_box.get_children():
		c.queue_free()
