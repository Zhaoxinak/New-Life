extends CanvasLayer
## 朝账议场演出层：席位图 + 段标 + 畅言焦点 + 帘影机位。
## 只订阅 DomainBus / DialogueRunner，不写 run_* 数值。

signal stage_opened
signal stage_closed

const LAYER := 25 ## 低于 CeremonyOverlay(30)，高于日常 UI

const SEG_LABELS := {
	"rollcall": "① 开门点名",
	"report": "② 分铺汇报",
	"ceremony": "③ 仪典升降",
	"council": "④ 诸人建言",
	"policy": "⑤ 东家定调",
	"tasks": "⑥ 摊派差事",
}

const DEFAULT_KEYWORDS: PackedStringArray = [
	"跑街", "满师", "特别货", "货单", "聚丰", "外场", "学徒", "后院",
]

@onready var root: Control = $Root
@onready var dim: ColorRect = $Root/Dim
@onready var hall: PanelContainer = $Root/Hall
@onready var hall_bg: TextureRect = %HallBg
@onready var curtain: Control = $Root/Curtain
@onready var seat_layer: Control = $Root/SeatLayer
@onready var segment_banner: PanelContainer = %SegmentBanner
@onready var segment_label: Label = %SegmentLabel
@onready var listen_badge: PanelContainer = %ListenBadge
@onready var policy_splash: Label = %PolicySplash
@onready var ladder_side: PanelContainer = %LadderSide
@onready var ladder_body: RichTextLabel = %LadderBody
@onready var task_fly_layer: Control = %TaskFlyLayer
@onready var focus_ring: PanelContainer = %FocusRing
@onready var focus_name: Label = %FocusName
@onready var silence_mark: Label = %SilenceMark

var _active: bool = false
var _segment: String = ""
var _seat_nodes: Dictionary = {} ## seat_id -> Control
var _def: Dictionary = {}
var _listen_mode: bool = true
var _focus_char: String = ""
var _rollcall_done: bool = false
var _tween: Tween
var _seating_full: bool = true ## 满席 / 简席
var _pending_seat_move: bool = false ## 升职后听→列席挪位
var _ceremony_dimmed: bool = false
var _rival_char: String = ""
var _home_positions: Dictionary = {} ## seat_id -> Vector2
var _audio: Node = null


func _ready() -> void:
	layer = LAYER
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("meeting_stage")
	_audio = load("res://ui/MeetingAudio.gd").new()
	add_child(_audio)
	_style_hall_chrome()
	if policy_splash:
		policy_splash.visible = false
	if ladder_side:
		ladder_side.visible = false
	if silence_mark:
		silence_mark.visible = false
	if focus_ring:
		focus_ring.visible = false
	if listen_badge:
		listen_badge.visible = false
	if not DomainBus.domain_event.is_connected(_on_domain):
		DomainBus.domain_event.connect(_on_domain)
	if not DialogueRunner.dialog_started.is_connected(_on_dialog_started):
		DialogueRunner.dialog_started.connect(_on_dialog_started)
	if not DialogueRunner.node_presented.is_connected(_on_node_presented):
		DialogueRunner.node_presented.connect(_on_node_presented)
	if not DialogueRunner.dialog_finished.is_connected(_on_dialog_finished):
		DialogueRunner.dialog_finished.connect(_on_dialog_finished)


func _style_hall_chrome() -> void:
	## 暖色木厅框 + 前堂底图，告别近黑矩形。
	if hall:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.78, 0.62, 0.42, 0.2)
		sb.border_color = Color(0.42, 0.28, 0.16, 1)
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(10)
		sb.shadow_color = Color(0.12, 0.08, 0.05, 0.35)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 4)
		hall.add_theme_stylebox_override("panel", sb)
	_apply_hall_background()
	if segment_banner:
		var sbb := StyleBoxFlat.new()
		sbb.bg_color = Color(0.36, 0.24, 0.14, 0.94)
		sbb.border_color = Color(0.86, 0.7, 0.38, 0.95)
		sbb.set_border_width_all(2)
		sbb.set_corner_radius_all(8)
		sbb.content_margin_left = 12
		sbb.content_margin_right = 12
		sbb.content_margin_top = 4
		sbb.content_margin_bottom = 4
		segment_banner.add_theme_stylebox_override("panel", sbb)
	if listen_badge:
		var sbl := StyleBoxFlat.new()
		sbl.bg_color = Color(0.32, 0.22, 0.14, 0.88)
		sbl.border_color = Color(0.9, 0.78, 0.5, 0.85)
		sbl.set_border_width_all(2)
		sbl.set_corner_radius_all(8)
		sbl.content_margin_left = 10
		sbl.content_margin_right = 10
		sbl.content_margin_top = 4
		sbl.content_margin_bottom = 4
		listen_badge.add_theme_stylebox_override("panel", sbl)
		var lb: Label = listen_badge.get_node_or_null("ListenBadgeLabel") as Label
		if lb:
			lb.text = L10n.t("meeting.listen_badge", "门外旁听 · 帘影")
			lb.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1))
			lb.add_theme_font_size_override("font_size", 16)
	if silence_mark:
		silence_mark.add_theme_color_override("font_color", KairoStyle.INK)
		silence_mark.add_theme_font_size_override("font_size", 26)
		KairoStyle.outline_for_light_text(silence_mark, 5)
	if focus_name:
		KairoStyle.style_readable_label(focus_name, 17)
	_style_ladder_side()


func _style_ladder_side() -> void:
	## 汇报段左侧序位条：浅底深字，避免贴在木厅上发糊。
	if ladder_side == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.96, 0.88, 0.96)
	sb.border_color = Color(0.55, 0.36, 0.18, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0.1, 0.06, 0.04, 0.4)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	ladder_side.add_theme_stylebox_override("panel", sb)
	if ladder_body:
		KairoStyle.style_readable_rich(ladder_body, 16, 18)


