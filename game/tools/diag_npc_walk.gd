extends SceneTree


## Headless outdoor NPC walk diagnostic. Writes builds/npc_walk_debug.log

const DebugLog := preload("res://world/NpcWalkDebug.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	DebugLog.ensure_open()
	DebugLog.trace("diag", "boot period=%s day=%s" % [GameState.period, GameState.day])

	var host: Node2D = load("res://world/WorldHost.tscn").instantiate()
	root.add_child(host)
	## Clear UI blocks that freeze NPC motion.
	GameFlow.dialogue_open = false
	GameFlow.event_open = false
	GameFlow.ending_open = false

	## Wait for HarborOutdoor spawn + NpcScheduler bootstrap.
	for i in 90:
		await physics_frame
		var npcs := get_nodes_in_group("outdoor_npc")
		if npcs.size() >= 3:
			DebugLog.trace("diag", "npcs_ready count=%d after %d frames" % [npcs.size(), i + 1])
			break

	var npcs := get_nodes_in_group("outdoor_npc")
	DebugLog.trace("diag", "npc_count=%d" % npcs.size())
	for n in npcs:
		DebugLog.sample_npc(n, "after_boot")

	## Force every NPC onto a distant outdoor route (no snap, no indoors).
	for n in npcs:
		if not is_instance_valid(n):
			continue
		var from: Vector2 = n.global_position
		var dest := from + Vector2(420, 180)
		if n.has_method("set_schedule_target"):
			n.call("set_schedule_target", dest, false, false, "")
		DebugLog.trace(str(n.get("npc_id")), "FORCE_ROUTE from=%s to=%s" % [from, dest])

	## Simulate ~3 seconds of outdoor motion.
	for i in 180:
		await physics_frame
		if i % 30 == 0:
			for n in get_nodes_in_group("outdoor_npc"):
				DebugLog.sample_npc(n, "pulse_%d" % i)

	for n in get_nodes_in_group("outdoor_npc"):
		DebugLog.sample_npc(n, "final")

	DebugLog.dump_summary()
	print("DIAG DONE -> builds/npc_walk_debug.log")
	quit(0)
