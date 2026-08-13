extends Control
## 开罗风对话气泡：头像/姓名用按钮点击，可靠打开档案。

signal continue_pressed
signal choice_selected(choice: Dictionary)
signal speaker_clicked(char_id: String)

@onready var root_panel: PanelContainer = %DialogRoot
@onready var accent: ColorRect = %Accent
@onready var portrait_plate: ColorRect = %PortraitPlate
@onready var portrait_tex: TextureRect = %PortraitTex
@onready var portrait_glyph: Label = %PortraitGlyph
@onready var portrait_hit: Button = %PortraitHit
@onready var speaker_btn: Button = %SpeakerBtn
@onready var stage_tag: Label = %StageTag
@onready var body: RichTextLabel = %Body
@onready var choice_row: VBoxContainer = %ChoiceRow

const SPEAKER_COLORS := {
	"narrator": Color(0.55, 0.5, 0.42),
	"char_qian_demao": Color(0.78, 0.42, 0.28),
	"char_qian_zian": Color(0.65, 0.35, 0.55),
	"char_liu_ruyan": Color(0.72, 0.45, 0.62),
	"char_lin_ruisheng": Color(0.4, 0.55, 0.68),
	"char_bradley": Color(0.35, 0.45, 0.7),
	"char_zhao_hongyun": Color(0.75, 0.55, 0.28),
	"char_wang_pangzi": Color(0.7, 0.5, 0.32),
	"char_zhou_guanshi": Color(0.55, 0.5, 0.4),
	"char_qing_daren": Color(0.6, 0.3, 0.35),
	"char_msg_broker": Color(0.6, 0.48, 0.35),
	"char_bank_clerk": Color(0.4, 0.55, 0.5),
	"char_firm_hand": Color(0.55, 0.45, 0.35),
}

var _tween: Tween
var _current_speaker: String = ""


func _ready() -> void:
	KairoStyle.style_bubble(root_panel)
	KairoStyle.style_readable_rich(body, 18, 20)
	KairoStyle.style_readable_label(stage_tag, 16, true)
	portrait_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_hit_button(portrait_hit)
	_style_speaker_button(speaker_btn)
	portrait_hit.pressed.connect(_emit_speaker_click)
	speaker_btn.pressed.connect(_emit_speaker_click)


func _style_hit_button(btn: Button) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)


func _style_speaker_button(btn: Button) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_color_override("font_color", KairoStyle.INK)
	btn.add_theme_color_override("font_hover_color", KairoStyle.ACCENT_INK)
	btn.add_theme_color_override("font_pressed_color", KairoStyle.WOOD_DARK)
	btn.add_theme_font_size_override("font_size", 20)
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)


func _emit_speaker_click() -> void:
	if _current_speaker.is_empty() or _current_speaker == "narrator":
		return
	speaker_clicked.emit(_current_speaker)


func clear_choices() -> void:
	## 先移出树再 queue_free：立刻不可点，又避免在信号栈里 free 锁死对象。
	while choice_row.get_child_count() > 0:
		var c: Node = choice_row.get_child(0)
		choice_row.remove_child(c)
		c.queue_free()


