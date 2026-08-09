extends Control




@onready var brand: Label = %Brand
@onready var subtitle: Label = %Subtitle
@onready var tagline: Label = %Tagline
@onready var new_btn: Button = %NewButton
@onready var continue_btn: Button = %ContinueButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var stage = %SceneStage
@onready var menu_column: VBoxContainer = %MenuColumn
@onready var prologue_root: Control = %PrologueRoot
@onready var prologue_chapter: Label = %PrologueChapter
@onready var prologue_body: RichTextLabel = %PrologueBody
@onready var prologue_hint: Label = %PrologueHint

const SettingsPanelScene: = preload("res://ui/SettingsPanel.tscn")
const SaveSlotPanelScene: = preload("res://ui/SaveSlotPanel.tscn")
const PROLOGUE_MIN_SEC: = 0.0

var _settings: CanvasLayer = null
var _slots: CanvasLayer = null
var _load_btn: Button = null
var _prologue_active: bool = false
var _prologue_segments: PackedStringArray = PackedStringArray()
var _prologue_index: int = 0
var _prologue_awaiting: bool = false
var _prologue_ready_at_ms: int = 0
var _prologue_token: int = 0


func _ready() -> void :
	SaveSystem.set_session_active(false)
	new_btn.pressed.connect(_on_new)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	_load_btn = Button.new()
	_load_btn.name = "LoadButton"
	_load_btn.custom_minimum_size = Vector2(320, 52)
	_load_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_column.add_child(_load_btn)
	menu_column.move_child(_load_btn, continue_btn.get_index() + 1)
	_load_btn.pressed.connect(_on_load)
	for b in [new_btn, continue_btn, _load_btn, settings_btn, quit_btn]:
		UiStyle.apply_cozy_button(b)
		b.custom_minimum_size = Vector2(320, 52)
	stage.set_location("dock")
	_settings = SettingsPanelScene.instantiate()
	add_child(_settings)
	_slots = SaveSlotPanelScene.instantiate()
	add_child(_slots)
	if _slots.has_signal("loaded_and_ready"):
		_slots.loaded_and_ready.connect(_enter_loaded_game)
	_set_prologue_visible(false)
	_refresh()

	SfxPlayer.play_ambience("title")
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func _on_locale(_l: String) -> void :
	_refresh()
	if _prologue_active and _prologue_index < _prologue_segments.size():
		_show_prologue_segment(_prologue_index)


func _refresh() -> void :
	brand.text = L10n.t("ui.game.title", "码头风云")
	subtitle.text = L10n.t("ui.game.subtitle", "复仇之路")
	tagline.text = L10n.t("ui.game.tagline", "你是林阿海。港城顺风里，裂缝已经张开。")
	new_btn.text = L10n.t("ui.menu.new_game", "新游戏")
	continue_btn.text = L10n.t("ui.menu.continue", "继续游戏")
	if _load_btn:
		_load_btn.text = L10n.t("ui.save.load_game", "读取游戏")
	settings_btn.text = L10n.t("ui.menu.settings", "设置")
	quit_btn.text = L10n.t("ui.menu.quit_game", "退出游戏")
	var any_save: = SaveSystem.has_any_save()
	continue_btn.disabled = not any_save
	if _load_btn:
		_load_btn.disabled = not any_save
	prologue_chapter.text = L10n.t("ui.prologue.chapter", "序 · 港城")
	prologue_hint.text = L10n.t("ui.event.continue_hint", "点击继续…")


func _input(event: InputEvent) -> void :
	if not _prologue_active or not _prologue_awaiting:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_prologue_advance()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_try_prologue_advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_try_prologue_advance()
			get_viewport().set_input_as_handled()


func _on_new() -> void :
	if _prologue_active:
		return
	SfxPlayer.play_click()
	_play_prologue()


func _play_prologue() -> void :
	_prologue_token += 1
	var token: = _prologue_token
	_prologue_active = true
	_prologue_awaiting = false
	_prologue_index = 0
	var body: = L10n.t(
		"ui.prologue.body", 
		"潮起潮落，这座港靠力与算计吃饭。货轮靠岸、账房拨算盘，谁先站稳，谁就能往上爬。|||你是林阿海——周记洋行装卸组长。码头上喊一声「阿海」，半个货仓都听得见。|||苦干这些年，升职几乎板上钉钉，未婚妻苏晚晴也开始跟你谈婚事。你以为，日子终于往上走了。|||今早你顺路去副理办公室，想问一句升职——门还没敲，里面先传来少霆的笑声，还有她压低的应声。"
	)
	_prologue_segments = EventStaging.split_body(body)
	menu_column.visible = false
	_set_prologue_visible(true)
	prologue_root.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(prologue_root, "modulate:a", 1.0, 0.35)
	SfxPlayer.play_stinger("tide")
	await tw.finished
	if token != _prologue_token:
		return
	while token == _prologue_token and _prologue_index < _prologue_segments.size():
		_show_prologue_segment(_prologue_index)
		var is_last: = _prologue_index >= _prologue_segments.size() - 1
		if is_last:
			prologue_hint.text = L10n.t("ui.prologue.enter_hint", "踏入港区…")
		else:
			prologue_hint.text = L10n.t("ui.event.continue_hint", "点击继续…")
		prologue_hint.visible = true
		_prologue_awaiting = true
		_prologue_ready_at_ms = Time.get_ticks_msec() + int(PROLOGUE_MIN_SEC * 1000.0)
		while token == _prologue_token and _prologue_awaiting:
			await get_tree().process_frame
		if token != _prologue_token:
			return
		if is_last:
			break
		_prologue_index += 1
	await _enter_new_game(token)


func _show_prologue_segment(index: int) -> void :
	var text: = _prologue_segments[index] if index < _prologue_segments.size() else ""
	prologue_body.text = text
	prologue_body.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(prologue_body, "modulate:a", 1.0, 0.28)


func _try_prologue_advance() -> void :
	if not _prologue_awaiting:
		return
	if Time.get_ticks_msec() < _prologue_ready_at_ms:
		return
	_prologue_awaiting = false
	SfxPlayer.play_click()


func _enter_new_game(token: int) -> void :
	if token != _prologue_token:
		return
	_prologue_awaiting = false
	var tw: = create_tween()
	tw.tween_property(prologue_root, "modulate:a", 0.0, 0.4)
	await tw.finished
	if token != _prologue_token:
		return
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _set_prologue_visible(on: bool) -> void :
	prologue_root.visible = on
	prologue_root.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	if not on:
		prologue_hint.visible = false


func _on_continue() -> void :
	if _prologue_active:
		return
	SfxPlayer.play_click()
	if SaveSystem.load_slot(SaveSystem.most_recent_slot()):
		_enter_loaded_game()


func _on_load() -> void :
	if _prologue_active:
		return
	SfxPlayer.play_click()
	if _slots and _slots.has_method("open"):
		_slots.open(1)


func _enter_loaded_game() -> void :
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_settings() -> void :
	if _prologue_active:
		return
	SfxPlayer.play_click()
	if _settings and _settings.has_method("open"):
		_settings.open(0)


func _on_quit() -> void :
	if _prologue_active:
		return
	SfxPlayer.play_click()
	get_tree().quit()
