extends Node


var enabled: bool = true
var volume: float = 1.0

var prefer_neural: bool = true

var _player: AudioStreamPlayer
var _token: int = 0
var _python: String = ""
var _script_path: String = ""
var _cache_dir: String = ""
var _edge_available: bool = false


func _ready() -> void :
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_cache_dir = ProjectSettings.globalize_path("user://voice_cache")
	DirAccess.make_dir_recursive_absolute(_cache_dir)
	_script_path = _resolve_script_path()
	_python = _resolve_python()
	_edge_available = _python != "" and _script_path != "" and FileAccess.file_exists(_script_path)
	if _edge_available:
		print("VoicePlayer: edge-tts ready (%s)" % _python)
	else:
		print("VoicePlayer: edge-tts unavailable, system TTS only")


func speak(text: String, speaker_id: String = "") -> void :
	if not enabled:
		return
	var cleaned: = text.strip_edges()
	if cleaned.is_empty():
		return
	_token += 1
	var token: = _token
	_stop_audio()
	var voice: = _neural_voice_for(speaker_id)
	var rate: = _edge_rate_for(speaker_id)
	var pitch: = _edge_pitch_for(speaker_id)
	var cache_path: = _cache_path(voice, cleaned, rate, pitch)
	if FileAccess.file_exists(cache_path) and _play_mp3(cache_path):
		return
	if prefer_neural and _edge_available:
		WorkerThreadPool.add_task(
			_generate_task.bind(cleaned, voice, rate, pitch, cache_path, token, speaker_id)
		)
		return
	_speak_system(cleaned, speaker_id)


func stop() -> void :
	_token += 1
	_stop_audio()


func set_enabled(on: bool) -> void :
	enabled = on
	if not on:
		stop()


func _stop_audio() -> void :
	if _player and _player.playing:
		_player.stop()
	if _player:
		_player.stream = null
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()


func _generate_task(
	text: String, 
	voice: String, 
	rate: String, 
	pitch: String, 
	cache_path: String, 
	token: int, 
	speaker_id: String
) -> void :
	var text_file: = "%s/_pending_%d.txt" % [_cache_dir, token]
	var tf: = FileAccess.open(text_file, FileAccess.WRITE)
	if tf == null:
		call_deferred("_on_generate_done", cache_path, token, 10, speaker_id, text, text_file)
		return
	tf.store_string(text)
	tf.close()
	var args: = PackedStringArray([
		_script_path, 
		"--text-file", text_file, 
		"--voice", voice, 
		"--out", cache_path, 
		"--rate", rate, 
		"--pitch", pitch, 
		"--timeout", "12", 
	])
	var output: Array = []
	var code: = OS.execute(_python, args, output, true, false)
	call_deferred("_on_generate_done", cache_path, token, code, speaker_id, text, text_file)


func _on_generate_done(
	cache_path: String, 
	token: int, 
	code: int, 
	speaker_id: String, 
	text: String, 
	text_file: String
) -> void :
	if text_file != "" and FileAccess.file_exists(text_file):
		DirAccess.remove_absolute(text_file)
	if token != _token or not enabled:
		return
	if code == 0 and FileAccess.file_exists(cache_path) and _play_mp3(cache_path):
		return
	_speak_system(text, speaker_id)


func _play_mp3(path: String) -> bool:
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var data: = f.get_buffer(f.get_length())
	f.close()
	if data.is_empty():
		return false
	var stream: = AudioStreamMP3.new()
	stream.data = data
	_stop_audio()
	_player.stream = stream
	_player.volume_db = _volume_db()
	_player.play()
	return true


func _speak_system(text: String, speaker_id: String) -> void :
	if not _has_system_voices():
		return
	var voice_id: = _pick_system_voice_id()
	if voice_id.is_empty():
		return
	var pitch: = _system_pitch_for(speaker_id)
	var rate: = _system_rate_for(speaker_id)
	var vol: = clampi(int(round(clampf(volume, 0.0, 1.0) * 100.0)), 0, 100)
	DisplayServer.tts_speak(text, voice_id, vol, pitch, rate, 0, true)


