extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var ok := true
	var npc: CharacterBody2D = load("res://world/OutdoorNpc.tscn").instantiate()
	root.add_child(npc)
	if npc.has_method("setup"):
		npc.call("setup", "zhou_hongye", Color.WHITE, "", Vector2.ZERO)
	await process_frame
	await process_frame

	var sprite: Sprite2D = npc.get_node("%Sprite") as Sprite2D
	if sprite == null or sprite.texture == null or not sprite.region_enabled:
		push_error("SMOKE FAIL: Sprite2D walk sheet not applied")
		ok = false
	else:
		var seen: Dictionary = {}
		for i in 4:
			WalkSheets.set_pose(sprite, "s", true, i)
			var key := str(sprite.region_rect)
			seen[key] = true
			print("SMOKE frame %s region=%s" % [i, sprite.region_rect])
		if seen.size() < 2:
			push_error("SMOKE FAIL: walk frames did not change region (%s unique)" % seen.size())
			ok = false
		else:
			print("SMOKE: %s unique walk regions" % seen.size())

	npc.queue_free()
	if ok:
		print("SMOKE PASS")
		quit(0)
	else:
		print("SMOKE FAIL")
		quit(1)
