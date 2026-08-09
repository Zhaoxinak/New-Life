extends Node



signal block_changed(blocked: bool)

var dialogue_open: bool = false
var event_open: bool = false
var ending_open: bool = false
var minigame_open: bool = false
var transition_open: bool = false


func is_blocked() -> bool:
	return dialogue_open or event_open or ending_open or minigame_open or transition_open or GameState.game_over


func set_dialogue_open(v: bool) -> void :
	dialogue_open = v
	block_changed.emit(is_blocked())


func set_event_open(v: bool) -> void :
	event_open = v
	block_changed.emit(is_blocked())


func set_ending_open(v: bool) -> void :
	ending_open = v
	block_changed.emit(is_blocked())


func set_minigame_open(v: bool) -> void :
	minigame_open = v
	block_changed.emit(is_blocked())


func set_transition_open(v: bool) -> void :
	transition_open = v
	block_changed.emit(is_blocked())


func boot_pulse() -> void :
	call_deferred("_boot")


func _boot() -> void :
	ThresholdWatcher.evaluate_all()
	# New-game door-crack beat must fire before free play.
	var intro_done: = int(GameState.event_triggers.get("ev_day1_intro", 0)) > 0
	if intro_done and GameState.get_flag("intro_lock") != 0:
		GameState.set_flag("intro_lock", 0)
	if GameState.get_flag("intro_lock") != 0 and not intro_done:
		if EventScheduler.active_event_id == "" or EventScheduler.active_event_id == "ev_day1_intro":
			if EventScheduler.active_event_id == "":
				EventScheduler.start_event("ev_day1_intro")
			else:
				## Started on title (no EventPanel) — present again now that Main is live.
				EventScheduler.present_active_event()
		else:
			EventScheduler.start_event("ev_day1_intro")
	else:
		EventScheduler.pulse()
	TipSystem.on_flags_changed()
