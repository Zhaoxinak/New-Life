extends Node
## 朝账音效钩子：有资源则播，无则静默。表现层专用，不改 run_*。

const AUDIO_DIR := "res://art/audio/meeting/"

var _se: AudioStreamPlayer
var _bgm: AudioStreamPlayer
var _enabled: bool = true


func _ready() -> void:
	_se = AudioStreamPlayer.new()
	_se.name = "MeetingSE"
	add_child(_se)
	_bgm = AudioStreamPlayer.new()
	_bgm.name = "MeetingBGM"
	_bgm.volume_db = -14.0
	add_child(_bgm)


func set_enabled(on: bool) -> void:
	_enabled = on
	if not on:
		stop_bgm()


func play_cue(cue_id: String) -> void:
	if not _enabled:
		return
	var path := _path_for(cue_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	_se.stream = stream
	_se.play()


func start_bgm() -> void:
	if not _enabled:
		return
	var path := _path_for("bgm")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	if _bgm.playing:
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		## 16-bit mono：每帧 2 字节
		var bytes_per := 2
		if wav.stereo:
			bytes_per = 4
		wav.loop_end = int(wav.data.size() / bytes_per)
	_bgm.stream = stream
	_bgm.volume_db = -14.0
	_bgm.play()


func stop_bgm() -> void:
	if _bgm and _bgm.playing:
		_bgm.stop()


func duck_bgm_for_gavel() -> void:
	if not _bgm or not _bgm.playing:
		return
	var tw := create_tween()
	tw.tween_property(_bgm, "volume_db", -28.0, 0.15)
	tw.tween_interval(0.55)
	tw.tween_property(_bgm, "volume_db", -14.0, 0.4)


func _path_for(cue_id: String) -> String:
	match cue_id:
		"open":
			return AUDIO_DIR + "open.wav"
		"gavel":
			return AUDIO_DIR + "gavel.wav"
		"cut":
			return AUDIO_DIR + "cut.wav"
		"seat":
			return AUDIO_DIR + "seat.wav"
		"bgm":
			return AUDIO_DIR + "bgm_loop.wav"
		_:
			return ""