func _apply_hall_background() -> void:
	if hall_bg == null:
		return
	var paths: PackedStringArray = [
		"res://art/meeting/hall_front.png",
		"res://art/locations/anchao/loc_01.png",
	]
	for p in paths:
		if ResourceLoader.exists(p):
			hall_bg.texture = load(p) as Texture2D
			hall_bg.visible = true
			hall_bg.modulate = Color(1, 1, 1, 1)
			return
	hall_bg.texture = null
	hall_bg.visible = false


func is_open() -> bool:
	return _active


func force_hide() -> void:
	_active = false
	_segment = ""
	_focus_char = ""
	_rollcall_done = false
	_pending_seat_move = false
	_ceremony_dimmed = false
	_rival_char = ""
	if listen_badge:
		listen_badge.visible = false
	if curtain:
		curtain.visible = false
	_seating_full = true
	_home_positions.clear()
	visible = false
	if _audio and _audio.has_method("stop_bgm"):
		_audio.stop_bgm()
	if policy_splash:
		policy_splash.visible = false
	if ladder_side:
		ladder_side.visible = false
	if silence_mark:
		silence_mark.visible = false
	if focus_ring:
		focus_ring.visible = false
	_clear_task_flies()


func _on_dialog_started(_dialog_id: String, event_id: String) -> void:
	if _is_meeting_event(event_id) or _dialog_looks_meeting(_dialog_id):
		_open_stage()


func _on_dialog_finished(_event_id: String) -> void:
	if _active:
		_close_stage()


func _on_domain(event_name: String, payload: Dictionary) -> void:
	match event_name:
		"meeting_segment_changed":
			if _active:
				_set_segment(String(payload.get("segment", "")))
		"council_turn_changed":
			if _active:
				_on_council_turn(payload)
		"meeting_policy_resolved":
			if _active:
				_play_policy_gavel(String(payload.get("policy", "")))
		"meeting_tasks_changed":
			if _active and _segment == "tasks":
				_fly_task_cards()
			elif _active and int(payload.get("count", 0)) > 0:
				_set_segment("tasks")
				_fly_task_cards()
		"meeting_changed":
			if _active:
				_recompute_seating_mode()
				_refresh_seats()
		"promotion_ceremony":
			if _active:
				_set_segment("ceremony")
				_ceremony_dimmed = true
				_dim_seats_for_ceremony(true)
				## 学徒旁听升堂 → 仪式结束后挪席
				var old_r := String(payload.get("old_rank", ""))
				var new_r := String(payload.get("new_rank", ""))
				if old_r == "apprentice" or _listen_mode:
					_pending_seat_move = true
				if new_r != "apprentice":
					_seating_full = true
		"demotion_applied":
			if _active:
				_set_segment("ceremony")
				_seating_full = true
				_refresh_seats()
		"ceremony_finished":
			if _active:
				_on_ceremony_finished(payload)


func _on_node_presented(node: Dictionary) -> void:
	if not _active:
		var tags: Array = node.get("tags", [])
		if tags.has("meeting") or _dialog_looks_meeting(String(node.get("dialog_id", ""))):
			_open_stage()
		else:
			return
	var seg := _infer_segment(node)
	if not seg.is_empty() and seg != _segment:
		_set_segment(seg)
	var speaker := String(node.get("speaker", ""))
	var tags2: Array = node.get("tags", [])
	var dialog_id := String(node.get("dialog_id", ""))
	var loc_key := String(node.get("loc_key", ""))
	## 东家截断：全席一震
	if dialog_id.contains("demao_cut") or loc_key == "council.demao.cut" or loc_key.ends_with("demao.cut"):
		_play_cutoff_shake(speaker)
	var silence := tags2.has("council") and (
		dialog_id.contains("pass")
		or loc_key.contains("pass")
	)
	if tags2.has("council"):
		silence = _last_speech_was_silence(speaker) or silence
	_set_focus(speaker, silence)
	## 子安建言：略偏席、多停半拍
	if speaker == "char_qian_zian" and tags2.has("council") and not silence:
		_nudge_zian_seat()
	## 旁听：点到自己名字 / 听建言碎片时帘动
	if _listen_mode:
		var named := speaker == "char_lin_ruisheng" or dialog_id.contains("player_named") \
			or dialog_id.contains("manshi") or dialog_id.contains("council_listen")
		if named:
			_pulse_curtain()
	if _segment == "report":
		_show_ladder_side(true)
	elif _segment != "report":
		_show_ladder_side(false)
	if _segment == "rollcall" and not _rollcall_done:
		_play_rollcall_lights()


func _is_meeting_event(event_id: String) -> bool:
	if event_id.is_empty():
		return false
	return event_id.begins_with("M") or event_id.begins_with("m")


func _dialog_looks_meeting(dialog_id: String) -> bool:
	var id := dialog_id.to_lower()
	return id.begins_with("dialog_m") or id.begins_with("dialog_meeting") or id.begins_with("dialog_council")


func _open_stage() -> void:
	MeetingSystem.ensure_state()
	_def = _load_def()
	_listen_mode = String(RunState.meeting.get("attendance_tier", "listen")) == "listen"
	_active = true
	visible = true
	_rollcall_done = false
	_pending_seat_move = false
	_ceremony_dimmed = false
	_recompute_seating_mode()
	_rival_char = _pick_rival_char()
	curtain.visible = _listen_mode
	curtain.modulate = Color(1, 1, 1, 1 if _listen_mode else 0.0)
	dim.color = Color(0.18, 0.12, 0.08, 0.42)
	if listen_badge:
		listen_badge.visible = _listen_mode
	_build_seats()
	_refresh_seats()
	if _segment.is_empty():
		_set_segment("rollcall")
	_animate_open()
	call_deferred("_rebuild_seats_layout")
	if _audio and _audio.has_method("play_cue"):
		_audio.play_cue("open")
		_audio.start_bgm()
	stage_opened.emit()


