extends Area2D


signal hotspot_activated(hotspot_id: String)

@export var hotspot_id: String = ""
var gated: bool = false
var gate_reason: String = ""
var tooltip_text: String = ""

@onready var label: Label = %Label
@onready var marker: Sprite2D = %Marker


func _ready() -> void :
	add_to_group("hotspot_zone")


func setup(id: String, title: String, is_gated: bool, reason: String = "") -> void :
	hotspot_id = id
	gated = is_gated
	gate_reason = reason
	if label:
		label.text = title if not is_gated else "%s（锁）" % title
	modulate = Color(1, 1, 1, 0.55) if is_gated else Color.WHITE
	tooltip_text = reason


func try_activate() -> bool:
	if gated or hotspot_id.is_empty():
		return false
	hotspot_activated.emit(hotspot_id)
	return true
