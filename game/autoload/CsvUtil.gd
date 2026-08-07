class_name CsvUtil
extends RefCounted
## Minimal CSV reader. Pack tables currently have no quoted commas.


static func load_table(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		push_error("CsvUtil: missing file %s" % path)
		return rows
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("CsvUtil: cannot open %s (%s)" % [path, FileAccess.get_open_error()])
		return rows
	var text := f.get_as_text()
	f.close()
	text = text.replace("\r\n", "\n").replace("\r", "\n")
	var lines := text.split("\n", false)
	if lines.is_empty():
		return rows
	var headers := _split_line(lines[0])
	for i in range(1, lines.size()):
		var line: String = lines[i].strip_edges()
		if line.is_empty():
			continue
		var cols := _split_line(line)
		var row: Dictionary = {}
		for h_i in headers.size():
			var key: String = headers[h_i]
			var val: String = cols[h_i] if h_i < cols.size() else ""
			row[key] = val
		rows.append(row)
	return rows


static func _split_line(line: String) -> PackedStringArray:
	# Keep empty fields (e.g. effects.target) aligned with headers.
	return line.split(",", true)
