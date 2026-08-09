extends Node2D


signal door_requested(location_id: String, return_spawn: Vector2)
signal transit_requested(from_stop_id: String)
signal mount_requested()

const DoorZoneScene: = preload("res://world/DoorZone.tscn")
const TransitStopScene: = preload("res://world/TransitStop.tscn")
const OutdoorNpcScene: = preload("res://world/OutdoorNpc.tscn")
const NpcCottageScript: = preload("res://world/NpcCottage.gd")
const VehiclePropScript: = preload("res://world/VehicleProp.gd")



const MAP_SCALE: = 2.55
const LAYOUT: = {

	"company": {
		"body": Rect2(0.08, 0.06, 0.18, 0.2), 

		"door": Vector2(0.185, 0.255), 
		"spawn": Vector2(0.2, 0.305), 
		"facing": "south", 
	}, 
	"home": {
		"body": Rect2(0.42, 0.05, 0.16, 0.2), 
		"door": Vector2(0.505, 0.235), 
		"spawn": Vector2(0.52, 0.3), 
		"facing": "south", 
		"stop": Vector2(0.5, 0.355), 
	}, 
	"rival": {
		"body": Rect2(0.78, 0.06, 0.16, 0.18), 
		"door": Vector2(0.87, 0.195), 
		"spawn": Vector2(0.82, 0.23), 
		"facing": "south", 
	}, 

	"tea_house": {
		"body": Rect2(0.04, 0.3, 0.14, 0.14), 
		"door": Vector2(0.13, 0.365), 

		"spawn": Vector2(0.21, 0.43), 
		"facing": "east", 
	}, 
	"plaza": {
		"body": Rect2(0.05, 0.48, 0.18, 0.16), 
		"door": Vector2(0.195, 0.56), 
		"spawn": Vector2(0.22, 0.6), 
		"facing": "east", 
		"stop": Vector2(0.255, 0.595), 
	}, 
	"garage": {
		"body": Rect2(0.04, 0.68, 0.16, 0.14), 
		"door": Vector2(0.155, 0.755), 
		"spawn": Vector2(0.22, 0.77), 
		"facing": "east", 
	}, 


	"exchange": {
		"body": Rect2(0.72, 0.4, 0.22, 0.2), 
		"door": Vector2(0.742, 0.505), 
		"spawn": Vector2(0.68, 0.51), 
		"facing": "west", 
		"stop": Vector2(0.62, 0.505), 
	}, 

	"dock": {
		"body": Rect2(0.42, 0.68, 0.2, 0.2), 
		"door": Vector2(0.52, 0.72), 
		"spawn": Vector2(0.52, 0.66), 
		"facing": "north", 
		"stop": Vector2(0.52, 0.585), 
	}, 
}



const HOME_BODIES: = {

	"tea_waiter": Rect2(0.255, 0.425, 0.09, 0.065), 
	"stall_aunt": Rect2(0.31, 0.605, 0.095, 0.07), 
	"garage_hand": Rect2(0.21, 0.695, 0.095, 0.07), 
	"dock_foreman": Rect2(0.405, 0.61, 0.095, 0.075), 
	"zhou_shaoting": Rect2(0.56, 0.38, 0.09, 0.065), 

	"chen_manager": Rect2(0.705, 0.375, 0.09, 0.055), 
}


const TRANSIT_STOPS: = ["home", "plaza", "exchange", "dock"]

var map_size: Vector2 = Vector2(1536, 1024) * MAP_SCALE
var _doors: Dictionary = {}
var _stops: Dictionary = {}
var _sign_labels: Dictionary = {}
var _vehicle_prop: Node2D
var _npc_layer: Node2D
var _cottage_labels: Dictionary = {}
var _t: float = 0.0

var _walk_nodes: Array[Vector2] = []
var _walk_adj: Array = []
var _walk_ring_count: int = 0
var _nav_region: NavigationRegion2D = null
const WALK_MERGE: = 48.0
const WALK_SOFT_LINK: = 100.0

const NAV_HALF_W: = 44.0

@onready var bg: Sprite2D = %Background
@onready var buildings: Node2D = %Buildings
@onready var doors: Node2D = %Doors
@onready var signs: Node2D = %Signs
@onready var path_fx: Node2D = %PathFx


func _ready() -> void :
	add_to_group("harbor_outdoor")
	_setup_background()
	_rebuild()
	set_process(true)
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)


