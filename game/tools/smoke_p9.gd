extends Node
## P9 smoke：B 跳槽线 + C 洋人线全链路。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP9.tscn

var _route_pick: String = "A"  # E009 A/B/C


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	if not _run_route_b():
		ok = false
	if not _run_route_c():
		ok = false

	if ok:
		print("SMOKE P9 OK ending_b+ending_c")
		get_tree().quit(0)
	else:
		print("SMOKE P9 FAILED")
		get_tree().quit(1)


func _run_route_b() -> bool:
	_route_pick = "B"
	_e014_pick = "B"
	_e017_pick = "B"
	RunState.new_game()
	TickPipeline.on_slot_enter()

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E009", false)), 400):
		push_error("SMOKE B FAIL: E009")
		return false
	if not RunState.get_flag("route_defect", false):
		push_error("SMOKE B FAIL: route_defect not set")
		return false

	_seed_discovery_gates()
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E013", false)), 400):
		push_error("SMOKE B FAIL: E013")
		return false

	_seed_for_defect()
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E020B", false)), 400):
		push_error("SMOKE B FAIL: E020B day=%s flags=%s" % [RunState.day(), str(RunState.flags.keys())])
		return false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E021B", false)), 200):
		push_error("SMOKE B FAIL: E021B")
		return false
	if String(RunState.meta.get("rank_address", "")) != PromotionSystem.address_for("waichang") \
		and not bool(RunState.get_flag("flag_rank_jufeng_paojie", false)):
		# E020B 升外场后称呼应为林外场；外座仪式在 E018B
		if String(RunState.meta.get("rank_address", "")) != L10n.t("promo.address.waichang", "林外场"):
			push_error("SMOKE B FAIL: post-E021B address=%s" % str(RunState.meta.get("rank_address", "")))
			return false
	if RunState.get_flag("flag_grudge_window_light", false):
		push_error("SMOKE B FAIL: light window still open")
		return false

	_seed_ch3_bridge()
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E014", false)), 200):
		push_error("SMOKE B FAIL: E014")
		return false
	RunState.set_edge_field("char_qian_demao", "char_lin_ruisheng", "suspicion", 0)
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E015", false)), 200):
		push_error("SMOKE B FAIL: E015")
		return false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E016", false)), 200):
		push_error("SMOKE B FAIL: E016")
		return false

	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E022B", false)), 200):
		push_error("SMOKE B FAIL: E022B")
		return false
	if not RunState.get_flag("flag_marriage_agency_reclaimed", false):
		push_error("SMOKE B FAIL: marriage agency after E022B")
		return false
	if not RunState.get_flag("flag_reckoning_zian_started", false):
		push_error("SMOKE B FAIL: reckoning started")
		return false

	RunState.set_stat("stat_network", 45)
	RunState.set_stat("stat_intel", 40)
	RunState.set_edge_field("char_zhao_hongyun", "char_lin_ruisheng", "score", 45)

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E018", false)), 200):
		push_error("SMOKE B FAIL: E018")
		return false
	if not RunState.get_flag("flag_ending_b", false):
		push_error("SMOKE B FAIL: ending_b flags route_d=%s net=%s" % [
			RunState.get_flag("route_defect", false),
			RunState.get_stat("stat_network", 0),
		])
		return false
	if String(RunState.meta.get("rank_address", "")) != PromotionSystem.address_for("", "jufeng_paojie"):
		push_error("SMOKE B FAIL: address=%s" % str(RunState.meta.get("rank_address", "")))
		return false
	if String(PromotionSystem.last_ceremony.get("seat", "")) != "jufeng_paojie":
		push_error("SMOKE B FAIL: ceremony seat")
		return false
	if PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_e018_b_land").is_empty():
		push_error("SMOKE B FAIL: missing b land")
		return false
	if RunState.get_flag("flag_ending_a", false) or RunState.get_flag("flag_ending_c", false):
		push_error("SMOKE B FAIL: wrong ending flags")
		return false
	print("SMOKE P9B OK ending_b jufeng=%s address=%s" % [
		RunState.get_flag("flag_rank_jufeng_paojie", false),
		RunState.meta.get("rank_address", ""),
	])
	return true


