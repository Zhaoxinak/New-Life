extends Node



const SFX_BASE_DB: = -8.0
const MUSIC_BASE_DB: = -11.0

var volume_db: float = SFX_BASE_DB
var music_volume_db: float = MUSIC_BASE_DB
var _sfx_linear: float = 0.75
var _music_linear: float = 0.7

var _muted: bool = false
var muted: bool:
	get:
		return _muted
	set(value):
		_muted = value
		_apply_mute_state()

var _music_enabled: bool = true
var music_enabled: bool:
	get:
		return _music_enabled
	set(value):
		set_music_enabled(value)

var _player: AudioStreamPlayer
var _music: AudioStreamPlayer
var _weather: AudioStreamPlayer

var _bed_location: String = ""
var _bed_mood: String = ""
var _track_id: String = ""
var _weather_id: String = ""
var _duck_token: int = 0
var _fade_token: int = 0
var _switching: bool = false
var _stream_cache: Dictionary = {}
var _recent_tracks: Array[String] = []
var _pool_cursor: Dictionary = {}
var _last_period: String = ""
var _last_day: int = -1


func _ready() -> void :
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	_music.volume_db = music_volume_db
	add_child(_music)
	_weather = AudioStreamPlayer.new()
	_weather.bus = "Master"
	_weather.volume_db = music_volume_db - 6.0
	add_child(_weather)
	if not _music.finished.is_connected(_on_music_finished):
		_music.finished.connect(_on_music_finished)
	if not GameState.state_changed.is_connected(_on_state_changed):
		GameState.state_changed.connect(_on_state_changed)
	_last_period = str(GameState.period)
	_last_day = int(GameState.day)


func set_sfx_volume_linear(v: float) -> void :
	_sfx_linear = clampf(v, 0.0, 1.0)
	volume_db = _linear_to_db(_sfx_linear, SFX_BASE_DB)


func set_music_volume_linear(v: float) -> void :
	_music_linear = clampf(v, 0.0, 1.0)
	music_volume_db = _linear_to_db(_music_linear, MUSIC_BASE_DB)
	_apply_music_level()

	if _weather and _weather.playing and not _muted:
		var w: = str(GameState.weather)
		if w == "storm":
			_weather.volume_db = music_volume_db - 16.0
		elif w == "rain":
			_weather.volume_db = music_volume_db - 20.0


func _target_music_db() -> float:

	return music_volume_db


func _apply_music_level() -> void :
	if _music == null or _muted or not _music_enabled:
		return
	if _music.playing and not _switching:
		_music.volume_db = _target_music_db()


func set_music_enabled(on: bool) -> void :
	_music_enabled = on
	if not on:
		_fade_token += 1
		if _music:
			_music.stop()

		return
	if _muted:
		return
	if _bed_location != "":
		var loc: = _bed_location
		_bed_location = ""
		_track_id = ""
		refresh_beds(loc)


func _linear_to_db(linear: float, base_db: float) -> float:
	if linear <= 0.001:
		return -80.0
	return base_db + linear_to_db(linear)


func _on_state_changed() -> void :
	if _bed_location == "" or _switching or _muted:
		return
	var mood: = resolve_mood()
	_last_period = str(GameState.period)
	_last_day = int(GameState.day)


	if mood != _bed_mood:
		refresh_beds(_bed_location)


func play_click() -> void :
	_play(_tone(660.0, 0.04, 0.18))


func play_success() -> void :
	_play(_chord([523.25, 659.25, 783.99], 0.12, 0.22))


func play_fail() -> void :
	_play(_tone(180.0, 0.16, 0.28))


func play_period() -> void :
	_play(_tone(420.0, 0.08, 0.15))


func play_event() -> void :
	_play(_chord([392.0, 493.88], 0.14, 0.2))


func play_ending() -> void :
	_play(_chord([261.63, 329.63, 392.0, 523.25], 0.28, 0.25))