func _process(delta: float) -> void :
	_t += delta
	path_fx.queue_redraw()


func _on_state() -> void :
	_refresh_doors()
	_refresh_signs()
	_refresh_vehicle_prop()


func _on_locale(_l: String) -> void :
	_refresh_doors()
	_refresh_signs()
	for nid in _cottage_labels.keys():
		var cot = _cottage_labels[nid]
		if cot != null and is_instance_valid(cot) and cot.has_method("refresh_label"):
			cot.refresh_label()


func _setup_background() -> void :
	var tex: Texture2D = load("res://art/world/harbor_outdoor.png")
	if tex == null:
		return
	bg.texture = tex
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.scale = Vector2(MAP_SCALE, MAP_SCALE)
	map_size = tex.get_size() * MAP_SCALE


func _add_world_bounds() -> void :
	var thickness: = 40.0
	_add_wall(Rect2( - thickness, - thickness, map_size.x + thickness * 2, thickness))
	_add_wall(Rect2( - thickness, map_size.y, map_size.x + thickness * 2, thickness))
	_add_wall(Rect2( - thickness, 0, thickness, map_size.y))
	_add_wall(Rect2(map_size.x, 0, thickness, map_size.y))


func _add_wall(r: Rect2) -> void :
	var body: = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: = CollisionShape2D.new()
	var rect: = RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.position + r.size * 0.5
	body.add_child(shape)
	buildings.add_child(body)


func _rebuild() -> void :
	for c in buildings.get_children():
		c.queue_free()
	for c in doors.get_children():
		c.queue_free()
	if signs:
		for c in signs.get_children():
			c.queue_free()
	_doors.clear()
	_stops.clear()
	_sign_labels.clear()
	_vehicle_prop = null
	_cottage_labels.clear()
	_add_world_bounds()
	_add_water_collision()
	_add_tree_colliders()
	_build_path_highlight()
	for id in LAYOUT.keys():
		var conf: Dictionary = LAYOUT[id]
		var body_r: Rect2 = conf["body"]
		var world_r: = Rect2(body_r.position * map_size, body_r.size * map_size)
		_add_building_body(world_r, id)
		var door_pos: Vector2 = conf["door"] * map_size
		_add_building_sign(id, door_pos, str(conf.get("facing", "south")))
		var door: Area2D = DoorZoneScene.instantiate()
		doors.add_child(door)
		door.position = door_pos
		door.setup(id, conf["spawn"] * map_size, str(conf.get("facing", "south")))
		door.door_activated.connect(_on_door)
		_doors[id] = door
		if str(id) in TRANSIT_STOPS:
			var stop: Area2D = TransitStopScene.instantiate()
			doors.add_child(stop)

			var stop_pos: Vector2 = conf.get("stop", conf["spawn"]) * map_size
			stop.position = stop_pos
			stop.setup(id)
			stop.transit_activated.connect(_on_transit)
			_stops[id] = stop
	for hid in HOME_BODIES.keys():
		var hr: Rect2 = HOME_BODIES[hid]
		_add_building_body(Rect2(hr.position * map_size, hr.size * map_size), "home_prop")
	_add_vehicle_prop()
	_rebuild_walk_graph()
	_rebuild_navigation()
	_spawn_cottages_and_npcs()
	_refresh_doors()
	_refresh_signs()
	_refresh_vehicle_prop()


func _add_water_collision() -> void :
	_add_wall(Rect2(Vector2(0.0, 0.82) * map_size, Vector2(0.36, 0.18) * map_size))
	_add_wall(Rect2(Vector2(0.64, 0.82) * map_size, Vector2(0.36, 0.18) * map_size))
	_add_wall(Rect2(Vector2(0.36, 0.94) * map_size, Vector2(0.28, 0.06) * map_size))
	_add_wall(Rect2(Vector2(0.0, 0.96) * map_size, Vector2(1.0, 0.06) * map_size))


func _add_tree_colliders() -> void :
	for r in [
		Rect2(0.0, 0.0, 0.04, 0.18), 
		Rect2(0.95, 0.0, 0.05, 0.18), 
		Rect2(0.94, 0.34, 0.06, 0.2), 
		Rect2(0.0, 0.88, 0.04, 0.06), 
	]:
		_add_wall(Rect2(r.position * map_size, r.size * map_size))


