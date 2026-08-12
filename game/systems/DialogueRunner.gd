extends Node
## 对话节点图执行器。选项只写 effect；文案走 loc_key。

signal dialog_started(dialog_id: String, event_id: String)
signal node_presented(node: Dictionary)
signal dialog_finished(event_id: String)
signal choice_presented(choices: Array)

var active: bool = false
var current_event_id: String = ""
var current_dialog_id: String = ""
var current_node: Dictionary = {}
## 事件入场时已结算的基线 effects（可选）；收尾再推进时段
var _event_entry_effects_applied: bool = false


func is_active() -> bool:
	return active


func force_abort() -> void:
	## 读档 / 回主界面：立刻掐断对白，不结算事件尾效、不推进时段、不广播 finished。
	active = false
	current_event_id = ""
	current_dialog_id = ""
	current_node = {}
	_event_entry_effects_applied = false


func start_event(event_id: String) -> bool:
	if active:
		push_warning("DialogueRunner: already active")
		return false
	var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", event_id)
	if ev.is_empty():
		push_error("DialogueRunner: unknown event %s" % event_id)
		return false
	var entry := String(ev.get("dialog_entry", ""))
	if entry.is_empty():
		EffectApplier.apply_all(ev.get("effects", []), "event:%s" % event_id)
		RunState.set_flag("seen_event_%s" % event_id, true)
		TickPipeline.finish_event_playback(event_id)
		return false

	active = true
	current_event_id = event_id
	_event_entry_effects_applied = false
	if String(ev.get("effects_when", "dialog")) == "entry":
		EffectApplier.apply_all(ev.get("effects", []), "event_entry:%s" % event_id)
		_event_entry_effects_applied = true
	dialog_started.emit(entry, event_id)
	return goto_dialog(entry)


func start_loose(dialog_id: String) -> bool:
	## 行动口风等：无 event_id，结束时不推进时段（由调用方负责）。
	if active:
		return false
	active = true
	current_event_id = ""
	_event_entry_effects_applied = true
	dialog_started.emit(dialog_id, "")
	return goto_dialog(dialog_id)


func goto_dialog(dialog_id: String) -> bool:
	if dialog_id.is_empty() or dialog_id == "null":
		_finish()
		return true
	var node: Dictionary = PackDB.get_row_by_id("def_dialog", "dialog_id", dialog_id)
	if node.is_empty():
		push_error("DialogueRunner: missing dialog %s" % dialog_id)
		_finish()
		return false
	var requires: Array = node.get("require", [])
	if not ConditionEval.eval_all(requires):
		# 节点自身 require 失败：尝试 next_by_condition / next
		return _advance_from_node(node)

	current_dialog_id = dialog_id
	current_node = node
	RunState.mark_dialog_seen(dialog_id)
	EffectApplier.apply_all(node.get("effects", []), "dialog:%s" % dialog_id)
	if not EffectApplier.pending_goto_dialog.is_empty():
		var jump := EffectApplier.pending_goto_dialog
		EffectApplier.pending_goto_dialog = ""
		return goto_dialog(jump)

	node_presented.emit(node)
	var choices: Array = _visible_choices(node)
	if not choices.is_empty():
		choice_presented.emit(choices)
	return true


func continue_linear() -> void:
	if not active:
		return
	var choices: Array = _visible_choices(current_node)
	if not choices.is_empty():
		return
	_advance_from_node(current_node)


func select_choice(choice: Dictionary) -> void:
	if not active:
		return
	# 检定型
	if choice.has("check") and typeof(choice.get("check")) == TYPE_DICTIONARY:
		var check: Dictionary = choice["check"] as Dictionary
		var req_variant: Variant = check.get("require", {})
		var pass_ok := true
		if typeof(req_variant) == TYPE_ARRAY:
			pass_ok = ConditionEval.eval_all(req_variant)
		elif typeof(req_variant) == TYPE_DICTIONARY:
			pass_ok = ConditionEval.eval_one(req_variant as Dictionary)
		var branch_v: Variant = check.get("on_pass" if pass_ok else "on_fail", {})
		var branch: Dictionary = branch_v if typeof(branch_v) == TYPE_DICTIONARY else {}
		EffectApplier.apply_all(branch.get("effects", []), "dialog_check:%s" % current_dialog_id)
		_goto_or_finish(branch.get("next", null))
		return

	EffectApplier.apply_all(choice.get("effects", []), "dialog_choice:%s" % current_dialog_id)
	if not EffectApplier.pending_goto_dialog.is_empty():
		var jump := EffectApplier.pending_goto_dialog
		EffectApplier.pending_goto_dialog = ""
		goto_dialog(jump)
		return
	_goto_or_finish(choice.get("next", null))


func _goto_or_finish(next_v: Variant) -> void:
	var next_id := _dialog_id_of(next_v)
	if next_id.is_empty() or next_id == "null":
		_finish()
	else:
		goto_dialog(next_id)


func _dialog_id_of(v: Variant) -> String:
	## 禁止对未知 Variant 调 String(...)：Dictionary/Array/Object 会直接 SCRIPT ERROR，
	## 若调用方在 while is_active 里没设上限，会把 file log 写到几十 GB。
	match typeof(v):
		TYPE_NIL:
			return ""
		TYPE_STRING:
			return v
		TYPE_STRING_NAME:
			return str(v)
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return str(v)
		_:
			push_warning("DialogueRunner: ignore non-id next type=%s" % typeof(v))
			return ""


func _visible_choices(node: Dictionary) -> Array:
	var raw: Array = node.get("choices", node.get("options", []))
	var out: Array = []
	for ch in raw:
		if typeof(ch) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = ch
		if ConditionEval.eval_all(c.get("require", [])):
			out.append(c)
	return out


func _advance_from_node(node: Dictionary) -> bool:
	# next_by_condition: 首个匹配
	var nbc: Array = node.get("next_by_condition", [])
	for item in nbc:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var it: Dictionary = item
		if it.has("default"):
			return goto_dialog(_dialog_id_of(it["default"]))
		if ConditionEval.eval_all(it.get("require", [])):
			return goto_dialog(_dialog_id_of(it.get("id", it.get("next", null))))
	var next_id := _dialog_id_of(node.get("next", null))
	if next_id.is_empty() or next_id == "null":
		_finish()
		return true
	return goto_dialog(next_id)


func _finish() -> void:
	var eid := current_event_id
	if not eid.is_empty() and not _event_entry_effects_applied:
		var ev: Dictionary = PackDB.get_row_by_id("def_event", "event_id", eid)
		# 若对白叶未写 effects，回落事件 effects（兼容）
		if not ev.is_empty() and String(ev.get("effects_when", "dialog")) != "entry":
			# 仅当叶节点未带 effects 时补一次？文档里 E001 效果在 close 节点。
			# 这里只打 seen；数值以对白为准。
			pass
	if not eid.is_empty():
		RunState.set_flag("seen_event_%s" % eid, true)
		RouteMutex.mark_mutex_done_for_event(eid)
	active = false
	var finished_event := eid
	current_event_id = ""
	current_dialog_id = ""
	current_node = {}
	dialog_finished.emit(finished_event)
	if not finished_event.is_empty():
		TickPipeline.finish_event_playback(finished_event)
