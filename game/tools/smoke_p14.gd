extends Node
## P14 smoke：R002/R009 加厚节点 + E018 闪回文案。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP14.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	var r2s: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_r002_start")
	if String(r2s.get("speaker", "")) != "char_wang_pangzi":
		push_error("SMOKE FAIL: r002 speaker")
		ok = false
	var r2o: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_r002_outro")
	if r2o.is_empty():
		push_error("SMOKE FAIL: r002 outro")
		ok = false
	if PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_r009_bradley").is_empty():
		push_error("SMOKE FAIL: r009 bradley")
		ok = false
	var r9s: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_r009_start")
	if String(r9s.get("next", "")) != "dialog_r009_bradley":
		push_error("SMOKE FAIL: r009 chain")
		ok = false

	var grudge_txt := L10n.t("dialog.e018.a.demao_grudge", "")
	if grudge_txt.find("闪回暂缓") >= 0 or grudge_txt.find("跑街暂缓") < 0:
		push_error("SMOKE FAIL: e018 flashback text='%s'" % grudge_txt)
		ok = false

	var demao_node: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", "dialog_e018_a_demao")
	var tags: Array = demao_node.get("tags", [])
	if not tags.has("flashback"):
		push_error("SMOKE FAIL: flashback tag")
		ok = false

	for eid in ["R002", "R009", "E018"]:
		var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		var entry := String(ev.get("dialog_entry", ""))
		if entry.is_empty() or PackDB.get_row_by_id("def_dialog", "dialog_id", entry).is_empty():
			push_error("SMOKE FAIL: entry %s" % eid)
			ok = false

	RunState.new_game()
	var intel0 := float(RunState.get_stat("stat_intel", 0))
	EffectApplier.apply_all(r2o.get("effects", []), "smoke:r002")
	if float(RunState.get_stat("stat_intel", 0)) <= intel0:
		push_error("SMOKE FAIL: r002 intel effect")
		ok = false

	if L10n.t("ui.tag_random", "").is_empty() or L10n.t("dialog.r009.bradley", "").is_empty():
		push_error("SMOKE FAIL: l10n")
		ok = false

	# closing prose not synopsis-short
	if L10n.t("dialog.e018.a.close", "").length() < 40:
		push_error("SMOKE FAIL: e018 close too thin")
		ok = false

	if ok:
		print("SMOKE P14 OK r002+r009+e018+speaker")
		get_tree().quit(0)
	else:
		print("SMOKE P14 FAIL")
		get_tree().quit(1)
