extends CanvasLayer
## Modal event panel.

@onready var root_panel: Control = %Root
@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var choices_box: VBoxContainer = %ChoicesBox

var _event_id: String = ""


func _ready() -> void:
	visible = false
	root_panel.visible = false
	if not EventScheduler.event_available.is_connected(_on_event):
		EventScheduler.event_available.connect(_on_event)


func _on_event(event_id: String) -> void:
	open(event_id)


func open(event_id: String) -> void:
	_event_id = event_id
	EventScheduler.ensure_event_effects()
	SfxPlayer.play_event()
	title_label.text = L10n.t("events.%s.title" % event_id, event_id)
	title_label.add_theme_color_override("font_color", UiStyle.WOOD)
	body_label.text = L10n.t("events.%s.body" % event_id, "")
	_clear_choices()
	var choices := PackDB.get_event_choices(event_id)
	var added := 0
	if choices.is_empty():
		var btn := Button.new()
		btn.text = L10n.t("ui.common.confirm", "确定")
		btn.custom_minimum_size = Vector2(0, 44)
		UiStyle.apply_cozy_button(btn)
		btn.pressed.connect(_on_choice.bind(""))
		choices_box.add_child(btn)
		added += 1
	else:
		for row in choices:
			var cid := str(row.get("id", ""))
			if PackDB.get_conditions("event_choice", cid).size() > 0:
				if not ConditionEval.eval_owner("event_choice", cid).get("ok", false):
					continue
			if PackDB.get_conditions("choice", cid).size() > 0:
				if not ConditionEval.eval_owner("choice", cid).get("ok", false):
					continue
			var btn2 := Button.new()
			btn2.text = L10n.t("event_choices.%s.label" % cid, cid)
			btn2.custom_minimum_size = Vector2(0, 44)
			btn2.focus_mode = Control.FOCUS_ALL
			btn2.mouse_filter = Control.MOUSE_FILTER_STOP
			UiStyle.apply_cozy_button(btn2)
			btn2.pressed.connect(_on_choice.bind(cid))
			choices_box.add_child(btn2)
			added += 1
	if added == 0:
		var fallback := Button.new()
		fallback.text = L10n.t("ui.common.confirm", "确定")
		fallback.custom_minimum_size = Vector2(0, 44)
		UiStyle.apply_cozy_button(fallback)
		fallback.pressed.connect(_on_choice.bind(""))
		choices_box.add_child(fallback)
	visible = true
	root_panel.visible = true
	GameFlow.set_event_open(true)
	# Ensure modal sits above tip chrome and receives input.
	layer = 25
	root_panel.mouse_filter = Control.MOUSE_FILTER_STOP



func _on_choice(choice_id: String) -> void:
	SfxPlayer.play_click()
	visible = false
	root_panel.visible = false
	GameFlow.set_event_open(false)
	EventScheduler.resolve_choice(choice_id)
	_event_id = ""
	TipSystem.pulse_when_free()


func _clear_choices() -> void:
	for c in choices_box.get_children():
		c.queue_free()
