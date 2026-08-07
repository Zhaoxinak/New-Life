extends Node
## Procedural UI SFX (no external audio assets).

var muted: bool = false
var volume_db: float = -8.0
var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)


func play_click() -> void:
	_play(_tone(660.0, 0.04, 0.18))


func play_success() -> void:
	_play(_chord([523.25, 659.25, 783.99], 0.12, 0.22))


func play_fail() -> void:
	_play(_tone(180.0, 0.16, 0.28))


func play_period() -> void:
	_play(_tone(420.0, 0.08, 0.15))


func play_event() -> void:
	_play(_chord([392.0, 493.88], 0.14, 0.2))


func play_ending() -> void:
	_play(_chord([261.63, 329.63, 392.0, 523.25], 0.28, 0.25))


func _play(stream: AudioStream) -> void:
	if muted or stream == null:
		return
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()


func _tone(freq: float, dur: float, amp: float) -> AudioStreamWAV:
	return _render([{ "f": freq, "a": amp }], dur)


func _chord(freqs: Array, dur: float, amp: float) -> AudioStreamWAV:
	var parts: Array = []
	for f in freqs:
		parts.append({ "f": float(f), "a": amp / float(freqs.size()) })
	return _render(parts, dur)


func _render(partials: Array, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := 1.0
		var attack := 0.01
		var release := maxf(0.02, dur * 0.35)
		if t < attack:
			env = t / attack
		elif t > dur - release:
			env = maxf(0.0, (dur - t) / release)
		var s := 0.0
		for p in partials:
			s += sin(TAU * float(p["f"]) * t) * float(p["a"])
		s *= env
		var sample := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
