extends Node
## Smoke: 小人闲聊挑选与兜底。
## Godot ... --headless --path game res://tools/SmokeChatter.tscn

const SmokeDialogUtilScript = preload("res://tools/SmokeDialogUtil.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	RunState.new_game()
	TickPipeline.on_slot_enter()
	# 消化开局事件，避免挡闲聊
	while not RunState.queue.is_empty() and not DialogueRunner.is_active():
		TickPipeline.begin_queued_event()
	if not SmokeDialogUtilScript.drain(80):
		ok = false

	if DialogueRunner.is_active():
		push_error("SMOKE FAIL: dialog still active after drain")
		DialogueRunner.force_abort()
		ok = false

	var d1 := ChatterSystem.pick_dialog("char_qian_demao")
	if d1.is_empty() or PackDB.get_row_by_id("def_dialog", "dialog_id", d1).is_empty():
		push_error("SMOKE FAIL: demao dialog empty %s" % d1)
		ok = false
	if not ChatterSystem.try_start("char_qian_demao"):
		push_error("SMOKE FAIL: demao chatter start")
		ok = false
	elif not SmokeDialogUtilScript.drain(40):
		ok = false

	# 同人连点：应仍有兜底/敷衍
	var d2 := ChatterSystem.pick_dialog("char_qian_demao")
	if d2.is_empty():
		push_error("SMOKE FAIL: demao second pick empty")
		ok = false

	var self_d := ChatterSystem.pick_dialog("char_lin_ruisheng")
	if self_d.is_empty():
		push_error("SMOKE FAIL: self chatter empty")
		ok = false

	if ok:
		print("SMOKE CHATTER OK")
		get_tree().quit(0)
	else:
		print("SMOKE CHATTER FAIL")
		get_tree().quit(1)
