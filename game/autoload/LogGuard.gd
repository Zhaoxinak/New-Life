extends Node
## 防止 Godot file log 被死循环/刷屏写爆磁盘。
## 启动时清理超大日志；运行中周期性截断。

const MAX_LOG_BYTES := 32 * 1024 * 1024 ## 32MB
const TRIM_TO_BYTES := 2 * 1024 * 1024 ## 截断后保留尾部 2MB
const POLL_SEC := 2.0

var _warned := false


func _enter_tree() -> void:
	_trim_logs(true)


func _ready() -> void:
	var t := Timer.new()
	t.wait_time = POLL_SEC
	t.one_shot = false
	t.autostart = true
	t.timeout.connect(func(): _trim_logs(false))
	add_child(t)


func _trim_logs(is_startup: bool) -> void:
	var logs_dir := OS.get_user_data_dir().path_join("logs")
	var da := DirAccess.open(logs_dir)
	if da == null:
		return
	da.list_dir_begin()
	var name := da.get_next()
	while name != "":
		if not da.current_is_dir() and name.ends_with(".log"):
			var path := logs_dir.path_join(name)
			_trim_one(path, is_startup)
		name = da.get_next()
	da.list_dir_end()


func _trim_one(path: String, is_startup: bool) -> void:
	if not FileAccess.file_exists(path):
		return
	var sz := FileAccess.get_size(path)
	if sz <= MAX_LOG_BYTES:
		return
	if is_startup or path.ends_with("godot.log"):
		## 运行中的 godot.log 可能被引擎占用：优先整文件删除；失败则截断尾部。
		if DirAccess.remove_absolute(path) == OK:
			if not _warned:
				_warned = true
				push_warning("LogGuard: removed oversized log (%s bytes) %s" % [sz, path])
			return
		_truncate_tail(path, sz)
		if not _warned:
			_warned = true
			push_warning("LogGuard: truncated oversized log (%s bytes) %s" % [sz, path])


func _truncate_tail(path: String, sz: int) -> void:
	var keep := mini(sz, TRIM_TO_BYTES)
	var src := FileAccess.open(path, FileAccess.READ)
	if src == null:
		return
	src.seek(sz - keep)
	var tail := src.get_buffer(keep)
	src = null
	var dst := FileAccess.open(path, FileAccess.WRITE)
	if dst == null:
		return
	dst.store_buffer(tail)
	dst = null