func _run_route_c() -> bool:
	_route_pick = "C"
	RunState.new_game()
	TickPipeline.on_slot_enter()

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E009", false)), 400):
		push_error("SMOKE C FAIL: E009")
		return false
	if not RunState.get_flag("route_foreign", false):
		push_error("SMOKE C FAIL: route_foreign not set")
		return false

	_seed_discovery_gates()
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E013", false)), 400):
		push_error("SMOKE C FAIL: E013")
		return false

	_seed_for_foreign()
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E020C", false)), 400):
		push_error("SMOKE C FAIL: E020C")
		return false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E021C", false)), 200):
		push_error("SMOKE C FAIL: E021C")
		return false

	# E014A 需民望；E017A 须在 E016 收尾自动开播前就选好
	RunState.set_stat("stat_support_mid", 45)
	RunState.set_stat("stat_support_low", 45)
	_seed_ch3_bridge()
	_e014_pick = "A"
	_e017_pick = "A"
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E014", false)), 200):
		push_error("SMOKE C FAIL: E014")
		return false
	if not RunState.items.has("item_qing_letter"):
		push_error("SMOKE C FAIL: qing letter")
		return false

	RunState.set_edge_field("char_qian_demao", "char_lin_ruisheng", "suspicion", 0)
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E015", false)), 200):
		push_error("SMOKE C FAIL: E015")
		return false

	if float(RunState.get_meter("father_son")) > 45.0:
		RunState.set_meter("father_son", 30)
	RunState.set_meter("impression_qing", max(30.0, RunState.get_meter("impression_qing")))
	RunState.set_meter("impression_bradley", max(15.0, RunState.get_meter("impression_bradley")))
	RunState.set_flag("route_foreign_closed", false)

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E017", false)), 400):
		push_error("SMOKE C FAIL: E017 day=%s slot=%s qing=%s brad=%s" % [
			RunState.day(), RunState.slot(),
			RunState.get_meter("impression_qing"),
			RunState.get_meter("impression_bradley"),
		])
		return false
	if not RunState.get_flag("flag_ending_c_ready", false):
		push_error("SMOKE C FAIL: ending_c_ready")
		return false

	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E022C", false)), 200):
		push_error("SMOKE C FAIL: E022C")
		return false
	if not RunState.get_flag("flag_marriage_agency_reclaimed", false):
		push_error("SMOKE C FAIL: marriage agency after E022C")
		return false

	RunState.set_stat("stat_intel", 40)
	RunState.set_stat("stat_support_mid", 45)
	RunState.set_meter("impression_qing", 35)
	RunState.set_meter("impression_bradley", 35)

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E018", false)), 200):
		push_error("SMOKE C FAIL: E018")
		return false
	if not RunState.get_flag("flag_ending_c", false):
		push_error("SMOKE C FAIL: ending_c")
		return false
	if String(RunState.meta.get("rank_address", "")) != PromotionSystem.address_for("", "foreign_agent"):
		push_error("SMOKE C FAIL: address=%s" % str(RunState.meta.get("rank_address", "")))
		return false
	if String(PromotionSystem.last_ceremony.get("seat", "")) != "foreign_agent":
		push_error("SMOKE C FAIL: ceremony seat")
		return false
	if PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_e018_c_land").is_empty():
		push_error("SMOKE C FAIL: missing c land")
		return false
	if RunState.get_flag("flag_ending_a", false) or RunState.get_flag("flag_ending_b", false):
		push_error("SMOKE C FAIL: wrong ending")
		return false
	print("SMOKE P9C OK ending_c agent=%s address=%s" % [
		RunState.get_flag("flag_rank_foreign_agent", false),
		RunState.meta.get("rank_address", ""),
	])
	return true


var _e014_pick: String = "B"
var _e017_pick: String = "B"


func _seed_discovery_gates() -> void:
	if int(RunState.get_stat("stat_intel", 0)) < 12:
		RunState.set_stat("stat_intel", 12)
	if not RunState.clues.has("clue_suspicious_manifest"):
		EffectApplier.apply_one({"op": "unlock_clue", "id": "clue_suspicious_manifest"}, "smoke")
	RunState.set_flag("flag_day3_ignored", false)
	RunState.set_flag("flag_know_bradley_scouting", true)
	RunState.set_flag("flag_endure_preview", true)
	RunState.set_edge_field("char_liu_ruyan", "char_lin_ruisheng", "score", 50)


func _seed_for_defect() -> void:
	RunState.set_stat("stat_intel", max(28, int(RunState.get_stat("stat_intel", 0))))
	RunState.set_stat("stat_network", max(30, int(RunState.get_stat("stat_network", 0))))
	RunState.set_stat("stat_trust_firm", max(48, int(RunState.get_stat("stat_trust_firm", 0))))
	RunState.set_flag("route_defect", true)
	RunState.set_flag("route_endure", false)
	RunState.set_flag("route_foreign", false)
	if String(RunState.grudges.get("grudge_zian_slight", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_slight", "buried_by": "E004"}, "smoke")
	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")


func _seed_for_foreign() -> void:
	RunState.set_stat("stat_intel", max(28, int(RunState.get_stat("stat_intel", 0))))
	RunState.set_stat("stat_trust_firm", max(48, int(RunState.get_stat("stat_trust_firm", 0))))
	RunState.set_flag("route_foreign", true)
	RunState.set_flag("route_endure", false)
	RunState.set_flag("route_defect", false)
	RunState.set_flag("route_foreign_closed", false)
	RunState.set_meter("impression_bradley", max(12.0, RunState.get_meter("impression_bradley")))
	if String(RunState.grudges.get("grudge_zian_slight", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_slight", "buried_by": "E004"}, "smoke")
	if String(RunState.grudges.get("grudge_zian_fiancee", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")


func _seed_ch3_bridge() -> void:
	RunState.set_edge_field("char_qian_demao", "char_lin_ruisheng", "suspicion", 0)
	if int(RunState.get_stat("stat_intel", 0)) < 40:
		RunState.set_stat("stat_intel", 42)
	if int(RunState.get_stat("stat_network", 0)) < 30:
		RunState.set_stat("stat_network", 32)
	RunState.set_edge_field("char_wang_pangzi", "char_lin_ruisheng", "score", 40)
	if not RunState.clues.has("clue_special_goods"):
		EffectApplier.apply_one({"op": "unlock_clue", "id": "clue_special_goods"}, "smoke")


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
	elif did == "dialog_e009_choice":
		for ch in visible:
			if String(ch.get("id", "")) == _route_pick:
				pick = ch
	elif did in ["dialog_e003_choice", "dialog_e010_choice", "dialog_e019_choice"]:
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
		for ch in visible:
			if String(ch.get("id", "")) == _e014_pick:
				pick = ch
	elif did == "dialog_e015_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	elif did == "dialog_e016_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	elif did == "dialog_e017_choice":
		for ch in visible:
			if String(ch.get("id", "")) == _e017_pick:
				pick = ch
	elif did.contains("e021") and did.ends_with("_choice"):
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	elif did.contains("e022") and did.ends_with("_choice"):
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	DialogueRunner.select_choice(pick)
