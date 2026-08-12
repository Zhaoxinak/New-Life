extends Node
## 同槽互斥 + 路线换皮：E020*/E021* 只播一条。

func pick_calendar_candidates(rows: Array) -> Array:
	## 输入：当日同时段所有 calendar 行；输出：应入队的 event_id 列表。
	var plain: Array = []
	var by_mutex: Dictionary = {}
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var r: Dictionary = row
		var eid := String(r.get("event_id", ""))
		if eid.is_empty():
			continue
		if RunState.get_flag("seen_event_%s" % eid, false):
			continue
		if RunState.queue.has(eid):
			continue
		if not ConditionEval.eval_all(r.get("require", [])):
			continue
		var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		if not ev.is_empty() and not ConditionEval.eval_all(ev.get("require", [])):
			continue
		if not _route_allows(ev if not ev.is_empty() else r):
			continue
		var mutex := String(r.get("mutex_group", ev.get("mutex_group", "")))
		if mutex.is_empty():
			plain.append(eid)
		else:
			if not by_mutex.has(mutex):
				by_mutex[mutex] = []
			by_mutex[mutex].append({"event_id": eid, "row": r, "ev": ev})

	var out: Array = []
	out.append_array(plain)
	for mutex_id in by_mutex.keys():
		if RunState.get_flag("mutex_done_%s" % mutex_id, false):
			continue
		var pick := _pick_mutex_variant(by_mutex[mutex_id])
		if pick.is_empty():
			continue
		out.append(pick)
		# 标记互斥组已用（播完再写 seen；此处先占位防同帧双入）
		RunState.set_flag("mutex_queued_%s" % mutex_id, true)
	return out


func mark_mutex_done_for_event(event_id: String) -> void:
	var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", event_id)
	var mutex := String(ev.get("mutex_group", ""))
	if mutex.is_empty():
		return
	# E010 选离开时只推迟，不封死同组的 E010b
	if mutex == "chapter2.night_cargo" and event_id == "E010" \
		and RunState.get_flag("flag_e010_delayed", false):
		return
	RunState.set_flag("mutex_done_%s" % mutex, true)


func _pick_mutex_variant(candidates: Array) -> String:
	# 路线优先：endure / defect / foreign
	var preferred := ""
	if RunState.get_flag("route_endure", false):
		preferred = "route_endure"
	elif RunState.get_flag("route_defect", false):
		preferred = "route_defect"
	elif RunState.get_flag("route_foreign", false):
		preferred = "route_foreign"

	var fallback := ""
	for item in candidates:
		var ev: Dictionary = item.get("ev", {})
		var tags: Array = ev.get("route_tags", item.get("row", {}).get("route_tags", []))
		var eid := String(item.get("event_id", ""))
		if tags.is_empty():
			if fallback.is_empty():
				fallback = eid
			continue
		if preferred.is_empty():
			return eid
		if tags.has(preferred):
			return eid
		if fallback.is_empty():
			fallback = eid
	return fallback


func _route_allows(ev: Dictionary) -> bool:
	var tags: Array = ev.get("route_tags", [])
	if tags.is_empty():
		return true
	# 有路线标签则必须命中其一；未选路线时允许（章一）
	var any_route: bool = bool(RunState.get_flag("route_endure", false)) \
		or bool(RunState.get_flag("route_defect", false)) \
		or bool(RunState.get_flag("route_foreign", false))
	if not any_route:
		return true
	for t in tags:
		if RunState.get_flag(String(t), false):
			return true
	return false