func _rebuild_seats_layout() -> void:
	if not _active:
		return
	_build_seats()
	_refresh_seats()
	if _segment == "rollcall" and not _rollcall_done:
		_play_rollcall_lights()
	elif not _focus_char.is_empty():
		_set_focus(_focus_char, silence_mark.visible if silence_mark else false)


func _close_stage() -> void:
	_active = false
	_segment = ""
	_focus_char = ""
	_rollcall_done = false
	_pending_seat_move = false
	_ceremony_dimmed = false
	_rival_char = ""
	_show_ladder_side(false)
	if policy_splash:
		policy_splash.visible = false
	_clear_task_flies()
	if _audio and _audio.has_method("stop_bgm"):
		_audio.stop_bgm()
	visible = false
	stage_closed.emit()


func _load_def() -> Dictionary:
	var raw: Variant = PackDB.tables.get("def_meeting_stage", {})
	if typeof(raw) == TYPE_DICTIONARY:
		return raw
	return {}


func _build_seats() -> void:
	for child in seat_layer.get_children():
		child.queue_free()
	_seat_nodes.clear()
	_home_positions.clear()
	var seats: Array = _def.get("seats", [])
	if seats.is_empty():
		seats = _fallback_seats()
	var size := seat_layer.size
	if size.x < 8.0:
		size = Vector2(1280, 490) ## 扣除底部台词区后的议场高度
	for s in seats:
		if typeof(s) != TYPE_DICTIONARY:
			continue
		var seat: Dictionary = s
		var sid := String(seat.get("id", ""))
		if sid.is_empty():
			continue
		var card := _make_seat_card(seat)
		seat_layer.add_child(card)
		var px := float(seat.get("x", 0.5)) * size.x - 44.0
		var py := float(seat.get("y", 0.5)) * size.y - 56.0
		var pos := Vector2(px, py)
		card.position = pos
		_home_positions[sid] = pos
		var sc := float(seat.get("scale", 1.0))
		card.scale = Vector2(sc, sc)
		_seat_nodes[sid] = card


func _fallback_seats() -> Array:
	return [
		{"id": "seat_master", "char": "char_qian_demao", "x": 0.5, "y": 0.18, "scale": 1.15},
		{"id": "seat_zhou", "char": "char_zhou_guanshi", "x": 0.4, "y": 0.36},
		{"id": "seat_zian", "char": "char_qian_zian", "x": 0.6, "y": 0.36, "require_flag": "flag_zian_arrived"},
		{"id": "seat_wang", "char": "char_wang_pangzi", "x": 0.28, "y": 0.58},
		{"id": "seat_player", "char": "char_lin_ruisheng", "x": 0.5, "y": 0.58},
		{"id": "seat_listen", "char": "char_lin_ruisheng", "x": 0.5, "y": 0.78, "role": "listen"},
	]


func _make_seat_card(seat: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(92, 118)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.93, 0.82, 0.96)
	sb.border_color = Color(0.55, 0.38, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0.1, 0.06, 0.04, 0.28)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	card.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)

	var plate := PanelContainer.new()
	plate.name = "Plate"
	plate.custom_minimum_size = Vector2(68, 68)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.62, 0.48, 0.34, 1)
	psb.border_color = Color(0.86, 0.72, 0.45, 0.9)
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(34)
	plate.add_theme_stylebox_override("panel", psb)
	v.add_child(plate)

	var plate_inner := Control.new()
	plate_inner.custom_minimum_size = Vector2(64, 64)
	plate.add_child(plate_inner)

	var tex := TextureRect.new()
	tex.name = "Tex"
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate_inner.add_child(tex)

	var glyph := Label.new()
	glyph.name = "Glyph"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.add_theme_font_size_override("font_size", 26)
	glyph.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	plate_inner.add_child(glyph)

	var name_lb := Label.new()
	name_lb.name = "Name"
	name_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lb.add_theme_font_size_override("font_size", 15)
	name_lb.add_theme_color_override("font_color", KairoStyle.INK)
	v.add_child(name_lb)

	var mark := Label.new()
	mark.name = "AbsentMark"
	mark.visible = false
	mark.text = "未到"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.add_theme_color_override("font_color", KairoStyle.DANGER)
	mark.add_theme_font_size_override("font_size", 14)
	v.add_child(mark)

	var mood := Label.new()
	mood.name = "MoodMark"
	mood.visible = false
	mood.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mood.add_theme_font_size_override("font_size", 14)
	mood.add_theme_color_override("font_color", KairoStyle.SOFT_INK)
	v.add_child(mood)

	var rival_tag := Label.new()
	rival_tag.name = "RivalTag"
	rival_tag.visible = false
	rival_tag.text = L10n.t("meeting.rival_tag", "劲敌")
	rival_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rival_tag.add_theme_font_size_override("font_size", 14)
	rival_tag.add_theme_color_override("font_color", KairoStyle.DANGER)
	v.add_child(rival_tag)

	var score_lb := Label.new()
	score_lb.name = "ScoreMark"
	score_lb.visible = false
	score_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lb.add_theme_font_size_override("font_size", 13)
	score_lb.add_theme_color_override("font_color", KairoStyle.ACCENT_INK)
	v.add_child(score_lb)

	card.set_meta("seat_def", seat)
	return card


