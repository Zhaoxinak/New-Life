extends SceneTree



func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	await process_frame
	await process_frame
	var pdb: Node = root.get_node_or_null("PackDB")
	if pdb == null:
		push_error("smoke_pack_bundled: PackDB autoload missing")
		quit(1)
		return
	var bundled: = ProjectSettings.globalize_path("res://data/packs")
	print("smoke_pack_bundled: bundled=", bundled)
	pdb.packs_root_abs = bundled
	pdb.call("load_pack", "core")
	var stats_n: int = pdb.call("get_table", "stats").size()
	var loc_n: int = pdb.call("get_table", "locations").size()
	var quest_n: int = pdb.call("get_table", "quests").size()
	var money_row: Dictionary = pdb.call("get_row", "stats", "money")
	var dock: Dictionary = pdb.call("get_row", "locations", "dock")
	print("smoke_pack_bundled: stats=%d locations=%d quests=%d" % [stats_n, loc_n, quest_n])
	print("smoke_pack_bundled: money.initial=", money_row.get("initial", "?"))
	print("smoke_pack_bundled: dock.start_unlocked=", dock.get("start_unlocked", "?"))
	var ok: = stats_n > 0 and loc_n > 0 and quest_n > 0\
	and str(money_row.get("initial", "")) == "80"\
	and str(dock.get("start_unlocked", "")) == "1"
	if ok:
		print("smoke_pack_bundled: OK")
		quit(0)
	else:
		push_error("smoke_pack_bundled: FAILED — bundled pack tables unreadable")
		quit(1)
