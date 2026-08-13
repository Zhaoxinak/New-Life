extends Node
## P5 smoke：Ceremony 可装载 + F001 警告 + F003 开除 end_run。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP5.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	for eid in ["F001", "F002", "F003", "F004", "F005"]:
		var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		if ev.is_empty():
			push_error("SMOKE FAIL: missing event %s" % eid)
			ok = false

	var overlay_res := load("res://ui/CeremonyOverlay.tscn")
	if overlay_res == null:
		push_error("SMOKE FAIL: CeremonyOverlay missing")
		ok = false

	RunState.new_game()
	TickPipeline.on_slot_enter()
	# 避开日历主线：清空队列后测失败扫描
	RunState.queue.clear()

	RunState.set_stat("stat_suspicion", 35)
	RunState.set_stat("stat_trust_firm", 40)
	var f1 := FailureScanner.scan_and_enqueue()
	if f1 != "F001":
		push_error("SMOKE FAIL: expected F001 got '%s'" % f1)
		ok = false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_F001", false)), 80):
		push_error("SMOKE FAIL: F001 playback")
		ok = false

	# 降职快测（不播完日历）
	RunState.queue.clear()
	RunState.set_stat("stat_suspicion", 55)
	RunState.set_stat("stat_trust_firm", 15)
	EffectApplier.apply_one({"op": "set_rank", "value": "waichang"}, "smoke")
	var f2 := FailureScanner.scan_and_enqueue()
	if f2 != "F002":
		push_error("SMOKE FAIL: expected F002 got '%s'" % f2)
		ok = false
	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_F002", false)), 80):
		push_error("SMOKE FAIL: F002 playback")
		ok = false
	if not RunState.get_flag("flag_demoted", false):
		push_error("SMOKE FAIL: flag_demoted")
		ok = false
	if RunState.player_rank() != "apprentice":
		push_error("SMOKE FAIL: demote rank got %s" % RunState.player_rank())
		ok = false
	if int(RunState.meta.get("monthly_stipend", -1)) != 2:
		push_error("SMOKE FAIL: monthly after demote %s" % str(RunState.meta.get("monthly_stipend", -1)))
		ok = false

	# 开除终局
	RunState.queue.clear()
	RunState.set_stat("stat_suspicion", 75)
	var f3 := FailureScanner.scan_and_enqueue()
	if f3 != "F003":
		push_error("SMOKE FAIL: expected F003 got '%s'" % f3)
		ok = false
	if not _play_until(func() -> bool: return RunState.ended, 80):
		push_error("SMOKE FAIL: F003 end_run")
		ok = false
	if RunState.end_reason != "fired":
		push_error("SMOKE FAIL: end_reason=%s" % RunState.end_reason)
		ok = false
	if not RunState.get_flag("flag_fired", false) or not RunState.get_flag("flag_ending_fail", false):
		push_error("SMOKE FAIL: fired flags")
		ok = false

	# F004 / F005 条件可触发（独立新局，不播完）
	RunState.new_game()
	RunState.queue.clear()
	RunState.set_edge_field("char_liu_ruyan", "char_lin_ruisheng", "score", -25)
	RunState.set_meter("pursuit", 65)
	if FailureScanner.scan_and_enqueue() != "F004":
		push_error("SMOKE FAIL: F004 require")
		ok = false

	RunState.new_game()
	RunState.queue.clear()
	RunState.set_edge_field("char_qian_demao", "char_lin_ruisheng", "suspicion", 4)
	if FailureScanner.scan_and_enqueue() != "F005":
		push_error("SMOKE FAIL: F005 require")
		ok = false

	# 社交称呼升职：A 阶 set_rank → 林外场；B/C 外座仪式
	RunState.new_game()
	RunState.queue.clear()
	EffectApplier.apply_one({"op": "set_rank", "value": "waichang"}, "smoke")
	var cer: Dictionary = PromotionSystem.last_ceremony
	if String(cer.get("address", "")) != "林外场" and String(cer.get("address", "")) != L10n.t("promo.address.waichang", "林外场"):
		push_error("SMOKE FAIL: waichang address=%s" % str(cer.get("address", "")))
		ok = false
	var beat_ids: PackedStringArray = []
	for b in cer.get("beats", []):
		if typeof(b) == TYPE_DICTIONARY:
			beat_ids.append(String((b as Dictionary).get("id", "")))
	if not beat_ids.has("standing"):
		push_error("SMOKE FAIL: missing standing beat %s" % str(beat_ids))
		ok = false
	if String(RunState.meta.get("rank_address", "")) != PromotionSystem.address_for("waichang"):
		push_error("SMOKE FAIL: meta rank_address")
		ok = false
	for crowd_id in ["dialog_e020_crowd", "dialog_e020b_crowd", "dialog_e020c_crowd"]:
		if PackDB.get_row_by_id("def_dialog", "dialog_id", crowd_id).is_empty():
			push_error("SMOKE FAIL: missing %s" % crowd_id)
			ok = false

	EffectApplier.apply_one({"op": "set_flag", "key": "flag_rank_jufeng_paojie", "value": true}, "smoke")
	EffectApplier.apply_one({"op": "external_rank_ceremony", "value": "jufeng_paojie"}, "smoke")
	cer = PromotionSystem.last_ceremony
	if String(cer.get("seat", "")) != "jufeng_paojie":
		push_error("SMOKE FAIL: jufeng seat")
		ok = false
	if String(cer.get("address", "")) != PromotionSystem.address_for("", "jufeng_paojie"):
		push_error("SMOKE FAIL: jufeng address=%s" % str(cer.get("address", "")))
		ok = false

	EffectApplier.apply_one({"op": "external_rank_ceremony", "value": "foreign_agent"}, "smoke")
	cer = PromotionSystem.last_ceremony
	if String(cer.get("seat", "")) != "foreign_agent":
		push_error("SMOKE FAIL: foreign seat")
		ok = false
	if String(cer.get("address", "")) != PromotionSystem.address_for("", "foreign_agent"):
		push_error("SMOKE FAIL: foreign address=%s" % str(cer.get("address", "")))
		ok = false

	# 轻清算仪式 payload：社交称呼 + 站位/看客拍
	RunState.new_game()
	RunState.queue.clear()
	EffectApplier.apply_one({"op": "set_rank", "value": "waichang"}, "smoke")
	EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_slight", "buried_by": "E004"}, "smoke")
	var got_reckon := {"fired": false}
	var _on_reckon := func(ev: String, payload: Dictionary) -> void:
		if ev == "grudge_resolved":
			got_reckon.clear()
			got_reckon["fired"] = true
			for k in payload.keys():
				got_reckon[k] = payload[k]
	DomainBus.domain_event.connect(_on_reckon)
	EffectApplier.apply_one({"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish"}, "smoke")
	DomainBus.domain_event.disconnect(_on_reckon)
	if not bool(got_reckon.get("fired", false)):
		push_error("SMOKE FAIL: grudge_resolved not emitted")
		ok = false
	elif String(got_reckon.get("address", "")) != PromotionSystem.address_for("waichang"):
		push_error("SMOKE FAIL: reckon address=%s" % str(got_reckon.get("address", "")))
		ok = false
	elif String(got_reckon.get("window", "")) != "light":
		push_error("SMOKE FAIL: light window=%s" % str(got_reckon.get("window", "")))
		ok = false
	if PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_e021_onlooker_choice").is_empty():
		push_error("SMOKE FAIL: missing onlooker branch")
		ok = false

	# 主清算：婚事债 window=main；silent 并兑不弹仪式
	EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_fiancee", "buried_by": "E008"}, "smoke")
	got_reckon = {"fired": false, "count": 0}
	var _on_main := func(ev: String, payload: Dictionary) -> void:
		if ev == "grudge_resolved":
			got_reckon["fired"] = true
			got_reckon["count"] = int(got_reckon.get("count", 0)) + 1
			got_reckon["window"] = payload.get("window", "")
			got_reckon["id"] = payload.get("id", "")
	DomainBus.domain_event.connect(_on_main)
	EffectApplier.apply_one({"op": "resolve_grudge", "id": "grudge_zian_fiancee", "mode": "punish"}, "smoke")
	EffectApplier.apply_one({"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish", "if_open": true, "silent": true}, "smoke")
	DomainBus.domain_event.disconnect(_on_main)
	if not bool(got_reckon.get("fired", false)) or String(got_reckon.get("window", "")) != "main":
		push_error("SMOKE FAIL: main reckon window=%s" % str(got_reckon.get("window", "")))
		ok = false
	if int(got_reckon.get("count", 0)) != 1:
		push_error("SMOKE FAIL: silent slight should not emit ceremony count=%s" % str(got_reckon.get("count", 0)))
		ok = false
	for did in ["dialog_e022_address", "dialog_e022_punish_lin", "dialog_e022_land_punish", "dialog_e022b_crowd_punish"]:
		if PackDB.get_row_by_id("def_dialog", "dialog_id", did).is_empty():
			push_error("SMOKE FAIL: missing %s" % did)
			ok = false

	if not await _assert_address_keyword_highlight():
		ok = false

	if ok:
		print("SMOKE P5 OK address+external+light+main-reckon+kw")
		get_tree().quit(0)
	else:
		print("SMOKE P5 FAILED")
		get_tree().quit(1)


