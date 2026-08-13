extends Node
## P4 smoke：章一→E019→E020→E021→E022→E018(A) 全链路。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP4.tscn


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

	_seed_for_endure_finale()

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E019", false)), 200):
		push_error("SMOKE FAIL: E019")
		ok = false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E020", false)), 200):
		push_error("SMOKE FAIL: E020")
		ok = false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E021", false)), 200):
		push_error("SMOKE FAIL: E021")
		ok = false

	# 主清算前确保婚事债仍 open（轻清算只打 slight）
	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")

	_seed_for_e018_a()

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E022", false)), 200):
		push_error("SMOKE FAIL: E022 day=%s fiancee=%s rank=%s" % [
			RunState.day(),
			RunState.grudges.get("grudge_zian_fiancee", {}),
			RunState.player_rank(),
		])
		ok = false

	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "punished":
		push_error("SMOKE FAIL: fiancee not punished")
		ok = false
	if not RunState.get_flag("flag_marriage_agency_reclaimed", false):
		push_error("SMOKE FAIL: marriage agency")
		ok = false
	if not RunState.get_flag("flag_reckoning_zian_started", false):
		push_error("SMOKE FAIL: reckoning started flag")
		ok = false
	if String(RunState.meta.get("rank_address", "")) != PromotionSystem.address_for():
		push_error("SMOKE FAIL: post-E022 address=%s" % str(RunState.meta.get("rank_address", "")))
		ok = false
	if PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_e022_punish_lin").is_empty():
		push_error("SMOKE FAIL: missing punish_lin")
		ok = false

	# E018 门槛
	RunState.set_stat("stat_trust_firm", 55)
	RunState.set_stat("stat_intel", 40)
	RunState.set_meter("father_son", 20)

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E018", false)), 200):
		push_error("SMOKE FAIL: E018")
		ok = false

	if not RunState.get_flag("flag_ending_a", false):
		push_error("SMOKE FAIL: ending A not set flags=%s" % str(RunState.flags.keys()))
		ok = false
	if RunState.player_rank() != "paojie":
		push_error("SMOKE FAIL: rank not paojie got %s" % RunState.player_rank())
		ok = false
	if String(RunState.meta.get("rank_address", "")) != PromotionSystem.address_for("paojie"):
		push_error("SMOKE FAIL: ending address=%s" % str(RunState.meta.get("rank_address", "")))
		ok = false
	if String(PromotionSystem.last_ceremony.get("address", "")) != L10n.t("promo.address.paojie", "林跑街"):
		push_error("SMOKE FAIL: ceremony address=%s" % str(PromotionSystem.last_ceremony.get("address", "")))
		ok = false
	for did in ["dialog_e018_a_standing", "dialog_e018_a_crowd", "dialog_e018_a_land"]:
		if PackDB.get_row_by_id("def_dialog", "dialog_id", did).is_empty():
			push_error("SMOKE FAIL: missing %s" % did)
			ok = false
	if RunState.get_flag("seen_event_E022B", false) or RunState.get_flag("seen_event_E022C", false):
		push_error("SMOKE FAIL: main reckoning mutex broken")
		ok = false

	if ok:
		print("SMOKE P4 OK rank=%s ending_a=%s fiancee=%s demao=%s day=%s monthly=%s" % [
			RunState.player_rank(),
			RunState.get_flag("flag_ending_a", false),
			RunState.grudges.get("grudge_zian_fiancee", {}).get("status", ""),
			RunState.grudges.get("grudge_demao_defer", {}).get("status", ""),
			RunState.day(),
			RunState.meta.get("monthly_stipend", 0),
		])
		get_tree().quit(0)
	else:
		print("SMOKE P4 FAILED")
		get_tree().quit(1)


func _seed_for_endure_finale() -> void:
	RunState.set_stat("stat_trust_firm", 50)
	RunState.set_stat("stat_intel", 28)
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
		if pred.call():
			return true
		if DialogueRunner.is_active():
			_step_dialog()
			continue
		if not RunState.queue.is_empty():
			TickPipeline.begin_queued_event()
			continue
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
	# Prefer A (punish / steady) except E008→B, E018 demao→B forgive optional use A
	if did == "dialog_e008_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	elif did == "dialog_e009_choice" or did == "dialog_e019_choice":
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
