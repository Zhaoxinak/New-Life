extends Node


## Continuous in-world clock: 06:00 → next day 02:00, then forced home rest.

signal speed_changed(speed: float)
signal clock_ticked()
signal curfew_started(forced: bool)

const WAKE_HOUR := 6
const CURFEW_HOUR := 2
const WAKE_MINUTE := WAKE_HOUR * 60
const CURFEW_MINUTE := CURFEW_HOUR * 60
const MINUTES_PER_DAY := 24 * 60
## Active window length: 06:00 → 02:00 next day = 20h.
const WINDOW_MINUTES := 20 * 60
## 20 game-hours in ~5 real minutes at 1×.
const REAL_SEC_PER_GAME_MINUTE := 0.25
## One CSV time_cost period ≈ 3.5 game hours.
const MINUTES_PER_ACTION_PERIOD := 210.0
const SPEED_STEPS: Array[float] = [0.0, 0.5, 1.0, 2.0, 4.0]

## Minutes since today's 06:00 (0 … WINDOW_MINUTES).
var window_minute: float = 0.0
var time_speed: float = 1.0
var _pending_curfew: bool = false
var _time_skip_lock: bool = false
var _last_emit_min: int = -1
## Player chose "先不回去" tonight — never force-home until they sleep themselves.
var _curfew_declined: bool = false
var _curfew_asking: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not GameFlow.block_changed.is_connected(_on_block_changed):
		GameFlow.block_changed.connect(_on_block_changed)
	set_process(true)
	set_process_unhandled_input(true)


func reset_for_new_day_start() -> void:
	window_minute = 0.0
	_pending_curfew = false
	_time_skip_lock = false
	_last_emit_min = -1
	_curfew_declined = false
	_curfew_asking = false
	## Silent sync: new_game runs on the title screen; emitting period_advanced
	## would start events before EventPanel exists (stuck intro_lock).
	_apply_period_from_clock(false)


func load_state(win_min: float, speed: float) -> void:
	window_minute = clampf(win_min, 0.0, float(WINDOW_MINUTES))
	time_speed = _nearest_speed(speed)
	_pending_curfew = false
	_curfew_asking = false
	## Silent: load often runs on the title screen before EventPanel exists.
	_apply_period_from_clock(false)
	speed_changed.emit(time_speed)


func clock_minute_of_day() -> int:
	return int(floor(float(WAKE_MINUTE) + window_minute)) % MINUTES_PER_DAY


func clock_hhmm() -> String:
	var m := clock_minute_of_day()
	return "%02d:%02d" % [int(m / 60.0), int(m % 60)]


func day_phase01() -> float:
	return clampf(window_minute / float(WINDOW_MINUTES), 0.0, 1.0)


func derive_period() -> String:
	var m := clock_minute_of_day()
	if m >= 6 * 60 and m < 12 * 60:
		return "morning"
	if m >= 12 * 60 and m < 18 * 60:
		return "afternoon"
	return "evening"


func effective_speed() -> float:
	if GameState.game_over or GameFlow.is_blocked() or _time_skip_lock:
		return 0.0
	return time_speed


## Character move / stride scale. Follows the HUD speed (incl. pause).
func motion_scale() -> float:
	return effective_speed()


func set_speed(speed: float) -> void:
	var next := _nearest_speed(speed)
	if is_equal_approx(time_speed, next):
		return
	time_speed = next
	speed_changed.emit(time_speed)
	GameState.state_changed.emit()


func _nearest_speed(speed: float) -> float:
	var next := 1.0
	var best_d := INF
	for s in SPEED_STEPS:
		var d := absf(float(s) - speed)
		if d < best_d:
			best_d = d
			next = float(s)
	return next


## Brief lock so players can't chain actions during the "time flies" beat.
func pulse_time_skip_lock(sec: float = 0.75) -> void:
	if sec <= 0.0 or _time_skip_lock or _pending_curfew:
		return
	call_deferred("_run_time_skip_pulse", sec)


func _run_time_skip_pulse(sec: float) -> void:
	if _time_skip_lock or _pending_curfew:
		return
	_time_skip_lock = true
	GameFlow.set_transition_open(true)
	await get_tree().create_timer(sec).timeout
	## Curfew presentation owns the lock from here — do not leave transition stuck.
	if _pending_curfew:
		_time_skip_lock = false
		call_deferred("_begin_curfew_flow", true)
		return
	GameFlow.set_transition_open(false)
	_time_skip_lock = false


