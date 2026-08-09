extends CanvasLayer


const FARE: = 2

@onready var root: Control = %Root
@onready var title_label: Label = %Title
@onready var fare_label: Label = %FareLabel
@onready var list: VBoxContainer = %List
@onready var close_btn: Button = %CloseButton

var _from_stop: String = ""


func _ready() -> void :
	add_to_group("transit_panel")
	visible = false
	root.visible = false
	close_btn.pressed.connect(close)
	UiStyle.apply_cozy_button(close_btn)


func open(from_stop_id: String) -> void :

	if int(GameState.get_stat("vehicle_tier")) >= 1:
		var host: = _find_world_host()
		if host and host.has_method("mount_vehicle_from_home"):
			host.mount_vehicle_from_home()
		return
	_from_stop = from_stop_id
	visible = true
	root.visible = true
	GameFlow.set_minigame_open(true)
	SfxPlayer.play_click()
	_rebuild()


func close() -> void :
	visible = false
	root.visible = false
	GameFlow.set_minigame_open(false)
	_from_stop = ""


func _rebuild() -> void :
	title_label.text = L10n.t("transit.title", "港湾环线")
	fare_label.text = L10n.tf("transit.fare", {"n": FARE}, "票价 %d 银元 · 不耗时段" % FARE)
	for c in list.get_children():
		c.queue_free()
	var stops: Array = []
	var host: = _find_world_host()
	if host and host.outdoor and host.outdoor.has_method("list_stop_ids"):
		stops = host.outdoor.list_stop_ids()
	else:
		stops = ["home", "plaza", "exchange", "dock"]
	for sid in stops:
		var id: = str(sid)
		if id == _from_stop:
			continue
		var btn: = Button.new()
		var loc_name: = L10n.t("locations.%s.name" % id, id)
		btn.text = L10n.tf("transit.to", {"name": loc_name}, "到%s" % loc_name)
		btn.custom_minimum_size = Vector2(0, 44)
		UiStyle.apply_cozy_button(btn)
		btn.pressed.connect(_on_pick.bind(id))
		list.add_child(btn)
	close_btn.text = L10n.t("ui.common.cancel", "算了")


func _find_world_host() -> Node:
	return get_tree().get_first_node_in_group("world_host")


func _on_pick(to_stop: String) -> void :
	if int(GameState.get_stat("money")) < FARE:
		fare_label.text = L10n.t("transit.broke", "票钱不够。先去码头扛两箱。")
		SfxPlayer.play_stinger("hush")
		return
	GameState.add_stat("money", - float(FARE))
	var host: = _find_world_host()
	if host == null or not host.has_method("teleport_to_stop"):
		close()
		return
	SfxPlayer.play_stinger("bell")
	close()
	host.teleport_to_stop(to_stop)
