extends Node
## P19–P23：2D 舞台壳 + 账簿 + 履历。
## Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP23.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false
	var ver := PackDB.content_version()
	if ver.find("1.9") < 0 and ver.find("1.10") < 0 and ver.find("p23") < 0 and ver.find("kairo") < 0:
		push_error("SMOKE FAIL: content_version=%s" % ver)
		ok = false

	# location art + hotspot objects
	for lid in ["loc_01", "loc_02", "loc_03", "loc_04", "loc_05", "loc_06"]:
		var path := "res://art/locations/anchao/%s.png" % lid
		if not ResourceLoader.exists(path):
			push_error("SMOKE FAIL: missing bg %s" % path)
			ok = false
		var row: Dictionary = PackDB.get_row_by_id("def_location", "loc_id", lid)
		var spots: Array = row.get("hotspots", [])
		if spots.is_empty():
			push_error("SMOKE FAIL: no hotspots %s" % lid)
			ok = false
		elif typeof(spots[0]) != TYPE_DICTIONARY:
			push_error("SMOKE FAIL: hotspot not object %s" % lid)
			ok = false

	# def_char
	var chars := PackDB.get_rows("def_char")
	if chars.size() < 8:
		push_error("SMOKE FAIL: def_char size=%d" % chars.size())
		ok = false
	var player := PackDB.get_row_by_id("def_char", "char_id", "char_lin_ruisheng")
	if player.is_empty() or not bool(player.get("is_player", false)):
		push_error("SMOKE FAIL: player char")
		ok = false

	# scenes exist
	for scn in [
		"res://ui/PlayChrome.tscn",
		"res://ui/LocationStage.tscn",
		"res://ui/DialogueBox.tscn",
		"res://ui/ActSheet.tscn",
		"res://ui/LedgerOverlay.tscn",
	]:
		if not ResourceLoader.exists(scn):
			push_error("SMOKE FAIL: missing %s" % scn)
			ok = false

	# history write path
	RunState.new_game()
	RunState.append_history("event", "E001", "event.E001", {})
	EffectApplier.apply_one({
		"op": "add",
		"edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
		"key": "score",
		"value": 1,
	}, "smoke")
	RunState.set_player_rank("waichang")
	var kinds: Dictionary = {}
	for e in RunState.history:
		kinds[String(e.get("kind", ""))] = true
	if not kinds.has("event") or not kinds.has("edge") or not kinds.has("rank"):
		push_error("SMOKE FAIL: history kinds=%s" % str(kinds))
		ok = false

	# ceremony payload unlocks
	var cer: Dictionary = PromotionSystem.last_ceremony
	if cer.is_empty() or not cer.has("unlocks"):
		push_error("SMOKE FAIL: ceremony unlocks")
		ok = false

	# snapshot roundtrip history
	var snap := RunState.snapshot()
	if not snap.has("history") or (snap["history"] as Array).is_empty():
		push_error("SMOKE FAIL: snapshot history")
		ok = false
	RunState.apply_snapshot(snap)
	if RunState.history.is_empty():
		push_error("SMOKE FAIL: apply_snapshot history")
		ok = false

	if ok:
		print("SMOKE P23 OK ui2d+ledger+history ver=%s hist=%d" % [ver, RunState.history.size()])
		get_tree().quit(0)
	else:
		print("SMOKE P23 FAIL")
		get_tree().quit(1)