func _ring_polylines_norm() -> Array:

	return [
		PackedVector2Array([
			Vector2(0.195, 0.3), Vector2(0.35, 0.295), Vector2(0.52, 0.3), 
			Vector2(0.7, 0.26), Vector2(0.82, 0.23), Vector2(0.87, 0.195), 
		]), 
		PackedVector2Array([
			Vector2(0.52, 0.3), Vector2(0.52, 0.42), Vector2(0.52, 0.505), 
			Vector2(0.52, 0.585), Vector2(0.52, 0.66), Vector2(0.52, 0.72), 
		]), 
		PackedVector2Array([
			Vector2(0.52, 0.505), Vector2(0.62, 0.505), Vector2(0.68, 0.51), Vector2(0.742, 0.505), 
		]), 
		PackedVector2Array([
			Vector2(0.195, 0.3), Vector2(0.185, 0.365), Vector2(0.185, 0.47), 
			Vector2(0.185, 0.56), Vector2(0.185, 0.68), Vector2(0.185, 0.76), 
		]), 
	]


func _walk_polylines_norm() -> Array:

	var polys: Array = _ring_polylines_norm()
	for id in LAYOUT.keys():
		var conf: Dictionary = LAYOUT[id]
		var door: Vector2 = conf["door"]
		var spawn: Vector2 = conf["spawn"]
		polys.append(PackedVector2Array([door, spawn]))
	for row in PackDB.get_table("npc_homes"):
		var hx: = float(row.get("home_x", 0.5))
		var hy: = float(row.get("home_y", 0.5))
		var home: = Vector2(hx, hy)
		var hub: = _nearest_norm_on_ring(home)
		var mid: = home.lerp(hub, 0.55)
		polys.append(PackedVector2Array([hub, mid, home]))
	return polys


func _nearest_norm_on_ring(p: Vector2) -> Vector2:
	var best: = Vector2(0.52, 0.3)
	var best_d: = INF
	for poly in _ring_polylines_norm():
		for i in poly.size():
			var q: Vector2 = poly[i]
			var d: = p.distance_squared_to(q)
			if d < best_d:
				best_d = d
				best = q
	return best


func _build_path_highlight() -> void :
	if not path_fx.has_method("set_paths"):
		return
	var mats: Array = [
		Rect2(0.47, 0.28, 0.06, 0.05), 
		Rect2(0.47, 0.48, 0.06, 0.05), 
		Rect2(0.6, 0.48, 0.06, 0.05), 
		Rect2(0.16, 0.36, 0.05, 0.04), 
		Rect2(0.18, 0.56, 0.06, 0.05), 
		Rect2(0.16, 0.74, 0.05, 0.04), 
	]
	path_fx.call("set_paths", map_size, mats, _walk_polylines_norm())


func _rebuild_walk_graph() -> void :


	_walk_nodes.clear()
	_walk_adj.clear()
	_walk_ring_count = 0
	for poly in _ring_polylines_norm():
		var prev: = -1
		for i in poly.size():
			var wp: Vector2 = poly[i] * map_size
			var idx: = _walk_add_node(wp)
			if prev >= 0 and prev != idx:
				_walk_link(prev, idx)
			prev = idx
	_walk_ring_count = _walk_nodes.size()
	for id in LAYOUT.keys():
		var conf: Dictionary = LAYOUT[id]
		var door_w: Vector2 = conf["door"] * map_size
		var spawn_w: Vector2 = conf["spawn"] * map_size
		var di: = _walk_attach_to_ring(door_w)
		var si: = _walk_attach_to_ring(spawn_w)
		_walk_link(di, si)
	for row in PackDB.get_table("npc_homes"):
		var nid: = str(row.get("npc_id", ""))
		if nid == "":
			continue
		var home: = get_npc_home_pos(nid)
		var porch: = home + Vector2(0, 22)
		var hi: = _walk_attach_to_ring(home)
		var pi: = _walk_attach_to_ring(porch)
		_walk_link(hi, pi)

	call_deferred("_walk_soft_link_nearby")


func _walk_add_node(p: Vector2) -> int:
	for i in _walk_nodes.size():
		if _walk_nodes[i].distance_to(p) <= WALK_MERGE:
			_walk_nodes[i] = _walk_nodes[i].lerp(p, 0.35)
			return i
	_walk_nodes.append(p)
	_walk_adj.append([])
	return _walk_nodes.size() - 1


func _walk_link(a: int, b: int) -> void :
	if a < 0 or b < 0 or a == b:
		return
	if not _walk_adj[a].has(b):
		_walk_adj[a].append(b)
	if not _walk_adj[b].has(a):
		_walk_adj[b].append(a)


