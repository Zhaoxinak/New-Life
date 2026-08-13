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

	# 议场表现层：def + 场景 + segment 信号
	var stage_def: Variant = PackDB.tables.get("def_meeting_stage", {})
	if typeof(stage_def) != TYPE_DICTIONARY or (stage_def as Dictionary).get("seats", []).is_empty():
		push_error("SMOKE FAIL: def_meeting_stage missing seats")
		get_tree().quit(1)
		return
	var ms_res := load("res://ui/MeetingStage.tscn")
	if ms_res == null:
		push_error("SMOKE FAIL: MeetingStage.tscn")
		get_tree().quit(1)
		return
	if not ResourceLoader.exists("res://art/meeting/hall_front.png"):
		push_error("SMOKE FAIL: missing hall_front.png")
		get_tree().quit(1)
		return
	for bust in ["char_qian_demao", "char_zhou_guanshi", "char_lin_ruisheng", "char_wang_pangzi"]:
		if not ResourceLoader.exists("res://art/meeting/busts/%s.png" % bust):
			push_error("SMOKE FAIL: missing bust %s" % bust)
			get_tree().quit(1)
			return
	var ms: CanvasLayer = (ms_res as PackedScene).instantiate() as CanvasLayer
	get_tree().root.add_child(ms)
	await get_tree().process_frame
	var bg: TextureRect = ms.get_node_or_null("%HallBg") as TextureRect
	if bg == null or bg.texture == null:
		push_error("SMOKE FAIL: HallBg not textured")
		get_tree().quit(1)
		return
	MeetingSystem.set_meeting_segment("council")
	MeetingSystem.init_council_queue(["char_zhou_guanshi", "char_wang_pangzi"])
	if not ms.has_method("is_open"):
		push_error("SMOKE FAIL: MeetingStage API")
		get_tree().quit(1)
		return
	## P2：满席启发 + 截断 API 存在
	if ms.has_method("_recompute_seating_mode"):
		ms._recompute_seating_mode()
	if ms.has_method("_play_cutoff_shake"):
		ms._active = true
		ms.visible = true
		ms._build_seats()
		ms._play_cutoff_shake("char_qian_demao")
	DomainBus.emit_domain("ceremony_finished", {"mode": "promo", "old_rank": "apprentice", "new_rank": "waichang"})
	## P3：音频资源 + 账簿朝账摘要字段
	for cue in ["open.wav", "gavel.wav", "cut.wav", "seat.wav", "bgm_loop.wav"]:
		if not FileAccess.file_exists("res://art/audio/meeting/%s" % cue):
			push_error("SMOKE FAIL: missing audio %s" % cue)
			get_tree().quit(1)
			return
	if not ResourceLoader.exists("res://ui/MeetingAudio.gd"):
		push_error("SMOKE FAIL: MeetingAudio.gd")
		get_tree().quit(1)
		return
	MeetingSystem.complete_meeting_cycle("meeting.summary.m000")
	if String(RunState.meeting.get("last_summary_key", "")) != "meeting.summary.m000":
		push_error("SMOKE FAIL: last_summary_key")
		get_tree().quit(1)
		return
	var has_meeting_hist := false
	for h in RunState.history:
		if String(h.get("kind", "")) == "meeting":
			has_meeting_hist = true
			break
	if not has_meeting_hist:
		push_error("SMOKE FAIL: meeting history entry")
		get_tree().quit(1)
		return
	## P4：关键朝账节点应带 stage.segment / set_meeting_segment
	var m001_start: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_m001_start")
	var st: Variant = m001_start.get("stage", {})
	if typeof(st) != TYPE_DICTIONARY or String((st as Dictionary).get("segment", "")) != "rollcall":
		push_error("SMOKE FAIL: m001_start stage.segment")
		get_tree().quit(1)
		return
	var has_seg_fx := false
	for fx in m001_start.get("effects", []):
		if typeof(fx) == TYPE_DICTIONARY and String(fx.get("op", "")) == "set_meeting_segment":
			has_seg_fx = true
			break
	if not has_seg_fx:
		push_error("SMOKE FAIL: m001_start set_meeting_segment")
		get_tree().quit(1)
		return
	## 内容扩写：仇人踩线节点 + pick_meeting_rival
	for did in [
		"dialog_council_sun_step",
		"dialog_council_zhao_step",
		"dialog_council_chen_steady",
		"dialog_council_li_work",
		"dialog_council_zhou_pick",
	]:
		if PackDB.get_row_by_id("def_dialog", "dialog_id", did).is_empty():
			push_error("SMOKE FAIL: missing %s" % did)
			get_tree().quit(1)
			return
	RunState.meeting["cycle_index"] = 2
	MeetingSystem.init_ladder_pool("pool_apprentice")
	MeetingSystem.add_ladder_score("char_apprentice_sun_liu", 20.0)
	var rival := MeetingSystem.pick_meeting_rival()
	if rival.is_empty():
		push_error("SMOKE FAIL: pick_meeting_rival empty under pressure")
		get_tree().quit(1)
		return
	if MeetingSystem.primary_rival().is_empty():
		push_error("SMOKE FAIL: primary_rival empty")
		get_tree().quit(1)
		return
	var q2: Array = MeetingSystem.build_default_council_queue()
	if not q2.has(rival):
		push_error("SMOKE FAIL: rival not in default queue %s" % str(q2))
		get_tree().quit(1)
		return
	## 附议 + 简席
	if PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_meeting_council_endorse").is_empty():
		push_error("SMOKE FAIL: endorse dialog missing")
		get_tree().quit(1)
		return
	MeetingSystem.init_council_queue(["char_zhou_guanshi", "char_wang_pangzi", "char_lin_ruisheng"])
	if not MeetingSystem.is_council_brief():
		push_error("SMOKE FAIL: expected brief council")
		get_tree().quit(1)
		return
	MeetingSystem.record_council_speech({
		"char": "char_wang_pangzi", "spoke": true, "stance": "bright_steady", "mode": "speak",
	})
	if MeetingSystem.last_council_spoke_entry().is_empty():
		push_error("SMOKE FAIL: last_council_spoke_entry")
		get_tree().quit(1)
		return
	MeetingSystem.set_meeting_tier("decide")
	MeetingSystem.endorse_last_council()
	var draft: Dictionary = RunState.meeting.get("policy_draft", {})
	if float(draft.get("bright_steady", 0)) < 2.0:
		push_error("SMOKE FAIL: endorse did not boost policy_draft")
		get_tree().quit(1)
		return
	ms.queue_free()

	## P5：DutyRail 文案与临期条件
	MeetingSystem.assign_weekly_tasks(["task_tidy_manifest", "task_front_duty"])
	if not MeetingSystem.should_show_duty_rail():
		push_error("SMOKE FAIL: duty rail should show after tasks")
		get_tree().quit(1)
		return
	var rail := MeetingSystem.duty_rail_bbcode()
	if rail.find("本周差事") < 0 and rail.find("差事") < 0:
		push_error("SMOKE FAIL: duty_rail_bbcode missing tasks")
		get_tree().quit(1)
		return
	if not MeetingSystem.has_incomplete_weekly_tasks():
		push_error("SMOKE FAIL: expected incomplete tasks")
		get_tree().quit(1)
		return
	RunState.meeting["days_until_next"] = 2
	if not ConditionEval.eval_all([{"meeting_days_leq": 2}, {"meeting_tasks_incomplete": true}]):
		push_error("SMOKE FAIL: meeting_days_leq / incomplete conditions")
		get_tree().quit(1)
		return
	MeetingSystem.on_player_action("act_02")
	MeetingSystem.on_player_action("act_02")
	MeetingSystem.on_player_action("act_01")
	if MeetingSystem.has_incomplete_weekly_tasks():
		push_error("SMOKE FAIL: tasks should be complete after acts")
		get_tree().quit(1)
		return

	print("SMOKE P16 OK help+meeting+M000 policy=%s cycle=%s stage=ok p2=ok p3=ok p4=ok content=ok rival=%s endorse=ok p5=ok" % [
		RunState.meeting.get("last_policy", ""),
		RunState.meeting.get("cycle_index", 0),
		rival,
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
