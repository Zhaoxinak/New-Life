extends Node
## P2 smoke：自动推进 Day1–7，播完 E001–E009（选项默认 A / 隐忍 B 在 E008）。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP2.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	RunState.new_game()
	TickPipeline.on_slot_enter()

	var guard := 0
	while guard < 400:
		guard += 1
		if DialogueRunner.is_active():
			_step_dialog()
			continue
		if not RunState.queue.is_empty():
			TickPipeline.begin_queued_event()
			continue
		if RunState.get_flag("seen_event_E009", false):
			break
		if RunState.day() > 8:
			break
		TickPipeline.advance_after_idle()

	if not RunState.get_flag("seen_event_E001", false):
		push_error("SMOKE FAIL: missing E001")
		ok = false
	if not RunState.get_flag("seen_event_E009", false):
		push_error("SMOKE FAIL: missing E009 after %d steps day=%s queue=%s" % [
			guard, RunState.day(), str(RunState.queue)
		])
		ok = false

	# 主债三条
	for gid in ["grudge_zian_slight", "grudge_demao_defer", "grudge_zian_fiancee"]:
		if not RunState.grudges.has(gid) or String(RunState.grudges[gid].get("status", "")) != "open":
			push_error("SMOKE FAIL: grudge not open %s=%s" % [gid, RunState.grudges.get(gid, {})])
			ok = false

	# E008 默认走 B（隐忍）→ endure preview；E009 默认 A → route_endure
	# 但 _step_dialog 对所有选择点第一项——E008 第一项是 A（理论）。
	# 章一切片 smoke 指定：E008 选 B，E009 选 A。
	# 上面已用第一选项；若 E008 走了 A，仍应埋 fiancee。
	if not (
		RunState.get_flag("route_endure", false)
		or RunState.get_flag("route_defect", false)
		or RunState.get_flag("route_foreign", false)
	):
		push_error("SMOKE FAIL: no route flag after E009")
		ok = false

	# 行动口风：钱紧时 act_01 应能触发
	RunState.set_stat("stat_money", 10)
	var before_day := RunState.day()
	# 找到开放前堂的时段
	var acted := false
	for _i in 10:
		if TickPipeline.try_player_action("act_01"):
			acted = true
			break
		if DialogueRunner.is_active():
			break
		TickPipeline.advance_after_idle()
	if DialogueRunner.is_active():
		var g2 := 0
		while DialogueRunner.is_active() and g2 < 20:
			g2 += 1
			_step_dialog()
		acted = true
	if not acted:
		push_error("SMOKE FAIL: act_01 outro path")
		ok = false

	if not RunState.clues.has("clue_suspicious_manifest") and not RunState.get_flag("flag_day3_ignored", false):
		# E003 默认 A 会 unlock clue
		push_error("SMOKE FAIL: expected clue from E003A")
		ok = false

	if ok:
		print("SMOKE P2 OK day=%s slot=%s route_endure=%s grudges_open=%s clue=%s money=%s trust=%s steps=%s before_act_day=%s" % [
			RunState.day(),
			RunState.slot(),
			RunState.get_flag("route_endure", false),
			_open_grudge_ids(),
			RunState.clues.has("clue_suspicious_manifest"),
			RunState.get_stat("stat_money"),
			RunState.get_stat("stat_trust_firm"),
			guard,
			before_day,
		])
		get_tree().quit(0)
	else:
		print("SMOKE P2 FAILED")
		get_tree().quit(1)


func _step_dialog() -> void:
	var node: Dictionary = DialogueRunner.current_node
	var choices: Array = node.get("choices", node.get("options", []))
	var visible: Array = []
	for ch in choices:
		if typeof(ch) == TYPE_DICTIONARY and ConditionEval.eval_all((ch as Dictionary).get("require", [])):
			visible.append(ch)
	if visible.is_empty():
		DialogueRunner.continue_linear()
		return
	# E008 优先隐忍 B；E009 优先忍 A（第一项）
	var pick: Dictionary = visible[0]
	var did := String(node.get("dialog_id", ""))
	if did == "dialog_e008_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
				break
	elif did == "dialog_e009_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
				break
	DialogueRunner.select_choice(pick)


func _open_grudge_ids() -> String:
	var ids: PackedStringArray = []
	for gid in RunState.grudges.keys():
		if String(RunState.grudges[gid].get("status", "")) == "open":
			ids.append(String(gid))
	return ",".join(ids)
