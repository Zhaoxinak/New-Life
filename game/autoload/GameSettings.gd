extends Node


const PATH: = "user://settings.cfg"

const WINDOW_PRESETS: = [
	{"id": "720", "w": 1280, "h": 720}, 
	{"id": "900", "w": 1600, "h": 900}, 
	{"id": "1080", "w": 1920, "h": 1080}, 
	{"id": "fullscreen", "w": 0, "h": 0}, 
]

var window_preset: String = "720"
var sfx_volume: float = 0.75
var music_volume: float = 0.7
var music_enabled: bool = true
var voice_enabled: bool = true
var locale: String = "zh_CN"


func _ready() -> void :
	load_settings()
	apply_all()


func load_settings() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	window_preset = str(cfg.get_value("display", "window_preset", window_preset))
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	music_enabled = bool(cfg.get_value("audio", "music_enabled", music_enabled))
	voice_enabled = bool(cfg.get_value("audio", "voice_enabled", voice_enabled))
	locale = str(cfg.get_value("locale", "id", locale))


func save_settings() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("display", "window_preset", window_preset)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "voice_enabled", voice_enabled)
	cfg.set_value("locale", "id", locale)
	cfg.save(PATH)


func apply_all() -> void :
	apply_window()
	apply_audio()
	if locale != "" and L10n.locale != locale:
		L10n.set_locale(locale)


func apply_window() -> void :
	var preset: = _find_preset(window_preset)
	if preset.is_empty():
		preset = WINDOW_PRESETS[0]
		window_preset = str(preset["id"])
	if str(preset["id"]) == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var w: = int(preset["w"])
	var h: = int(preset["h"])
	DisplayServer.window_set_size(Vector2i(w, h))

	var screen: = DisplayServer.window_get_current_screen()
	var usable: = DisplayServer.screen_get_usable_rect(screen)
	var pos: = usable.position + Vector2i(
		maxi(0, (usable.size.x - w) / 2), 
		maxi(0, (usable.size.y - h) / 2)
	)
	DisplayServer.window_set_position(pos)


func apply_audio() -> void :
	SfxPlayer.set_sfx_volume_linear(sfx_volume)
	SfxPlayer.set_music_volume_linear(music_volume)
	SfxPlayer.set_music_enabled(music_enabled)
	VoicePlayer.set_enabled(voice_enabled)


func set_window_preset(preset_id: String) -> void :
	window_preset = preset_id
	apply_window()
	save_settings()


func set_sfx_volume(v: float) -> void :
	sfx_volume = clampf(v, 0.0, 1.0)
	SfxPlayer.set_sfx_volume_linear(sfx_volume)
	save_settings()


func set_music_volume(v: float) -> void :
	music_volume = clampf(v, 0.0, 1.0)
	SfxPlayer.set_music_volume_linear(music_volume)
	save_settings()


func set_music_enabled(on: bool) -> void :
	music_enabled = on
	SfxPlayer.set_music_enabled(music_enabled)
	save_settings()


func set_voice_enabled(on: bool) -> void :
	voice_enabled = on
	VoicePlayer.set_enabled(voice_enabled)
	save_settings()


func set_locale_pref(new_locale: String) -> void :
	locale = new_locale
	L10n.set_locale(new_locale)
	save_settings()


func cycle_window_preset() -> String:
	var idx: = 0
	for i in WINDOW_PRESETS.size():
		if str(WINDOW_PRESETS[i]["id"]) == window_preset:
			idx = i
			break
	idx = (idx + 1) % WINDOW_PRESETS.size()
	var next_id: = str(WINDOW_PRESETS[idx]["id"])
	set_window_preset(next_id)
	return next_id


func window_preset_label() -> String:
	match window_preset:
		"720":
			return "1280×720"
		"900":
			return "1600×900"
		"1080":
			return "1920×1080"
		"fullscreen":
			return L10n.t("ui.settings.fullscreen", "全屏")
		_:
			return window_preset


func _find_preset(id: String) -> Dictionary:
	for p in WINDOW_PRESETS:
		if str(p["id"]) == id:
			return p
	return {}