func _refresh_seats() -> void:
	MeetingSystem.ensure_state()
	_listen_mode = String(RunState.meeting.get("attendance_tier", "listen")) == "listen"
	curtain.visible = _listen_mode
	if listen_badge:
		listen_badge.visible = _listen_mode
	_rival_char = _pick_rival_char()
	var hide_simple: Array = _def.get("simple_hide_seats", ["seat_rival_0", "seat_paojie"])
	for sid in _seat_nodes.keys():
		var card: Control = _seat_nodes[sid]
		var seat: Dictionary = card.get_meta("seat_def", {})
		var role := String(seat.get("role", ""))
		var char_id := _resolve_seat_char(seat)
		var occupied := not char_id.is_empty()
		## 简席：隐藏空跑街/仇人等次要席
		if not _seating_full and hide_simple.has(sid) and (role == "rival" or role == "paojie"):
			if role == "rival" and _rival_char.is_empty():
				card.visible = false
				continue
			if role == "paojie" and char_id.is_empty():
				card.visible = false
				continue
		## listen 机位：堂内席剪影；门外 listen 槽强调玩家
		if role == "listen":
			card.visible = _listen_mode
			if _listen_mode:
				char_id = "char_lin_ruisheng"
				occupied = true
		elif role == "player":
			card.visible = not _listen_mode
		elif String(seat.get("require_flag", "")) != "" and not bool(RunState.get_flag(String(seat.get("require_flag")), false)):
			occupied = false
			char_id = ""
			## 满席时虚位仍显示「未到」；简席可藏空子安席
			if not _seating_full and role == "zian":
				card.visible = false
				continue
			card.visible = true
		else:
			card.visible = true
		_paint_seat(card, char_id, occupied, false, false)
		if _ceremony_dimmed:
			card.modulate.a = 0.62
		elif _listen_mode and role == "listen":
			card.modulate = Color(1.05, 1.0, 0.92, 1.0)
		elif _listen_mode and role == "master":
			card.modulate = Color(0.95, 0.9, 0.8, 0.95)
		elif _listen_mode and role == "rival" and occupied:
			## 帘外也能感到劲敌：略亮于其他剪影
			card.modulate = Color(0.82, 0.48, 0.4, 0.95)
		elif _listen_mode:
			## 帘影：堂内人影偏暖；不压到字看不清
			card.modulate = Color(0.62, 0.54, 0.42, 0.88)
		elif not _listen_mode:
			card.modulate = Color(1, 1, 1, 1)
		## 劲敌席压迫感：红框 + 角标（简席也要有）
		if role == "rival" and occupied:
			_tint_rival(card)
		## 跑街池：子安即劲敌——专席也套红框，避免 rival 席空着没压迫
		elif occupied and char_id == MeetingSystem.primary_rival() and char_id == "char_qian_zian":
			_tint_rival(card)


func _resolve_seat_char(seat: Dictionary) -> String:
	var role := String(seat.get("role", ""))
	var req := String(seat.get("require_flag", ""))
	if not req.is_empty() and not bool(RunState.get_flag(req, false)):
		return ""
	var cid := String(seat.get("char", ""))
	if role == "rival":
		if not _rival_char.is_empty():
			return _rival_char
		return _pick_rival_char()
	if role == "paojie" and cid.is_empty():
		## 满席且玩家已是跑街时，虚位可留空；若有 NPC 跑街旗标可扩展
		return ""
	return cid


func _set_plate_tone(plate: Control, col: Color) -> void:
	if plate == null:
		return
	if plate is PanelContainer:
		var psb := StyleBoxFlat.new()
		psb.bg_color = col
		psb.border_color = Color(0.86, 0.72, 0.45, 0.9)
		psb.set_border_width_all(2)
		psb.set_corner_radius_all(34)
		(plate as PanelContainer).add_theme_stylebox_override("panel", psb)
	elif plate is ColorRect:
		(plate as ColorRect).color = col


func _paint_seat(card: Control, char_id: String, occupied: bool, focused: bool, silenced: bool) -> void:
	var plate: Control = card.find_child("Plate", true, false) as Control
	var tex: TextureRect = card.find_child("Tex", true, false) as TextureRect
	var glyph: Label = card.find_child("Glyph", true, false) as Label
	var name_lb: Label = card.find_child("Name", true, false) as Label
	var absent: Label = card.find_child("AbsentMark", true, false) as Label
	var mood: Label = card.find_child("MoodMark", true, false) as Label
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(3 if focused else 2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0.1, 0.06, 0.04, 0.28)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	if focused:
		sb.border_color = Color(0.92, 0.72, 0.28)
		sb.bg_color = Color(0.98, 0.92, 0.7, 0.98)
	elif silenced:
		sb.border_color = Color(0.45, 0.42, 0.4)
		sb.bg_color = Color(0.72, 0.68, 0.62, 0.85)
	else:
		sb.border_color = Color(0.55, 0.38, 0.2)
		sb.bg_color = Color(0.98, 0.93, 0.82, 0.96)
	card.add_theme_stylebox_override("panel", sb)

	if not occupied or char_id.is_empty():
		if name_lb:
			name_lb.text = "—"
		if glyph:
			glyph.text = "·"
			glyph.visible = true
		if tex:
			tex.visible = false
		if absent:
			absent.visible = true
		if mood:
			mood.visible = false
		var empty_tag: Label = card.find_child("RivalTag", true, false) as Label
		if empty_tag:
			empty_tag.visible = false
		var empty_score: Label = card.find_child("ScoreMark", true, false) as Label
		if empty_score:
			empty_score.visible = false
		_set_plate_tone(plate, Color(0.45, 0.4, 0.34))
		card.modulate.a = 0.55
		return

	if absent:
		absent.visible = false
	card.modulate.a = 0.7 if silenced else 1.0
	var display := KairoStyle.nameplate(char_id) if char_id != "narrator" else L10n.t("char.narrator", "旁白")
	if name_lb:
		name_lb.text = display
	_set_plate_tone(plate, Color(0.62, 0.48, 0.34) if not silenced else Color(0.48, 0.44, 0.4))
	_apply_portrait(tex, glyph, char_id, silenced)
	if silenced and name_lb:
		name_lb.text = "%s …" % display
	_apply_mood(mood, focused, silenced, char_id)
	var rival_tag: Label = card.find_child("RivalTag", true, false) as Label
	var score_mark: Label = card.find_child("ScoreMark", true, false) as Label
	var seat_meta: Dictionary = card.get_meta("seat_def", {})
	var is_rival_seat := String(seat_meta.get("role", "")) == "rival"
	if rival_tag and not is_rival_seat:
		rival_tag.visible = false
	if score_mark and not is_rival_seat:
		score_mark.visible = false


