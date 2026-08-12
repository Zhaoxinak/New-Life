extends CanvasLayer
## 强引导：短步带过各操作面。可跳过，可在设置重开。

signal finished
signal skipped

const STEPS: Array = [
	{
		"id": "welcome",
		"focus": "",
		"title": "tut.welcome.title",
		"body": "tut.welcome.body",
		"title_fb": "带你点一遍界面",
		"body_fb": "一共几步，每步一句。不想看可随时「跳过」。",
	},
	{
		"id": "hud",
		"focus": "hud",
		"title": "tut.hud.title",
		"body": "tut.hud.body",
		"title_fb": "顶栏数字",
		"body_fb": "银两 / 职级 / 热度 / 嫌疑。鼠标悬停可看细账与升职门槛。",
	},
	{
		"id": "goal",
		"focus": "goal",
		"title": "tut.goal.title",
		"body": "tut.goal.body",
		"title_fb": "目标条",
		"body_fb": "告诉你此刻该忙什么：待办事件、今日暗流，或自由探索。",
	},
	{
		"id": "stage",
		"focus": "hotspot",
		"require": "hotspot",
		"title": "tut.stage.title",
		"body": "tut.stage.body_force",
		"title_fb": "场景热区（必点）",
		"body_fb": "请点高亮的【家具热区】。平时点开会出行动纸片；选做事才耗时段。",
	},
	{
		"id": "npc",
		"focus": "npc",
		"require": "npc_left",
		"title": "tut.npc.title",
		"body": "tut.npc.body_force",
		"title_fb": "场上小人（必点）",
		"body_fb": "请左键点高亮停下的小人：闲聊。右键才是档案。",
	},
	{
		"id": "loc",
		"focus": "loc",
		"title": "tut.loc.title",
		"body": "tut.loc.body",
		"title_fb": "底部地点",
		"body_fb": "切换前堂、后院、街市等。灰色表示此时辰未开放。",
	},
	{
		"id": "rest",
		"focus": "rest",
		"title": "tut.rest.title",
		"body": "tut.rest.body",
		"title_fb": "歇一口气",
		"body_fb": "无事可做时推进时辰。有事件排队时会先拉你处理事件。",
	},
	{
		"id": "keys",
		"focus": "settings",
		"title": "tut.keys.title",
		"body": "tut.keys.body",
		"title_fb": "快捷键与设置",
		"body_fb": "J 账簿 · C 本档 · H 说明 · Esc 设置（存读档 / 回主界面 / 重开本引导）。",
	},
	{
		"id": "done",
		"focus": "",
		"title": "tut.done.title",
		"body": "tut.done.body",
		"title_fb": "可以开干了",
		"body_fb": "先把对白走完，再去热区做事。设置里随时可重开引导。",
	},
]

@onready var dim_top: ColorRect = %DimTop
@onready var dim_bottom: ColorRect = %DimBottom
@onready var dim_left: ColorRect = %DimLeft
@onready var dim_right: ColorRect = %DimRight
@onready var ring: Panel = %FocusRing
@onready var card: PanelContainer = %Card
@onready var step_label: Label = %StepLabel
@onready var title_label: Label = %Title
@onready var body_label: RichTextLabel = %Body
@onready var btn_next: Button = %BtnNext
@onready var btn_skip: Button = %BtnSkip

var _host: Control = null
var _step: int = 0
var _targets: Dictionary = {} ## focus_id -> Control
var _awaiting: String = ""
var _ring_tween: Tween
var _hint: Label = null


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	KairoStyle.style_panel(card)
	title_label.add_theme_color_override("font_color", KairoStyle.INK)
	title_label.add_theme_font_size_override("font_size", 20)
	body_label.add_theme_color_override("default_color", KairoStyle.INK)
	body_label.add_theme_font_size_override("normal_font_size", 15)
	step_label.add_theme_color_override("font_color", KairoStyle.SOFT_INK)
	KairoStyle.style_button(btn_next, true)
	KairoStyle.style_button(btn_skip)
	btn_next.pressed.connect(_on_next)
	btn_skip.pressed.connect(_on_skip)
	get_viewport().size_changed.connect(_relayout)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.85, 0.35, 0.12)
	sb.border_color = KairoStyle.ACCENT
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(12)
	ring.add_theme_stylebox_override("panel", sb)
	_hint = Label.new()
	_hint.visible = false
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02, 0.95))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)