func present_node(node: Dictionary) -> void:
	visible = true
	z_index = 40
	move_to_front()
	var speaker_id := String(node.get("speaker", "narrator"))
	_current_speaker = speaker_id
	var text_body := L10n.t(String(node.get("loc_key", "")), String(node.get("dialog_id", "")))
	var tags: Array = node.get("tags", [])
	_set_speaker_caption(speaker_id)
	_apply_style(speaker_id, tags)
	## 旁听朝账 / 升职称呼拍：keyword_highlight，或 listen 机位 meeting，或 rank_address
	var want_kw := tags.has("keyword_highlight") or tags.has("rank_address")
	if not want_kw and tags.has("meeting"):
		var tier := String(RunState.meeting.get("attendance_tier", ""))
		if tier == "listen":
			want_kw = true
	if want_kw:
		text_body = _apply_keyword_highlight(text_body, node)
	if tags.has("flashback"):
		stage_tag.text = L10n.t("ui.flashback", "【闪回】")
		body.text = "[i]%s[/i]" % text_body
	elif tags.has("rank_address"):
		stage_tag.text = L10n.t("ui.tag_address", "称呼")
		body.text = text_body
	elif tags.has("failure"):
		stage_tag.text = L10n.t("ui.tag_failure", "风波")
		body.text = text_body
	elif tags.has("ending"):
		stage_tag.text = L10n.t("ui.tag_ending", "结局")
		body.text = text_body
	elif tags.has("random"):
		stage_tag.text = L10n.t("ui.tag_random", "街市风声")
		body.text = text_body
	elif tags.has("meeting") and tags.has("council"):
		stage_tag.text = L10n.t("ui.tag_council", "建言")
		body.text = text_body
	elif tags.has("meeting"):
		stage_tag.text = L10n.t("ui.tag_meeting", "朝账")
		body.text = text_body
	elif speaker_id == "narrator":
		stage_tag.text = ""
		body.text = "[i]%s[/i]" % text_body
	else:
		stage_tag.text = KairoStyle.rank_label_for(speaker_id)
		body.text = text_body
	clear_choices()
	_fade_in()


func _address_keywords() -> Array:
	## 长词在前，避免「林跑街」被「跑街」拆坏（占位替换时再排序一次）
	return [
		L10n.t("promo.address.jufeng_paojie", "聚丰的林跑街"),
		L10n.t("promo.address.waichang", "林外场"),
		L10n.t("promo.address.paojie", "林跑街"),
		L10n.t("promo.address.foreign", "林朋友"),
		L10n.t("promo.address.houtang", "林先生"),
		"林外场", "林跑街", "林朋友", "林先生", "聚丰的林跑街",
	]


func _default_meeting_keywords() -> Array:
	return ["跑街", "满师", "特别货", "货单", "聚丰", "外场", "学徒", "后院", "差事", "月例"]


func _keyword_list_for(node: Dictionary) -> Array:
	var words: Array = []
	var stage_v: Variant = node.get("stage", {})
	if typeof(stage_v) == TYPE_DICTIONARY:
		var kw: Variant = (stage_v as Dictionary).get("keywords", [])
		if typeof(kw) == TYPE_ARRAY:
			words = (kw as Array).duplicate()
	var tags: Array = node.get("tags", [])
	if tags.has("rank_address") or tags.has("rank_up") or tags.has("ending"):
		for w in _address_keywords():
			if not words.has(w):
				words.append(w)
	if words.is_empty():
		var raw: Variant = PackDB.tables.get("def_meeting_stage", {})
		if typeof(raw) == TYPE_DICTIONARY:
			var dk: Variant = (raw as Dictionary).get("default_keywords", [])
			if typeof(dk) == TYPE_ARRAY:
				words = (dk as Array).duplicate()
	if words.is_empty():
		words = _default_meeting_keywords()
	## 升职相关对白始终并入称呼词
	if tags.has("keyword_highlight") and (tags.has("rank_up") or tags.has("reckoning") or tags.has("ending")):
		for w in _address_keywords():
			if not words.has(w):
				words.append(w)
	return words


func _apply_keyword_highlight(text: String, node: Dictionary) -> String:
	## BBCode 高亮关键字；长词优先占位，防止短词拆坏长称呼。
	var words: Array = _keyword_list_for(node)
	words.sort_custom(func(a, b): return String(a).length() > String(b).length())
	var out := text
	var placeholders: Dictionary = {}
	var i := 0
	for w in words:
		var word := String(w)
		if word.is_empty() or not out.contains(word):
			continue
		## 已是占位/已高亮则跳过
		var already := "[color=#7a3214][b]%s[/b][/color]" % word
		if out.contains(already):
			continue
		var ph := "§KW%d§" % i
		i += 1
		placeholders[ph] = already
		out = out.replace(word, ph)
	for ph in placeholders.keys():
		out = out.replace(String(ph), String(placeholders[ph]))
	return out


func show_continue_button() -> void:
	clear_choices()
	var btn := Button.new()
	btn.text = L10n.t("ui.continue_hint", "继续（空格）")
	KairoStyle.style_button(btn, true)
	btn.pressed.connect(func(): continue_pressed.emit())
	choice_row.add_child(btn)


