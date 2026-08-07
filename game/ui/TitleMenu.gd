extends Control
## Title / settings over painted harbor stage.


@onready var brand: Label = %Brand
@onready var subtitle: Label = %Subtitle
@onready var tagline: Label = %Tagline
@onready var new_btn: Button = %NewButton
@onready var continue_btn: Button = %ContinueButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var settings_panel: Control = %SettingsPanel
@onready var lang_btn: Button = %LangButton
@onready var mute_btn: Button = %MuteButton
@onready var back_btn: Button = %BackButton
@onready var stage = %SceneStage


func _ready() -> void:
	new_btn.pressed.connect(_on_new)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	lang_btn.pressed.connect(_on_lang)
	mute_btn.pressed.connect(_on_mute)
	back_btn.pressed.connect(_on_back)
	settings_panel.visible = false
	for b in [new_btn, continue_btn, settings_btn, quit_btn, lang_btn, mute_btn, back_btn]:
		UiStyle.apply_cozy_button(b)
		b.custom_minimum_size = Vector2(320, 52)
	stage.set_location("dock")
	_refresh()
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func _on_locale(_l: String) -> void:
	_refresh()


func _refresh() -> void:
	brand.text = L10n.t("ui.game.title", "码头风云")
	subtitle.text = L10n.t("ui.game.subtitle", "复仇之路")
	tagline.text = L10n.t("ui.game.tagline", "近代港口 · 权谋与选择")
	new_btn.text = L10n.t("ui.menu.new_game", "新游戏")
	continue_btn.text = L10n.t("ui.menu.continue", "继续游戏")
	settings_btn.text = L10n.t("ui.menu.settings", "设置")
	quit_btn.text = L10n.t("ui.menu.quit", "退出")
	back_btn.text = L10n.t("ui.settings.back", "返回")
	lang_btn.text = "%s：%s" % [L10n.t("ui.settings.language", "语言"), L10n.locale]
	mute_btn.text = L10n.t("ui.settings.volume_sfx", "音效") + ("：OFF" if SfxPlayer.muted else "：ON")
	continue_btn.disabled = not SaveSystem.has_save()


func _on_new() -> void:
	SfxPlayer.play_click()
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_continue() -> void:
	SfxPlayer.play_click()
	if SaveSystem.load_game():
		get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_settings() -> void:
	SfxPlayer.play_click()
	settings_panel.visible = true


func _on_back() -> void:
	SfxPlayer.play_click()
	settings_panel.visible = false


func _on_lang() -> void:
	SfxPlayer.play_click()
	var next := "en" if L10n.locale == "zh_CN" else "zh_CN"
	L10n.set_locale(next)


func _on_mute() -> void:
	SfxPlayer.muted = not SfxPlayer.muted
	SfxPlayer.play_click()
	_refresh()


func _on_quit() -> void:
	SfxPlayer.play_click()
	get_tree().quit()
