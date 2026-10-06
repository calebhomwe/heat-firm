extends SceneTree
# Headless UI smoke: loads the real main scene, opens every tab, plays a round.
var _t := 0.0
var _step := 0
var _main: Node = null
var _game: Node = null

func _initialize() -> void:
	change_scene_to_file("res://src/scene/main.tscn")

func _g() -> Node:
	if _game == null:
		_game = root.get_node("/root/Game")
	return _game

func _process(delta: float) -> bool:
	_t += delta
	if _t < 0.5:
		return false
	_t = 0.0
	if _main == null:
		_main = root.get_node_or_null("Main")
		if _main == null:
			print("UI_SMOKE FAIL: no Main node")
			quit(1)
			return true
		print("UI_SMOKE: main scene loaded")
	var g := _g()
	match _step:
		0:
			for tab in ["Field", "Craft", "Market", "Orders", "Staff", "Upgrades", "Venue", "Missions", "Theme", "Menu"]:
				_main._open_tab(tab)
			print("UI_SMOKE: all tabs opened without script errors")
		1:
			_main._select_plot(0)
			print("UI_SMOKE: plant ok=", g.plant(0, "chilli_raw"))
		2:
			for i in 220:
				g.tick(0.1)
			var y: Dictionary = g.harvest(0)
			print("UI_SMOKE: harvest yields=", y)
			_main._open_tab("Market")
			print("UI_SMOKE: sell=", g.sell_stock("chilli_raw", 99))
			print("UI_SMOKE: cash=", g.get_cash(), " xp=", g.get_xp())
			print("UI_SMOKE: switch coffee=", g.switch_theme("coffee"))
			_main._layout()
		3:
			print("UI_SMOKE: theme now ", g.get_theme(), " cash=", g.get_cash())
			print("UI_SMOKE PASS")
			quit(0)
	_step += 1
	return false