func play_stinger(kind: String) -> void :
	var k: = kind.strip_edges().to_lower()
	if k == "":
		return
	match k:
		"laugh":
			_play(_laugh_stinger())
		"hush":
			_play(_tone(220.0, 0.22, 0.12))
		"tide":
			_play(_render([
				{"f": 70.0, "a": 0.1}, 
				{"f": 110.0, "a": 0.06}, 
			], 0.45, false, 0.05))
		"shatter":
			_play(_shatter_stinger())
		"bell":
			_play(_chord([523.25, 659.25], 0.32, 0.2))
		"paper":
			_play(_render([
				{"f": 1400.0, "a": 0.06}, 
				{"f": 900.0, "a": 0.04}, 
			], 0.18, false, 0.04))
		"tick":
			_play(_tone(880.0, 0.06, 0.16))
		"rain":
			_play(_render([
				{"f": 180.0, "a": 0.04}, 
				{"f": 320.0, "a": 0.03}, 
			], 0.5, false, 0.09))
		"thud":
			_play(_tone(95.0, 0.2, 0.22))
		"ebike":
			_play(_ebike_whir())
		"moto":
			_play(_moto_growl())
		"car":
			_play(_car_ignition())
		_:
			_play(_tone(400.0, 0.1, 0.15))


func play_ride(tier: int) -> void :

	match clampi(tier, 0, 4):
		1:
			_play(_ebike_whir())
		2:
			_play(_render([
				{"f": 160.0, "a": 0.08}, 
				{"f": 240.0, "a": 0.04}, 
			], 0.35, false, 0.03))
		3:
			_play(_moto_growl())
		4:
			_play(_car_ignition())
		_:
			play_stinger("bell")


func play_ambience(location_id: String) -> void :
	refresh_beds(location_id)


func set_weather(weather_id: String) -> void :

	var wid: = weather_id.strip_edges()
	var want_bed: = wid == "rain" or wid == "storm"
	if wid == _weather_id and _weather != null:
		if want_bed and not _weather.playing and not _muted:
			pass
		elif want_bed and _weather.playing:
			return
		else:
			if not want_bed:
				_stop_weather_bed()
			return
	_weather_id = wid
	if _muted or not want_bed:
		_stop_weather_bed()
		return

	var base: = music_volume_db - 14.0
	if wid == "storm":
		_play_weather_bed(_rain_loop(0.45), base - 2.0)
	else:
		_play_weather_bed(_rain_loop(0.28), base - 6.0)


func _play_weather_bed(stream: AudioStream, vol_db: float) -> void :
	if _weather == null:
		return
	_weather.stop()
	_weather.stream = stream
	_weather.volume_db = -48.0
	_weather.play()
	var tw: = create_tween()
	tw.tween_property(_weather, "volume_db", vol_db, 0.35)


func _stop_weather_bed() -> void :
	if _weather == null:
		return
	if not _weather.playing:
		_weather.stop()
		return
	var tw: = create_tween()
	tw.tween_property(_weather, "volume_db", -48.0, 0.25)
	tw.tween_callback( func():
		if _weather == null:
			return
		var w: = str(GameState.weather)
		if w != "rain" and w != "storm":
			_weather.stop()
	)


