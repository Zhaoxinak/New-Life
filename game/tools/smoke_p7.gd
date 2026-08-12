extends Node
## P7 smoke：发现弧 → 升职/轻清算 → E014/E015/E016 → E022 → E018(A)
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP7.tscn


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

	_seed_discovery_gates()
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E013", false)), 400):
		push_error("SMOKE FAIL: E013")
		ok = false
	if not RunState.clues.has("clue_special_goods"):
		push_error("SMOKE FAIL: special goods")
		ok = false

	_seed_for_endure_finale()
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E021", false)), 400):
		push_error("SMOKE FAIL: E021")
		ok = false

	# 章三桥：避免德茂 suspicion 叠满误触 F005
	RunState.set_edge_field("char_qian_demao", "char_lin_ruisheng", "suspicion", 0)
	if int(RunState.get_stat("stat_intel", 0)) < 40:
		RunState.set_stat("stat_intel", 42)
	if int(RunState.get_stat("stat_network", 0)) < 30:
		RunState.set_stat("stat_network", 32)
	RunState.set_edge_field("char_wang_pangzi", "char_lin_ruisheng", "score", 40)
	if not RunState.clues.has("clue_special_goods"):
		EffectApplier.apply_one({"op": "unlock_clue", "id": "clue_special_goods"}, "smoke")

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E014", false)), 200):
		push_error("SMOKE FAIL: E014 father_son=%s ended=%s" % [RunState.get_meter("father_son"), RunState.ended])
		ok = false
	if RunState.ended:
		push_error("SMOKE FAIL: run ended after E014 reason=%s" % RunState.end_reason)
		ok = false
	if float(RunState.get_meter("father_son")) > 45.0:
		push_error("SMOKE FAIL: father_son not cracked got %s" % RunState.get_meter("father_son"))
		ok = false

	# E015 前再钉一次门槛
	RunState.set_edge_field("char_qian_demao", "char_lin_ruisheng", "suspicion", 0)
	if int(RunState.get_stat("stat_intel", 0)) < 35:
		RunState.set_stat("stat_intel", 40)
	if int(RunState.get_stat("stat_network", 0)) < 25:
		RunState.set_stat("stat_network", 30)
	RunState.set_edge_field("char_wang_pangzi", "char_lin_ruisheng", "score", 40)
	if not RunState.clues.has("clue_special_goods"):
		EffectApplier.apply_one({"op": "unlock_clue", "id": "clue_special_goods"}, "smoke")

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E015", false)), 400):
		push_error("SMOKE FAIL: E015 day=%s slot=%s ended=%s reason=%s sus=%s demao_s=%s" % [
			RunState.day(), RunState.slot(), RunState.ended, RunState.end_reason,
			RunState.get_stat("stat_suspicion", 0),
			RunState.get_edge("char_qian_demao", "char_lin_ruisheng").get("suspicion", 0),
		])
		ok = false
	if not (RunState.clues.has("clue_opium_infer") or RunState.clues.has("clue_opium_secret")):
		push_error("SMOKE FAIL: opium clue")
		ok = false

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E016", false)), 200):
		push_error("SMOKE FAIL: E016")
		ok = false
	if not RunState.get_flag("flag_power_shift_visible", false):
		push_error("SMOKE FAIL: power shift flag")
		ok = false
	if RunState.get_flag("seen_event_E017", false):
		push_error("SMOKE FAIL: E017 should skip on endure")
		ok = false

	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")
	_seed_for_e018_a()

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E022", false)), 200):
		push_error("SMOKE FAIL: E022")
		ok = false

	RunState.set_stat("stat_trust_firm", 55)
	RunState.set_stat("stat_intel", 45)
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

	if ok:
		print("SMOKE P7 OK day=%s e014-16=true opium=%s infight=%s ending_a=%s" % [
			RunState.day(),
			RunState.clues.has("clue_opium_infer") or RunState.clues.has("clue_opium_secret"),
			RunState.get_flag("flag_qian_infighting", false),
			RunState.get_flag("flag_ending_a", false),
		])
		get_tree().quit(0)
	else:
		print("SMOKE P7 FAILED")
		get_tree().quit(1)


func _seed_discovery_gates() -> void:
	if int(RunState.get_stat("stat_intel", 0)) < 12:
		RunState.set_stat("stat_intel", 12)
	if not RunState.clues.has("clue_suspicious_manifest"):
		EffectApplier.apply_one({"op": "unlock_clue", "id": "clue_suspicious_manifest"}, "smoke")
	RunState.set_flag("flag_day3_ignored", false)
	RunState.set_flag("flag_know_bradley_scouting", true)
	RunState.set_flag("flag_endure_preview", true)
	RunState.set_flag("route_endure", true)
	RunState.set_edge_field("char_liu_ruyan", "char_lin_ruisheng", "score", 50)


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
	RunState.set_stat("stat_intel", 40)
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
		var got := false
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
				got = true
		if not got:
			for ch in visible:
				if String(ch.get("id", "")) == "C":
					pick = ch
	elif did == "dialog_e014_choice":
		# 告密德茂：裂父子，不依赖民望门槛
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	elif did == "dialog_e015_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	elif did == "dialog_e016_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "A":
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
