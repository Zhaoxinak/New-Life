extends Node


## Build short gain/loss lines from applied effect rows for result cards.


func summarize(applied: Array, suspicion_delta: float = 0.0, action_id: String = "") -> Dictionary:
	var gains: PackedStringArray = PackedStringArray()
	var losses: PackedStringArray = PackedStringArray()
	var favor_delta: = 0.0
	var tension_delta: = 0.0
	var intel_delta: = 0.0
	var money_delta: = 0.0
	var trust_delta: = 0.0
	var network_delta: = 0.0
	var suspicion_from_fx: = 0.0

	for row in applied:
		var et: = str(row.get("effect_type", ""))
		var key: = str(row.get("key", ""))
		var op: = str(row.get("op", "add"))
		var value: = float(row.get("value", 0))
		if op != "add":
			continue
		if et == "relation" and key.ends_with(":favor"):
			favor_delta += value
		elif et == "stat" and key == "father_son_tension":
			tension_delta += value
		elif et == "stat" and key == "intel":
			intel_delta += value
		elif et == "stat" and key == "money":
			money_delta += value
		elif et == "stat" and (key == "trust" or key == "tongyang_trust"):
			trust_delta += value
		elif et == "stat" and (key == "network_elite" or key == "network_base"):
			network_delta += value
		elif et == "stat" and key == "suspicion":
			suspicion_from_fx += value

	var sus: = suspicion_delta + suspicion_from_fx
	_push_delta(gains, losses, favor_delta, "ui.beat.favor", "人情")
	_push_delta(gains, losses, trust_delta, "ui.beat.trust", "信任")
	_push_delta(gains, losses, intel_delta, "ui.beat.intel", "情报")
	_push_delta(gains, losses, money_delta, "ui.beat.money", "金钱")
	_push_delta(gains, losses, network_delta, "ui.beat.network", "声望")
	if tension_delta >= 1.5:
		losses.append(L10n.t("ui.beat.tension_up", "楼内张力↑"))
	elif tension_delta <= -1.5:
		gains.append(L10n.t("ui.beat.tension_down", "楼内张力↓"))
	if sus >= 0.5:
		losses.append(L10n.t("ui.beat.suspicion_up", "嫌疑↑"))
	elif sus <= -0.5:
		gains.append(L10n.t("ui.beat.suspicion_down", "嫌疑↓"))

	var situation: = ""
	var aid: = action_id.strip_edges()
	if aid != "":
		situation = L10n.t_if("ui.situation.action.%s" % aid)
	if situation == "":
		if sus > 0.05:
			situation = L10n.t("ui.situation.suspicion_up", "有人多盯了你一眼")
		elif sus < -0.05:
			situation = L10n.t("ui.situation.suspicion_down", "风声暂时松了")
		elif favor_delta <= -2.0:
			situation = L10n.t("ui.situation.favor_down", "身边的人更冷了")
		elif favor_delta >= 2.0:
			situation = L10n.t("ui.situation.favor_up", "有人把你往里拉了半步")
		elif tension_delta >= 2.0:
			situation = L10n.t("ui.situation.tension_up", "楼里的裂缝又深了一寸")
		elif trust_delta >= 3.0:
			situation = L10n.t("ui.situation.trust_up", "楼里又有人把你往名册里记了一笔")
		elif trust_delta <= -8.0:
			situation = L10n.t("ui.situation.trust_down", "公司这边的信任裂开了一截")
		elif intel_delta >= 3.0:
			situation = L10n.t("ui.situation.intel_up", "你多攥住了一句能用的话")
		elif network_delta >= 2.0:
			situation = L10n.t("ui.situation.network_up", "上层圈子多听见了你的名字")
		elif money_delta >= 8.0:
			situation = L10n.t("ui.situation.money_up", "口袋沉了，也更容易被人盯")
		elif not applied.is_empty() or not is_zero_approx(suspicion_delta):
			situation = L10n.t("ui.situation.generic", "这一步留下了痕迹")

	return {
		"gains": gains, 
		"losses": losses, 
		"situation": situation, 
		"has_weight": gains.size() > 0 or losses.size() > 0 or situation != "", 
	}


func _push_delta(gains: PackedStringArray, losses: PackedStringArray, delta: float, key: String, fallback: String) -> void :
	if absf(delta) < 0.5:
		return
	var label: = L10n.t(key, fallback)
	var line: = "%s %s" % [label, _arrow(delta)]
	if delta > 0.0:
		gains.append(line)
	else:
		losses.append(line)


func _arrow(delta: float) -> String:
	if delta >= 8.0:
		return "↑↑"
	if delta <= -8.0:
		return "↓↓"
	return "↑" if delta > 0.0 else "↓"