func _walk_attach_to_ring(p: Vector2) -> int:

	var idx: = _walk_add_node(p)
	var best: = _nearest_ring_index(_walk_nodes[idx])
	if best < 0:
		return idx
	var best_d: = _walk_nodes[idx].distance_to(_walk_nodes[best])
	if best_d <= WALK_MERGE:
		return idx
	if best_d > 160.0:
		var mid_p: = _walk_nodes[idx].lerp(_walk_nodes[best], 0.5)
		var mid: = _walk_add_node(mid_p)
		_walk_link(idx, mid)
		_walk_link(mid, best)
	else:
		_walk_link(idx, best)
	return idx


func _nearest_ring_index(world_pos: Vector2) -> int:
	var best_i: = -1
	var best_d: = INF
	var lim: = mini(_walk_ring_count, _walk_nodes.size())
	for i in lim:
		var d: = _walk_nodes[i].distance_to(world_pos)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i


func _walk_soft_link_nearby() -> void :

	if not is_inside_tree() or get_world_2d() == null:
		return
	var space: = get_world_2d().direct_space_state
	if space == null:
		return
	var n: = mini(_walk_ring_count, _walk_nodes.size())
	for i in n:
		for j in range(i + 1, n):
			if _walk_adj[i].has(j):
				continue
			var d: = _walk_nodes[i].distance_to(_walk_nodes[j])
			if d <= WALK_MERGE or d > WALK_SOFT_LINK:
				continue
			if _walk_ray_clear(_walk_nodes[i], _walk_nodes[j], space):
				_walk_link(i, j)


func _walk_ray_clear(a: Vector2, b: Vector2, space: PhysicsDirectSpaceState2D) -> bool:
	var dir: = b - a
	var len: = dir.length()
	if len < 1.0:
		return true
	dir /= len
	var from: = a + dir * 8.0
	var to: = b - dir * 8.0
	var q: = PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = 1
	q.collide_with_areas = false
	return space.intersect_ray(q).is_empty()


func _rebuild_navigation() -> void :

	if _nav_region == null or not is_instance_valid(_nav_region):
		_nav_region = NavigationRegion2D.new()
		_nav_region.name = "WalkNav"
		add_child(_nav_region)
	var np: = NavigationPolygon.new()
	for poly in _walk_polylines_norm():
		if poly.size() < 2:
			continue
		for i in range(poly.size() - 1):
			var a: Vector2 = poly[i] * map_size
			var b: Vector2 = poly[i + 1] * map_size
			var quad: = _outline_ccw(_corridor_quad(a, b, NAV_HALF_W))
			if quad.size() >= 3:
				np.add_outline(quad)
		for i in poly.size():
			var c: Vector2 = poly[i] * map_size
			np.add_outline(_outline_ccw(_nav_disk(c, NAV_HALF_W * 0.95)))
	if np.get_outline_count() <= 0:
		return
	np.make_polygons_from_outlines()
	_nav_region.navigation_polygon = np

	call_deferred("_nav_kick")


func _nav_kick() -> void :
	if _nav_region == null or not is_instance_valid(_nav_region):
		return
	_nav_region.enabled = false
	_nav_region.enabled = true


func _corridor_quad(a: Vector2, b: Vector2, half_w: float) -> PackedVector2Array:
	var d: = b - a
	if d.length_squared() < 4.0:
		return _nav_disk(a, half_w)
	var n: = d.normalized().orthogonal() * half_w
	return PackedVector2Array([a + n, b + n, b - n, a - n])


func _nav_disk(c: Vector2, r: float) -> PackedVector2Array:

	return PackedVector2Array([
		c + Vector2( - r, - r), 
		c + Vector2(r, - r), 
		c + Vector2(r, r), 
		c + Vector2( - r, r), 
	])


