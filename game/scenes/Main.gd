extends Node
## Main shell: free-roam world + UI chrome + quest guide.


@onready var world: Node2D = %WorldHost
@onready var chrome = %PlayChrome


func _ready() -> void:
	if chrome and chrome.has_method("bind_world"):
		chrome.bind_world(world)
	call_deferred("_boot")


func _boot() -> void:
	GameFlow.boot_pulse()
	QuestGuide.start_or_resume()
	# Keep unlock/status tips only — no tip-banner tutorial spam.
	TipSystem.on_unlock_pulse()
	TipSystem.on_flags_changed()
	TipSystem.pulse_when_free()