func bind_host(host: Control, targets: Dictionary) -> void:
	_host = host
	_targets = targets


func is_running() -> bool:
	return visible


func is_awaiting(kind: String) -> bool:
	return visible and _awaiting == kind


func notify_player_action(kind: String) -> void:
	if not visible:
		return
	if _awaiting.is_empty() or _awaiting != kind:
		return
	_awaiting = ""
	_clear_stage_pulse()
	_on_tip_host(L10n.t("tut.action_ok", "对，就是这样。"))
	_on_next()


func start_guide() -> void:
	_step = 0
	_awaiting = ""
	visible = true
	_present()


func stop_guide(mark_done: bool = true) -> void:
	_awaiting = ""
	_clear_stage_pulse()
	_stop_ring_pulse()
	if _hint:
		_hint.visible = false
	visible = false
	if mark_done:
		RunState.set_flag("flag_tutorial_done", true)
	finished.emit()


func _on_next() -> void:
	if not _awaiting.is_empty():
		## 强制步：没点到位不能进
		_shake_card()
		return
	_step += 1
	if _step >= STEPS.size():
		stop_guide(true)
		return
	_present()


func _on_skip() -> void:
	_awaiting = ""
	_clear_stage_pulse()
	visible = false
	RunState.set_flag("flag_tutorial_done", true)
	skipped.emit()
	finished.emit()


func _present() -> void:
	var step: Dictionary = STEPS[_step]
	_awaiting = String(step.get("require", ""))
	_clear_stage_pulse()
	## 强制步前先清挡板（行动纸片等）
	if _host != null and _host.has_method("tutorial_prepare_step"):
		_host.call("tutorial_prepare_step", String(step.get("id", "")), _awaiting)
	step_label.text = L10n.t("tut.step_n", "引导 %d / %d") % [_step + 1, STEPS.size()]
	title_label.text = L10n.t(String(step.get("title", "")), String(step.get("title_fb", "")))
	body_label.text = L10n.t(String(step.get("body", "")), String(step.get("body_fb", "")))
	btn_skip.text = L10n.t("tut.skip", "跳过引导")
	btn_skip.visible = true
	if _awaiting.is_empty():
		btn_next.disabled = false
		btn_next.text = L10n.t("tut.next", "下一步") if _step < STEPS.size() - 1 else L10n.t("tut.finish", "开始游玩")
	else:
		btn_next.disabled = true
		btn_next.text = L10n.t("tut.do_it", "请先点高亮处")
		_apply_stage_pulse(_awaiting)
	## 钉位后再量洞，连两帧防止布局未刷完
	call_deferred("_relayout")
	call_deferred("_relayout_late")


func _apply_stage_pulse(kind: String) -> void:
	var st: Node = _targets.get("stage")
	if st == null or not st.has_method("set_tutorial_pulse"):
		return
	if kind == "hotspot":
		st.call("set_tutorial_pulse", "hotspot")
	elif kind == "npc_left":
		st.call("set_tutorial_pulse", "actor")


func _clear_stage_pulse() -> void:
	var st: Node = _targets.get("stage")
	if st != null and st.has_method("set_tutorial_pulse"):
		st.call("set_tutorial_pulse", "")


func _on_tip_host(text: String) -> void:
	if _host != null and _host.has_method("_on_tip"):
		_host.call("_on_tip", text)


func _shake_card() -> void:
	var origin := card.position
	var tw := create_tween()
	tw.tween_property(card, "position:x", origin.x + 8.0, 0.04)
	tw.tween_property(card, "position:x", origin.x - 8.0, 0.06)
	tw.tween_property(card, "position:x", origin.x, 0.05)


func _relayout() -> void:
	if not visible:
		return
	var step: Dictionary = STEPS[_step] if _step < STEPS.size() else {}
	var focus_id := String(step.get("focus", ""))
	var hole := _focus_rect(focus_id)
	_apply_dims(hole)
	_place_card(hole)


