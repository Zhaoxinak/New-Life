extends Node
## Localization. Keys live in packs/*/l10n/{locale}.csv

signal locale_changed(locale: String)

var locale: String = "zh_CN"
var _strings: Dictionary = {} # key -> text


func _ready() -> void:
	if not PackDB.pack_loaded.is_connected(_on_pack_loaded):
		PackDB.pack_loaded.connect(_on_pack_loaded)
	if PackDB.loaded:
		_reload()


func _on_pack_loaded(_pack_id: String) -> void:
	_reload()


func set_locale(new_locale: String) -> void:
	if new_locale == locale and not _strings.is_empty():
		return
	locale = new_locale
	_reload()
	locale_changed.emit(locale)


func _reload() -> void:
	_strings.clear()
	if PackDB.packs_root_abs.is_empty():
		return
	var path := PackDB.l10n_path(locale)
	var rows: Array[Dictionary] = CsvUtil.load_table(path)
	for row in rows:
		var key := str(row.get("key", ""))
		if key.is_empty():
			continue
		_strings[key] = str(row.get("text", ""))
	print("L10n: %s (%d keys) from %s" % [locale, _strings.size(), path])


func t(key: String, fallback: String = "") -> String:
	if _strings.has(key):
		return str(_strings[key])
	if fallback != "":
		return fallback
	return key


func tf(key: String, fields: Dictionary, fallback: String = "") -> String:
	var text := t(key, fallback)
	for k in fields.keys():
		text = text.replace("{%s}" % str(k), str(fields[k]))
	return text
