extends Control
## 主界面：新局 / 读档 / 退出。

signal new_game_requested
signal load_requested(slot_id: int)
signal quit_requested

@onready var brand: Label = %Brand
@onready var blurb: Label = %Blurb
@onready var menu: VBoxContainer = %Menu
@onready var slot_box: VBoxContainer = %SlotBox
@onready var btn_back: Button = %BtnBack
@onready var panel: PanelContainer = %Panel


func _ready() -> void:
	KairoStyle.style_panel(panel)
	brand.add_theme_color_override("font_color", KairoStyle.ACCENT)
	blurb.add_theme_color_override("font_color", KairoStyle.SOFT_INK)
	KairoStyle.style_button(btn_back)
	btn_back.pressed.connect(_show_menu)
	brand.text = L10n.t("ui.title_brand", "暗潮")
	blurb.text = L10n.t("ui.title_blurb", "清光绪十六年 · 天津钱记")
	refresh()


func refresh() -> void:
	_show_menu()


func _show_menu() -> void:
	slot_box.visible = false
	menu.visible = true
	btn_back.visible = false
	_clear(menu)
	_add(menu, L10n.t("ui.new_game", "新的一局"), func(): new_game_requested.emit())
	_add(menu, L10n.t("ui.load", "读档"), _show_load, SaveSystem.any_slot())
	_add(menu, L10n.t("ui.quit_game", "退出游戏"), func(): quit_requested.emit())


func _show_load() -> void:
	menu.visible = false
	slot_box.visible = true
	btn_back.visible = true
	btn_back.text = L10n.t("ui.back", "返回")
	_clear(slot_box)
	for info in SaveSystem.list_slots():
		var sid := int(info.get("slot_id", 0))
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = _slot_label(info)
		btn.disabled = not bool(info.get("exists", false))
		KairoStyle.style_button(btn, true)
		btn.pressed.connect(func(): load_requested.emit(sid))
		slot_box.add_child(btn)


func _slot_label(info: Dictionary) -> String:
	var n := int(info.get("slot_id", 0)) + 1
	if not bool(info.get("exists", false)):
		return L10n.t("ui.slot_empty", "槽位 %d · （空）") % n
	var day := int(info.get("day", 1))
	var slot := _slot_name(String(info.get("slot", "")))
	var rank := PromotionSystem.title_for(String(info.get("rank", "apprentice")))
	var money = info.get("money", 0)
	var at := String(info.get("saved_at", ""))
	var ended := " · " + L10n.t("ui.ended_tag", "已终局") if bool(info.get("ended", false)) else ""
	return L10n.t(
		"ui.slot_filled",
		"槽位 %d · 第%d日·%s · %s · %s两 · %s%s"
	) % [n, day, slot, rank, str(money), at, ended]


func _slot_name(slot: String) -> String:
	match slot:
		"morning":
			return L10n.t("slot.morning", "清晨")
		"noon":
			return L10n.t("slot.noon", "正午")
		"afternoon":
			return L10n.t("slot.afternoon", "午后")
		"evening":
			return L10n.t("slot.evening", "傍晚")
		"late_night":
			return L10n.t("slot.late_night", "深夜")
		_:
			return slot


func _add(box: VBoxContainer, text: String, cb: Callable, enabled: bool = true) -> void:
	var btn := Button.new()
	btn.text = text
	btn.disabled = not enabled
	KairoStyle.style_button(btn, true)
	btn.pressed.connect(cb)
	box.add_child(btn)


func _clear(box: VBoxContainer) -> void:
	while box.get_child_count() > 0:
		var c: Node = box.get_child(0)
		box.remove_child(c)
		c.queue_free()