func _apply_portrait(tex: TextureRect, glyph: Label, char_id: String, silenced: bool) -> void:
	if tex == null:
		return
	## 议场席位：圆裁胸像 > 档案胸像 > 黑底 sprite（最后才用）
	var paths: PackedStringArray = [
		"res://art/meeting/busts/%s.png" % char_id,
		"res://art/portraits/anchao/%s.png" % char_id,
		"res://art/sprites/anchao/%s.png" % char_id,
	]
	var loaded := false
	for p in paths:
		if ResourceLoader.exists(p):
			tex.texture = load(p) as Texture2D
			tex.visible = true
			## 圆裁胸像已透明底；档案胸像 cover；sprite 也 cover
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			loaded = true
			if glyph:
				glyph.visible = false
			break
	if not loaded:
		tex.texture = null
		tex.visible = false
		if glyph:
			glyph.visible = true
			var nm := L10n.t(char_id, char_id)
			glyph.text = nm.substr(0, 1) if not nm.is_empty() else "·"
	if silenced:
		tex.modulate = Color(0.55, 0.55, 0.55, 0.85)
	else:
		tex.modulate = Color(1, 1, 1, 1)


func _apply_mood(mood: Label, focused: bool, silenced: bool, char_id: String) -> void:
	## 无立绘差分时用席位角标表达：言 / 默 / 偏（子安）/ 断（东家截断后）
	if mood == null:
		return
	var cut_flag := bool(mood.get_meta("cutoff", false)) if mood.has_meta("cutoff") else false
	if cut_flag and char_id == "char_qian_demao":
		mood.visible = true
		mood.text = L10n.t("meeting.mood.cut", "断")
		mood.add_theme_color_override("font_color", Color(0.75, 0.28, 0.22))
		return
	if silenced:
		mood.visible = true
		mood.text = L10n.t("meeting.mood.silent", "默")
		mood.add_theme_color_override("font_color", KairoStyle.SOFT_INK)
	elif focused:
		mood.visible = true
		if char_id == "char_qian_zian":
			mood.text = L10n.t("meeting.mood.bias", "偏")
			mood.add_theme_color_override("font_color", Color(0.55, 0.22, 0.42))
		else:
			mood.text = L10n.t("meeting.mood.speak", "言")
			mood.add_theme_color_override("font_color", KairoStyle.WOOD_DARK)
	else:
		mood.visible = false
		mood.text = ""


func _set_segment(seg: String) -> void:
	if seg.is_empty():
		return
	_segment = seg
	var label := String(SEG_LABELS.get(seg, seg))
	var segs: Dictionary = _def.get("segments", {})
	if segs.has(seg) and typeof(segs[seg]) == TYPE_DICTIONARY:
		var row: Dictionary = segs[seg]
		label = L10n.t(String(row.get("label_key", "")), String(row.get("label", label)))
	else:
		label = L10n.t("meeting.seg.%s" % seg, label)
	segment_label.text = label
	segment_banner.modulate.a = 0.0
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(segment_banner, "modulate:a", 1.0, 0.25)
	_dim_seats_for_ceremony(seg == "ceremony")
	if seg == "policy":
		_policy_lights()
	elif seg == "council":
		_refresh_council_visuals()
	elif seg == "report":
		_show_ladder_side(true)
	else:
		_show_ladder_side(false)


func _infer_segment(node: Dictionary) -> String:
	var stage_v: Variant = node.get("stage", {})
	if typeof(stage_v) == TYPE_DICTIONARY:
		var s := String((stage_v as Dictionary).get("segment", ""))
		if not s.is_empty():
			return s
	var tags: Array = node.get("tags", [])
	for t in ["seg_rollcall", "seg_report", "seg_ceremony", "seg_council", "seg_policy", "seg_tasks"]:
		if tags.has(t):
			return t.trim_prefix("seg_")
	if tags.has("council"):
		return "council"
	var id := String(node.get("dialog_id", "")).to_lower()
	if id.contains("rollcall"):
		return "rollcall"
	if id.contains("ladder") or id.contains("report") or id.contains("paojie_echo") or id.contains("manshi"):
		return "report"
	if id.contains("promo") or id.contains("ceremony") or id.contains("e020"):
		return "ceremony"
	if id.contains("council"):
		return "council"
	if id.contains("policy"):
		return "policy"
	if id.contains("demao_nod") or id.contains("demao_cut"):
		return "policy"
	if id.contains("task"):
		return "tasks"
	if id.ends_with("_close") or id.contains("m001_close") or id.contains("m000_close") or id.contains("m002_close") or id.contains("m003_close"):
		return "tasks"
	if id.contains("_start") and (id.contains("m000") or id.contains("m001") or id.contains("m002") or id.contains("m003")):
		return "rollcall"
	if id.contains("zhou_order"):
		return "rollcall"
	return ""


func _set_focus(speaker: String, silence: bool) -> void:
	_focus_char = speaker
	if silence_mark:
		silence_mark.visible = silence and speaker != "narrator" and not speaker.is_empty()
	if focus_ring:
		if speaker.is_empty() or speaker == "narrator":
			focus_ring.visible = false
		else:
			focus_ring.visible = true
			focus_name.text = KairoStyle.nameplate(speaker)
			if silence:
				focus_name.text = "%s · ……" % KairoStyle.nameplate(speaker)
	for sid in _seat_nodes.keys():
		var card: Control = _seat_nodes[sid]
		var seat: Dictionary = card.get_meta("seat_def", {})
		var cid := _resolve_seat_char(seat)
		var role := String(seat.get("role", ""))
		if role == "listen" and _listen_mode:
			cid = "char_lin_ruisheng"
		var occupied := not cid.is_empty()
		if role == "player":
			occupied = occupied and not _listen_mode
		elif role == "listen":
			occupied = _listen_mode
		var focused := occupied and cid == speaker and speaker != "narrator"
		var silenced := false
		if _segment == "council" and occupied:
			silenced = _char_was_silent(cid)
			if focused and silence:
				silenced = true
		_paint_seat(card, cid if occupied else "", occupied, focused, silenced and not focused)
		if focused:
			_pulse_card(card)


