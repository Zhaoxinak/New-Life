extends Node
## 场上小人闲聊：按人物 / 剧情旗 / 关系档挑口风；无话可说则敷衍收场。

const PLAYER_ID := "char_lin_ruisheng"


func try_start(char_id: String) -> bool:
	if char_id.is_empty():
		return false
	if RunState.ended:
		DomainBus.tip.emit(L10n.t("ui.run_ended", "本局结束：%s") % RunState.end_reason)
		return false
	if DialogueRunner.is_active():
		DomainBus.tip.emit(L10n.t("ui.dialog_busy", "对话进行中"))
		return false
	if not RunState.queue.is_empty():
		DomainBus.tip.emit(L10n.t("ui.event_pending", "有事件待处理"))
		return false

	var dialog_id := pick_dialog(char_id)
	if dialog_id.is_empty():
		DomainBus.tip.emit(L10n.t("ui.chatter_none", "对方正忙，只略一点头。"))
		return false

	_mark_used(char_id, dialog_id)
	return DialogueRunner.start_loose(dialog_id)


func pick_dialog(char_id: String) -> String:
	var slot_key := _slot_key()
	var used: Dictionary = _used_map()
	var used_ids: Array = used.get(slot_key, [])
	if typeof(used_ids) != TYPE_ARRAY:
		used_ids = []

	var best: Array = [] ## Dictionary rows
	var best_pri := -999999
	for row in PackDB.get_rows("def_chatter"):
		if String(row.get("char_id", "")) != char_id:
			continue
		if not ConditionEval.eval_all(row.get("require", [])):
			continue
		var cid := String(row.get("chatter_id", ""))
		if bool(row.get("once", false)) and RunState.get_flag("seen_chatter_%s" % cid, false):
			continue
		if bool(row.get("once_per_slot", true)) and used_ids.has(cid):
			continue
		var pri := int(row.get("priority", 0))
		if pri > best_pri:
			best_pri = pri
			best = [row]
		elif pri == best_pri:
			best.append(row)

	if not best.is_empty():
		var pick: Dictionary = best[randi() % best.size()]
		var did := String(pick.get("dialog_id", ""))
		if bool(pick.get("once", false)):
			RunState.set_flag("seen_chatter_%s" % String(pick.get("chatter_id", "")), true)
		return did

	## 本时段已聊过 / 无匹配：走敷衍兜底（不记 once，但本时段同人只敷衍一次）
	var fb_id := "chatter_fallback_%s" % char_id
	if used_ids.has(fb_id):
		return "dialog_chat_generic_repeat"
	## 按交情档挑一句通用敷衍，speaker 用目标角色的专用兜底更自然
	var char_fb := "dialog_chat_%s_fallback" % _short(char_id)
	if not PackDB.get_row_by_id("def_dialog", "dialog_id", char_fb).is_empty():
		return char_fb
	return "dialog_chat_generic_nod"


func _mark_used(char_id: String, dialog_id: String) -> void:
	var slot_key := _slot_key()
	var used: Dictionary = _used_map()
	var used_ids: Array = used.get(slot_key, [])
	if typeof(used_ids) != TYPE_ARRAY:
		used_ids = []
	## 记下 dialog 与 fallback 标记
	for row in PackDB.get_rows("def_chatter"):
		if String(row.get("dialog_id", "")) == dialog_id and String(row.get("char_id", "")) == char_id:
			var cid := String(row.get("chatter_id", ""))
			if not cid.is_empty() and not used_ids.has(cid):
				used_ids.append(cid)
			break
	if dialog_id.ends_with("_fallback") or dialog_id == "dialog_chat_generic_nod" \
			or dialog_id == "dialog_chat_generic_repeat":
		var fb_id := "chatter_fallback_%s" % char_id
		if not used_ids.has(fb_id):
			used_ids.append(fb_id)
	used[slot_key] = used_ids
	RunState.meta["chatter_used"] = used


func _used_map() -> Dictionary:
	var raw: Variant = RunState.meta.get("chatter_used", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw


func _slot_key() -> String:
	return "%d:%s" % [RunState.day(), RunState.slot()]


func _short(char_id: String) -> String:
	## char_qian_demao -> qian_demao
	if char_id.begins_with("char_"):
		return char_id.substr(5)
	return char_id
