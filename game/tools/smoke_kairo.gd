extends Node
## 开罗风舞台自检。
## Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeKairo.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false
	var ver := PackDB.content_version()
	if ver.find("kairo") < 0 and ver.find("1.10") < 0:
		push_error("SMOKE FAIL: ver=%s" % ver)
		ok = false
	for lid in ["loc_01", "loc_02", "loc_03", "loc_04", "loc_05", "loc_06"]:
		if not ResourceLoader.exists("res://art/locations/anchao/%s.png" % lid):
			push_error("SMOKE FAIL: loc art %s" % lid)
			ok = false
	for cid in ["char_lin_ruisheng", "char_qian_demao", "char_liu_ruyan"]:
		if not ResourceLoader.exists("res://art/sprites/anchao/%s.png" % cid):
			push_error("SMOKE FAIL: sprite %s" % cid)
			ok = false
	if not ResourceLoader.exists("res://ui/KairoStyle.gd"):
		push_error("SMOKE FAIL: KairoStyle")
		ok = false
	# style helper callable
	var _c := KairoStyle.CREAM
	if _c.a <= 0.0:
		push_error("SMOKE FAIL: cream")
		ok = false
	var cast: Array = KairoStyle.LOC_CAST.get("loc_01", [])
	if cast.is_empty():
		push_error("SMOKE FAIL: loc cast")
		ok = false
	if ok:
		print("SMOKE KAIRO OK ver=%s cast=%d" % [ver, cast.size()])
		get_tree().quit(0)
	else:
		print("SMOKE KAIRO FAIL")
		get_tree().quit(1)