func _char_was_silent(char_id: String) -> bool:
	for entry in RunState.meeting.get("council_log", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if String(entry.get("char", "")) == char_id:
			return not bool(entry.get("spoke", false))
	return false


func _last_speech_was_silence(speaker: String) -> bool:
	var log: Array = RunState.meeting.get("council_log", [])
	if log.is_empty():
		return false
	var last: Variant = log.back()
	if typeof(last) != TYPE_DICTIONARY:
		return false
	var e: Dictionary = last
	if not speaker.is_empty() and String(e.get("char", "")) != speaker:
		return false
	return not bool(e.get("spoke", true))


func _on_council_turn(payload: Dictionary) -> void:
	_set_segment("council")
	var char_id := String(payload.get("char", ""))
	if char_id.is_empty():
		var q: Array = payload.get("queue", RunState.meeting.get("council_queue", []))
		var idx := int(payload.get("index", RunState.meeting.get("council_index", 0)))
		if idx >= 0 and idx < q.size():
			char_id = String(q[idx])
	_refresh_council_visuals()
	if not char_id.is_empty():
		_set_focus(char_id, false)


func _refresh_council_visuals() -> void:
	for sid in _seat_nodes.keys():
		var card: Control = _seat_nodes[sid]
		var seat: Dictionary = card.get_meta("seat_def", {})
		var cid := _resolve_seat_char(seat)
		if cid.is_empty():
			continue
		var silenced := _char_was_silent(cid)
		var focused := cid == _focus_char
		_paint_seat(card, cid, true, focused, silenced and not focused)


func _play_rollcall_lights() -> void:
	_rollcall_done = true
	var order: Array = _def.get("seat_order", _seat_nodes.keys())
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	for sid_v in order:
		var sid := String(sid_v)
		if not _seat_nodes.has(sid):
			continue
		var card: Control = _seat_nodes[sid]
		card.modulate.a = 0.15
		_tween.tween_callback(func():
			if _audio and _audio.has_method("play_cue"):
				_audio.play_cue("seat")
		)
		_tween.tween_property(card, "modulate:a", 1.0 if not _listen_mode or sid == "seat_listen" or sid == "seat_master" else 0.85, 0.18)


func _policy_lights() -> void:
	for sid in _seat_nodes.keys():
		var card: Control = _seat_nodes[sid]
		var seat: Dictionary = card.get_meta("seat_def", {})
		if String(seat.get("role", "")) == "master" or String(seat.get("id", "")) == "seat_master":
			card.modulate = Color(1.1, 1.05, 0.9, 1.0)
			_set_focus(String(seat.get("char", "char_qian_demao")), false)
		else:
			card.modulate = Color(0.45, 0.42, 0.4, 0.55)


func _play_policy_gavel(policy_key: String) -> void:
	_set_segment("policy")
	_policy_lights()
	if _audio and _audio.has_method("play_cue"):
		_audio.play_cue("gavel")
		_audio.duck_bgm_for_gavel()
	if policy_splash == null:
		return
	var label := _policy_label(policy_key)
	policy_splash.text = label
	policy_splash.visible = true
	policy_splash.modulate.a = 0.0
	policy_splash.scale = Vector2(0.85, 0.85)
	var tw := create_tween()
	tw.tween_property(policy_splash, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(policy_splash, "scale", Vector2.ONE, 0.25)
	tw.tween_interval(1.2)
	tw.tween_property(policy_splash, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): policy_splash.visible = false)


func _policy_label(key: String) -> String:
	match key:
		"bright_steady":
			return L10n.t("meeting.policy.bright_steady", "定调 · 稳明面")
		"watch_jufeng", "market_watch":
			return L10n.t("meeting.policy.market", "定调 · 盯街市")
		"look_away":
			return L10n.t("meeting.policy.look_away", "定调 · 少问后院")
		"risk_report", "manifest_risk":
			return L10n.t("meeting.policy.risk", "定调 · 慎言货单")
		"son_first":
			return L10n.t("meeting.policy.son_first", "定调 · 先顾脸面")
		"foreign_caution":
			return L10n.t("meeting.policy.foreign", "定调 · 洋行慎行")
		_:
			return L10n.t("meeting.policy.generic", "定调 · %s") % key


func _show_ladder_side(on: bool) -> void:
	if ladder_side == null:
		return
	ladder_side.visible = on
	if not on or ladder_body == null:
		return
	_style_ladder_side()
	MeetingSystem.ensure_state()
	var pool := String(RunState.ladder.get("pool_id", ""))
	var pool_name := L10n.t("ladder.%s.name" % pool, pool if not pool.is_empty() else "—")
	var rank := int(RunState.ladder.get("player_rank", 0))
	var total := int(RunState.ladder.get("player_total", 0))
	var rival_id := _rival_char if not _rival_char.is_empty() else MeetingSystem.pick_meeting_rival()
	var lines: PackedStringArray = []
	lines.append("[b][color=#3a2414]%s[/color][/b]" % L10n.t("ui.ladder_board_title", "序位 · %s") % pool_name)
	if total > 0 and rank > 0:
		lines.append("[color=#8a4020]%s[/color]" % (L10n.t("ui.duty_rank_you", "你：第 %d / %d") % [rank, total]))
	lines.append("")
	var entries: Array = MeetingSystem.sorted_ladder_entries()
	var i := 0
	for e in entries:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		i += 1
		if i > 5:
			break
		var cid := String(e.get("char", e.get("char_id", "")))
		var score := float(e.get("score", 0))
		var plate := KairoStyle.nameplate(cid)
		var is_you := cid == "char_lin_ruisheng" or bool(e.get("is_player", false))
		var is_rival := (not rival_id.is_empty() and cid == rival_id)
		if is_you:
			lines.append("[b][color=#b45a18]★ %d. %s  %d[/color][/b]" % [i, plate, int(score)])
		elif is_rival:
			lines.append("[color=#c43828]◆ %d. %s  %d[/color]" % [i, plate, int(score)])
		else:
			lines.append("[color=#2a1c12]%d. %s  %d[/color]" % [i, plate, int(score)])
	if i == 0:
		lines.append("[color=#5a4030]%s[/color]" % L10n.t("ui.ladder_pending", "序位 —"))
	ladder_body.text = "\n".join(lines)


func _fly_task_cards() -> void:
	_clear_task_flies()
	if task_fly_layer == null:
		return
	var tasks: Array = RunState.meeting.get("weekly_tasks", [])
	if tasks.is_empty():
		return
	var i := 0
	for t in tasks:
		if typeof(t) != TYPE_DICTIONARY:
			continue
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(160, 44)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.98, 0.94, 0.82, 0.95)
		sb.border_color = Color(0.72, 0.48, 0.28)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel", sb)
		var lb := Label.new()
		lb.text = L10n.t(String(t.get("label_key", "")), String(t.get("id", "差事")))
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_color_override("font_color", Color(0.22, 0.16, 0.12))
		card.add_child(lb)
		task_fly_layer.add_child(card)
		card.position = Vector2(560, 120 + i * 12)
		card.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(card, "modulate:a", 1.0, 0.15)
		tw.parallel().tween_property(card, "position", Vector2(980, 28 + i * 50), 0.55).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.8)
		tw.tween_property(card, "modulate:a", 0.0, 0.3)
		i += 1