func show_choices(choices: Array) -> void:
	clear_choices()
	for ch in choices:
		if typeof(ch) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = ch
		var b := Button.new()
		var label_key := String(c.get("loc_key", ""))
		var cid := String(c.get("id", c.get("choice_id", "…")))
		b.text = "%s. %s" % [cid, L10n.t(label_key, cid)]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		KairoStyle.style_button(b)
		b.pressed.connect(func(): choice_selected.emit(c))
		choice_row.add_child(b)


func show_pending_event(event_id: String) -> void:
	visible = true
	_current_speaker = "narrator"
	_set_speaker_caption("narrator")
	speaker_btn.text = L10n.t("ui.event_pending", "有事件待处理")
	stage_tag.text = event_id
	body.text = L10n.t("ui.event_pending_hint", "点击下方按钮继续。")
	_apply_style("narrator", [])
	clear_choices()
	var btn := Button.new()
	btn.text = L10n.t("ui.resolve_event", "处理事件")
	KairoStyle.style_button(btn, true)
	btn.pressed.connect(func(): continue_pressed.emit())
	choice_row.add_child(btn)


func _set_speaker_caption(speaker_id: String) -> void:
	var plate := _speaker_plate(speaker_id)
	var clickable := not speaker_id.is_empty() and speaker_id != "narrator"
	portrait_hit.disabled = not clickable
	speaker_btn.disabled = not clickable
	if clickable:
		speaker_btn.text = "%s · %s" % [plate, L10n.t("ui.click_dossier", "（点击查看）")]
		var tip := L10n.t("ui.dossier_hint", "点击打开档案：%s") % plate
		portrait_hit.tooltip_text = tip
		speaker_btn.tooltip_text = tip
	else:
		speaker_btn.text = plate
		portrait_hit.tooltip_text = ""
		speaker_btn.tooltip_text = ""


func _speaker_plate(speaker_id: String) -> String:
	if speaker_id.is_empty() or speaker_id == "narrator":
		return L10n.t("char.narrator", "旁白")
	return KairoStyle.nameplate(speaker_id)


func _speaker_name(speaker_id: String) -> String:
	if speaker_id.is_empty() or speaker_id == "narrator":
		return L10n.t("char.narrator", "旁白")
	return L10n.t(speaker_id, speaker_id)


func _apply_style(speaker_id: String, tags: Array) -> void:
	var col: Color = SPEAKER_COLORS.get(speaker_id, Color(0.62, 0.55, 0.42))
	if tags.has("flashback"):
		col = Color(0.55, 0.5, 0.7)
	elif tags.has("failure"):
		col = Color(0.75, 0.32, 0.28)
	elif tags.has("ending"):
		col = Color(0.75, 0.6, 0.28)
	portrait_plate.color = col.lightened(0.35)
	accent.color = col
	var spath := "res://art/sprites/anchao/%s.png" % speaker_id
	var ppath := "res://art/portraits/anchao/%s.png" % speaker_id
	if ResourceLoader.exists(spath):
		portrait_tex.texture = load(spath) as Texture2D
		portrait_tex.visible = true
		portrait_glyph.visible = false
	elif ResourceLoader.exists(ppath):
		portrait_tex.texture = load(ppath) as Texture2D
		portrait_tex.visible = true
		portrait_glyph.visible = false
	else:
		portrait_tex.texture = null
		portrait_tex.visible = false
		portrait_glyph.visible = true
		var name := _speaker_name(speaker_id)
		portrait_glyph.text = name.substr(0, 1) if not name.is_empty() else "·"
		portrait_glyph.add_theme_color_override("font_color", col.darkened(0.2))


func _fade_in() -> void:
	body.modulate.a = 0.0
	portrait_plate.modulate.a = 0.5
	root_panel.scale = Vector2(0.96, 0.96)
	root_panel.pivot_offset = root_panel.size * 0.5
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(body, "modulate:a", 1.0, 0.2)
	_tween.tween_property(portrait_plate, "modulate:a", 1.0, 0.25)
	_tween.tween_property(root_panel, "scale", Vector2.ONE, 0.18)
