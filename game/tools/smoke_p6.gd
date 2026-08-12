extends Node
## P6 smoke：章一 → E010/E011/E012/E013 发现弧 → E019→E022→E018(A)
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP6.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	RunState.new_game()
	TickPipeline.on_slot_enter()

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E009", false)), 400):
		push_error("SMOKE FAIL: E009")
		ok = false

	# 发现弧门槛（章一后通常已够；略补防抖动）
	if int(RunState.get_stat("stat_intel", 0)) < 12:
		RunState.set_stat("stat_intel", 12)
	if not RunState.clues.has("clue_suspicious_manifest"):
		EffectApplier.apply_one({"op": "unlock_clue", "id": "clue_suspicious_manifest"}, "smoke")
	RunState.set_flag("flag_day3_ignored", false)
	RunState.set_flag("flag_know_bradley_scouting", true)
	RunState.set_flag("flag_endure_preview", true)
	RunState.set_flag("route_endure", true)
	RunState.set_edge_field("char_liu_ruyan", "char_lin_ruisheng", "score", 50)

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E010", false)), 200):
		push_error("SMOKE FAIL: E010 intel=%s clues=%s" % [RunState.get_stat("stat_intel", 0), RunState.clues.keys()])
		ok = false
	if not RunState.clues.has("clue_light_crate"):
		push_error("SMOKE FAIL: clue_light_crate")
		ok = false

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E011", false)), 200):
		push_error("SMOKE FAIL: E011")
		ok = false
	if not RunState.get_flag("flag_saw_bradley_spy", false) and not RunState.items.has("item_bradley_spy_note"):
		# C 线也算走过；要求至少播完
		pass
	else:
		if not RunState.items.has("item_bradley_spy_note"):
			push_error("SMOKE FAIL: bradley spy note")
			ok = false

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E012", false)), 200):
		push_error("SMOKE FAIL: E012 liu=%s endure=%s" % [
			RunState.get_edge("char_liu_ruyan", "char_lin_ruisheng"),
			RunState.get_flag("flag_endure_preview", false),
		])
		ok = false

	# E013 前确保门槛
	if int(RunState.get_stat("stat_intel", 0)) < 25:
		RunState.set_stat("stat_intel", 28)
	if not RunState.clues.has("clue_light_crate"):
		EffectApplier.apply_one({"op": "unlock_clue", "id": "clue_light_crate"}, "smoke")

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E013", false)), 200):
		push_error("SMOKE FAIL: E013")
		ok = false
	if not RunState.clues.has("clue_special_goods"):
		push_error("SMOKE FAIL: clue_special_goods")
		ok = false

	_seed_for_endure_finale()

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E019", false)), 200):
		push_error("SMOKE FAIL: E019 day=%s" % RunState.day())
		ok = false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E020", false)), 200):
		push_error("SMOKE FAIL: E020")
		ok = false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E021", false)), 200):
		push_error("SMOKE FAIL: E021")
		ok = false

	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")

	_seed_for_e018_a()

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E022", false)), 200):
		push_error("SMOKE FAIL: E022")
		ok = false

	RunState.set_stat("stat_trust_firm", 55)
	RunState.set_stat("stat_intel", 40)
	RunState.set_meter("father_son", 20)

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E018", false)), 200):
		push_error("SMOKE FAIL: E018")
		ok = false

	if not RunState.get_flag("flag_ending_a", false):
		push_error("SMOKE FAIL: ending A")
		ok = false
	if RunState.player_rank() != "paojie":
		push_error("SMOKE FAIL: rank %s" % RunState.player_rank())
		ok = false
	if RunState.get_flag("seen_event_E010b", false):
		push_error("SMOKE FAIL: E010b should not fire on A path")
		ok = false

	if ok:
		print("SMOKE P6 OK day=%s light=%s special=%s spy=%s ending_a=%s rank=%s" % [
			RunState.day(),
			RunState.clues.has("clue_light_crate"),
			RunState.clues.has("clue_special_goods"),
			RunState.items.has("item_bradley_spy_note"),
			RunState.get_flag("flag_ending_a", false),
			RunState.player_rank(),
		])
		get_tree().quit(0)
	else:
		print("SMOKE P6 FAILED")
		get_tree().quit(1)


func _seed_for_endure_finale() -> void:
	RunState.set_stat("stat_trust_firm", 50)
	RunState.set_stat("stat_intel", max(28, int(RunState.get_stat("stat_intel", 0))))
	RunState.set_flag("route_endure", true)
	RunState.set_flag("route_defect", false)
	RunState.set_flag("route_foreign", false)
	if String(RunState.grudges.get("grudge_zian_slight", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_slight", "buried_by": "E004"}, "smoke")
	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")


func _seed_for_e018_a() -> void:
	RunState.set_stat("stat_trust_firm", 52)
	RunState.set_stat("stat_intel", 38)
	RunState.set_meter("father_son", 25)


func _play_until(pred: Callable, max_steps: int) -> bool:
	var guard := 0
	while guard < max_steps:
		guard += 1
		if DialogueRunner.is_active():
			_step_dialog()
			continue
		if pred.call():
			return true
		if not RunState.queue.is_empty():
			TickPipeline.begin_queued_event()
			continue
		if RunState.ended:
			return pred.call()
		# 失败事件可能插队；播完继续
		TickPipeline.advance_after_idle()
	return pred.call()


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
	var pick: Dictionary = visible[0]
	var did := String(node.get("dialog_id", ""))
	if did == "dialog_e008_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	elif did in ["dialog_e003_choice", "dialog_e009_choice", "dialog_e010_choice", "dialog_e019_choice"]:
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	elif did == "dialog_e011_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	elif did == "dialog_e012_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	elif did == "dialog_e013_choice":
		# 优先记脑（低嫌疑）；不够门槛则末页
		var got := false
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
				got = true
		if not got:
			for ch in visible:
				if String(ch.get("id", "")) == "C":
					pick = ch
	elif did.contains("e021") and did.ends_with("_choice"):
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	elif did.contains("e022") and did.ends_with("_choice"):
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	elif did == "dialog_e018_a_demao_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	DialogueRunner.select_choice(pick)