func _clear_task_flies() -> void:
	if task_fly_layer == null:
		return
	for c in task_fly_layer.get_children():
		c.queue_free()


func _dim_seats_for_ceremony(on: bool) -> void:
	_ceremony_dimmed = on
	for sid in _seat_nodes.keys():
		var card: Control = _seat_nodes[sid]
		card.modulate.a = 0.62 if on else 1.0


func _pulse_card(card: Control) -> void:
	var tw := create_tween()
	var base := card.scale
	tw.tween_property(card, "scale", base * 1.08, 0.12)
	tw.tween_property(card, "scale", base, 0.15)


func _animate_open() -> void:
	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.28)


## ——— P2：仪式衔接 / 挪席 / 简满席 / 截断 ———

func _recompute_seating_mode() -> void:
	## 满席：有仇人入队、子安在、本周有升降迹象、或汇报分极端；否则简席。
	MeetingSystem.ensure_state()
	var full := false
	if bool(RunState.get_flag("flag_zian_arrived", false)):
		full = true
	if _pending_seat_move:
		full = true
	var q: Array = RunState.meeting.get("council_queue", [])
	var fixed := {
		"char_qian_demao": true,
		"char_zhou_guanshi": true,
		"char_wang_pangzi": true,
		"char_qian_zian": true,
		"char_lin_ruisheng": true,
	}
	for qid_v in q:
		if not fixed.has(String(qid_v)):
			full = true
			break
	var score := int(RunState.meeting.get("report_score", 50))
	if score >= 85 or score <= 25:
		full = true
	## 序位池内有人分差紧逼玩家
	if _ladder_pressure():
		full = true
	## 剧情朝账 M002/M003 强制满席
	var eid := DialogueRunner.current_event_id
	if eid in ["M002", "M003"]:
		full = true
	## M001 首听：满席教学
	if eid == "M001":
		full = true
	_seating_full = full


func _ladder_pressure() -> bool:
	var entries: Array = MeetingSystem.sorted_ladder_entries()
	if entries.size() < 2:
		return false
	var player_score := -1.0
	var best_other := -1.0
	for e in entries:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var cid := String(e.get("char", e.get("char_id", "")))
		var sc := float(e.get("score", 0))
		if cid == "char_lin_ruisheng":
			player_score = sc
		elif sc > best_other:
			best_other = sc
	if player_score < 0.0:
		return false
	return absf(player_score - best_other) <= 8.0


func _pick_rival_char() -> String:
	var fixed := {
		"char_qian_demao": true,
		"char_zhou_guanshi": true,
		"char_wang_pangzi": true,
		"char_qian_zian": true,
		"char_lin_ruisheng": true,
	}
	for q in RunState.meeting.get("council_queue", []):
		var qid := String(q)
		if not fixed.has(qid):
			_rival_char = qid
			return qid
	var poked := MeetingSystem.pick_meeting_rival()
	if not poked.is_empty():
		_rival_char = poked
		return poked
	var primary := MeetingSystem.primary_rival()
	if not primary.is_empty() and not fixed.has(primary):
		_rival_char = primary
		return primary
	## 即使本周未入建言，也从序位池挑最高分非玩家对手，保证席上有压迫感
	var pool: Array = _def.get("rival_pool", [
		"char_apprentice_sun_liu",
		"char_apprentice_xiao_chen",
		"char_zhao_waichang",
		"char_li_waichang",
	])
	var best_id := ""
	var best_sc := -1.0
	for e in MeetingSystem.sorted_ladder_entries():
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var cid := String(e.get("char", e.get("char_id", "")))
		if cid == "char_lin_ruisheng" or fixed.has(cid):
			continue
		var sc := float(e.get("score", 0))
		if sc > best_sc:
			best_sc = sc
			best_id = cid
	if not best_id.is_empty():
		_rival_char = best_id
		return best_id
	for pid in pool:
		var p := String(pid)
		if PackDB.get_row_by_id("def_char", "char_id", p).is_empty():
			continue
		_rival_char = p
		return p
	_rival_char = ""
	return ""


