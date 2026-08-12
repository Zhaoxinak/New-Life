extends Node
## 随机事件扫描：仅在玩家行动后、失败扫描未入队时尝试入队（每日最多 1 次）。

## 演示优先序：看客债 / 聚丰 / 钱庄 / 子安发难 / 茶楼 …
const RANDOM_ORDER: PackedStringArray = [
	"R010", "R005", "R006", "R003", "R001", "R009", "R004", "R008", "R007", "R002",
]


func scan_and_enqueue() -> String:
	if not RunState.is_running():
		return ""
	if DialogueRunner.is_active():
		return ""
	if not RunState.queue.is_empty():
		return ""
	if RunState.get_flag("flag_random_fired_today", false):
		return ""

	for eid in RANDOM_ORDER:
		if not _eligible(eid):
			continue
		var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		if ev.is_empty():
			continue
		if String(ev.get("event_type", "")) != "random":
			continue
		if not ConditionEval.eval_all(ev.get("require", [])):
			continue
		if not _route_allows(ev):
			continue
		RunState.enqueue_event(eid)
		RunState.set_flag("flag_random_fired_today", true)
		if eid == "R002":
			RunState.meta["last_r002_day"] = RunState.day()
		DomainBus.emit_domain("random_queued", {"event_id": eid})
		DomainBus.tip.emit(L10n.t("ui.random_pending", "街市上有点动静……"))
		return eid
	return ""


func _eligible(eid: String) -> bool:
	if RunState.queue.has(eid):
		return false
	# R007 可日更；其余默认 once（R002 用冷却）
	if eid == "R007":
		return not RunState.get_flag("flag_surveilled_today", false)
	if eid == "R002":
		var last := int(RunState.meta.get("last_r002_day", -999))
		return RunState.day() - last >= 5
	if RunState.get_flag("seen_event_%s" % eid, false):
		return false
	return true


func _route_allows(ev: Dictionary) -> bool:
	var tags: Array = ev.get("route_tags", [])
	if tags.is_empty():
		return true
	var any_route: bool = bool(RunState.get_flag("route_endure", false)) \
		or bool(RunState.get_flag("route_defect", false)) \
		or bool(RunState.get_flag("route_foreign", false))
	if not any_route:
		return true
	for t in tags:
		if RunState.get_flag(String(t), false):
			return true
	return false


func clear_day_flags() -> void:
	RunState.clear_flag("flag_random_fired_today")
	RunState.clear_flag("flag_surveilled_today")
	RunState.clear_flag("flag_liu_gift_today")
	RunState.clear_flag("flag_companied_liu_today")
