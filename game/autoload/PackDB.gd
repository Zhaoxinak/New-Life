extends Node
## 定义库加载器。只读 packs；永不写 run_*。

signal pack_loaded(pack_id: String)

const DEFAULT_PACK_ID := "anchao"
const SCHEMA_VERSION := "0.1"

var pack_id: String = ""
var pack_meta: Dictionary = {}
## table_name -> Array[Dictionary] 或 Dictionary（l10n / registry）
var tables: Dictionary = {}
var loaded: bool = false


func _ready() -> void:
	load_pack(DEFAULT_PACK_ID)


func packs_root() -> String:
	return "res://packs"


func load_pack(id: String) -> bool:
	var pack_dir := packs_root().path_join(id)
	var meta_path := pack_dir.path_join("pack.json")
	if not FileAccess.file_exists(meta_path):
		push_error("PackDB: missing %s" % meta_path)
		loaded = false
		return false

	var meta := _read_json(meta_path)
	if meta.is_empty():
		push_error("PackDB: invalid pack.json")
		loaded = false
		return false

	pack_id = id
	pack_meta = meta
	tables.clear()

	var table_files: Array = meta.get("tables", [])
	for entry in table_files:
		var table_name: String = String(entry.get("name", ""))
		var rel: String = String(entry.get("file", ""))
		if table_name.is_empty() or rel.is_empty():
			continue
		var path := pack_dir.path_join(rel)
		var data: Variant = _read_json_variant(path)
		tables[table_name] = data

	loaded = true
	pack_loaded.emit(id)
	print("PackDB: loaded pack=%s schema=%s tables=%s" % [
		id, meta.get("schema_version", "?"), ",".join(tables.keys())
	])
	return true


func get_rows(table_name: String) -> Array:
	var data: Variant = tables.get(table_name, [])
	if typeof(data) == TYPE_ARRAY:
		return data
	if typeof(data) == TYPE_DICTIONARY:
		var rows: Array = data.get("rows", [])
		if rows is Array:
			return rows
	return []


func get_row_by_id(table_name: String, id_key: String, id_value: String) -> Dictionary:
	for row in get_rows(table_name):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if String(row.get(id_key, "")) == id_value:
			return row
	return {}


func get_table_dict(table_name: String) -> Dictionary:
	var data: Variant = tables.get(table_name, {})
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}


func content_version() -> String:
	return String(pack_meta.get("content_version", "0.0.0"))


func _read_json(path: String) -> Dictionary:
	var v: Variant = _read_json_variant(path)
	if typeof(v) == TYPE_DICTIONARY:
		return v as Dictionary
	return {}


func _read_json_variant(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("PackDB: file not found %s" % path)
		return null
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("PackDB: cannot open %s" % path)
		return null
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("PackDB: JSON parse failed %s" % path)
	return parsed
