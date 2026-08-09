class_name NpcWalkDebug
extends RefCounted


## Temporary instrumentation for outdoor NPC walk.

const ENABLED := false
const SAMPLE_EVERY_SEC := 0.25

static var _file: FileAccess = null
static var _opened := false
static var _counts: Dictionary = {}
static var _last_sample: Dictionary = {}
static var _boot_ms: int = 0
static var _path: String = ""


static func ensure_open() -> void:
	if not ENABLED:
		return
	if _opened:
		return
	_opened = true
	_boot_ms = Time.get_ticks_msec()
	var candidates: PackedStringArray = PackedStringArray([
		"f:/Games/New-Life/builds/npc_walk_debug.log",
		ProjectSettings.globalize_path("user://npc_walk_debug.log"),
		OS.get_user_data_dir().path_join("npc_walk_debug.log"),
	])
	for path in candidates:
		var dir_path := path.get_base_dir()
		DirAccess.make_dir_recursive_absolute(dir_path)
		_file = FileAccess.open(path, FileAccess.WRITE)
		if _file != null:
			_path = path
			break
	var line := "=== NpcWalkDebug start %s path=%s ===" % [
		Time.get_datetime_string_from_system(), _path
	]
	print(line)
	if _file != null:
		_file.store_line(line)
		_file.flush()
	else:
		push_warning("NpcWalkDebug: no writable log path")


static func trace(tag: String, msg: String) -> void:
	if not ENABLED:
		return
	ensure_open()
	var line := "[+%dms][%s] %s" % [Time.get_ticks_msec() - _boot_ms, tag, msg]
	print(line)
	if _file != null:
		_file.store_line(line)
		_file.flush()


static func count(key: String, n: int = 1) -> void:
	_counts[key] = int(_counts.get(key, 0)) + n


static func sample_npc(npc: Node, reason: String) -> void:
	if not ENABLED or npc == null:
		return
	var nid := str(npc.get("npc_id"))
	var now := Time.get_ticks_msec()
	var prev := int(_last_sample.get(nid, 0))
	if reason == "tick" and now - prev < int(SAMPLE_EVERY_SEC * 1000.0):
		return
	_last_sample[nid] = now
	var sprite := npc.get_node_or_null("%Sprite") as Sprite2D
	var tex_ok := sprite != null and sprite.texture != null
	var region := Rect2()
	if sprite != null:
		region = sprite.region_rect
	var body := npc as CharacterBody2D
	trace(
		nid if nid != "" else "npc",
		"%s pos=%s has_target=%s indoors=%s visible=%s wait=%.2f stuck=%.2f facing=%s walking=%s phase=%.2f vel=%.1f region=%s tex=%s loadout=%s"
		% [
			reason,
			npc.global_position if npc is Node2D else Vector2.ZERO,
			npc.get("_has_target"),
			npc.get("_indoors"),
			npc.visible,
			float(npc.get("_wait")),
			float(npc.get("_stuck")),
			npc.get("_facing_dir"),
			npc.get("_walking"),
			float(npc.get("_walk_phase")),
			body.velocity.length() if body != null else -1.0,
			region,
			tex_ok,
			WalkSheets.loadout_for(nid) if nid != "" else "?",
		]
	)


static func dump_summary() -> void:
	if not ENABLED:
		return
	ensure_open()
	trace("summary", "counts=%s path=%s" % [_counts, _path])
	if _file != null:
		_file.store_line("=== NpcWalkDebug end ===")
		_file.flush()
