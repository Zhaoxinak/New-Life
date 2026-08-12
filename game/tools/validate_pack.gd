extends Node
## 校验 packs/anchao：effect op 白名单、引用完整性。
## Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe --headless --path game res://tools/ValidatePack.tscn

const ALLOWED_OPS: PackedStringArray = [
	"add", "set", "add_range",
	"set_flag", "clear_flag",
	"set_rank",
	"unlock_clue", "revoke_clue",
	"grant_item", "revoke_item",
	"open_service", "open_debt", "repay_debt", "set_debt_status",
	"unlock_grudge", "bury_grudge", "open_grudge", "resolve_grudge", "expire_grudge",
	"set_temp", "queue_event", "enqueue_event",
	"goto_dialog", "mod_success", "end_run", "menu",
]

var _errors: PackedStringArray = []
var _warnings: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if not PackDB.loaded:
		_err("PackDB not loaded")
		_finish(1)
		return

	_check_table_rows()
	_check_effects_everywhere()
	_check_dialog_links()
	_check_calendar_events()
	_check_registry()

	if _errors.is_empty():
		print("VALIDATE OK warnings=%d" % _warnings.size())
		for w in _warnings:
			print("  WARN: ", w)
		_finish(0)
	else:
		print("VALIDATE FAIL errors=%d warnings=%d" % [_errors.size(), _warnings.size()])
		for e in _errors:
			print("  ERR: ", e)
		for w in _warnings:
			print("  WARN: ", w)
		_finish(1)


func _finish(code: int) -> void:
	get_tree().quit(code)


func _err(msg: String) -> void:
	_errors.append(msg)


func _warn(msg: String) -> void:
	_warnings.append(msg)


func _check_table_rows() -> void:
	for t in ["def_stat", "def_location", "def_action", "def_event", "def_dialog"]:
		if PackDB.get_rows(t).is_empty():
			_err("table empty: %s" % t)


func _check_effects_everywhere() -> void:
	for row in PackDB.get_rows("def_action"):
		_scan_effects(row.get("effects", []), "act:%s" % row.get("act_id", "?"))
		_scan_requires(row.get("require", []), "act:%s" % row.get("act_id", "?"))
	for row in PackDB.get_rows("def_event"):
		_scan_effects(row.get("effects", []), "event:%s" % row.get("event_id", "?"))
		_scan_requires(row.get("require", []), "event:%s" % row.get("event_id", "?"))
	for row in PackDB.get_rows("def_dialog"):
		_scan_effects(row.get("effects", []), "dialog:%s" % row.get("dialog_id", "?"))
		_scan_requires(row.get("require", []), "dialog:%s" % row.get("dialog_id", "?"))
		for ch in row.get("choices", row.get("options", [])):
			if typeof(ch) != TYPE_DICTIONARY:
				continue
			_scan_effects(ch.get("effects", []), "dialog_choice:%s" % row.get("dialog_id", "?"))
			_scan_requires(ch.get("require", []), "dialog_choice:%s" % row.get("dialog_id", "?"))
	for row in PackDB.get_rows("def_tick"):
		_scan_effects(row.get("effects", []), "tick:%s" % row.get("tick_id", "?"))
		_scan_requires(row.get("require", []), "tick:%s" % row.get("tick_id", "?"))


func _scan_effects(effects: Array, ctx: String) -> void:
	for fx in effects:
		if typeof(fx) != TYPE_DICTIONARY:
			_err("%s: non-dict effect" % ctx)
			continue
		var op := String(fx.get("op", ""))
		if not ALLOWED_OPS.has(op):
			_err("%s: unknown op '%s'" % [ctx, op])
		if op in ["add", "set", "add_range"] and not fx.has("edge") and not fx.has("meter") and not fx.has("org"):
			var key := String(fx.get("key", ""))
			if not key.begins_with("stat_"):
				_err("%s: %s needs key stat_*" % [ctx, op])
		if fx.has("org") and String(fx.get("key", "")).is_empty():
			_err("%s: org effect needs key" % ctx)
		if op == "goto_dialog":
			var did := String(fx.get("id", ""))
			if PackDB.get_row_by_id("def_dialog", "dialog_id", did).is_empty():
				_err("%s: goto_dialog missing %s" % [ctx, did])
		if op in ["queue_event", "enqueue_event"]:
			var eid := String(fx.get("id", ""))
			if PackDB.get_row_by_id("def_event", "event_id", eid).is_empty():
				_warn("%s: queue_event id %s not in def_event" % [ctx, eid])


func _scan_requires(requires: Array, ctx: String) -> void:
	for req in requires:
		if typeof(req) != TYPE_DICTIONARY:
			_err("%s: non-dict require" % ctx)


func _check_dialog_links() -> void:
	for row in PackDB.get_rows("def_dialog"):
		var did := String(row.get("dialog_id", ""))
		var nxt := String(row.get("next", ""))
		if not nxt.is_empty() and nxt != "null":
			if PackDB.get_row_by_id("def_dialog", "dialog_id", nxt).is_empty():
				_err("dialog %s next missing %s" % [did, nxt])
		for ch in row.get("choices", row.get("options", [])):
			if typeof(ch) != TYPE_DICTIONARY:
				continue
			var nxt_v: Variant = ch.get("next", "")
			if nxt_v == null:
				continue
			var cn := String(nxt_v)
			if not cn.is_empty() and cn != "null" and PackDB.get_row_by_id("def_dialog", "dialog_id", cn).is_empty():
				_err("dialog %s choice next missing %s" % [did, cn])
	for row in PackDB.get_rows("def_event"):
		var entry := String(row.get("dialog_entry", ""))
		if entry.is_empty():
			continue
		if PackDB.get_row_by_id("def_dialog", "dialog_id", entry).is_empty():
			_err("event %s dialog_entry missing %s" % [row.get("event_id"), entry])
	for row in PackDB.get_rows("def_chatter"):
		var cdid := String(row.get("dialog_id", ""))
		if cdid.is_empty():
			_err("chatter missing dialog_id: %s" % row.get("chatter_id", "?"))
		elif PackDB.get_row_by_id("def_dialog", "dialog_id", cdid).is_empty():
			_err("chatter %s dialog missing %s" % [row.get("chatter_id"), cdid])


func _check_calendar_events() -> void:
	for row in PackDB.get_rows("def_calendar"):
		var eid := String(row.get("event_id", ""))
		if PackDB.get_row_by_id("def_event", "event_id", eid).is_empty():
			_err("calendar references missing event %s" % eid)


func _check_registry() -> void:
	var reg: Dictionary = PackDB.get_table_dict("registry_events")
	var events: Array = reg.get("events", [])
	for e in events:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var eid := String(e.get("event_id", ""))
		if PackDB.get_row_by_id("def_event", "event_id", eid).is_empty():
			_warn("registry event not in def_event: %s" % eid)
