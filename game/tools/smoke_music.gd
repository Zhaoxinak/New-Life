extends SceneTree




func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	await process_frame
	await process_frame
	var sfx: Node = Engine.get_main_loop().root.get_node_or_null("SfxPlayer")
	if sfx == null:
		push_error("SMOKE MUSIC FAIL: SfxPlayer autoload missing")
		quit(1)
		return
	var ok: = true
	var locs: = ["outdoor", "dock", "company", "home", "rival", "exchange"]
	var moods: = ["calm", "unease", "crack", "climax", "route_a", "route_b", "route_c"]
	print("SMOKE MUSIC: begin")
	for loc in locs:
		for mood in moods:
			var seen: Dictionary = {}
			for _i in 8:
				var t: String = sfx.call("pick_track", loc, mood, true)
				seen[t] = true
				var path: = "res://audio/music/%s.ogg" % t
				if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
					push_error("MISSING file %s (loc=%s mood=%s)" % [t, loc, mood])
					ok = false
			if seen.size() < 2:
				push_warning("LOW VARIETY loc=%s mood=%s unique=%d -> %s" % [loc, mood, seen.size(), str(seen.keys())])
			else:
				print("OK %s/%s unique=%d -> %s" % [loc, mood, seen.size(), str(seen.keys())])
	sfx.call("play_ambience", "outdoor")
	await create_timer(0.5).timeout
	sfx.call("play_ambience", "dock")
	await create_timer(0.5).timeout
	sfx.call("play_ambience", "company")
	await create_timer(0.5).timeout
	sfx.call("play_ambience", "home")
	await create_timer(0.4).timeout
	sfx.call("play_ambience", "rival")
	await create_timer(0.4).timeout
	sfx.call("play_ambience", "exchange")
	await create_timer(0.4).timeout
	if ok:
		print("SMOKE MUSIC: PASS track=%s loc=%s" % [sfx.get("_track_id"), sfx.get("_bed_location")])
		quit(0)
	else:
		print("SMOKE MUSIC: FAIL")
		quit(1)