func _outline_ccw(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var area: = 0.0
	for i in poly.size():
		var j: = (i + 1) % poly.size()
		area += poly[i].x * poly[j].y - poly[j].x * poly[i].y
	if area < 0.0:
		poly.reverse()
	return poly


func nearest_walk_point(world_pos: Vector2) -> Vector2:

	if is_inside_tree() and get_world_2d() != null:
		var map: = get_world_2d().get_navigation_map()
		if map.is_valid():
			var snapped: = NavigationServer2D.map_get_closest_point(map, world_pos)
			if snapped.distance_to(world_pos) < 220.0:
				return snapped
	if _walk_nodes.is_empty():
		return world_pos
	var best_i: = _nearest_walk_index(world_pos)
	return _walk_nodes[best_i] if best_i >= 0 else world_pos


func snap_walk_goal(world_pos: Vector2, npc_id: String = "") -> Vector2:

	if npc_id.is_empty():
		pass
	return nearest_walk_point(world_pos)


func find_walk_path(from: Vector2, to: Vector2) -> PackedVector2Array:

	var out: PackedVector2Array = PackedVector2Array()
	if _walk_nodes.is_empty():
		out.append(to)
		return out
	var start_i: = _nearest_walk_index(from)
	var goal_i: = _nearest_walk_index(to)
	if start_i < 0 or goal_i < 0:
		out.append(nearest_walk_point(to))
		return out
	if start_i == goal_i:
		out.append(_walk_nodes[goal_i])
		return out
	var n: = _walk_nodes.size()
	var dist: Array = []
	var prev: Array = []
	dist.resize(n)
	prev.resize(n)
	for i in n:
		dist[i] = INF
		prev[i] = -1
	dist[start_i] = 0.0
	var open: Array = [start_i]
	while not open.is_empty():
		var best: = 0
		var best_d: float = dist[open[0]]
		for oi in range(1, open.size()):
			var d: float = dist[open[oi]]
			if d < best_d:
				best_d = d
				best = oi
		var u: int = open[best]
		open.remove_at(best)
		if u == goal_i:
			break
		for v in _walk_adj[u]:
			var alt: float = dist[u] + _walk_nodes[u].distance_to(_walk_nodes[v])
			if alt < dist[v]:
				dist[v] = alt
				prev[v] = u
				if not open.has(v):
					open.append(v)
	if prev[goal_i] < 0 and start_i != goal_i:

		var rs: = _nearest_ring_index(from)
		var rg: = _nearest_ring_index(to)
		if rs >= 0:
			out.append(_walk_nodes[rs])
		if rg >= 0 and rg != rs:
			out.append(_walk_nodes[rg])
		out.append(_walk_nodes[goal_i])
		return out
	var chain: Array[int] = []
	var cur: = goal_i
	while cur >= 0:
		chain.append(cur)
		if cur == start_i:
			break
		cur = int(prev[cur])
	chain.reverse()
	if from.distance_to(_walk_nodes[start_i]) > 16.0:
		out.append(_walk_nodes[start_i])
	for i in chain.size():
		if i == 0 and not out.is_empty() and out[out.size() - 1].distance_to(_walk_nodes[chain[i]]) < 10.0:
			continue
		out.append(_walk_nodes[chain[i]])
	return out


func _nearest_walk_index(world_pos: Vector2) -> int:
	var best_i: = -1
	var best_d: = INF
	for i in _walk_nodes.size():
		var d: = _walk_nodes[i].distance_to(world_pos)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i


func get_spawn_for(location_id: String) -> Vector2:
	if LAYOUT.has(location_id):
		return LAYOUT[location_id]["spawn"] * map_size
	return map_size * Vector2(0.47, 0.36)


func get_stop_spawn(stop_id: String) -> Vector2:
	if LAYOUT.has(stop_id):
		var conf: Dictionary = LAYOUT[stop_id]
		return conf.get("stop", conf["spawn"]) * map_size
	return get_default_spawn()


func get_default_spawn() -> Vector2:
	return map_size * Vector2(0.52, 0.3)


func list_stop_ids() -> Array[String]:
	var out: Array[String] = []
	for id in TRANSIT_STOPS:
		if LAYOUT.has(id):
			out.append(str(id))
	return out


func get_minimap_markers() -> Array:
	var out: Array = []
	for id in LAYOUT.keys():
		var conf: Dictionary = LAYOUT[id]
		var pos: Vector2 = conf.get("stop", conf["spawn"]) * map_size
		out.append({"id": str(id), "pos": pos, "kind": "building"})

	for n in get_tree().get_nodes_in_group("outdoor_npc"):
		if not is_instance_valid(n) or not bool(n.visible):
			continue
		var nid: = str(n.get("npc_id"))
		if nid not in ["su_qing", "zhou_shaoting", "zhou_hongye", "chen_manager"]:
			continue
		out.append({"id": nid, "pos": n.global_position, "kind": "npc"})
	return out


func get_npc_home_pos(npc_id: String) -> Vector2:
	var row: = _home_row(npc_id)
	if row.is_empty():
		return map_size * Vector2(0.5, 0.4)
	return Vector2(float(row.get("home_x", 0.5)), float(row.get("home_y", 0.5))) * map_size


func get_npc_spot(spot_id: String) -> Vector2:

	match spot_id:
		"plaza_court":
			return map_size * Vector2(0.3, 0.56)
		"north_boulevard":
			return map_size * Vector2(0.5, 0.28)
		_:
			if LAYOUT.has(spot_id):
				return get_spawn_for(spot_id)
			return get_npc_home_pos(spot_id)


func get_npc_anchor(npc_id: String) -> Vector2:
	return get_npc_home_pos(npc_id)


func _home_row(npc_id: String) -> Dictionary:
	for row in PackDB.get_table("npc_homes"):
		if str(row.get("npc_id", "")) == npc_id:
			return row
	return {}


func _parse_tint(hex: String, fallback: Color) -> Color:
	var h: = hex.strip_edges().trim_prefix("#")
	if h == "":
		return fallback
	return Color(h)


func _spawn_cottages_and_npcs() -> void :
	if _npc_layer != null and is_instance_valid(_npc_layer):
		NpcScheduler.unbind_outdoor(self)
		_npc_layer.queue_free()
	_npc_layer = Node2D.new()
	_npc_layer.name = "OutdoorNpcs"
	_npc_layer.z_index = 8
	add_child(_npc_layer)
	for row in PackDB.get_table("npc_homes"):
		var nid: = str(row.get("npc_id", ""))
		if nid == "":
			continue
		var home: = get_npc_home_pos(nid)
		if str(row.get("show_cottage", "0")) in ["1", "true", "True"]:
			_add_cottage(nid, home)
		var tint: = _parse_tint(str(row.get("tint", "")), UiStyle.portrait_color(nid))
		var dlg: = str(row.get("street_dialogue_id", ""))
		var npc: Node = OutdoorNpcScene.instantiate()
		_npc_layer.add_child(npc)
		if npc.has_method("setup"):
			npc.setup(nid, tint, dlg, home)

		var porch: = home + Vector2(0, 22)
		npc.global_position = nearest_walk_point(porch)
	NpcScheduler.bind_outdoor(self)


func _add_cottage(npc_id: String, door_pos: Vector2) -> void :
	var cottage: = Node2D.new()
	cottage.set_script(NpcCottageScript)
	cottage.z_index = 5
	buildings.add_child(cottage)
	if cottage.has_method("setup"):
		cottage.setup(npc_id, door_pos)
	_cottage_labels[npc_id] = cottage

	var loc_id: = _cottage_location_id(npc_id)
	if loc_id == "" or _doors.has(loc_id):
		return
	var door: Area2D = DoorZoneScene.instantiate()
	doors.add_child(door)
	door.position = door_pos

	var spawn: = door_pos + Vector2(0, 72)
	door.setup(loc_id, spawn, "south")
	door.door_activated.connect(_on_door)
	_doors[loc_id] = door



func _cottage_location_id(npc_id: String) -> String:
	var row: = _home_row(npc_id)
	return str(row.get("location_id", "")).strip_edges()


func _add_building_body(r: Rect2, location_id: String = "") -> void :
	var body: = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: = CollisionShape2D.new()
	var rect: = RectangleShape2D.new()
	var solid: Rect2
	match location_id:
		"dock":
			solid = Rect2(r.position + Vector2(r.size.x * 0.12, r.size.y * 0.3), Vector2(r.size.x * 0.76, r.size.y * 0.6))
		"exchange":

			solid = Rect2(r.position + Vector2(r.size.x * 0.32, r.size.y * 0.16), Vector2(r.size.x * 0.52, r.size.y * 0.64))
		"plaza", "tea_house", "garage":
			solid = Rect2(r.position + Vector2(r.size.x * 0.06, r.size.y * 0.08), Vector2(r.size.x * 0.62, r.size.y * 0.84))
		"company", "home", "rival":

			solid = Rect2(r.position + Vector2(r.size.x * 0.12, r.size.y * 0.06), Vector2(r.size.x * 0.76, r.size.y * 0.42))
		"home_prop":
			solid = Rect2(r.position + Vector2(r.size.x * 0.08, r.size.y * 0.1), Vector2(r.size.x * 0.84, r.size.y * 0.7))
		_:
			solid = Rect2(r.position + Vector2(r.size.x * 0.1, r.size.y * 0.08), Vector2(r.size.x * 0.8, r.size.y * 0.55))
	rect.size = solid.size
	shape.shape = rect
	shape.position = solid.position + solid.size * 0.5
	body.add_child(shape)
	buildings.add_child(body)


func _add_building_sign(location_id: String, door_pos: Vector2, facing: String = "south") -> void :
	if signs == null:
		return
	var sign: = Node2D.new()

	var offset: = Vector2(0, -56)
	match facing:
		"east":
			offset = Vector2(8, -48)
		"west":
			offset = Vector2(-8, -48)
		"north":
			offset = Vector2(0, 40)
		_:
			offset = Vector2(0, -56)
	sign.position = door_pos + offset
	sign.z_index = 10
	var board: = Panel.new()
	board.position = Vector2(-110, -22)
	board.custom_minimum_size = Vector2(220, 40)
	board.size = Vector2(220, 40)
	var sign_style: = StyleBoxFlat.new()
	sign_style.bg_color = UiStyle.PARCHMENT
	sign_style.border_color = UiStyle.WOOD
	sign_style.set_border_width_all(2)
	sign_style.set_corner_radius_all(8)
	sign_style.content_margin_left = 10
	sign_style.content_margin_right = 10
	sign_style.content_margin_top = 6
	sign_style.content_margin_bottom = 6
	sign_style.shadow_color = Color(0, 0, 0, 0.18)
	sign_style.shadow_size = 4
	board.add_theme_stylebox_override("panel", sign_style)
	sign.add_child(board)
	var title: = Label.new()
	title.name = "Title"
	title.text = UnlockScheduler.location_sign_text(location_id)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", UiStyle.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.position = Vector2.ZERO
	title.size = board.custom_minimum_size
	board.add_child(title)
	_sign_labels[location_id] = title
	signs.add_child(sign)


func _add_vehicle_prop() -> void :
	var prop: = Area2D.new()
	prop.set_script(VehiclePropScript)
	prop.name = "VehicleProp"
	prop.z_index = 8
	if LAYOUT.has("home"):
		var home_spawn: Vector2 = LAYOUT["home"]["spawn"] * map_size

		prop.position = home_spawn + Vector2(48, -6)
	signs.add_child(prop)
	if prop.has_signal("mount_requested") and not prop.mount_requested.is_connected(_on_mount_requested):
		prop.mount_requested.connect(_on_mount_requested)
	_vehicle_prop = prop


func _refresh_vehicle_prop() -> void :
	if _vehicle_prop == null or not is_instance_valid(_vehicle_prop):
		return
	if LAYOUT.has("home") and _vehicle_prop.has_method("set_taken") and not bool(_vehicle_prop.get("_taken")):

		pass
	if _vehicle_prop.has_method("refresh_visual"):
		_vehicle_prop.refresh_visual()


func park_vehicle_at(world_pos: Vector2) -> void :
	if _vehicle_prop and _vehicle_prop.has_method("park_at"):
		_vehicle_prop.park_at(world_pos)


func set_vehicle_taken(taken: bool) -> void :
	if _vehicle_prop and _vehicle_prop.has_method("set_taken"):
		_vehicle_prop.set_taken(taken)


func vehicle_prop_position() -> Vector2:
	if _vehicle_prop != null and is_instance_valid(_vehicle_prop):
		return _vehicle_prop.global_position
	if LAYOUT.has("home"):
		return LAYOUT["home"]["spawn"] * map_size + Vector2(48, -6)
	return get_default_spawn()


func _on_mount_requested() -> void :
	mount_requested.emit()


func _refresh_doors() -> void :
	for id in _doors.keys():
		_doors[id].refresh()


func _refresh_signs() -> void :
	for id in _sign_labels.keys():
		var title: Label = _sign_labels[id]
		if title == null or not is_instance_valid(title):
			continue
		title.text = UnlockScheduler.location_sign_text(str(id))
		var locked: = not GameState.is_location_unlocked(str(id))
		title.add_theme_color_override("font_color", Color(0.45, 0.38, 0.32) if locked else UiStyle.TEXT)


func _on_door(location_id: String, return_spawn: Vector2) -> void :
	door_requested.emit(location_id, return_spawn)


func _on_transit(stop_id: String) -> void :
	transit_requested.emit(stop_id)
