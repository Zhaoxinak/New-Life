extends Node
## 显示：2K/4K 友好窗口、全屏、界面倍率。落盘 user://display.cfg。

const CFG_PATH := "user://display.cfg"

## 设计分辨率（布局基准）；窗口可拉到 2K/4K，由 stretch 放大。
const DESIGN_W := 1280
const DESIGN_H := 720

const MODE_WINDOWED := "windowed"
const MODE_BORDERLESS := "borderless"
const MODE_FULLSCREEN := "fullscreen"

const SIZE_AUTO := "auto"

var mode: String = MODE_WINDOWED
var size_key: String = SIZE_AUTO
var ui_scale: float = 1.0
var _boot_applied: bool = false


func _ready() -> void:
	load_prefs()
	## 等一帧再套，避开启动时 DisplayServer 未就绪
	call_deferred("apply")


func load_prefs() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		## 首次：按显示器挑合适默认
		size_key = SIZE_AUTO
		mode = MODE_WINDOWED
		ui_scale = default_ui_scale_for_screen()
		return
	mode = String(cfg.get_value("display", "mode", MODE_WINDOWED))
	size_key = String(cfg.get_value("display", "size_key", SIZE_AUTO))
	ui_scale = float(cfg.get_value("display", "ui_scale", default_ui_scale_for_screen()))
	ui_scale = clampf(ui_scale, 1.0, 2.0)


func save_prefs() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "mode", mode)
	cfg.set_value("display", "size_key", size_key)
	cfg.set_value("display", "ui_scale", ui_scale)
	cfg.save(CFG_PATH)


func apply(quiet: bool = false) -> void:
	var win := get_window()
	if win == null:
		return
	## 拉伸：奶油 UI 用 canvas_items，在 2K/4K 上放大清晰度够用
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_size = Vector2i(DESIGN_W, DESIGN_H)
	win.content_scale_factor = ui_scale

	match mode:
		MODE_FULLSCREEN:
			win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if _prefer_exclusive() else Window.MODE_FULLSCREEN
			win.borderless = false
		MODE_BORDERLESS:
			## 无边框铺满主屏（适合多显示器时只占一块）
			win.mode = Window.MODE_WINDOWED
			win.borderless = true
			var screen := _primary_screen_size()
			var spos := DisplayServer.screen_get_position(DisplayServer.get_primary_screen())
			win.position = spos
			win.size = screen
		_:
			win.borderless = false
			if win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN \
				or win.mode == Window.MODE_MAXIMIZED:
				win.mode = Window.MODE_WINDOWED
			var want := resolve_window_size()
			win.size = want
			_center_on_screen(win, want)

	save_prefs()
	if quiet or not _boot_applied:
		_boot_applied = true
		return
	if DomainBus:
		DomainBus.tip.emit(L10n.t("ui.display_applied", "显示已套用：%s · %s · ×%.2f") % [
			mode_label(mode), size_label(size_key), ui_scale
		])


func resolve_window_size() -> Vector2i:
	var screen := _primary_screen_size()
	var presets := size_presets()
	if size_key == SIZE_AUTO:
		## 取不超过屏幕 92% 的最大预设，至少 1280×720
		var best := Vector2i(DESIGN_W, DESIGN_H)
		for p in presets:
			var wh: Vector2i = p["size"]
			if wh.x <= int(screen.x * 0.92) and wh.y <= int(screen.y * 0.92):
				if wh.x * wh.y >= best.x * best.y:
					best = wh
		return best
	for p in presets:
		if String(p["key"]) == size_key:
			var wh2: Vector2i = p["size"]
			return Vector2i(mini(wh2.x, screen.x), mini(wh2.y, screen.y))
	return Vector2i(DESIGN_W, DESIGN_H)


func size_presets() -> Array:
	## 含 1080p / 2K / 4K
	return [
		{"key": "1280x720", "size": Vector2i(1280, 720), "label": "1280×720"},
		{"key": "1600x900", "size": Vector2i(1600, 900), "label": "1600×900"},
		{"key": "1920x1080", "size": Vector2i(1920, 1080), "label": "1920×1080"},
		{"key": "2560x1440", "size": Vector2i(2560, 1440), "label": "2560×1440 (2K)"},
		{"key": "3840x2160", "size": Vector2i(3840, 2160), "label": "3840×2160 (4K)"},
	]


func mode_label(m: String = "") -> String:
	match m if not m.is_empty() else mode:
		MODE_FULLSCREEN:
			return L10n.t("ui.display_mode_fullscreen", "全屏")
		MODE_BORDERLESS:
			return L10n.t("ui.display_mode_borderless", "无边框全屏")
		_:
			return L10n.t("ui.display_mode_windowed", "窗口")


func size_label(key: String = "") -> String:
	var k := key if not key.is_empty() else size_key
	if k == SIZE_AUTO:
		var s := resolve_window_size()
		return L10n.t("ui.display_size_auto", "自动（%d×%d）") % [s.x, s.y]
	for p in size_presets():
		if String(p["key"]) == k:
			return String(p["label"])
	return k


func set_mode(m: String) -> void:
	mode = m
	apply()


func set_size_key(k: String) -> void:
	size_key = k
	## 改分辨率时默认回窗口，避免全屏下看不出变化
	if mode != MODE_WINDOWED and k != SIZE_AUTO:
		mode = MODE_WINDOWED
	apply()


func set_ui_scale(s: float) -> void:
	ui_scale = clampf(s, 1.0, 2.0)
	apply()


func cycle_mode() -> void:
	match mode:
		MODE_WINDOWED:
			mode = MODE_BORDERLESS
		MODE_BORDERLESS:
			mode = MODE_FULLSCREEN
		_:
			mode = MODE_WINDOWED
	apply()


func cycle_size() -> void:
	var keys: PackedStringArray = [SIZE_AUTO]
	for p in size_presets():
		keys.append(String(p["key"]))
	var i := keys.find(size_key)
	i = (i + 1) % keys.size()
	set_size_key(String(keys[i]))


func cycle_ui_scale() -> void:
	var steps: Array = [1.0, 1.25, 1.5, 1.75, 2.0]
	var i := 0
	for j in range(steps.size()):
		if absf(float(steps[j]) - ui_scale) < 0.01:
			i = j
			break
	i = (i + 1) % steps.size()
	set_ui_scale(float(steps[i]))


func _primary_screen_size() -> Vector2i:
	var idx := DisplayServer.get_primary_screen()
	return DisplayServer.screen_get_size(idx)


func _center_on_screen(win: Window, size: Vector2i) -> void:
	var idx := DisplayServer.get_primary_screen()
	var screen_pos := DisplayServer.screen_get_position(idx)
	var screen := DisplayServer.screen_get_size(idx)
	var pos := screen_pos + Vector2i(
		maxi(0, int((screen.x - size.x) / 2.0)),
		maxi(0, int((screen.y - size.y) / 2.0))
	)
	win.position = pos


func default_ui_scale_for_screen() -> float:
	## 4K 默认略放大一档，字更易读；2K 保持 1.0
	var screen := _primary_screen_size()
	if screen.y >= 2100:
		return 1.25
	if screen.y >= 1400:
		return 1.0
	return 1.0


func _prefer_exclusive() -> bool:
	## Windows 上独占全屏切换更快；其他平台用普通全屏
	return OS.get_name() == "Windows"