func _rain_loop(intensity: float = 0.28) -> AudioStreamWAV:

	var sample_rate: = 22050
	var seconds: = 3.0
	var n: = int(sample_rate * seconds)
	var data: = PackedByteArray()
	data.resize(n * 2)
	var rng: = RandomNumberGenerator.new()
	rng.seed = 90421
	var low: = 0.0
	var mid: = 0.0
	for i in n:
		var white: = rng.randf() * 2.0 - 1.0
		low = low * 0.985 + white * 0.05
		mid = mid * 0.92 + white * 0.08
		var drip: = 0.0
		if rng.randf() < 0.012 * intensity:
			drip = (rng.randf() * 2.0 - 1.0) * 0.12 * intensity
		var s: = (low * 0.7 + mid * 0.35) * (0.22 + intensity * 0.25) + drip
		s = clampf(s, -1.0, 1.0)
		var v: = int(s * 10000.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var stream: = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream

func refresh_beds(location_id: String = "") -> void :
	var loc: = location_id.strip_edges()
	if loc == "":
		loc = _bed_location if _bed_location != "" else "outdoor"
	var mood: = resolve_mood()
	var pool_key: = _pool_key(loc, mood)

	if loc == _bed_location and mood == _bed_mood and _music.playing and not _switching:
		return
	var track: = pick_track(loc, mood, true)
	if _muted or not _music_enabled:
		_bed_location = loc
		_bed_mood = mood
		_track_id = track
		return
	if _switching:
		_bed_location = loc
		_bed_mood = mood
		_track_id = track
		return
	if track == _track_id and _music.playing:
		_bed_location = loc
		_bed_mood = mood
		return
	_crossfade_to_track(loc, mood, track)


func _on_music_finished() -> void :

	if _muted or not _music_enabled or _switching:
		return
	if _bed_location == "":
		return
	var mood: = resolve_mood()
	var track: = pick_track(_bed_location, mood, true)
	_crossfade_to_track(_bed_location, mood, track)


func resolve_mood() -> String:
	if GameState.get_flag("ending_route_a_ready", 0) >= 1\
	or GameState.get_flag("ending_route_b_ready", 0) >= 1\
	or GameState.get_flag("ending_route_c_ready", 0) >= 1\
	or GameState.get_flag("tension_high", 0) >= 1:
		return "climax"
	if GameState.get_flag("route_focus_a", 0) >= 1:
		return "route_a"
	if GameState.get_flag("route_focus_b", 0) >= 1:
		return "route_b"
	if GameState.get_flag("route_focus_c", 0) >= 1:
		return "route_c"
	if GameState.get_flag("su_accepts_son_gifts", 0) >= 1 or GameState.day >= 5:
		return "crack"
	if GameState.get_flag("son_notices_su", 0) >= 1 or GameState.day >= 3:
		return "unease"
	return "calm"


func resolve_track(loc: String, mood: String) -> String:
	return pick_track(loc, mood, false)


func pick_track(loc: String, mood: String, advance: bool) -> String:
	var pool: = _track_pool(loc, mood)
	if pool.is_empty():
		return "asianoriental1"
	var key: = _pool_key(loc, mood)
	var idx: = int(_pool_cursor.get(key, 0))

	var chosen: = ""
	for attempt in pool.size():
		var cand: String = str(pool[(idx + attempt) % pool.size()])
		if cand == _track_id and pool.size() > 1:
			continue
		if _recent_tracks.has(cand) and pool.size() > 2 and attempt + 1 < pool.size():
			continue
		chosen = cand
		if advance:
			_pool_cursor[key] = (idx + attempt + 1) % pool.size()
		break
	if chosen == "":
		chosen = str(pool[idx % pool.size()])
		if advance:
			_pool_cursor[key] = (idx + 1) % pool.size()
	if advance:
		_remember_track(chosen)
	return chosen


func _pool_key(loc: String, mood: String) -> String:
	return "%s|%s" % [loc, _mood_band(mood)]


func _mood_band(mood: String) -> String:
	if mood == "climax":
		return "climax"
	if mood == "crack" or mood == "route_b":
		return "tense"
	if mood == "unease" or mood == "route_c" or mood == "route_a":
		return "unease"
	return "calm"


func _remember_track(track_id: String) -> void :
	_recent_tracks.erase(track_id)
	_recent_tracks.push_front(track_id)
	while _recent_tracks.size() > 4:
		_recent_tracks.pop_back()


func _track_pool(loc: String, mood: String) -> Array[String]:

	var band: = _mood_band(mood)
	var pool: Array[String] = []

	if loc.begins_with("nh_"):
		loc = "home"
	match loc:
		"title":

			pool = ["title_theme", "menu_theme", "port_town"]
		"outdoor":
			match band:
				"calm":
					pool = [
						"asianoriental1", "town_theme_0", "stereotypical_asian_town", 
						"garden3", "market_zone", "rpg_orient_17", "port_town", 
					]
				"unease":
					pool = [
						"market_zone", "mysterious_lake", "dark_theme", "alone", 
						"fools_philosophy", "orien", "liyan", 
					]
				"tense":
					pool = ["orientalsomber", "dark_theme", "defeat", "mysterious_lake", "alone", "fools_philosophy"]
				_:
					pool = ["samurai_nights", "orientalsomber", "dark_theme", "defeat", "determination"]
		"dock":
			match band:
				"calm":
					pool = [
						"port_town", "market_zone", "stereotypical_asian_town", 
						"town_theme_0", "asianoriental1", "ch_ay_na", "rpg_orient_17", 
					]
				"unease":
					pool = [
						"market_zone", "port_town", "mysterious_lake", "orient_high_strings", 
						"dark_theme", "alone", "liyan", 
					]
				"tense":
					pool = ["orientalsomber", "market_zone", "dark_theme", "defeat", "fools_philosophy"]
				_:
					pool = ["samurai_nights", "orientalsomber", "port_town", "dark_theme", "defeat"]
		"company":
			match band:
				"calm":
					pool = [
						"asianoriental2", "fools_philosophy", "koto_booth", "orien", 
						"asianoriental1", "garden3", "melody_vollen", "honor_lowrund_village_theme", 
					]
				"unease":
					pool = [
						"fools_philosophy", "asianoriental2", "mysterious_lake", 
						"orient_high_strings", "dark_theme", "alone", "orien", 
					]
				"tense":
					pool = ["orientalsomber", "fools_philosophy", "dark_theme", "defeat", "mysterious_lake"]
				_:
					pool = ["samurai_nights", "orientalsomber", "fools_philosophy", "dark_theme", "determination"]
		"home":
			match band:
				"calm":
					pool = [
						"home_garden", "garden3", "koto_booth", "asianoriental1", 
						"honor_lowrund_village_theme", "menu_theme", "ch_ay_na", 
					]
				"unease":
					pool = [
						"mysterious_lake", "home_garden", "garden3", "alone", 
						"dark_theme", "orien", "orientalsomber", 
					]
				"tense":
					pool = ["orientalsomber", "mysterious_lake", "dark_theme", "alone", "defeat"]
				_:
					pool = ["samurai_nights", "orientalsomber", "mysterious_lake", "dark_theme", "defeat"]
		"rival":
			match band:
				"calm":
					pool = [
						"fools_philosophy", "mysterious_lake", "orien", "asianoriental2", 
						"orient_high_strings", "dark_theme", "liyan", 
					]
				"unease":
					pool = [
						"mysterious_lake", "fools_philosophy", "dark_theme", "alone", 
						"orientalsomber", "orient_high_strings", "defeat", 
					]
				"tense":
					pool = ["orientalsomber", "dark_theme", "defeat", "fools_philosophy", "samurai_nights"]
				_:
					pool = ["samurai_nights", "orientalsomber", "dark_theme", "defeat", "determination"]
		"exchange":
			match band:
				"calm":
					pool = [
						"city_pulse", "four_sequence", "orient_high_strings", "fools_philosophy", 
						"asianoriental2", "melody_vollen", "koto_booth", 
					]
				"unease":
					pool = [
						"orient_high_strings", "city_pulse", "mysterious_lake", "dark_theme", 
						"alone", "fools_philosophy", "liyan", 
					]
				"tense":
					pool = ["orientalsomber", "city_pulse", "dark_theme", "defeat", "samurai_nights"]
				_:
					pool = ["samurai_nights", "orientalsomber", "city_pulse", "dark_theme", "determination"]
		"plaza":
			match band:
				"calm":
					pool = [
						"market_zone", "stereotypical_asian_town", "town_theme_0", "garden3", 
						"port_town", "asianoriental1", "ch_ay_na", 
					]
				"unease":
					pool = [
						"market_zone", "mysterious_lake", "alone", "orien", 
						"dark_theme", "port_town", "liyan", 
					]
				"tense":
					pool = ["orientalsomber", "market_zone", "dark_theme", "defeat", "alone"]
				_:
					pool = ["samurai_nights", "orientalsomber", "market_zone", "dark_theme", "defeat"]
		"tea_house":
			match band:
				"calm":
					pool = [
						"koto_booth", "garden3", "ch_ay_na", "asianoriental1", 
						"honor_lowrund_village_theme", "menu_theme", "melody_vollen", 
					]
				"unease":
					pool = [
						"mysterious_lake", "orien", "alone", "koto_booth", 
						"dark_theme", "fools_philosophy", 
					]
				"tense":
					pool = ["orientalsomber", "mysterious_lake", "dark_theme", "alone", "defeat"]
				_:
					pool = ["samurai_nights", "orientalsomber", "koto_booth", "dark_theme", "defeat"]
		"garage":
			match band:
				"calm":
					pool = [
						"city_pulse", "market_zone", "port_town", "stereotypical_asian_town", 
						"asianoriental2", "four_sequence", 
					]
				"unease":
					pool = [
						"market_zone", "mysterious_lake", "alone", "city_pulse", 
						"dark_theme", "orien", 
					]
				"tense":
					pool = ["orientalsomber", "city_pulse", "dark_theme", "defeat", "alone"]
				_:
					pool = ["samurai_nights", "orientalsomber", "market_zone", "dark_theme", "defeat"]
		_:
			match band:
				"calm":
					pool = ["asianoriental1", "town_theme_0", "garden3", "menu_theme", "rpg_orient_17"]
				"unease":
					pool = ["market_zone", "mysterious_lake", "dark_theme", "alone", "fools_philosophy"]
				"tense":
					pool = ["orientalsomber", "dark_theme", "mysterious_lake", "defeat"]
				_:
					pool = ["samurai_nights", "orientalsomber", "dark_theme", "defeat"]
	return _filter_existing(pool)


func _filter_existing(pool: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for id in pool:
		var path: = "res://audio/music/%s.ogg" % id
		if ResourceLoader.exists(path) or FileAccess.file_exists(path) or _stream_cache.has(id):
			out.append(id)
		else:

			var abs_path: = ProjectSettings.globalize_path(path)
			if FileAccess.file_exists(abs_path):
				out.append(id)
	if out.is_empty():
		out.append("asianoriental1")
	return out


func stop_ambience() -> void :
	_fade_token += 1
	_bed_location = ""
	_bed_mood = ""
	_track_id = ""
	if _music:
		_music.stop()


func duck_ambience(seconds: float = 0.55) -> void :

	if _muted or not _music_enabled or _music == null or not _music.playing:
		return
	_duck_token += 1
	var token: = _duck_token
	var target: = _target_music_db()
	var mus_t: = target - 6.0
	var tw: = create_tween()
	tw.tween_property(_music, "volume_db", mus_t, 0.12)
	await get_tree().create_timer(maxf(0.1, seconds)).timeout
	if token != _duck_token or _muted:
		return
	var tw2: = create_tween()
	tw2.tween_property(_music, "volume_db", target, 0.28)
	await tw2.finished
	if token == _duck_token and _music and _music.playing:
		_music.volume_db = _target_music_db()


func _volume_for_mood(_mood: String) -> float:

	return _target_music_db()


func _apply_mute_state() -> void :
	if _muted:
		_fade_token += 1
		if _music:
			_music.stop()
		_stop_weather_bed()
		return
	if _music_enabled and _bed_location != "":
		var loc: = _bed_location
		_bed_location = ""
		_track_id = ""
		refresh_beds(loc)

	var wid: = _weather_id if _weather_id != "" else str(GameState.weather)
	_weather_id = ""
	set_weather(wid)


func _crossfade_to_track(loc: String, mood: String, track: String) -> void :
	_fade_token += 1
	var token: = _fade_token
	_switching = true
	_bed_location = loc
	_bed_mood = mood
	_track_id = track
	if _muted or not _music_enabled:
		_switching = false
		return
	var target: = _target_music_db()
	if _music.playing:
		var tw_out: = create_tween()
		tw_out.tween_property(_music, "volume_db", -40.0, 0.28)
		await tw_out.finished
		if token != _fade_token:
			_switching = false
			return
		_music.stop()

	loc = _bed_location
	mood = _bed_mood
	track = _track_id
	var stream: = _load_track(track)
	if stream == null:
		push_warning("SfxPlayer: missing music track '%s'" % track)

		var fallback: = pick_track(loc, mood, true)
		if fallback != track:
			_track_id = fallback
			stream = _load_track(fallback)
		if stream == null:
			_switching = false
			return
	if token != _fade_token:
		_switching = false
		return
	_music.stream = stream
	_music.volume_db = target - 3.0
	_music.play()
	var tw_in: = create_tween()
	tw_in.tween_property(_music, "volume_db", target, 0.35)
	await tw_in.finished
	if token == _fade_token:
		_music.volume_db = _target_music_db()
		_switching = false

		var want: = resolve_mood()
		if _mood_band(want) != _mood_band(_bed_mood):
			refresh_beds(_bed_location if _bed_location != "" else loc)
	else:
		_switching = false


func _load_track(track_id: String) -> AudioStream:
	if _stream_cache.has(track_id):
		return _stream_cache[track_id]
	var res_path: = "res://audio/music/%s.ogg" % track_id
	var stream: AudioStream = null
	if ResourceLoader.exists(res_path):
		stream = load(res_path) as AudioStream
	if stream == null:
		var abs_path: = ProjectSettings.globalize_path(res_path)
		if FileAccess.file_exists(abs_path):
			stream = AudioStreamOggVorbis.load_from_file(abs_path)
	if stream == null and FileAccess.file_exists(res_path):
		stream = AudioStreamOggVorbis.load_from_file(res_path)
	if stream != null:

		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = false
		_stream_cache[track_id] = stream
	return stream

func _play(stream: AudioStream) -> void :
	if _muted or stream == null:
		return
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()


func _tone(freq: float, dur: float, amp: float) -> AudioStreamWAV:
	return _render([{"f": freq, "a": amp}], dur, false)


func _laugh_stinger() -> AudioStreamWAV:
	return _render([
		{"f": 520.0, "a": 0.1}, 
		{"f": 780.0, "a": 0.07}, 
		{"f": 390.0, "a": 0.05}, 
	], 0.28, false, 0.02)


func _shatter_stinger() -> AudioStreamWAV:
	return _render([
		{"f": 1800.0, "a": 0.12}, 
		{"f": 2400.0, "a": 0.08}, 
		{"f": 900.0, "a": 0.06}, 
		{"f": 320.0, "a": 0.05}, 
	], 0.22, false, 0.08)


func _ebike_whir() -> AudioStreamWAV:

	return _render([
		{"f": 180.0, "a": 0.07}, 
		{"f": 320.0, "a": 0.05}, 
		{"f": 520.0, "a": 0.035}, 
	], 0.55, false, 0.025)


func _moto_growl() -> AudioStreamWAV:
	return _render([
		{"f": 85.0, "a": 0.12}, 
		{"f": 140.0, "a": 0.08}, 
		{"f": 220.0, "a": 0.04}, 
	], 0.48, false, 0.04)


func _car_ignition() -> AudioStreamWAV:
	return _render([
		{"f": 70.0, "a": 0.1}, 
		{"f": 110.0, "a": 0.07}, 
		{"f": 190.0, "a": 0.04}, 
	], 0.5, false, 0.03)


func _chord(freqs: Array, dur: float, amp: float) -> AudioStreamWAV:
	var parts: Array = []
	for f in freqs:
		parts.append({"f": float(f), "a": amp / float(freqs.size())})
	return _render(parts, dur, false)


func _render(
	partials: Array, 
	dur: float, 
	loop: bool = false, 
	noise_amp: float = 0.0, 
	_pulse_hz: float = 0.0, 
	_pulse_depth: float = 0.0
) -> AudioStreamWAV:
	var rate: = 22050
	var n: = int(rate * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	var rng: = RandomNumberGenerator.new()
	rng.seed = 17
	for i in n:
		var t: = float(i) / float(rate)
		var env: = 1.0
		if not loop:
			var attack: = 0.01
			var release: = maxf(0.02, dur * 0.35)
			if t < attack:
				env = t / attack
			elif t > dur - release:
				env = maxf(0.0, (dur - t) / release)
		var s: = 0.0
		for p in partials:
			s += sin(TAU * float(p["f"]) * t) * float(p["a"])
		if noise_amp > 0.0:
			s += (rng.randf() * 2.0 - 1.0) * noise_amp
		s *= env
		var sample: = int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 255
		data[i * 2 + 1] = (sample >> 8) & 255
	var stream: = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = n
	return stream
