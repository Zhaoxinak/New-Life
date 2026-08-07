extends Node
## Loads core pack CSV tables into memory.
## Dev: reads ../docs/tables/packs (sibling of game/).
## Optional: res://data/packs if present (export / local copy).

signal pack_loaded(pack_id: String)

const CORE_ID := "core"
## Tables that are folders / non-CSV at root — skip or special-case.
const SKIP_TABLES: PackedStringArray = ["l10n"]

var pack_meta: Dictionary = {}
var tables: Dictionary = {} # table_name -> Array[Dictionary]
var indexes: Dictionary = {} # table_name -> { id -> row }
var effects_by_owner: Dictionary = {} # "owner_type|owner_id" -> Array[Dictionary]
var conditions_by_owner: Dictionary = {} # "owner_type|owner_id" -> Array[Dictionary]
var check_mods_by_check: Dictionary = {} # check_id -> Array[Dictionary]
var actions_by_hotspot: Dictionary = {} # hotspot_id -> Array[Dictionary]
var hotspots_by_location: Dictionary = {} # location_id -> Array[Dictionary]
var unlocks_by_day: Dictionary = {} # day:int -> Array[Dictionary]
var lines_by_dialogue: Dictionary = {} # dialogue_id -> Array[Dictionary]
var choices_by_dialogue: Dictionary = {} # dialogue_id -> Array[Dictionary]
var variants_by_line: Dictionary = {} # base_line_id -> Array[Dictionary]
var event_choices_by_event: Dictionary = {} # event_id -> Array[Dictionary]
var stock_config: Dictionary = {} # key -> value string
var stock_rules_by_action: Dictionary = {} # action_id -> Array[Dictionary]
var stock_rules_by_phase: Dictionary = {} # when_phase -> Array[Dictionary]
var packs_root_abs: String = ""
var loaded: bool = false


func _ready() -> void:
	load_core()


func resolve_packs_root() -> String:
	## Prefer repo docs (dev). Fall back to bundled res://data/packs (export).
	var game_root := ProjectSettings.globalize_path("res://")
	var docs_packs := game_root.path_join("../docs/tables/packs").simplify_path()
	if FileAccess.file_exists(docs_packs.path_join("core/pack.json")):
		return docs_packs
	var bundled := ProjectSettings.globalize_path("res://data/packs")
	if FileAccess.file_exists(bundled.path_join("core/pack.json")):
		return bundled
	push_error("PackDB: cannot find packs (tried %s and %s)" % [docs_packs, bundled])
	return docs_packs


func load_core() -> void:
	load_pack(CORE_ID)


