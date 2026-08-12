extends Node
## 失败阈值扫描：行动后入队 F 事件（一次性 seen 门控）。

const FAILURE_ORDER: PackedStringArray = ["F005", "F003", "F004", "F002", "F001"]


func scan_and_enqueue() -> String:
	## 返回入队的 event_id；无则空串。优先更严重失败。
	if not RunState.is_running():
		return ""
	if DialogueRunner.is_active():
		return ""
	for eid in FAILURE_ORDER:
		if RunState.get_flag("seen_event_%s" % eid, false):
			continue
		if RunState.queue.has(eid):
			continue
		var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		if ev.is_empty():
			continue
		if not ConditionEval.eval_all(ev.get("require", [])):
			continue
		RunState.enqueue_event(eid)
		DomainBus.emit_domain("failure_queued", {"event_id": eid})
		DomainBus.tip.emit(L10n.t("ui.failure_pending", "风声不对……"))
		return eid
	return ""
