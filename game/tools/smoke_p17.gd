extends Node
## P17 smoke：立绘占位资源可加载。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/SmokeP17.tscn

const REQUIRED := [
	"narrator",
	"char_lin_ruisheng",
	"char_qian_demao",
	"char_qian_zian",
	"char_liu_ruyan",
	"char_bradley",
	"char_zhao_hongyun",
	"char_wang_pangzi",
	"char_zhou_guanshi",
	"char_qing_daren",
	"char_msg_broker",
	"char_bank_clerk",
	"char_firm_hand",
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not PackDB.loaded:
		push_error("SMOKE FAIL: PackDB")
		ok = false

	for sid in REQUIRED:
		var path := "res://art/portraits/anchao/%s.png" % sid
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			push_error("SMOKE FAIL: missing portrait %s" % path)
			ok = false
			continue
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			push_error("SMOKE FAIL: load %s" % path)
			ok = false
		elif tex.get_width() < 64 or tex.get_height() < 64:
			push_error("SMOKE FAIL: tiny portrait %s" % sid)
			ok = false

	if PackDB.content_version().find("p17") < 0:
		push_error("SMOKE FAIL: content_version=%s" % PackDB.content_version())
		ok = false

	if ok:
		print("SMOKE P17 OK portraits=%d" % REQUIRED.size())
		get_tree().quit(0)
	else:
		print("SMOKE P17 FAIL")
		get_tree().quit(1)
