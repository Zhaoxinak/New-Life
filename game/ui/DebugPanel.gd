extends CanvasLayer
## F3 toggle debug panel for QA.


@onready var root: PanelContainer = %Root
@onready var info: RichTextLabel = %Info
@onready var day_spin: SpinBox = %DaySpin
@onready var apply_day_btn: Button = %ApplyDayBtn
@onready var sus_btn: Button = %SusBtn
@onready var tension_btn: Button = %TensionBtn
@onready var money_btn: Button = %MoneyBtn
@onready var pulse_btn: Button = %PulseBtn
@onready var end_b_btn: Button = %EndBBtn


func _ready() -> void:
	visible = false
	root.visible = false
	apply_day_btn.pressed.connect(_on_day)
	sus_btn.pressed.connect(func(): GameState.set_stat("suspicion", 40); _refresh())
	tension_btn.pressed.connect(func(): GameState.set_stat("father_son_tension", 75); _refresh())
	money_btn.pressed.connect(func(): GameState.set_stat("money", 200); _refresh())
	pulse_btn.pressed.connect(func(): EventScheduler.pulse(); _refresh())
	end_b_btn.pressed.connect(_force_b)
	if not GameState.state_changed.is_connected(_refresh):
		GameState.state_changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			visible = not visible
			root.visible = visible
			_refresh()
			get_viewport().set_input_as_handled()


func _refresh() -> void:
	if not visible:
		return
	info.text = "day=%d %s loc=%s\nmoney=%d trust=%d sus=%d intel=%d tension=%d\nrank=%s ending=%s" % [
		GameState.day, GameState.period, GameState.location_id,
		int(GameState.get_stat("money")), int(GameState.get_stat("trust")),
		int(GameState.get_stat("suspicion")), int(GameState.get_stat("intel")),
		int(GameState.get_stat("father_son_tension")),
		GameState.get_rank_id(), GameState.active_ending_id,
	]
	day_spin.value = GameState.day


func _on_day() -> void:
	GameState.day = int(day_spin.value)
	UnlockScheduler.apply_up_to_day(GameState.day)
	_refresh()


func _force_b() -> void:
	GameState.set_flag("route_focus_b", 1)
	GameState.set_stat("father_son_tension", 75)
	GameState.set_relation("su_qing", "player", "favor", 60.0)
	GameState.set_flag("ending_show_b", 0)
	EventScheduler.pulse()
	_refresh()
