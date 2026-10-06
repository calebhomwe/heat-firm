class_name SaveManager
extends Node

const SAVE_VERSION := "heat_firm_godot_save_v1"

var _game: Node = null
var _mem_mode := false
var _mem_store := {}
var last_offline_report := {}

func _ready() -> void:
	_game = get_node_or_null("/root/Game")
	var d := load_data()
	if d is Dictionary and not d.is_empty() and _game != null:
		_game.restore(d)
		var off := _offline_elapsed(d)
		if off > 60.0:
			last_offline_report = _game.compute_offline(off)
			_game.offline_report_ready.emit(last_offline_report)
	var t := Timer.new()
	t.wait_time = 5.0
	t.autostart = true
	t.timeout.connect(save_now)
	add_child(t)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()

func _offline_elapsed(d: Dictionary) -> float:
	var ls := int(d.get("last_seen_unix", 0))
	if ls <= 0:
		return 0.0
	return maxf(0.0, float(Time.get_unix_time_from_system()) - float(ls))

func load_data() -> Dictionary:
	if _mem_mode:
		return _mem_store.get("save", {})
	var f := FileAccess.open("user://save.json", FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if d is Dictionary:
		return d
	return {}

func save_data(d: Dictionary) -> void:
	var copy := d.duplicate(true)
	copy["last_seen_unix"] = int(Time.get_unix_time_from_system())
	if _mem_mode:
		_mem_store["save"] = copy
		return
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	if f == null:
		push_warning("Heat Firm: could not write save")
		return
	f.store_string(JSON.stringify(copy, "\t"))
	f.close()

func save_now() -> void:
	if _game != null:
		save_data(_game.serialize())

func reset_save() -> void:
	if _mem_mode:
		_mem_store.erase("save")
		return
	var abs := ProjectSettings.globalize_path("user://save.json")
	if FileAccess.file_exists(abs):
		DirAccess.remove_absolute(abs)

func new_memory() -> void:
	_mem_mode = true
