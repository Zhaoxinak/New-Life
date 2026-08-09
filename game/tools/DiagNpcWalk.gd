extends Node


func _ready() -> void:
	## Hard timeout so headless never hangs forever.
	get_tree().create_timer(12.0).timeout.connect(func():
		NpcWalkDebug.trace("diag", "TIMEOUT")
		NpcWalkDebug.dump_summary()
		get_tree().quit(2)
	)
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	NpcWalkDebug.ensure_open()
	NpcWalkDebug.trace("diag", "boot period=%s day=%s" % [GameState.period, GameState.day])

	var host: Node2D = load("res://world/WorldHost.tscn").instantiate()
	add_child(host)
	GameFlow.dialogue_open = false
	GameFlow.event_open = false
	GameFlow.ending_open = false

	for i in 120:
		await get_tree().physics_frame
		var npcs := get_tree().get_nodes_in_group("outdoor_npc")
		if npcs.size() >= 3:
			NpcWalkDebug.trace("diag", "npcs_ready count=%d after %d frames" % [npcs.size(), i + 1])
			break
		if i == 119:
			NpcWalkDebug.trace("diag", "npcs_ready TIMEOUT count=%d" % npcs.size())

	var npcs := get_tree().get_nodes_in_group("outdoor_npc")
	NpcWalkDebug.trace("diag", "npc_count=%d" % npcs.size())
	for n in npcs:
		NpcWalkDebug.sample_npc(n, "after_boot")

	for n in npcs:
		if not is_instance_valid(n):
			continue
		var from: Vector2 = (n as Node2D).global_position
		var dest := from + Vector2(420, 180)
		if n.has_method("set_schedule_target"):
			n.call("set_schedule_target", dest, false, false, "")
		NpcWalkDebug.trace(str(n.get("npc_id")), "FORCE_ROUTE from=%s to=%s" % [from, dest])

	for i in 180:
		await get_tree().physics_frame
		if i % 30 == 0:
			for n in get_tree().get_nodes_in_group("outdoor_npc"):
				NpcWalkDebug.sample_npc(n, "pulse_%d" % i)

	for n in get_tree().get_nodes_in_group("outdoor_npc"):
		NpcWalkDebug.sample_npc(n, "final")

	NpcWalkDebug.dump_summary()
	print("DIAG DONE path=", NpcWalkDebug._path)
	get_tree().quit(0)
