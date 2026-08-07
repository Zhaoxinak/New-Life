class_name UiStyle
extends RefCounted
## Stardew-inspired cozy harbor visual tokens.


const BG := Color("1a2430")
const BG_PANEL := Color("3d2a1c")
const BG_PANEL_2 := Color("4a3424")
const BRASS := Color("e8c56b")
const WOOD := Color("6b4226")
const WOOD_LIGHT := Color("8a5a32")
const PARCHMENT := Color("f3e6c8")
const PARCHMENT_DIM := Color("d9c7a0")
const FOG := Color("a8b8c4")
const DANGER := Color("c45c4a")
const OK := Color("6aa84f")
const TEXT := Color("3a2a1c")
const TEXT_ON_DARK := Color("f3e6c8")
const TEXT_DIM := Color("9a8060")
const SKY := Color("7eb6d9")
const GRASS := Color("5a8f4a")

const LOCATION_TINT := {
	"dock": Color("1a3048"),
	"company": Color("3a2a1c"),
	"home": Color("2a2838"),
	"rival": Color("1a3830"),
	"exchange": Color("3a3020"),
}

const LOCATION_PALETTE := {
	"dock": [Color("0a1524"), Color("1a3048"), Color("0e1a22"), Color("e8c56b"), Color("1a4058")],
	"company": [Color("1a1410"), Color("3a2a1c"), Color("12100c"), Color("d4a060"), Color("2a2018")],
	"home": [Color("101828"), Color("243048"), Color("141820"), Color("8fa3b5"), Color("1c2838")],
	"rival": [Color("081810"), Color("143028"), Color("0c1410"), Color("5a9a7a"), Color("102820")],
	"exchange": [Color("181410"), Color("3a3020"), Color("14100c"), Color("e0c070"), Color("2a2418")],
}

const PORTRAIT := {
	"player": Color("3d5a73"),
	"zhou_hongye": Color("5a4030"),
	"zhou_shaoting": Color("6b4e3d"),
	"su_qing": Color("4a5568"),
	"chen_manager": Color("2f4f45"),
	"narrator": Color("2a3340"),
}


static func location_color(location_id: String) -> Color:
	return LOCATION_TINT.get(location_id, BG_PANEL)


static func location_palette(location_id: String) -> Array:
	return LOCATION_PALETTE.get(location_id, LOCATION_PALETTE["dock"])


static func portrait_color(speaker_id: String) -> Color:
	if PORTRAIT.has(speaker_id):
		return PORTRAIT[speaker_id]
	var h := float(absi(speaker_id.hash()) % 360)
	return Color.from_hsv(h / 360.0, 0.35, 0.35)


static func location_texture(location_id: String) -> Texture2D:
	var path := "res://art/locations/%s.png" % location_id
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func portrait_texture(portrait_key: String) -> Texture2D:
	if portrait_key.strip_edges() == "":
		return null
	var path := "res://art/portraits/%s.png" % portrait_key
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func ui_texture(name: String) -> Texture2D:
	var path := "res://art/ui/%s.png" % name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func portrait_key_for_speaker(speaker_id: String) -> String:
	var row: Dictionary = PackDB.get_row("npcs", speaker_id)
	if row.is_empty():
		return ""
	return str(row.get("portrait_key", "")).strip_edges()


static func make_wood_style(bg: Color = Color("3d2a1c"), border: Color = Color("e8c56b")) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 6
	return s


static func make_parchment_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PARCHMENT
	s.border_color = WOOD
	s.set_border_width_all(3)
	s.set_corner_radius_all(8)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.3)
	s.shadow_size = 8
	return s


static func make_button_style(normal: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if normal:
		s.bg_color = Color("6b4226")
		s.border_color = Color("e8c56b")
	else:
		s.bg_color = Color("8a5a32")
		s.border_color = Color("ffe08a")
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func apply_cozy_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", make_button_style(true))
	btn.add_theme_stylebox_override("hover", make_button_style(false))
	btn.add_theme_stylebox_override("pressed", make_button_style(false))
	btn.add_theme_stylebox_override("disabled", make_wood_style(Color("2a1c14"), Color("6a5638")))
	btn.add_theme_color_override("font_color", TEXT_ON_DARK)
	btn.add_theme_color_override("font_hover_color", Color("fff4d0"))
	btn.add_theme_color_override("font_pressed_color", BRASS)
	btn.add_theme_color_override("font_disabled_color", TEXT_DIM)
