extends Node
## 开罗风配色与控件皮肤（Autoload）。

const CREAM := Color(1.0, 0.96, 0.88)
const PANEL := Color(1.0, 0.94, 0.82)
const WOOD := Color(0.72, 0.48, 0.28)
const WOOD_DARK := Color(0.48, 0.32, 0.18)
const SKY := Color(0.62, 0.78, 0.92)
const COIN := Color(1.0, 0.82, 0.28)
const INK := Color(0.22, 0.16, 0.12)
const SOFT_INK := Color(0.42, 0.34, 0.28)
const ACCENT := Color(0.86, 0.42, 0.28)
const GOOD := Color(0.35, 0.62, 0.38)

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
	btn.add_theme_color_override("font_pressed_color", ACCENT)
	btn.add_theme_font_size_override("font_size", 18 if big else 15)
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


static func rank_label_for(char_id: String) -> String:
	if char_id.is_empty() or char_id == "narrator":
		return ""
	## 场上/对话铭牌：玩家标「本人」，职级只在 HUD / 本档里看
	if char_id == "char_lin_ruisheng":
		return L10n.t("ui.self", "本人")
	var row: Dictionary = PackDB.get_row_by_id("def_char", "char_id", char_id)
	return String(row.get("rank_label", ""))


static func nameplate(char_id: String) -> String:
	if char_id == "char_lin_ruisheng":
		return L10n.t("ui.you_self", "你〔本人〕")
	var name := L10n.t(char_id, char_id) if char_id != "narrator" else L10n.t("char.narrator", "旁白")
	if char_id.is_empty() or char_id == "narrator":
		return name
	var rank := rank_label_for(char_id)
	if rank.is_empty():
		return name
	return "%s〔%s〕" % [name, rank]
