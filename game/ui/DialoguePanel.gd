extends CanvasLayer


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
var _cold_tone: bool = false


func _ready() -> void :
	add_to_group("dialogue_panel")
	visible = false
	root_panel.visible = false
	next_button.pressed.connect(_on_next)
	UiStyle.apply_cozy_button(next_button)
	if not ActionPipeline.dialogue_requested.is_connected(_on_dialogue_requested):
		ActionPipeline.dialogue_requested.connect(_on_dialogue_requested)
	if RelationJournal.has_method("bind_dialogue_panel"):
		RelationJournal.bind_dialogue_panel(self)


func _on_dialogue_requested(dialogue_id: String, action_id: String) -> void :
	open(dialogue_id, action_id)


func open(dialogue_id: String, action_id: String = "") -> void :
	_dialogue_id = dialogue_id
	_action_id = action_id
	_lines = PackDB.get_dialogue_lines(dialogue_id)
	_line_index = 0
	_awaiting_choice = false
	_cold_tone = _is_cold_su_dialogue(dialogue_id)
	_clear_choices()
	visible = true
	root_panel.visible = true
	GameFlow.set_dialogue_open(true)
	if _cold_tone:
		SfxPlayer.play_stinger("hush")
	else:
		SfxPlayer.play_click()
	if portrait and portrait.has_method("set_cold"):
		portrait.set_cold(_cold_tone)
	if _lines.is_empty():
		_finish("")
		return
	_show_current_line()


func _is_cold_su_dialogue(dialogue_id: String) -> bool:
	if dialogue_id != "dlg_su_talk" and dialogue_id != "dlg_su_guide":
		return false
	return GameState.get_flag("su_accepts_son_gifts", 0) >= 1


func _show_current_line() -> void :
	if _line_index >= _lines.size():
		_show_choices_for_last()
		return
	var line: Dictionary = _lines[_line_index]
	var line_id: = str(line.get("id", ""))
	var speaker: = str(line.get("speaker_id", ""))
	speaker_label.text = L10n.t("npcs.%s.name" % speaker, speaker)
	speaker_label.add_theme_color_override("font_color", UiStyle.WOOD)
	var text: = _resolve_line_text(line_id)
	body_label.text = text
	portrait.set_speaker(speaker)
	if portrait and portrait.has_method("set_cold"):
		portrait.set_cold(_cold_tone)
	next_button.visible = true
	next_button.text = L10n.t("ui.common.confirm", "确定")
	_clear_choices()
	_awaiting_choice = false
	VoicePlayer.speak(text, speaker)


func _resolve_line_text(line_id: String) -> String:
	for variant in PackDB.get_line_variants(line_id):
		var vid: = str(variant.get("id", ""))
		var ok: = ConditionEval.eval_owner("line_variant", vid)
		if ok.get("ok", false):
			return L10n.t("dialogue_line_variants.%s.text" % vid, L10n.t("dialogue_lines.%s.text" % line_id, line_id))
	return L10n.t("dialogue_lines.%s.text" % line_id, line_id)


func _on_next() -> void :
	if _awaiting_choice:
		return
	VoicePlayer.stop()
	SfxPlayer.play_click()
	var line: Dictionary = _lines[_line_index]
	var line_id: = str(line.get("id", ""))
	var choices: = _choices_after(line_id)
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
		var cid: = str(row.get("id", ""))
		var gate: = ConditionEval.eval_owner("dialogue_choice", cid)
		if not gate.get("ok", false):
			continue
		out.append(row)
	return out


func _show_choices_for_last() -> void :
	if _lines.is_empty():
		_finish("")
		return
	var last_id: = str(_lines[_lines.size() - 1].get("id", ""))
	var choices: = _choices_after(last_id)
	if choices.is_empty():
		_finish("")
	else:
		_show_choices(choices)


