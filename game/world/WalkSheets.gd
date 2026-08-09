class_name WalkSheets
extends RefCounted


## Walk sprites from demo_ai_town classic resident complete sets
## (3 dirs × 4 frames · 512×512 · left mirrored from right).
## Driven like ResidentFrozenWhitebodyRig: Sprite2D + region_rect.

const FRAME_W := 512
const FRAME_H := 512
const SHEET_W := 1536
const SHEET_H := 2048
const WALK_ROWS := 4
const IDLE_FRAME := 1
const WALK_CYCLE_DISTANCE := 128.0
const DIR8 := ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
const ATLAS_DIR := "res://art/characters/walk_hi"
## Display height ≈ demo ResidentFrozenWhitebodyRig (152px body).
const DISPLAY_SCALE := 152.0 / 430.0
const SOURCE_FOOT_Y := 452.0

const NPC_LOADOUT := {
	"player": "qiao_yiming",
	"zhou_hongye": "cheng_yan",
	"zhou_shaoting": "wen_xu",
	"su_qing": "su_tang",
	"chen_manager": "zhou_jiming",
	"dock_foreman": "lu_qingzhou",
	"stall_aunt": "tang_xiaoman",
	"tea_waiter": "hanako",
	"garage_hand": "luo_yuan",
}

## 8-dir → sheet column (0=down, 1=side, 2=up).
const DIR8_TO_COL := {
	"s": 0,
	"se": 0,
	"sw": 0,
	"e": 1,
	"w": 1,
	"ne": 2,
	"n": 2,
	"nw": 2,
}


static func _packdb() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("/root/PackDB")


static func loadout_for(npc_id: String) -> String:
	var row: Dictionary = {}
	var pdb := _packdb()
	if pdb != null and bool(pdb.get("loaded")):
		row = pdb.call("get_row", "npcs", npc_id) as Dictionary
	if not row.is_empty():
		var key := str(row.get("walk_key", "")).strip_edges()
		if key != "" and atlas_path_exists(key):
			return key
	if NPC_LOADOUT.has(npc_id) and atlas_path_exists(str(NPC_LOADOUT[npc_id])):
		return str(NPC_LOADOUT[npc_id])
	if atlas_path_exists("qiao_yiming"):
		return "qiao_yiming"
	return ""


static func atlas_path(loadout_id: String) -> String:
	return "%s/%s_walk4_3dir_v1_alpha.png" % [ATLAS_DIR, loadout_id]


static func atlas_path_exists(loadout_id: String) -> bool:
	return ResourceLoader.exists(atlas_path(loadout_id))


static func texture_for_loadout(loadout_id: String) -> Texture2D:
	var path := atlas_path(loadout_id)
	if not ResourceLoader.exists(path):
		push_warning("WalkSheets: missing atlas %s" % path)
		return null
	return load(path) as Texture2D


static func needs_flip_h(dir: String) -> bool:
	## Same as demo ResidentFrozenWhitebodyRig complete-set: flip when facing right.
	return dir in ["e", "ne", "se"]


static func apply_to_sprite(sprite: Sprite2D, loadout_id: String, _walk_fps: float = 8.0) -> bool:
	if sprite == null:
		return false
	var tex := texture_for_loadout(loadout_id)
	if tex == null:
		return false
	if tex.get_width() != SHEET_W or tex.get_height() != SHEET_H:
		push_warning(
			"WalkSheets: unexpected sheet size %sx%s for %s (want %sx%s)"
			% [tex.get_width(), tex.get_height(), loadout_id, SHEET_W, SHEET_H]
		)
	sprite.texture = tex
	sprite.centered = true
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(DISPLAY_SCALE, DISPLAY_SCALE)
	## Feet sit on CharacterBody origin (same foot math as demo complete set).
	sprite.offset = Vector2(0.0, -(SOURCE_FOOT_Y - FRAME_H * 0.5))
	sprite.modulate = Color.WHITE
	sprite.flip_h = false
	set_pose(sprite, "s", false, 0)
	return true


static func set_pose(sprite: Sprite2D, dir: String, walking: bool, walk_frame: int) -> void:
	if sprite == null or sprite.texture == null:
		return
	var d := dir if DIR8_TO_COL.has(dir) else "s"
	var col := int(DIR8_TO_COL[d])
	var row := IDLE_FRAME
	if walking:
		row = posmod(walk_frame, WALK_ROWS)
	sprite.region_rect = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
	sprite.flip_h = needs_flip_h(d)


static func walk_frame_from_phase(phase: float) -> int:
	return int(floor(phase / TAU * float(WALK_ROWS))) % WALK_ROWS


static func bust_texture(npc_id: String) -> Texture2D:
	var loadout := loadout_for(npc_id)
	if loadout == "":
		return null
	var tex := texture_for_loadout(loadout)
	if tex == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(120, IDLE_FRAME * FRAME_H + 40, 272, 280)
	atlas.filter_clip = true
	return atlas
