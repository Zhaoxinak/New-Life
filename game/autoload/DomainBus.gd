extends Node
## 模拟层 → 表现层总线。UI 只订阅，不改 run_*。

signal stat_changed(stat_id: String, old_value: Variant, new_value: Variant)
signal flag_changed(flag_id: String, value: Variant)
signal meter_changed(meter_id: String, old_value: float, new_value: float)
signal edge_changed(from_id: String, to_id: String, key: String, value: Variant)
signal org_changed(org_id: String, key: String, old_value: Variant, new_value: Variant)
signal rank_changed(old_rank: String, new_rank: String)
signal grudge_changed(grudge_id: String, status: String)
signal slot_changed(day: int, slot: String)
signal day_ended(day: int)
signal tip(text: String)
signal domain_event(event_name: String, payload: Dictionary)


func emit_domain(event_name: String, payload: Dictionary = {}) -> void:
	domain_event.emit(event_name, payload)
