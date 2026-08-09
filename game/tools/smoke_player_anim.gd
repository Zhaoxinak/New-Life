extends SceneTree




func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	await process_frame
	var player: CharacterBody2D = load("res://world/Player.tscn").instantiate()
	root.add_child(player)
	await process_frame
	await process_frame

	var ok: = true
	var sprite: AnimatedSprite2D = player.get_node("%Sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("SMOKE FAIL: missing SpriteFrames")
		ok = false
	else:
		var dirs: = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
		for d in dirs:
			for prefix in ["idle_", "walk_"]:
				var anim_name: String = prefix + d
				if not sprite.sprite_frames.has_animation(anim_name):
					push_error("SMOKE FAIL: missing anim %s" % anim_name)
					ok = false
			var walk: String = "walk_%s" % d
			if sprite.sprite_frames.get_frame_count(walk) != 6:
				push_error("SMOKE FAIL: %s frame count=%s" % [walk, sprite.sprite_frames.get_frame_count(walk)])
				ok = false
		print("SMOKE: anim=%s walk_frames=%s" % [
			sprite.animation, sprite.sprite_frames.get_frame_count("walk_s")
		])

	player.queue_free()
	if ok:
		print("SMOKE PASS")
		quit(0)
	else:
		print("SMOKE FAIL")
		quit(1)
