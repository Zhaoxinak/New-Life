extends Node
## P13 smoke：ACT_01–12 齐全 + 关键行动效果 + 口风节点。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP13.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	for i in range(1, 13):
		var aid := "act_%02d" % i
		if PackDB.get_row_by_id("def_action", "act_id", aid).is_empty():
			push_error("SMOKE FAIL: missing %s" % aid)
			ok = false

	var a02: Dictionary = PackDB.get_row_by_id("def_action", "act_id", "act_02")
	var a03: Dictionary = PackDB.get_row_by_id("def_action", "act_id", "act_03")
	var a11: Dictionary = PackDB.get_row_by_id("def_action", "act_id", "act_11")
	if String(a02.get("loc_id", "")) != "loc_02":
		push_error("SMOKE FAIL: act_02 loc")
		ok = false
	if String(a03.get("loc_id", "")) != "loc_03":
		push_error("SMOKE FAIL: act_03 loc")
		ok = false
	if String(a11.get("loc_id", "")) != "loc_04":
		push_error("SMOKE FAIL: act_11 loc")
		ok = false

	for did in [
		"dialog_act_04_outro_default",
		"dialog_act_06_outro_gift",
		"dialog_act_09_outro_default",
		"dialog_act_10_outro_well",
		"dialog_act_12_outro_default",
	]:
		if PackDB.get_row_by_id("def_dialog", "dialog_id", did).is_empty():
			push_error("SMOKE FAIL: dialog %s" % did)
			ok = false

	# Direct effect apply (avoid dialog coupling)
	RunState.new_game()
	RunState.set_stat("stat_money", 40)
	var money0 := float(RunState.get_stat("stat_money", 0))
	var edge0 := float(RunState.get_edge("char_wang_pangzi", "char_lin_ruisheng").get("score", 0))
	var row4: Dictionary = PackDB.get_row_by_id("def_action", "act_id", "act_04")
	EffectApplier.apply_all(row4.get("effects", []), "smoke:act_04")
	if float(RunState.get_stat("stat_money", 0)) != money0 - 3.0:
		push_error("SMOKE FAIL: act_04 money")
		ok = false
	elif float(RunState.get_edge("char_wang_pangzi", "char_lin_ruisheng").get("score", 0)) < edge0 + 5.0:
		push_error("SMOKE FAIL: act_04 edge")
		ok = false

	RunState.new_game()
	RunState.set_stat("stat_network", 12)
	var credit0 := float(RunState.get_stat("stat_credit_market", 0))
	var row10: Dictionary = PackDB.get_row_by_id("def_action", "act_id", "act_10")
	EffectApplier.apply_all(row10.get("effects", []), "smoke:act_10")
	if float(RunState.get_stat("stat_credit_market", 0)) < credit0 + 5.0:
		push_error("SMOKE FAIL: act_10 credit")
		ok = false

	RunState.new_game()
	var intel0 := float(RunState.get_stat("stat_intel", 0))
	var row9: Dictionary = PackDB.get_row_by_id("def_action", "act_id", "act_09")
	EffectApplier.apply_all(row9.get("effects", []), "smoke:act_09")
	if float(RunState.get_stat("stat_intel", 0)) <= intel0:
		push_error("SMOKE FAIL: act_09 intel")
		ok = false

	# gift dialog effects
	RunState.new_game()
	RunState.set_stat("stat_money", 35)
	var gift: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_act_06_outro_gift")
	EffectApplier.apply_all(gift.get("effects", []), "smoke:gift")
	if String(RunState.get_edge("char_liu_ruyan", "char_lin_ruisheng").get("debt", "")) != "收过你的小心意":
		push_error("SMOKE FAIL: gift debt")
		ok = false

	if L10n.t("ui.help_body", "").is_empty():
		push_error("SMOKE FAIL: help body")
		ok = false

	if ok:
		print("SMOKE P13 OK act01-12+howto")
		get_tree().quit(0)
	else:
		print("SMOKE P13 FAIL")
		get_tree().quit(1)