func _volume_db() -> float:
	var v: = clampf(volume, 0.0, 1.0)
	if v <= 0.001:
		return -80.0
	return linear_to_db(v)


func _cache_path(voice: String, text: String, rate: String, pitch: String) -> String:
	var key: = "%s|%s|%s|%s" % [voice, rate, pitch, text]
	var h: = key.sha256_text().substr(0, 24)
	return "%s/%s.mp3" % [_cache_dir, h]


func _neural_voice_for(speaker_id: String) -> String:
	var zh: = str(L10n.locale).begins_with("zh")
	if zh:
		match speaker_id:
			"su_qing":
				return "zh-CN-XiaoxiaoNeural"
			"zhou_shaoting":
				return "zh-CN-YunxiNeural"
			"zhou_hongye":
				return "zh-CN-YunjianNeural"
			"chen_manager":
				return "zh-CN-YunyangNeural"
			"narrator":
				return "zh-CN-YunyangNeural"
			"player":
				return "zh-CN-YunxiNeural"
			_:
				return "zh-CN-XiaoxiaoNeural"
	match speaker_id:
		"su_qing":
			return "en-US-JennyNeural"
		"zhou_shaoting":
			return "en-US-ChristopherNeural"
		"zhou_hongye":
			return "en-US-GuyNeural"
		"chen_manager":
			return "en-US-DavisNeural"
		"narrator":
			return "en-US-GuyNeural"
		"player":
			return "en-US-ChristopherNeural"
		_:
			return "en-US-JennyNeural"


func _edge_rate_for(speaker_id: String) -> String:
	match speaker_id:
		"su_qing":
			return "-5%"
		"zhou_shaoting":
			return "+5%"
		"zhou_hongye":
			return "-10%"
		"narrator":
			return "-8%"
		_:
			return "+0%"


func _edge_pitch_for(speaker_id: String) -> String:
	match speaker_id:
		"su_qing":
			return "+4Hz"
		"zhou_shaoting":
			return "-2Hz"
		"zhou_hongye":
			return "-6Hz"
		"narrator":
			return "-4Hz"
		_:
			return "+0Hz"


func _system_pitch_for(speaker_id: String) -> float:
	match speaker_id:
		"su_qing":
			return 1.12
		"zhou_shaoting":
			return 0.88
		"zhou_hongye":
			return 0.82
		"chen_manager":
			return 0.95
		"narrator":
			return 0.92
		_:
			return 1.0


func _system_rate_for(speaker_id: String) -> float:
	match speaker_id:
		"su_qing":
			return 0.95
		"zhou_shaoting":
			return 1.05
		"zhou_hongye":
			return 0.9
		"narrator":
			return 0.88
		_:
			return 1.0


func _has_system_voices() -> bool:
	return not DisplayServer.tts_get_voices().is_empty()


func _pick_system_voice_id() -> String:
	var voices: = DisplayServer.tts_get_voices()
	if voices.is_empty():
		return ""
	var want: = "zh" if str(L10n.locale).begins_with("zh") else "en"
	var fallback: = ""
	for v in voices:
		if typeof(v) != TYPE_DICTIONARY:
			continue
		var id: = str(v.get("id", ""))
		var lang: = str(v.get("language", "")).to_lower()
		if id.is_empty():
			continue
		if fallback.is_empty():
			fallback = id
		if lang.begins_with(want):
			return id
	return fallback


func _resolve_script_path() -> String:
	var candidates: = [
		ProjectSettings.globalize_path("res://../tools/edge_tts_speak.py"), 
		ProjectSettings.globalize_path("res://../../tools/edge_tts_speak.py"), 
	]
	for p in candidates:
		if p != "" and FileAccess.file_exists(p):
			return p

	var abs_guess: = "F:/Games/New-Life/tools/edge_tts_speak.py"
	if FileAccess.file_exists(abs_guess):
		return abs_guess
	return ""


func _resolve_python() -> String:
	for cmd in ["python", "py"]:
		var output: Array = []
		var code: = OS.execute(cmd, PackedStringArray(["--version"]), output, true, false)
		if code == 0:
			return cmd
	return ""


func _exit_tree() -> void :
	stop()
