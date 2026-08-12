extends Node
## P18 smoke：外发版本号（允许后续 1.9+ 继续通过）。
## Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP18.tscn


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false
	var ver := PackDB.content_version()
	# P18 起：至少 1.8；后续重做 UI 仍视为通过
	if ver.find("1.8") < 0 and ver.find("1.9") < 0 and ver.find("p18") < 0 and ver.find("p23") < 0:
		push_error("SMOKE FAIL: content_version=%s" % ver)
		ok = false
	if ok:
		print("SMOKE P18 OK dist-version=%s" % ver)
		get_tree().quit(0)
	else:
		print("SMOKE P18 FAIL")
		get_tree().quit(1)
