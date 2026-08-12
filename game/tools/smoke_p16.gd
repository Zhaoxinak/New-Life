extends Node
## P16 smoke：试玩说明文案 + 朝账 M001/run_meeting/ladder。
## Godot --headless --path game res://tools/SmokeP16.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	var body := L10n.t("ui.help_body", "")
	for needle in ["建议试玩", "隐忍", "跳槽", "洋行"]:
		if body.find(needle) < 0:
			push_error("SMOKE FAIL: help missing %s" % needle)
			ok = false

	if PackDB.content_version().is_empty():
		push_error("SMOKE FAIL: empty content_version")
		ok = false

	if not ok:
		print("SMOKE P16 FAIL help")
		get_tree().quit(1)
		return

	RunState.new_game()
	TickPipeline.on_slot_enter()
	if RunState.queue.size() < 2 or String(RunState.queue[0]) != "E001" or String(RunState.queue[1]) != "M001":
		push_error("SMOKE FAIL: day1 queue want [E001,M001] got %s" % str(RunState.queue))
		get_tree().quit(1)
		return

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E001", false)), 80):
		push_error("SMOKE FAIL: E001 not seen")
		get_tree().quit(1)
		return
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_M001", false)), 120):
		push_error("SMOKE FAIL: M001 not seen")
		get_tree().quit(1)
		return

	if not bool(RunState.get_flag("flag_meeting_witness", false)):
		push_error("SMOKE FAIL: flag_meeting_witness")
		get_tree().quit(1)
		return
	if String(RunState.meeting.get("attendance_tier", "")) != "listen":
		push_error("SMOKE FAIL: tier listen got %s" % RunState.meeting.get("attendance_tier", ""))
		get_tree().quit(1)
		return
	if String(RunState.ladder.get("pool_id", "")) != "pool_apprentice":
		push_error("SMOKE FAIL: ladder pool")
		get_tree().quit(1)
		return
	var tasks: Array = RunState.meeting.get("weekly_tasks", [])
	if tasks.size() < 2:
		push_error("SMOKE FAIL: weekly_tasks %s" % str(tasks))
		get_tree().quit(1)
		return
	if int(RunState.meeting.get("cycle_index", 0)) < 1:
		push_error("SMOKE FAIL: cycle_index")
		get_tree().quit(1)
		return

	MeetingSystem.on_player_action("act_02")
	var prog := 0
	for t in RunState.meeting.get("weekly_tasks", []):
		if String(t.get("id", "")) == "task_tidy_manifest":
			prog = int(t.get("progress", 0))
	if prog < 1:
		push_error("SMOKE FAIL: task progress")
		get_tree().quit(1)
		return

	# 推进至 D15 例行朝账 M000
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_M000", false)), 400):
		push_error("SMOKE FAIL: M000 day=%s queue=%s" % [RunState.day(), str(RunState.queue)])
		get_tree().quit(1)
		return
	if String(RunState.meeting.get("last_policy", "")).is_empty():
		push_error("SMOKE FAIL: last_policy empty after M000")
		get_tree().quit(1)
		return
	if MeetingSystem.sorted_ladder_entries().is_empty():
		push_error("SMOKE FAIL: ladder empty")
		get_tree().quit(1)
		return

	print("SMOKE P16 OK help+meeting+M000 policy=%s cycle=%s" % [
		RunState.meeting.get("last_policy", ""),
		RunState.meeting.get("cycle_index", 0),
	])
	get_tree().quit(0)


func _play_until(pred: Callable, max_steps: int) -> bool:
	for _i in range(max_steps):
		if pred.call():
			return true
		if DialogueRunner.is_active():
			var choices: Array = DialogueRunner._visible_choices(DialogueRunner.current_node)
			if not choices.is_empty():
				DialogueRunner.select_choice(choices[0])
			else:
				DialogueRunner.continue_linear()
			continue
		if not RunState.queue.is_empty():
			TickPipeline.begin_queued_event()
			continue
		TickPipeline.advance_after_idle()
	return pred.call()
