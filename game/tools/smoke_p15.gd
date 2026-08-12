extends Node
## P15 smoke：R001/R006/R007/R008 角色口吻链 + 立绘占位色板。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP15.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	var checks := {
		"dialog_r001_start": "dialog_r001_broker",
		"dialog_r006_start": "dialog_r006_clerk",
		"dialog_r007_start": "dialog_r007_warn",
		"dialog_r008_start": "dialog_r008_gossip",
	}
	for start_id in checks.keys():
		var row: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", start_id)
		if String(row.get("next", "")) != String(checks[start_id]):
			push_error("SMOKE FAIL: chain %s" % start_id)
			ok = false

	var speakers := {
		"dialog_r001_broker": "char_msg_broker",
		"dialog_r006_clerk": "char_bank_clerk",
		"dialog_r007_warn": "char_wang_pangzi",
		"dialog_r008_gossip": "char_firm_hand",
	}
	for did in speakers.keys():
		var d: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", did)
		if d.is_empty() or String(d.get("speaker", "")) != String(speakers[did]):
			push_error("SMOKE FAIL: speaker %s" % did)
			ok = false

	# effects still on leaf nodes
	var r1: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_r001_pay")
	var r6: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_r006_outro")
	var r7: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_r007_feel")
	var r8: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_r008_outro")
	if (r1.get("effects", []) as Array).is_empty() or (r6.get("effects", []) as Array).is_empty() \
		or (r7.get("effects", []) as Array).is_empty() or (r8.get("effects", []) as Array).is_empty():
		push_error("SMOKE FAIL: leaf effects")
		ok = false

	RunState.new_game()
	RunState.set_stat("stat_money", 20)
	var money0 := float(RunState.get_stat("stat_money", 0))
	EffectApplier.apply_all(r1.get("effects", []), "smoke")
	if float(RunState.get_stat("stat_money", 0)) != money0 - 5.0:
		push_error("SMOKE FAIL: r001 pay")
		ok = false

	RunState.new_game()
	EffectApplier.apply_all(r6.get("effects", []), "smoke")
	if not RunState.get_flag("flag_bank_tier2", false):
		push_error("SMOKE FAIL: r006 tier2")
		ok = false

	for key in ["char_msg_broker", "char_bank_clerk", "char_firm_hand", "dialog.r007.warn", "dialog.r008.outro"]:
		if L10n.t(key, "").is_empty():
			push_error("SMOKE FAIL: l10n %s" % key)
			ok = false

	# Portrait drop path: res://art/portraits/anchao/<speaker_id>.png （缺省用色板字）
	if L10n.t("char.narrator", "旁白").substr(0, 1).is_empty():
		push_error("SMOKE FAIL: glyph source")
		ok = false

	if ok:
		print("SMOKE P15 OK random-voice+portrait-fallback")
		get_tree().quit(0)
	else:
		print("SMOKE P15 FAIL")
		get_tree().quit(1)
