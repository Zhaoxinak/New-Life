extends PanelContainer
## 热区点开后的行动纸片。

signal action_picked(act_id: String)
signal closed

@onready var title_label: Label = %Title
@onready var list: VBoxContainer = %List
@onready var close_btn: Button = %CloseBtn

var _loc_id: String = ""
var _hotspot_id: String = ""


func _ready() -> void:
	KairoStyle.style_panel(self)
	title_label.add_theme_color_override("font_color", KairoStyle.INK)
	KairoStyle.style_button(close_btn)
	close_btn.pressed.connect(func(): closed.emit(); visible = false)
	## 顶置，别盖住地坪上的小人
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_for(loc_id: String, hotspot_id: String) -> void:
	_loc_id = loc_id
	_hotspot_id = hotspot_id
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	move_to_front()
	_rebuild()


func refresh_if_open() -> void:
	if visible and not _loc_id.is_empty():
		_rebuild()


func _rebuild() -> void:
	var loc_name := L10n.t(
		String(PackDB.get_row_by_id("def_location", "loc_id", _loc_id).get("loc_key", "")),
		_loc_id
	)
	var hz_name := L10n.t(_hz_key(_hotspot_id), _hotspot_id)
	var icon := String(KairoStyle.HZ_ICON.get(_hotspot_id, "【★】"))
	title_label.text = "%s %s · %s" % [icon, loc_name, hz_name]
	_clear_list()
	var any := false
	for row in TickPipeline.available_actions():
		if String(row.get("loc_id", "")) != _loc_id:
			continue
		any = true
		var aid := String(row.get("act_id", ""))
		var btn := Button.new()
		btn.text = L10n.t(String(row.get("loc_key", "")), aid)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		KairoStyle.style_button(btn, true)
		btn.pressed.connect(_on_pick.bind(aid))
		list.add_child(btn)
	if not any:
		var empty := Label.new()
		empty.add_theme_color_override("font_color", KairoStyle.SOFT_INK)
		empty.add_theme_font_size_override("font_size", 16)
		empty.text = L10n.t("ui.no_actions", "此刻此处无可做之事")
		list.add_child(empty)
	close_btn.text = L10n.t("ui.close", "收起")


func _on_pick(aid: String) -> void:
	action_picked.emit(aid)


func _clear_list() -> void:
	## 先移出树再 queue_free，避免点选项时在信号栈里 free。
	while list.get_child_count() > 0:
		var c: Node = list.get_child(0)
		list.remove_child(c)
		c.queue_free()


func _hz_key(hotspot_id: String) -> String:
	match hotspot_id:
		"hz_front_hall":
			return "hz.front_hall"
		"hz_front_door":
			return "hz.front_door"
		"hz_yard":
			return "hz.yard"
		"hz_market":
			return "hz.market"
		"hz_bank":
			return "hz.bank"
		"hz_foreign":
			return "hz.foreign"
		"hz_cottage":
			return "hz.cottage"
		_:
			return "hz.%s" % hotspot_id
