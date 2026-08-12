extends CanvasLayer
## 序位迷你排行榜：点击 HUD「序位」芯片展开。

@onready var root: Control = $Root
@onready var title_label: Label = %Title
@onready var body: RichTextLabel = %Body
@onready var close_btn: Button = %CloseBtn


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 35
	close_btn.pressed.connect(hide_board)
	var panel: PanelContainer = root.get_node_or_null("Panel") as PanelContainer
	if panel:
		KairoStyle.style_panel(panel)
	title_label.add_theme_color_override("font_color", KairoStyle.INK)
	body.add_theme_color_override("default_color", KairoStyle.INK)
	KairoStyle.style_button(close_btn)
	var dim: ColorRect = root.get_node_or_null("Dim") as ColorRect
	if dim:
		dim.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				hide_board()
		)
	if not DomainBus.domain_event.is_connected(_on_domain):
		DomainBus.domain_event.connect(_on_domain)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_board()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		hide_board()
	else:
		show_board()


func show_board() -> void:
	_refresh()
	visible = true


func hide_board() -> void:
	visible = false


func _on_domain(event_name: String, _payload: Dictionary) -> void:
	if visible and event_name in ["ladder_rank_changed", "meeting_changed"]:
		_refresh()


func _refresh() -> void:
	MeetingSystem.ensure_state()
	var pool := String(RunState.ladder.get("pool_id", ""))
	var pool_name := L10n.t("ladder.%s.name" % pool, pool if not pool.is_empty() else "—")
	var rank := int(RunState.ladder.get("player_rank", 0))
	var total := int(RunState.ladder.get("player_total", 0))
	title_label.text = L10n.t("ui.ladder_board_title", "序位 · %s") % pool_name

	var lines: PackedStringArray = [
		L10n.t("ui.ladder_board_you", "你：第 %d / %d") % [rank, total],
		"",
	]
	var entries: Array = MeetingSystem.sorted_ladder_entries()
	if entries.is_empty():
		lines.append(L10n.t("ui.ladder_board_empty", "尚无序位池——朝账后才会排。"))
	else:
		var top := float(entries[0].get("score", 1))
		if top <= 0.0:
			top = 1.0
		for i in range(entries.size()):
			var e: Dictionary = entries[i]
			var cid := String(e.get("char_id", ""))
			var name := L10n.t(cid, cid)
			var score := float(e.get("score", 0))
			var bar_n := clampi(int(round(score / top * 8.0)), 1, 8)
			var bar := "█".repeat(bar_n) + "░".repeat(8 - bar_n)
			var mark := "★" if bool(e.get("is_player", false)) or cid == "char_lin_ruisheng" else " "
			lines.append("%s%d  %s  %s  %.0f" % [mark, i + 1, name, bar, score])

	var days := int(RunState.meeting.get("days_until_next", 0))
	lines.append("")
	lines.append(L10n.t("ui.ladder_board_meeting", "距朝账：%d 日") % days)
	var policy := String(RunState.meeting.get("last_policy", ""))
	if not policy.is_empty():
		lines.append(L10n.t("ui.ladder_board_policy", "上次定调：%s") % L10n.t("meeting.policy.%s" % policy, policy))
	body.text = "\n".join(lines)