func _assert_address_keyword_highlight() -> bool:
	var node: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_e018_a_title")
	if node.is_empty():
		push_error("SMOKE FAIL: missing dialog_e018_a_title")
		return false
	var tags: Array = node.get("tags", [])
	if not tags.has("rank_address") and not tags.has("keyword_highlight"):
		push_error("SMOKE FAIL: title missing highlight tags")
		return false
	var box: Control = (load("res://ui/DialogueBox.tscn") as PackedScene).instantiate()
	add_child(box)
	await get_tree().process_frame
	if not box.has_method("present_node"):
		push_error("SMOKE FAIL: DialogueBox present_node")
		box.queue_free()
		return false
	box.call("present_node", node)
	var body: RichTextLabel = box.get_node_or_null("%Body") as RichTextLabel
	if body == null:
		push_error("SMOKE FAIL: DialogueBox Body")
		box.queue_free()
		return false
	var txt := String(body.text)
	if not txt.contains("[color=#c4783a]") or not txt.contains("林跑街"):
		push_error("SMOKE FAIL: address keyword not highlighted txt=%s" % txt.substr(0, 120))
		box.queue_free()
		return false
	## 长词不被短词拆坏：高亮块应是完整「林跑街」
	if not txt.contains("[color=#c4783a][b]林跑街[/b][/color]"):
		push_error("SMOKE FAIL: 林跑街 wrap broken txt=%s" % txt.substr(0, 160))
		box.queue_free()
		return false
	box.queue_free()
	return true


func _play_until(pred: Callable, max_steps: int) -> bool:
	var guard := 0
	while guard < max_steps:
		guard += 1
		# 先收完对白（end_run 可能在叶节点入场就写 ended）
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
	DialogueRunner.select_choice(visible[0])
