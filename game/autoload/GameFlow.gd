extends Node
## Coordinates modal UI blocking and boot pulse.


signal block_changed(blocked: bool)

var dialogue_open: bool = false
var event_open: bool = false
var ending_open: bool = false


func is_blocked() -> bool:
	return dialogue_open or event_open or ending_open or GameState.game_over


func set_dialogue_open(v: bool) -> void:
	dialogue_open = v
	block_changed.emit(is_blocked())


func set_event_open(v: bool) -> void:
	event_open = v
	block_changed.emit(is_blocked())


func set_ending_open(v: bool) -> void:
	ending_open = v
	block_changed.emit(is_blocked())


func boot_pulse() -> void:
	call_deferred("_boot")


func _boot() -> void:
	ThresholdWatcher.evaluate_all()
	EventScheduler.pulse()
	TipSystem.on_flags_changed()
