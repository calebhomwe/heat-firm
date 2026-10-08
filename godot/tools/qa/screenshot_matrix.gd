extends SceneTree
# QA screenshot matrix: runs the REAL main scene, resizes the window to the
# 4 acceptance sizes, waits ~2s each, saves PNGs to res://qa/shots/.
# Usage: godot --path <proj> --script res://tools/qa/screenshot_matrix.gd

const SIZES := [
	[390, 844],    # phone portrait
	[768, 1024],   # tablet portrait
	[844, 390],    # phone landscape
	[1366, 768],   # desktop landscape
]
const WAIT_SEC := 2.0

var _step := -1
var _t := 0.0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/shots"))
	root.mode = Window.MODE_WINDOWED
	change_scene_to_file("res://src/scene/main.tscn")
	_advance()

func _advance() -> void:
	_step += 1
	_t = 0.0
	if _step >= SIZES.size():
		print("SCREENSHOT MATRIX DONE: %d shots" % SIZES.size())
		quit(0)
		return
	var sz: Array = SIZES[_step]
	root.size = Vector2i(int(sz[0]), int(sz[1]))
	root.move_to_center()
	print("resize -> %dx%d" % [int(sz[0]), int(sz[1])])

func _process(delta: float) -> bool:
	_t += delta
	if _t < WAIT_SEC or _step >= SIZES.size():
		return false
	var sz: Array = SIZES[_step]
	var img := _grab()
	if img == null:
		print("FAIL: no image at %dx%d" % [int(sz[0]), int(sz[1])])
	else:
		var path := "res://qa/shots/shot_%dx%d.png" % [int(sz[0]), int(sz[1])]
		var err := img.save_png(path)
		print(("OK " + path) if err == OK else ("FAIL write " + path))
	_advance()
	return false

func _grab() -> Image:
	var vp := root.get_viewport()
	if vp == null:
		return null
	var tex := vp.get_texture()
	if tex == null:
		return null
	return tex.get_image()
