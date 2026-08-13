extends Node
## 主入口：标题屏 ↔ 玩法壳。玩法壳延迟实例化，缩短 Debug「正在启动」黑屏。

@onready var title: Control = $TitleScreen

var chrome: Control = null
var ceremony: CanvasLayer = null
var meeting_stage: CanvasLayer = null
var cheat: CanvasLayer = null
var title_settings: CanvasLayer = null

const PLAY_CHROME_PATH := "res://ui/PlayChrome.tscn"
const CEREMONY_PATH := "res://ui/CeremonyOverlay.tscn"
const MEETING_STAGE_PATH := "res://ui/MeetingStage.tscn"
const CHEAT_PATH := "res://ui/CheatOverlay.tscn"
const SETTINGS_PATH := "res://ui/SettingsOverlay.tscn"


func _ready() -> void:
	print("暗潮 · pack=%s loaded=%s ver=%s" % [
		PackDB.pack_id, PackDB.loaded, PackDB.content_version()
	])
	title.new_game_requested.connect(_start_new)
	title.load_requested.connect(_start_load)
	title.quit_requested.connect(_quit)
	if title.has_signal("settings_requested"):
		title.settings_requested.connect(_open_title_settings)
	_show_title()
	## 标题先出来，下一帧再装玩法壳，缩短「正在启动」黑屏
	call_deferred("_warmup_play_stack")


func _open_title_settings() -> void:
	if title_settings == null:
		title_settings = (load(SETTINGS_PATH) as PackedScene).instantiate() as CanvasLayer
		add_child(title_settings)
		title_settings.quit_requested.connect(_quit)
		title_settings.return_to_title_requested.connect(func():
			if title_settings:
				title_settings.close_settings()
		)
	## 标题屏：可调显示；存档按钮会因未开局自动灰掉
	title_settings.open_settings(false)


func _warmup_play_stack() -> void:
	_ensure_play_stack()
	if chrome:
		chrome.visible = false
	if ceremony and ceremony.has_method("force_hide"):
		ceremony.force_hide()
	if meeting_stage and meeting_stage.has_method("force_hide"):
		meeting_stage.force_hide()


func _ensure_play_stack() -> void:
	if meeting_stage == null:
		meeting_stage = (load(MEETING_STAGE_PATH) as PackedScene).instantiate() as CanvasLayer
		add_child(meeting_stage)
		if meeting_stage.has_method("force_hide"):
			meeting_stage.force_hide()
		elif meeting_stage:
			meeting_stage.visible = false
	if ceremony == null:
		ceremony = (load(CEREMONY_PATH) as PackedScene).instantiate() as CanvasLayer
		add_child(ceremony)
		if ceremony.has_method("force_hide"):
			ceremony.force_hide()
		elif ceremony:
			ceremony.visible = false
	if chrome == null:
		chrome = (load(PLAY_CHROME_PATH) as PackedScene).instantiate() as Control
		add_child(chrome)
		chrome.visible = false
		if chrome.has_signal("return_to_title"):
			chrome.return_to_title.connect(_show_title)
	if cheat == null:
		cheat = (load(CHEAT_PATH) as PackedScene).instantiate() as CanvasLayer
		add_child(cheat)
		if cheat:
			cheat.visible = false


func _show_title() -> void:
	DialogueRunner.force_abort()
	if chrome:
		chrome.visible = false
	if ceremony and ceremony.has_method("force_hide"):
		ceremony.force_hide()
	elif ceremony:
		ceremony.visible = false
	if meeting_stage and meeting_stage.has_method("force_hide"):
		meeting_stage.force_hide()
	elif meeting_stage:
		meeting_stage.visible = false
	title.visible = true
	title.refresh()


func _enter_play() -> void:
	_ensure_play_stack()
	title.visible = false
	chrome.visible = true
	if ceremony and ceremony.has_method("force_hide"):
		ceremony.force_hide()
	elif ceremony:
		ceremony.visible = false
	if meeting_stage and meeting_stage.has_method("force_hide"):
		meeting_stage.force_hide()
	elif meeting_stage:
		meeting_stage.visible = false


func _start_new() -> void:
	_enter_play()
	if chrome.has_method("boot_new_game"):
		chrome.boot_new_game()


func _start_load(slot_id: int) -> void:
	if not SaveSystem.load_slot(slot_id):
		title.refresh()
		return
	_enter_play()
	if chrome.has_method("boot_from_load"):
		chrome.boot_from_load()


func _quit() -> void:
	get_tree().quit()