func load_pack(pack_id: String) -> void:
	packs_root_abs = resolve_packs_root()
	var pack_dir := packs_root_abs.path_join(pack_id)
	var meta_path := pack_dir.path_join("pack.json")
	if not FileAccess.file_exists(meta_path):
		push_error("PackDB: pack.json not found at %s" % meta_path)
		return
	var meta_file := FileAccess.open(meta_path, FileAccess.READ)
	var meta_text := meta_file.get_as_text()
	meta_file.close()
	var parsed: Variant = JSON.parse_string(meta_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("PackDB: invalid pack.json")
		return
	pack_meta = parsed
	tables.clear()
	indexes.clear()
	effects_by_owner.clear()
	conditions_by_owner.clear()
	check_mods_by_check.clear()
	actions_by_hotspot.clear()
	hotspots_by_location.clear()
	unlocks_by_day.clear()
	lines_by_dialogue.clear()
	choices_by_dialogue.clear()
	variants_by_line.clear()
	event_choices_by_event.clear()
	stock_config.clear()
	stock_rules_by_action.clear()
	stock_rules_by_phase.clear()

	var table_list: Array = pack_meta.get("tables", [])
	for table_name_v in table_list:
		var table_name := str(table_name_v)
		if table_name in SKIP_TABLES:
			continue
		var path := pack_dir.path_join("%s.csv" % table_name)
		if not FileAccess.file_exists(path):
			push_warning("PackDB: missing table file %s" % path)
			tables[table_name] = [] as Array[Dictionary]
			continue
		var rows: Array[Dictionary] = CsvUtil.load_table(path)
		tables[table_name] = rows
		_index_table(table_name, rows)
		print("PackDB: loaded %s (%d rows)" % [table_name, rows.size()])

	_build_secondary_indexes()
	loaded = true
	pack_loaded.emit(pack_id)
	print("PackDB: pack '%s' ready (schema %s · v%s) tables=%d root=%s" % [
		str(pack_meta.get("id", pack_id)),
		str(pack_meta.get("schema_version", "?")),
		str(pack_meta.get("version", "?")),
		tables.size(),
		packs_root_abs,
	])


func _index_table(table_name: String, rows: Array) -> void:
	var by_id: Dictionary = {}
	for row in rows:
		if row.has("id") and str(row["id"]) != "":
			by_id[str(row["id"])] = row
	indexes[table_name] = by_id


func _build_secondary_indexes() -> void:
	for row in tables.get("effects", []):
		var ek := "%s|%s" % [str(row.get("owner_type", "")), str(row.get("owner_id", ""))]
		if not effects_by_owner.has(ek):
			effects_by_owner[ek] = []
		effects_by_owner[ek].append(row)

	for row in tables.get("conditions", []):
		var ck := "%s|%s" % [str(row.get("owner_type", "")), str(row.get("owner_id", ""))]
		if not conditions_by_owner.has(ck):
			conditions_by_owner[ck] = []
		conditions_by_owner[ck].append(row)

	for row in tables.get("check_mods", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var cid := str(row.get("check_id", ""))
		if not check_mods_by_check.has(cid):
			check_mods_by_check[cid] = []
		check_mods_by_check[cid].append(row)

	for row in tables.get("actions", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var hid := str(row.get("hotspot_id", ""))
		if not actions_by_hotspot.has(hid):
			actions_by_hotspot[hid] = []
		actions_by_hotspot[hid].append(row)
	for hid in actions_by_hotspot.keys():
		actions_by_hotspot[hid].sort_custom(func(a, b): return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))

	for row in tables.get("hotspots", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var lid := str(row.get("location_id", ""))
		if not hotspots_by_location.has(lid):
			hotspots_by_location[lid] = []
		hotspots_by_location[lid].append(row)
	for lid in hotspots_by_location.keys():
		hotspots_by_location[lid].sort_custom(func(a, b): return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))

	for row in tables.get("unlock_schedule", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var d := int(row.get("day", 0))
		if not unlocks_by_day.has(d):
			unlocks_by_day[d] = []
		unlocks_by_day[d].append(row)

	for row in tables.get("dialogue_lines", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var did := str(row.get("dialogue_id", ""))
		if not lines_by_dialogue.has(did):
			lines_by_dialogue[did] = []
		lines_by_dialogue[did].append(row)
	for did in lines_by_dialogue.keys():
		lines_by_dialogue[did].sort_custom(func(a, b): return int(a.get("sort", 0)) < int(b.get("sort", 0)))

	for row in tables.get("dialogue_choices", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var did2 := str(row.get("dialogue_id", ""))
		if not choices_by_dialogue.has(did2):
			choices_by_dialogue[did2] = []
		choices_by_dialogue[did2].append(row)
	for did2 in choices_by_dialogue.keys():
		choices_by_dialogue[did2].sort_custom(func(a, b): return int(a.get("sort", 0)) < int(b.get("sort", 0)))

	for row in tables.get("dialogue_line_variants", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var lid := str(row.get("base_line_id", ""))
		if not variants_by_line.has(lid):
			variants_by_line[lid] = []
		variants_by_line[lid].append(row)
	for lid in variants_by_line.keys():
		variants_by_line[lid].sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))

	for row in tables.get("event_choices", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var eid := str(row.get("event_id", ""))
		if not event_choices_by_event.has(eid):
			event_choices_by_event[eid] = []
		event_choices_by_event[eid].append(row)
	for eid in event_choices_by_event.keys():
		event_choices_by_event[eid].sort_custom(func(a, b): return int(a.get("sort", 0)) < int(b.get("sort", 0)))

	for row in tables.get("stock_config", []):
		stock_config[str(row.get("key", ""))] = str(row.get("value", ""))

	for row in tables.get("stock_rules", []):
		if str(row.get("enabled", "1")) == "0":
			continue
		var phase := str(row.get("when_phase", ""))
		if not stock_rules_by_phase.has(phase):
			stock_rules_by_phase[phase] = []
		stock_rules_by_phase[phase].append(row)
		var aid := str(row.get("action_id", "")).strip_edges()
		if aid != "":
			if not stock_rules_by_action.has(aid):
				stock_rules_by_action[aid] = []
			stock_rules_by_action[aid].append(row)


func get_dialogue_lines(dialogue_id: String) -> Array:
	return lines_by_dialogue.get(dialogue_id, [])


func get_dialogue_choices(dialogue_id: String) -> Array:
	return choices_by_dialogue.get(dialogue_id, [])


func get_line_variants(base_line_id: String) -> Array:
	return variants_by_line.get(base_line_id, [])


func get_event_choices(event_id: String) -> Array:
	return event_choices_by_event.get(event_id, [])


func get_stock_config(key: String, default_value: float = 0.0) -> float:
	if not stock_config.has(key):
		return default_value
	return float(stock_config[key])


func get_stock_rules_for_action(action_id: String) -> Array:
	return stock_rules_by_action.get(action_id, [])


func get_stock_rules_for_phase(phase: String) -> Array:
	return stock_rules_by_phase.get(phase, [])


func get_row(table_name: String, id: String) -> Dictionary:
	var by_id: Dictionary = indexes.get(table_name, {})
	return by_id.get(id, {})


func get_table(table_name: String) -> Array:
	return tables.get(table_name, [])


func get_effects(owner_type: String, owner_id: String) -> Array:
	return effects_by_owner.get("%s|%s" % [owner_type, owner_id], [])


func get_conditions(owner_type: String, owner_id: String) -> Array:
	return conditions_by_owner.get("%s|%s" % [owner_type, owner_id], [])


func get_check_mods(check_id: String) -> Array:
	return check_mods_by_check.get(check_id, [])


func get_hotspots_for_location(location_id: String) -> Array:
	return hotspots_by_location.get(location_id, [])


func get_actions_for_hotspot(hotspot_id: String) -> Array:
	return actions_by_hotspot.get(hotspot_id, [])


func get_unlocks_for_day(day: int) -> Array:
	return unlocks_by_day.get(day, [])


func get_enabled_locations() -> Array:
	var out: Array = []
	for row in tables.get("locations", []):
		if str(row.get("enabled", "1")) != "0":
			out.append(row)
	out.sort_custom(func(a, b): return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))
	return out


func l10n_path(locale: String) -> String:
	var pack_id := str(pack_meta.get("id", CORE_ID))
	return packs_root_abs.path_join(pack_id).path_join("l10n").path_join("%s.csv" % locale)
