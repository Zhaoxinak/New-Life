extends Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	GameState.new_game(42)
	WorldClock.set_speed(0.0)
	print("DIAG clock start day=%s period=%s hhmm=%s win=%.1f" % [
		GameState.day, GameState.period, WorldClock.clock_hhmm(), WorldClock.window_minute
	])
	var info: Dictionary = WorldClock.advance_minutes(6.0 * 60.0, false)
	print("DIAG +6h -> %s period=%s changed=%s" % [
		WorldClock.clock_hhmm(), GameState.period, info.get("period_changed")
	])
	info = WorldClock.advance_minutes(6.0 * 60.0, false)
	print("DIAG +6h -> %s period=%s" % [WorldClock.clock_hhmm(), GameState.period])
	## Jump near curfew
	WorldClock.window_minute = float(WorldClock.WINDOW_MINUTES) - 30.0
	WorldClock._apply_period_from_clock(false)
	print("DIAG near curfew hhmm=%s win=%.1f" % [WorldClock.clock_hhmm(), WorldClock.window_minute])
	info = WorldClock.jump_action_minutes(1)
	print("DIAG jump1 curfew=%s day=%s hhmm=%s period=%s" % [
		info.get("curfew"), GameState.day, WorldClock.clock_hhmm(), GameState.period
	])
	print("DIAG DONE")
	get_tree().quit(0)
