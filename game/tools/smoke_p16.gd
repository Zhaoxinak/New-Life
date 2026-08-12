extends Node
## P16 smoke：试玩说明文案入包。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP16.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	var body := L10n.t("ui.help_body", "")
	for needle in ["建议试玩", "隐忍", "跳槽", "洋行", "19"]:
		if body.find(needle) < 0:
			push_error("SMOKE FAIL: help missing %s" % needle)
			ok = false

	# content_version advances; only assert help copy remains
	if PackDB.content_version().is_empty():
		push_error("SMOKE FAIL: empty content_version")
		ok = false

	if ok:
		print("SMOKE P16 OK playtest-guide")
		get_tree().quit(0)
	else:
		print("SMOKE P16 FAIL")
		get_tree().quit(1)
