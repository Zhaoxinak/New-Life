extends Node
## 本地化。文案只走 loc_key；存档不存显示名。

var _strings: Dictionary = {}
var locale: String = "zh_CN"


func _ready() -> void:
	if not PackDB.pack_loaded.is_connected(_on_pack_loaded):
		PackDB.pack_loaded.connect(_on_pack_loaded)
	if PackDB.loaded:
		_reload_from_pack()


func _on_pack_loaded(_pack_id: String) -> void:
	_reload_from_pack()


func _reload_from_pack() -> void:
	var l10n: Dictionary = PackDB.get_table_dict("def_loc_string")
	var by_locale: Variant = l10n.get(locale, l10n.get("zh_CN", {}))
	if typeof(by_locale) == TYPE_DICTIONARY:
		_strings = by_locale
	else:
		_strings = {}


func t(key: String, fallback: String = "") -> String:
	if key.is_empty():
		return fallback
	if _strings.has(key):
		return String(_strings[key])
	if not fallback.is_empty():
		return fallback
	return key
