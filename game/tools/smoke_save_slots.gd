extends Node
## Smoke: 多槽存读档落盘。
## Godot ... --headless --path game res://tools/SmokeSaveSlots.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	RunState.new_game()
	TickPipeline.on_slot_enter()
	RunState.set_stat("stat_money", 77)
	RunState.meta["day"] = 2
	RunState.meta["slot"] = "afternoon"

	if not SaveSystem.save_slot(2):
		push_error("SMOKE FAIL: save slot 2")
		ok = false
	var peek: Dictionary = SaveSystem.peek_slot(2)
	if not bool(peek.get("exists", false)):
		push_error("SMOKE FAIL: peek missing")
		ok = false
	if int(peek.get("day", -1)) != 2 or int(peek.get("money", 0)) != 77:
		push_error("SMOKE FAIL: peek summary %s" % str(peek))
		ok = false
	if not FileAccess.file_exists(SaveSystem.slot_path(2)):
		push_error("SMOKE FAIL: file not on disk")
		ok = false

	RunState.new_game()
	if int(RunState.get_stat("stat_money")) == 77:
		push_error("SMOKE FAIL: new game should reset money")
		ok = false
	if not SaveSystem.load_slot(2):
		push_error("SMOKE FAIL: load slot 2")
		ok = false
	if int(RunState.get_stat("stat_money")) != 77 or RunState.day() != 2:
		push_error("SMOKE FAIL: load restore money=%s day=%s" % [
			str(RunState.get_stat("stat_money")), str(RunState.day())
		])
		ok = false

	# cleanup test slot
	SaveSystem.delete_slot(2)

	if ok:
		print("SMOKE SAVE SLOTS OK path=", ProjectSettings.globalize_path(SaveSystem.SAVE_DIR))
		get_tree().quit(0)
	else:
		print("SMOKE SAVE SLOTS FAIL")
		get_tree().quit(1)
