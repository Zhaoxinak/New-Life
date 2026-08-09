extends Node


const STREET_DLG_TO_NPC: = {
	"dlg_street_foreman": "dock_foreman", 
	"dlg_street_aunt": "stall_aunt", 
	"dlg_street_waiter": "tea_waiter", 
	"dlg_street_garage": "garage_hand", 
	"dlg_street_su": "su_qing", 
	"dlg_street_son": "zhou_shaoting", 
	"dlg_street_boss": "zhou_hongye", 
	"dlg_street_chen": "chen_manager", 
}

const FLAG_LOG_KEYS: = {
	"heard_foreman_rumor": "dock_foreman", 
	"heard_waiter_gossip": "tea_waiter", 
	"met_street_aunt": "stall_aunt", 
	"met_garage_hand": "garage_hand", 
}

const FAVOR_LOG_THRESHOLD: = 2.0


func _ready() -> void :
	if not GameState.relation_changed.is_connected(_on_relation_changed):
		GameState.relation_changed.connect(_on_relation_changed)
	if not GameState.flag_changed.is_connected(_on_flag_changed):
		GameState.flag_changed.connect(_on_flag_changed)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_dialogue")


func bind_dialogue_panel(panel: Node) -> void :
	if panel == null or not panel.has_signal("finished"):
		return
	if not panel.finished.is_connected(_on_dialogue_finished):
		panel.finished.connect(_on_dialogue_finished)


func _on_node_added(node: Node) -> void :
	if node.is_in_group("dialogue_panel"):
		bind_dialogue_panel(node)


func _bind_dialogue() -> void :
	var panel: = get_tree().get_first_node_in_group("dialogue_panel")
	bind_dialogue_panel(panel)


func _on_dialogue_finished(dialogue_id: String, _choice_id: String) -> void :
	var npc_id: = str(STREET_DLG_TO_NPC.get(dialogue_id, ""))
	if npc_id == "":
		return
	_log(npc_id, "street", "journal.street.%s" % npc_id, {})


func _on_flag_changed(flag_id: String, old_value: int, new_value: int) -> void :
	if old_value != 0 or new_value <= 0:
		return
	if not FLAG_LOG_KEYS.has(flag_id):
		return
	var npc_id: = str(FLAG_LOG_KEYS[flag_id])
	_log(npc_id, "flag", "journal.flag.%s" % flag_id, {})


func _on_relation_changed(source_id: String, target_id: String, relation_key: String, old_value: float, new_value: float) -> void :
	if relation_key != "favor" or target_id != "player":
		return
	var delta: = new_value - old_value
	if absf(delta) < FAVOR_LOG_THRESHOLD:
		return
	var key: = "journal.favor.up" if delta > 0.0 else "journal.favor.down"
	var shown: = absf(delta)
	_log(source_id, "favor", key, {"n": int(round(shown)) if delta > 0.0 else int(round(delta))})


func _log(npc_id: String, kind: String, text_key: String, params: Dictionary) -> void :
	if npc_id == "" or text_key == "":
		return

	if kind in ["street", "flag"]:
		for e in GameState.relation_log:
			if str(e.get("npc_id", "")) == npc_id\
			and str(e.get("kind", "")) == kind\
			and str(e.get("text_key", "")) == text_key\
			and int(e.get("day", -1)) == GameState.day\
			and str(e.get("period", "")) == GameState.period:
				return
	GameState.append_relation_log({
		"day": GameState.day, 
		"period": GameState.period, 
		"npc_id": npc_id, 
		"other_id": str(params.get("other_id", "")), 
		"kind": kind, 
		"text_key": text_key, 
		"params": params, 
	})
