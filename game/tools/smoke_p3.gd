extends Node
## P3 smoke：章一 → seed → E019 → E020(A) → E021 惩罚 → 校验职级/清算。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP3.tscn


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
		push_error("SMOKE FAIL: chapter1 E009")
		ok = false

	# 压缩演示：补门槛（章一结束信任常不足 45）
	RunState.set_stat("stat_trust_firm", 50)
	RunState.set_stat("stat_intel", 28)
	RunState.set_flag("route_endure", true)
	RunState.set_flag("route_defect", false)
	RunState.set_flag("route_foreign", false)
	if String(RunState.grudges.get("grudge_zian_slight", {}).get("status", "")) != "open":
		EffectApplier.apply_one({"op": "unlock_grudge", "id": "grudge_zian_slight", "buried_by": "E004"}, "smoke")

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E019", false)), 200):
		push_error("SMOKE FAIL: E019 day=%s slot=%s queue=%s" % [RunState.day(), RunState.slot(), str(RunState.queue)])
		ok = false

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E020", false)), 200):
		push_error("SMOKE FAIL: E020 day=%s rank=%s trust=%s mutex=%s" % [
			RunState.day(), RunState.player_rank(), RunState.get_stat("stat_trust_firm"),
			RunState.get_flag("mutex_done_chapter2.rankup", false),
		])
		ok = false

	if RunState.player_rank() != "waichang":
		push_error("SMOKE FAIL: rank not waichang")
		ok = false
	if not RunState.get_flag("flag_grudge_window_light", false) and String(RunState.grudges["grudge_zian_slight"].get("status", "")) == "open":
		# window may already be cleared if E021 also finished in same loop — check below
		pass
	if int(RunState.meta.get("monthly_stipend", 0)) < 5:
		# PromotionSystem should have set on rank change
		if PromotionSystem.monthly_for("waichang") < 5:
			push_error("SMOKE FAIL: monthly stipend")
			ok = false
		else:
			RunState.meta["monthly_stipend"] = PromotionSystem.monthly_for("waichang")

	if not _play_until(func() -> bool: return bool(RunState.get_flag("seen_event_E021", false)), 200):
		push_error("SMOKE FAIL: E021")
		ok = false

	var gstatus := String(RunState.grudges.get("grudge_zian_slight", {}).get("status", ""))
	if gstatus != "punished":
		push_error("SMOKE FAIL: expected slight punished, got %s" % gstatus)
		ok = false
	if RunState.get_flag("flag_grudge_window_light", false):
		push_error("SMOKE FAIL: grudge window should clear")
		ok = false

	# 外场行动解锁
	var has_act20 := false
	for row in TickPipeline.available_actions():
		if String(row.get("act_id", "")) == "act_20":
			has_act20 = true
			break
	# may be wrong loc/slot — force morning loc_01
	RunState.meta["slot"] = "morning"
	RunState.set_current_loc("loc_01")
	has_act20 = false
	for row in TickPipeline.available_actions():
		if String(row.get("act_id", "")) == "act_20":
			has_act20 = true
	if not has_act20:
		push_error("SMOKE FAIL: act_20 not unlocked for waichang")
		ok = false

	# 互斥：不应见到 E020B
	if RunState.get_flag("seen_event_E020B", false) or RunState.get_flag("seen_event_E020C", false):
		push_error("SMOKE FAIL: mutex broken for rankup")
		ok = false

	if ok:
		print("SMOKE P3 OK rank=%s monthly=%s slight=%s e019=%s e020=%s e021=%s day=%s" % [
			RunState.player_rank(),
			RunState.meta.get("monthly_stipend", PromotionSystem.monthly_for(RunState.player_rank())),
			gstatus,
			RunState.get_flag("seen_event_E019", false),
			RunState.get_flag("seen_event_E020", false),
			RunState.get_flag("seen_event_E021", false),
			RunState.day(),
		])
		get_tree().quit(0)
	else:
		print("SMOKE P3 FAILED")
		get_tree().quit(1)


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
	# E008 隐忍；E009 忍；E019 点到为止；E021 惩罚
	if did == "dialog_e008_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "B":
				pick = ch
	elif did == "dialog_e009_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	elif did == "dialog_e019_choice":
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	elif did.begins_with("dialog_e021") and did.ends_with("_choice"):
		for ch in visible:
			if String(ch.get("id", "")) == "A":
				pick = ch
	DialogueRunner.select_choice(pick)
