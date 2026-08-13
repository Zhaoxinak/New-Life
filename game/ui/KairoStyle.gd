extends Node
## 开罗风配色与控件皮肤（Autoload）。

const CREAM := Color(1.0, 0.96, 0.88)
const PANEL := Color(1.0, 0.94, 0.82)
const WOOD := Color(0.72, 0.48, 0.28)
const WOOD_DARK := Color(0.48, 0.32, 0.18)
const SKY := Color(0.62, 0.78, 0.92)
const COIN := Color(1.0, 0.82, 0.28)
const INK := Color(0.22, 0.16, 0.12)
const SOFT_INK := Color(0.36, 0.28, 0.22) ## 次要字也要够深
const ACCENT := Color(0.86, 0.42, 0.28) ## 边框/点缀；奶油底上勿作正文色
const ACCENT_INK := Color(0.58, 0.24, 0.12) ## 奶油底上的强调字
const GOOD := Color(0.28, 0.52, 0.32)
const GOOD_INK := Color(0.22, 0.42, 0.26)
const DANGER := Color(0.72, 0.22, 0.14)
const READ_MIN := 15 ## 中文可读下限（字号）

## loc_id -> default ambient NPC sprites (char ids)
const LOC_CAST := {
	"loc_01": ["char_qian_demao", "char_zhou_guanshi", "char_lin_ruisheng"],
	"loc_02": ["char_wang_pangzi", "char_firm_hand", "char_lin_ruisheng"],
	"loc_03": ["char_msg_broker", "char_zhao_hongyun", "char_lin_ruisheng"],
	"loc_04": ["char_bank_clerk", "char_lin_ruisheng"],
	"loc_05": ["char_bradley", "char_lin_ruisheng"],
	"loc_06": ["char_liu_ruyan", "char_lin_ruisheng"],
}

## hotspot furniture icons (emoji-like labels for buttons)
const HZ_ICON := {
	"hz_front_hall": "【柜】",
	"hz_front_door": "【门】",
	"hz_yard": "【货】",
	"hz_market": "【市】",
	"hz_bank": "【票】",
	"hz_foreign": "【洋】",
	"hz_cottage": "【屋】",
	"hz_main": "【★】",
}


static func style_button(btn: Button, big: bool = false) -> void:
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", WOOD_DARK)
	btn.add_theme_color_override("font_pressed_color", ACCENT_INK)
	btn.add_theme_font_size_override("font_size", 18 if big else 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = WOOD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = CREAM
	sbh.border_color = ACCENT
	btn.add_theme_stylebox_override("hover", sbh)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(1.0, 0.88, 0.7)
	btn.add_theme_stylebox_override("pressed", sbp)


static func style_panel(panel: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = WOOD
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", sb)


static func style_bubble(panel: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM
	sb.border_color = WOOD_DARK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 8
	panel.add_theme_stylebox_override("panel", sb)


## 奶油底上的正文 Label：深墨 + 足够字号
static func style_readable_label(lb: Label, size: int = 16, emphasize: bool = false) -> void:
	if lb == null:
		return
	lb.add_theme_color_override("font_color", ACCENT_INK if emphasize else INK)
	lb.add_theme_font_size_override("font_size", maxi(READ_MIN, size))


## 奶油底上的 RichText：深墨正文
static func style_readable_rich(rt: RichTextLabel, size: int = 16, bold_size: int = -1) -> void:
	if rt == null:
		return
	rt.add_theme_color_override("default_color", INK)
	rt.add_theme_font_size_override("normal_font_size", maxi(READ_MIN, size))
	rt.add_theme_font_size_override("bold_font_size", maxi(READ_MIN + 1, bold_size if bold_size > 0 else size + 2))
	rt.add_theme_constant_override("line_separation", 6)


## 浅色/强调色字贴在场景上：加奶油描边，避免糊进背景
static func outline_for_light_text(ctrl: Control, outline_size: int = 4) -> void:
	if ctrl == null:
		return
	ctrl.add_theme_color_override("font_outline_color", Color(1.0, 0.95, 0.85, 0.95))
	ctrl.add_theme_constant_override("outline_size", outline_size)


static func rank_label_for(char_id: String) -> String:
	if char_id.is_empty() or char_id == "narrator":
		return ""
	## 玩家铭牌：学徒仍「本人」；升阶后改社交称呼（林外场 / 聚丰的林跑街 / 林朋友）
	if char_id == "char_lin_ruisheng":
		var addr := String(RunState.meta.get("rank_address", ""))
		if addr.is_empty() and Engine.get_main_loop() != null:
			addr = PromotionSystem.address_for()
		if not addr.is_empty() and addr != L10n.t("promo.address.apprentice", "瑞生"):
			return addr
		if RunState.player_rank() != "apprentice":
			return PromotionSystem.address_for(RunState.player_rank())
		return L10n.t("ui.self", "本人")
	var row: Dictionary = PackDB.get_row_by_id("def_char", "char_id", char_id)
	return String(row.get("rank_label", ""))


static func nameplate(char_id: String) -> String:
	if char_id == "char_lin_ruisheng":
		var label := rank_label_for(char_id)
		if label == L10n.t("ui.self", "本人"):
			return L10n.t("ui.you_self", "你〔本人〕")
		return L10n.t("ui.you_address", "你〔%s〕") % label
	var name := L10n.t(char_id, char_id) if char_id != "narrator" else L10n.t("char.narrator", "旁白")
	if char_id.is_empty() or char_id == "narrator":
		return name
	var rank := rank_label_for(char_id)
	if rank.is_empty():
		return name
	return "%s〔%s〕" % [name, rank]
