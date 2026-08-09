extends Node



@onready var world: Node2D = %WorldHost
@onready var chrome = %PlayChrome


func _ready() -> void :
	SaveSystem.set_session_active(true)
	if chrome and chrome.has_method("bind_world"):
		chrome.bind_world(world)
	call_deferred("_boot")


func _exit_tree() -> void :
	SaveSystem.set_session_active(false)


func _boot() -> void :
	GameFlow.boot_pulse()
	QuestGuide.start_or_resume()

	TipSystem.on_unlock_pulse()
	TipSystem.on_flags_changed()
	TipSystem.pulse_when_free()