func cycle_speed() -> void:
	nudge_speed(1)


func speed_step_index() -> int:
	var best := 2
	var best_d := INF
	for i in SPEED_STEPS.size():
		var d := absf(float(SPEED_STEPS[i]) - time_speed)
		if d < best_d:
			best_d = d
			best = i
	return best


## Numpad +/- and HUD: step through pause → 0.5× → 1× → 2× → 4×.
func nudge_speed(delta_steps: int) -> void:
	if delta_steps == 0:
		return
	var idx := clampi(speed_step_index() + delta_steps, 0, SPEED_STEPS.size() - 1)
	set_speed(float(SPEED_STEPS[idx]))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_KP_ADD or event.physical_keycode == KEY_KP_ADD:
			nudge_speed(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_KP_SUBTRACT or event.physical_keycode == KEY_KP_SUBTRACT:
			nudge_speed(-1)
			get_viewport().set_input_as_handled()


func minutes_for_action_cost(cost: int) -> float:
	return maxf(0.0, float(cost) * MINUTES_PER_ACTION_PERIOD)


func _process(delta: float) -> void:
	if (
		_pending_curfew
		and not _curfew_declined
		and not _curfew_asking
		and not GameFlow.is_blocked()
		and not _time_skip_lock
	):
		_begin_curfew_flow(true)
		return
	var spd := effective_speed()
	if spd <= 0.0:
		return
	advance_minutes(delta / REAL_SEC_PER_GAME_MINUTE * spd, true)


## Advance the world clock. Returns info about what crossed.
func advance_minutes(amount: float, allow_curfew: bool = true) -> Dictionary:
	var info := {
		"applied": 0.0,
		"curfew": false,
		"period_changed": false,
		"day_changed": false,
		"prev_period": str(GameState.period),
		"prev_day": GameState.day,
	}
	if amount <= 0.0 or GameState.game_over:
		return info
	var prev_period := str(GameState.period)
	var room := float(WINDOW_MINUTES) - window_minute
	## Already at/after 02:00 and player declined — freeze clock, no force-home.
	if _curfew_declined and room <= 0.0001:
		return info
	if allow_curfew and not _curfew_declined and amount >= room - 0.0001:
		window_minute = float(WINDOW_MINUTES)
		info["applied"] = maxf(0.0, room)
		_apply_period_from_clock(false)
		info["period_changed"] = str(GameState.period) != prev_period
		info["curfew"] = true
		## Offer once: go home, or stay without being forced later.
		_pending_curfew = true
		call_deferred("_begin_curfew_flow", true)
		return info
	var step := minf(amount, maxf(0.0, room))
	window_minute += step
	info["applied"] = step
	_apply_period_from_clock(false)
	info["period_changed"] = str(GameState.period) != prev_period
	var im := int(floor(window_minute))
	if im != _last_emit_min:
		_last_emit_min = im
		clock_ticked.emit()
		if im % 5 == 0:
			GameState.state_changed.emit()
	return info


func jump_action_minutes(cost: int) -> Dictionary:
	return advance_minutes(minutes_for_action_cost(cost), true)


## Voluntary or forced sleep → next day's 06:00. Resets speed to 1×.
func sleep_to_morning(forced: bool = false) -> void:
	curfew_started.emit(forced)
	var completed := GameState.day
	if GameState.get_flag("divorce_snooze") != 0:
		GameState.set_flag("divorce_snooze", 0)
	GameState.day_ended.emit(completed)
	GameState.day = mini(GameState.day + 1, GameState.MAX_DAY)
	UnlockScheduler.apply_day(GameState.day)
	window_minute = 0.0
	_pending_curfew = false
	_curfew_declined = false
	_curfew_asking = false
	_apply_period_from_clock(true)
	## Fresh day: always restore a calm 1× so players aren't stuck at 4×.
	if not is_equal_approx(time_speed, 1.0):
		time_speed = 1.0
		speed_changed.emit(time_speed)
	GameState.state_changed.emit()


func advance_to_next_period() -> void:
	## Debug / legacy: snap to next period start, or sleep if past evening start of late night.
	var m := clock_minute_of_day()
	var target_window := 0.0
	if m >= WAKE_MINUTE and m < 12 * 60:
		target_window = float(12 * 60 - WAKE_MINUTE)
	elif m >= 12 * 60 and m < 18 * 60:
		target_window = float(18 * 60 - WAKE_MINUTE)
	elif m >= 18 * 60:
		target_window = float(WINDOW_MINUTES)
	else:
		_begin_curfew_flow(false)
		return
	if target_window >= float(WINDOW_MINUTES) - 0.5:
		window_minute = float(WINDOW_MINUTES)
		_begin_curfew_flow(false)
		return
	window_minute = target_window
	_apply_period_from_clock(false)


func request_curfew_if_due() -> void:
	if _curfew_declined:
		return
	if window_minute >= float(WINDOW_MINUTES) - 0.001:
		_begin_curfew_flow(true)


func _on_block_changed(_blocked: bool) -> void:
	if _curfew_declined:
		return
	if _pending_curfew and not _curfew_asking and not GameFlow.is_blocked() and not _time_skip_lock:
		call_deferred("_begin_curfew_flow", true)


func _apply_period_from_clock(force_signal: bool) -> void:
	var next := derive_period()
	if next == GameState.period and not force_signal:
		return
	var prev := GameState.period
	GameState.period = next
	if force_signal or prev != next:
		GameState.period_advanced.emit(GameState.day, GameState.period)


## Entry: ask once on natural curfew; voluntary/debug sleep skips the ask.
func _begin_curfew_flow(forced: bool) -> void:
	if GameState.game_over or _curfew_asking:
		return
	if forced and _curfew_declined:
		_pending_curfew = false
		return
	if forced:
		call_deferred("_ask_curfew_then_run")
		return
	call_deferred("_execute_curfew", forced)


func _ask_curfew_then_run() -> void:
	if GameState.game_over or _curfew_asking or _curfew_declined:
		return
	if GameFlow.is_blocked() or _time_skip_lock:
		_pending_curfew = true
		return
	_pending_curfew = false
	_curfew_asking = true
	_time_skip_lock = true
	GameFlow.set_transition_open(true)
	var feed := _beat_feed()
	var choice := "home"
	if feed != null and feed.has_method("ask_curfew"):
		choice = await feed.ask_curfew()
	_curfew_asking = false
	if choice == "linger":
		## Stay out — no second force-home tonight. Clock holds at 02:00.
		_curfew_declined = true
		_pending_curfew = false
		window_minute = float(WINDOW_MINUTES)
		GameFlow.set_transition_open(false)
		_time_skip_lock = false
		clock_ticked.emit()
		GameState.state_changed.emit()
		return
	await _execute_curfew(true)


func _execute_curfew(forced: bool) -> void:
	if GameState.game_over:
		return
	if _curfew_asking:
		return
	if GameFlow.is_blocked() and not _time_skip_lock:
		_pending_curfew = true
		return
	_pending_curfew = false
	_time_skip_lock = true
	GameFlow.set_transition_open(true)
	curfew_started.emit(forced)
	_apply_rest_bonuses()
	ActionPipeline.suppress_period_feed = true
	sleep_to_morning(forced)
	ActionPipeline.suppress_period_feed = false
	SfxPlayer.play_period()
	await _finish_curfew_presentation(forced)


## After voluntary bed rest (already at home).
func present_morning_wake(forced: bool = false) -> void:
	call_deferred("_finish_curfew_presentation", forced)


func _finish_curfew_presentation(forced: bool) -> void:
	_time_skip_lock = true
	GameFlow.set_transition_open(true)
	if forced:
		await _force_go_home()
	var feed := _beat_feed()
	if feed != null and feed.has_method("show_wake_card"):
		await feed.show_wake_card(forced)
	else:
		GameFlow.set_transition_open(false)
	_time_skip_lock = false
	EventScheduler.pulse()
	TipSystem.pulse_when_free()


func _apply_rest_bonuses() -> void:
	var ht := int(GameState.get_stat("home_tier"))
	if ht >= 2:
		GameState.add_stat("suspicion", -2.0 if ht < 4 else -4.0)
	if ht >= 3:
		GameState.add_stat("intel", 1.0)


func _force_go_home() -> void:
	var host := get_tree().get_first_node_in_group("world_host")
	if host != null and host.has_method("force_home_for_curfew"):
		await host.force_home_for_curfew()
	else:
		GameState.set_location("home")


func _beat_feed() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("beat_feed")
