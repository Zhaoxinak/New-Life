extends RefCounted
## Smoke 共用：有上限地推进对白，避免死循环把 file log 写爆。


static func drain(max_steps: int = 80) -> bool:
	var guard := 0
	var last_id := ""
	var same_count := 0
	while DialogueRunner.is_active() and guard < max_steps:
		guard += 1
		var did := DialogueRunner.current_dialog_id
		if did == last_id:
			same_count += 1
			if same_count >= 8:
				push_error("SMOKE FAIL: dialog not advancing id=%s" % did)
				DialogueRunner.force_abort()
				return false
		else:
			last_id = did
			same_count = 0
		_step_once()
	if DialogueRunner.is_active():
		push_error("SMOKE FAIL: dialog drain stuck after %d steps id=%s" % [
			max_steps, DialogueRunner.current_dialog_id
		])
		DialogueRunner.force_abort()
		return false
	return true


static func _step_once() -> void:
	var node: Dictionary = DialogueRunner.current_node
	var choices: Array = node.get("choices", node.get("options", []))
	var visible: Array = []
	for ch in choices:
		if typeof(ch) == TYPE_DICTIONARY and ConditionEval.eval_all((ch as Dictionary).get("require", [])):
			visible.append(ch)
	if visible.is_empty():
		DialogueRunner.continue_linear()
	else:
		DialogueRunner.select_choice(visible[0] as Dictionary)
