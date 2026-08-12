extends CanvasLayer
## 设置：多槽存读档、说明、回主界面、退出。

signal closed
signal return_to_title_requested
signal quit_requested
signal save_done(slot_id: int)
signal load_done(slot_id: int)
signal help_requested
signal tutorial_requested

enum Mode { ROOT, SAVE, LOAD }

@onready var root_panel: PanelContainer = %RootPanel
@onready var title_label: Label = %Title
@onready var menu_box: VBoxContainer = %MenuBox
@onready var slot_box: VBoxContainer = %SlotBox
@onready var hint_label: Label = %Hint
@onready var btn_back: Button = %BtnBack

var _mode: Mode = Mode.ROOT
var _allow_save: bool = true


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	KairoStyle.style_panel(root_panel)
	title_label.add_theme_color_override("font_color", KairoStyle.INK)
	title_label.add_theme_font_size_override("font_size", 22)
	hint_label.add_theme_color_override("font_color", KairoStyle.SOFT_INK)
	KairoStyle.style_button(btn_back)
	btn_back.pressed.connect(_on_back)


func open_settings(allow_save: bool = true) -> void:
	_allow_save = allow_save
	visible = true
	_show_root()


func close_settings() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (
		event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE
	):
		if _mode == Mode.ROOT:
			close_settings()
		else:
			_show_root()
		get_viewport().set_input_as_handled()


func _show_root() -> void:
	_mode = Mode.ROOT
	title_label.text = L10n.t("ui.settings", "设置")
	hint_label.text = L10n.t("ui.settings_hint", "Esc 关闭 · 存档写入本机 user://saves")
	btn_back.text = L10n.t("ui.close", "关闭")
	slot_box.visible = false
	menu_box.visible = true
	_clear(menu_box)
	_add_menu_btn(L10n.t("ui.save", "存档"), _enter_save, _allow_save and RunState.is_running())
	_add_menu_btn(L10n.t("ui.load", "读档"), _enter_load, true)
	_add_menu_btn(L10n.t("ui.help", "说明"), func(): help_requested.emit(); close_settings(), true)
	_add_menu_btn(L10n.t("ui.tutorial_restart", "重开操作引导"), func(): tutorial_requested.emit(), true)
	_add_menu_btn(L10n.t("ui.return_title", "返回主界面"), func(): return_to_title_requested.emit(), true)
	_add_menu_btn(L10n.t("ui.quit_game", "退出游戏"), func(): quit_requested.emit(), true)


func _enter_save() -> void:
	_mode = Mode.SAVE
	title_label.text = L10n.t("ui.save_pick", "选择存档槽位")
	hint_label.text = L10n.t("ui.save_pick_hint", "写入会覆盖该槽。摘要来自实际落盘文件。")
	btn_back.text = L10n.t("ui.back", "返回")
	menu_box.visible = false
	slot_box.visible = true
	_rebuild_slots(true)


func _enter_load() -> void:
	_mode = Mode.LOAD
	title_label.text = L10n.t("ui.load_pick", "选择读档槽位")
	hint_label.text = L10n.t("ui.load_pick_hint", "读取本机已保存的进度。")
	btn_back.text = L10n.t("ui.back", "返回")
	menu_box.visible = false
	slot_box.visible = true
	_rebuild_slots(false)


func _rebuild_slots(for_save: bool) -> void:
	_clear(slot_box)
	for info in SaveSystem.list_slots():
		var sid := int(info.get("slot_id", 0))
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = _slot_label(info)
		KairoStyle.style_button(btn, true)
		if for_save:
			btn.pressed.connect(_do_save.bind(sid))
		else:
			btn.disabled = not bool(info.get("exists", false))
			btn.pressed.connect(_do_load.bind(sid))
		slot_box.add_child(btn)


func _slot_label(info: Dictionary) -> String:
	var n := int(info.get("slot_id", 0)) + 1
	if not bool(info.get("exists", false)):
		return L10n.t("ui.slot_empty", "槽位 %d · （空）") % n
	if bool(info.get("corrupt", false)):
		return L10n.t("ui.slot_corrupt", "槽位 %d · （损坏）") % n
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


func _do_save(slot_id: int) -> void:
	if SaveSystem.save_slot(slot_id):
		save_done.emit(slot_id)
		_rebuild_slots(true)


func _do_load(slot_id: int) -> void:
	if SaveSystem.load_slot(slot_id):
		load_done.emit(slot_id)
		close_settings()


func _on_back() -> void:
	if _mode == Mode.ROOT:
		close_settings()
	else:
		_show_root()


func _add_menu_btn(text: String, cb: Callable, enabled: bool) -> void:
	var btn := Button.new()
	btn.text = text
	btn.disabled = not enabled
	KairoStyle.style_button(btn, true)
	btn.pressed.connect(cb)
	menu_box.add_child(btn)


func _clear(box: VBoxContainer) -> void:
	while box.get_child_count() > 0:
		var c: Node = box.get_child(0)
		box.remove_child(c)
		c.queue_free()
