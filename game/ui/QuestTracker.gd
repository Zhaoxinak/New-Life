extends CanvasLayer


const MIN_SIZE: = Vector2(200, 96)
const MAX_SIZE: = Vector2(560, 520)
const DEFAULT_SHELL: = Rect2(12, 104, 280, 182)

@onready var shell: VBoxContainer = %Shell
@onready var frame: Control = %Frame
@onready var root: PanelContainer = %Root
@onready var header: Label = %Header
@onready var title_label: Label = %TitleLabel
@onready var hint_label: RichTextLabel = %HintLabel
@onready var progress_label: Label = %ProgressLabel
@onready var toggle_button: Button = %QuestToggleButton
@onready var resize_handle: ColorRect = %ResizeHandle

var _tween: Tween
var _visible: bool = true
var _resizing: bool = false
var _resize_start_mouse: Vector2 = Vector2.ZERO
var _resize_start_shell: Vector2 = Vector2.ZERO


func _ready() -> void :
	layer = 6
	shell.position = DEFAULT_SHELL.position
	shell.size = DEFAULT_SHELL.size
	UiStyle.apply_cozy_button(toggle_button)
	if not QuestGuide.quest_changed.is_connected(_on_quest):
		QuestGuide.quest_changed.connect(_on_quest)
	if not QuestGuide.quest_advanced.is_connected(_on_advanced):
		QuestGuide.quest_advanced.connect(_on_advanced)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)
	toggle_button.pressed.connect(_on_toggle_pressed)
	resize_handle.gui_input.connect(_on_resize_gui)
	resize_handle.tooltip_text = L10n.t("quest.panel.resize_tip", "拖拽右下角调整大小")
	_visible = GameState.quest_pinned
	_refresh_header()
	call_deferred("_refresh_from_guide")


func _on_locale(_l: String) -> void :
	_refresh_header()
	resize_handle.tooltip_text = L10n.t("quest.panel.resize_tip", "拖拽右下角调整大小")
	_refresh_from_guide()


func _on_state() -> void :
	if _visible != GameState.quest_pinned:
		_visible = GameState.quest_pinned
		_refresh_visibility()


func _refresh_header() -> void :
	if QuestGuide.is_current_optional():
		header.text = L10n.t("quest.panel.header_main", "主线目标")
	else:
		header.text = L10n.t("quest.panel.header", "当前任务")


func _refresh_from_guide() -> void :
	QuestGuide.refresh_ui()
	_refresh_visibility()


func _refresh_visibility() -> void :
	frame.visible = _visible
	resize_handle.visible = _visible
	var key: = "quest.panel.hide" if _visible else "quest.panel.show"
	var label: = "收起主线" if _visible else "显示主线"
	toggle_button.text = L10n.t(key, label)

	if _visible:
		shell.custom_minimum_size = Vector2(MIN_SIZE.x, MIN_SIZE.y + 34)
	else:
		shell.custom_minimum_size = Vector2(88, 30)
		shell.size = Vector2(maxi(shell.size.x, 100), 34)


func _on_toggle_pressed() -> void :
	_visible = not _visible
	GameState.quest_pinned = _visible
	_refresh_visibility()


func _on_resize_gui(event: InputEvent) -> void :
	if not _visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_resizing = true
			_resize_start_mouse = event.global_position
			_resize_start_shell = shell.size
			resize_handle.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			_resizing = false


func _input(event: InputEvent) -> void :
	if not _resizing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_resizing = false
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var delta: Vector2 = event.global_position - _resize_start_mouse
		var next: = _resize_start_shell + delta
		next.x = clampf(next.x, MIN_SIZE.x, MAX_SIZE.x)
		next.y = clampf(next.y, MIN_SIZE.y + 34.0, MAX_SIZE.y)
		shell.size = next
		get_viewport().set_input_as_handled()


func _on_quest(_id: String, title: String, hint: String, index: int, total: int) -> void :
	_refresh_header()
	title_label.text = title

	hint_label.text = hint.replace("||", "\n")
	if total <= 0:
		progress_label.text = ""
	elif index >= total and _id == "":
		progress_label.text = L10n.t("quest.panel.complete", "已完成")
	else:
		progress_label.text = L10n.tf("quest.panel.progress", {"i": index, "n": total}, "%d / %d" % [index, total])
	_visible = GameState.quest_pinned
	_refresh_visibility()


func _on_advanced(_done: String, _next: String) -> void :
	if _tween:
		_tween.kill()
	root.modulate = Color(1.2, 1.15, 0.85, 1)
	_tween = create_tween()
	_tween.tween_property(root, "modulate", Color.WHITE, 0.45)
	SfxPlayer.play_success()