func _show_choices(choices: Array) -> void :
	_awaiting_choice = true
	next_button.visible = false
	_clear_choices()
	TipSystem.queue_tip("tip_dialogue_branch")
	for row in choices:
		var cid: = str(row.get("id", ""))
		var weight: = "cold" if _cold_tone else _choice_weight(cid)
		var label: = L10n.t("dialogue_choices.%s.label" % cid, cid)
		var prefix: = _choice_prefix(weight)
		var btn: = Button.new()
		btn.text = "%s%s" % [prefix, label]
		btn.tooltip_text = _choice_tooltip(weight)
		UiStyle.apply_choice_button(btn, weight)
		btn.pressed.connect(_on_choice.bind(cid))
		choices_box.add_child(btn)


func _choice_weight(choice_id: String) -> String:

	var favor: = 0.0
	var suspicion: = 0.0
	var tension: = 0.0
	var intel: = 0.0
	for row in PackDB.get_effects("dialogue_choice", choice_id):
		if str(row.get("op", "add")) != "add":
			continue
		var et: = str(row.get("effect_type", ""))
		var key: = str(row.get("key", ""))
		var value: = float(row.get("value", 0))
		if et == "relation" and key.ends_with(":favor"):
			favor += value
		elif et == "stat" and key == "suspicion":
			suspicion += value
		elif et == "stat" and key == "father_son_tension":
			tension += value
		elif et == "stat" and key == "intel":
			intel += value
	if suspicion >= 2.0 or favor <= -4.0 or tension >= 5.0:
		return "hard"
	if favor >= 4.0 and suspicion <= 0.0:
		return "soft"
	if intel >= 3.0 and suspicion <= 1.0:
		return "probe"
	var id: = choice_id
	if id.ends_with("_press") or id.ends_with("_extra") or id.ends_with("_push")\
	or id.ends_with("_needle") or id.ends_with("_cold") or id.ends_with("_jab")\
	or id.ends_with("_greed") or id.ends_with("_bold"):
		return "hard"
	if id.ends_with("_soft") or id.ends_with("_calm") or id.ends_with("_humble")\
	or id.ends_with("_hesitate") or id.ends_with("_wary") or id.ends_with("_delay"):
		return "soft"
	if id.ends_with("_scheme") or id.ends_with("_ask") or id.ends_with("_listen")\
	or id.ends_with("_think") or id.ends_with("_quiet"):
		return "probe"
	return "normal"


func _choice_prefix(weight: String) -> String:
	match weight:
		"soft":
			return L10n.t("ui.choice.prefix_soft", "【退】")
		"hard":
			return L10n.t("ui.choice.prefix_hard", "【硬】")
		"probe":
			return L10n.t("ui.choice.prefix_probe", "【试】")
		"cold":
			return L10n.t("ui.choice.prefix_cold", "【冷】")
		_:
			return ""


func _choice_tooltip(weight: String) -> String:
	match weight:
		"soft":
			return L10n.t("ui.choice.tip_soft", "退让 / 缓和")
		"hard":
			return L10n.t("ui.choice.tip_hard", "强硬 / 高代价")
		"probe":
			return L10n.t("ui.choice.tip_probe", "试探 / 套话")
		"cold":
			return L10n.t("ui.choice.tip_cold", "疏远 / 裂缝")
		_:
			return ""


func _on_choice(choice_id: String) -> void :
	VoicePlayer.stop()
	SfxPlayer.play_click()
	_finish(choice_id)


func _finish(choice_id: String) -> void :
	VoicePlayer.stop()
	visible = false
	root_panel.visible = false
	if portrait and portrait.has_method("set_cold"):
		portrait.set_cold(false)
	_cold_tone = false
	GameFlow.set_dialogue_open(false)
	var dlg: = _dialogue_id
	var act: = _action_id
	_dialogue_id = ""
	finished.emit(dlg, choice_id)
	if act != "":
		ActionPipeline.finish_after_dialogue(act, choice_id)
	elif choice_id != "":

		EffectApplier.apply_owner("dialogue_choice", choice_id)
	_action_id = ""
	TipSystem.pulse_when_free()


func _clear_choices() -> void :
	for c in choices_box.get_children():
		c.queue_free()