func _relayout_late() -> void:
	## 再量一次全局矩形（小人钉位后尺寸可能晚一帧）
	_relayout()


func _focus_rect(focus_id: String) -> Rect2:
	var vp := get_viewport().get_visible_rect().size
	var st: Node = _targets.get("stage")
	if focus_id == "hotspot" and st != null and st.has_method("tutorial_hotspot_rect"):
		var hr: Rect2 = st.call("tutorial_hotspot_rect")
		if hr.size.x > 4.0:
			return hr.grow(14.0)
	if focus_id == "npc" and st != null and st.has_method("tutorial_actor_rect"):
		var ar: Rect2 = st.call("tutorial_actor_rect")
		if ar.size.x > 4.0:
			return ar.grow(28.0)
	if focus_id.is_empty() or not _targets.has(focus_id):
		return Rect2(vp.x * 0.5 - 1.0, vp.y * 0.42, 2.0, 2.0)
	var ctrl: Control = _targets[focus_id] as Control
	if ctrl == null or not is_instance_valid(ctrl):
		return Rect2(vp.x * 0.5 - 1.0, vp.y * 0.42, 2.0, 2.0)
	return ctrl.get_global_rect().grow(8.0)


func _apply_dims(hole: Rect2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var dim := Color(0.05, 0.03, 0.02, 0.72 if not _awaiting.is_empty() else 0.62)
	for d in [dim_top, dim_bottom, dim_left, dim_right]:
		d.color = dim
		d.mouse_filter = Control.MOUSE_FILTER_STOP
		d.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var hx := hole.position.x
	var hy := hole.position.y
	var hw := hole.size.x
	var hh := hole.size.y
	dim_top.position = Vector2(0, 0)
	dim_top.size = Vector2(vp.x, maxf(0.0, hy))
	dim_bottom.position = Vector2(0, hy + hh)
	dim_bottom.size = Vector2(vp.x, maxf(0.0, vp.y - (hy + hh)))
	dim_left.position = Vector2(0, hy)
	dim_left.size = Vector2(maxf(0.0, hx), hh)
	dim_right.position = Vector2(hx + hw, hy)
	dim_right.size = Vector2(maxf(0.0, vp.x - (hx + hw)), hh)
	if hw <= 4.0:
		ring.visible = false
		_stop_ring_pulse()
		if _hint:
			_hint.visible = false
	else:
		ring.visible = true
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.set_anchors_preset(Control.PRESET_TOP_LEFT)
		ring.position = hole.position
		ring.size = hole.size
		_start_ring_pulse()
		if _hint and not _awaiting.is_empty():
			_hint.visible = true
			_hint.text = L10n.t("tut.click_here", "▼ 点这里")
			_hint.reset_size()
			_hint.position = Vector2(
				hole.position.x + hole.size.x * 0.5 - _hint.size.x * 0.5,
				maxf(8.0, hole.position.y - 36.0)
			)
		elif _hint:
			_hint.visible = false


func _start_ring_pulse() -> void:
	_stop_ring_pulse()
	ring.scale = Vector2.ONE
	ring.pivot_offset = ring.size * 0.5
	_ring_tween = create_tween()
	_ring_tween.set_loops()
	_ring_tween.tween_property(ring, "scale", Vector2(1.06, 1.06), 0.45)
	_ring_tween.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.45)


func _stop_ring_pulse() -> void:
	if _ring_tween != null:
		_ring_tween.kill()
		_ring_tween = null
	if is_instance_valid(ring):
		ring.scale = Vector2.ONE


func _place_card(hole: Rect2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var card_w := 520.0
	var card_h := 150.0
	var x := clampf((vp.x - card_w) * 0.5, 16.0, vp.x - card_w - 16.0)
	## 强制点场景时：卡片顶置，绝不挡热区/小人
	var y: float
	if not _awaiting.is_empty():
		y = 72.0
	else:
		y = vp.y - card_h - 88.0
		if hole.position.y > vp.y * 0.55:
			y = 96.0
		elif hole.end.y > y - 12.0:
			y = maxf(72.0, hole.position.y - card_h - 16.0)
	card.position = Vector2(x, y)
	card.size = Vector2(card_w, card_h)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_skip()
		get_viewport().set_input_as_handled()