func _tint_rival(card: Control) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.84, 0.78, 0.98)
	sb.border_color = Color(0.78, 0.22, 0.16)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0.55, 0.1, 0.08, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", sb)
	var tag: Label = card.find_child("RivalTag", true, false) as Label
	if tag:
		tag.visible = true
		tag.text = L10n.t("meeting.rival_tag", "劲敌")
	var score_lb: Label = card.find_child("ScoreMark", true, false) as Label
	if score_lb:
		var seat: Dictionary = card.get_meta("seat_def", {})
		var cid := _resolve_seat_char(seat)
		var you := MeetingSystem.ladder_score_of("char_lin_ruisheng")
		var them := MeetingSystem.ladder_score_of(cid)
		var gap := them - you
		if gap > 0.5:
			score_lb.text = L10n.t("meeting.rival_lead", "领先你 %.0f") % gap
			score_lb.add_theme_color_override("font_color", KairoStyle.DANGER)
		elif gap < -0.5:
			score_lb.text = L10n.t("meeting.rival_trail", "落后你 %.0f") % (-gap)
			score_lb.add_theme_color_override("font_color", KairoStyle.GOOD_INK)
		else:
			score_lb.text = L10n.t("meeting.rival_neck", "咬得很紧")
			score_lb.add_theme_color_override("font_color", KairoStyle.ACCENT_INK)
		score_lb.visible = true
	var plate: Control = card.find_child("Plate", true, false) as Control
	_set_plate_tone(plate, Color(0.72, 0.36, 0.28))


func _on_ceremony_finished(payload: Dictionary) -> void:
	_dim_seats_for_ceremony(false)
	_ceremony_dimmed = false
	## 升职后：旁听位 → 列席位
	var new_r := String(payload.get("new_rank", ""))
	if _pending_seat_move or (not new_r.is_empty() and new_r != "apprentice"):
		_pending_seat_move = false
		## tier 可能已由 effect 改写；强制刷新机位
		_listen_mode = String(RunState.meeting.get("attendance_tier", "listen")) == "listen"
		if not _listen_mode or new_r in ["waichang", "paojie", "houtang"]:
			_animate_promo_seat_move()
		else:
			_refresh_seats()
	else:
		_refresh_seats()


func _animate_promo_seat_move() -> void:
	## 从门外旁听席动画挪到堂内玩家席（站位即爽点）。
	var from_card: Control = _seat_nodes.get("seat_listen") as Control
	var to_card: Control = _seat_nodes.get("seat_player") as Control
	if to_card == null:
		_refresh_seats()
		return
	_listen_mode = false
	curtain.visible = false
	if listen_badge:
		listen_badge.visible = false
	if from_card:
		from_card.visible = true
		_paint_seat(from_card, "char_lin_ruisheng", true, true, false)
	to_card.visible = true
	var target: Vector2 = _home_positions.get("seat_player", to_card.position)
	var start: Vector2 = _home_positions.get("seat_listen", from_card.position if from_card else target)
	## 用玩家席卡做挪位主体
	to_card.position = start
	_paint_seat(to_card, "char_lin_ruisheng", true, true, false)
	to_card.modulate = Color(1.15, 1.1, 0.9, 1.0)
	if from_card:
		from_card.modulate.a = 0.4
	var tw := create_tween()
	tw.tween_property(to_card, "position", target, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if from_card:
		tw.parallel().tween_property(from_card, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		if from_card:
			from_card.visible = false
		_refresh_seats()
		_pulse_card(to_card)
		if focus_ring:
			focus_ring.visible = true
			focus_name.text = L10n.t("meeting.seat_promoted", "列席 · %s") % KairoStyle.nameplate("char_lin_ruisheng")
	)


func _play_cutoff_shake(speaker: String = "char_qian_demao") -> void:
	## 东家「够了」：全席一震，上首放大。
	_set_segment("council")
	if _audio and _audio.has_method("play_cue"):
		_audio.play_cue("cut")
	_set_focus(speaker if not speaker.is_empty() else "char_qian_demao", false)
	var master: Control = _seat_nodes.get("seat_master") as Control
	if master:
		master.z_index = 8
		var mood: Label = master.find_child("MoodMark", true, false) as Label
		if mood:
			mood.set_meta("cutoff", true)
			_apply_mood(mood, true, false, "char_qian_demao")
		var base_sc := master.scale
		var twm := create_tween()
		twm.tween_property(master, "scale", base_sc * 1.22, 0.12)
		twm.tween_property(master, "scale", base_sc, 0.2)
	var origin := root.position
	var tw := create_tween()
	for i in range(5):
		var ox := 6.0 if i % 2 == 0 else -6.0
		var oy := -3.0 if i % 2 == 0 else 3.0
		tw.tween_property(root, "position", origin + Vector2(ox, oy), 0.04)
	tw.tween_property(root, "position", origin, 0.06)
	## 他席熄半格
	for sid in _seat_nodes.keys():
		if sid == "seat_master":
			continue
		var card: Control = _seat_nodes[sid]
		card.modulate = Color(0.5, 0.48, 0.45, 0.7)


func _nudge_zian_seat() -> void:
	var card: Control = _seat_nodes.get("seat_zian") as Control
	if card == null or not card.visible:
		return
	var home: Vector2 = _home_positions.get("seat_zian", card.position)
	var tw := create_tween()
	tw.tween_property(card, "position", home + Vector2(10, -4), 0.15)
	tw.tween_interval(0.35) ## 故意多停半拍
	tw.tween_property(card, "position", home, 0.2)


func _pulse_curtain() -> void:
	## 门外旁听：帘影晃一下，暗示「听见自己的名字 / 关键句」。
	if curtain == null or not _listen_mode:
		return
	curtain.visible = true
	if listen_badge:
		listen_badge.visible = true
	var base_a := 1.0
	curtain.modulate = Color(1, 1, 1, base_a)
	var tw := create_tween()
	tw.tween_property(curtain, "modulate:a", 0.72, 0.12)
	tw.tween_property(curtain, "modulate:a", base_a, 0.28)
	## 门外听席也亮一下
	var listen_card: Control = _seat_nodes.get("seat_listen") as Control
	if listen_card and listen_card.visible:
		_pulse_card(listen_card)
