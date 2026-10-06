extends Node
# Heat Firm — main scene. All UI built in code (contract: single-node .tscn).
# Talks to the sim ONLY through the Game autoload's public API.

const VERSION := "1.0.0"
const TABS := ["Field", "Craft", "Market", "Orders", "Staff", "Upgrades", "Venue", "Missions", "Theme", "Menu"]

var _root: Control
var _room: RoomView
var _plots: Array[PlotView] = []
var _hud_cash: Label
var _hud_theme: Label
var _hud_rank: Label
var _hud_time: Label
var _hud_event: Label
var _hud_xp_fill: ColorRect
var _dock: PanelContainer
var _tab_bar: HFlowContainer
var _tab_body: ScrollContainer
var _tab_body_inner: VBoxContainer
var _toast_box: VBoxContainer
var _modal_layer: Control
var _customer: CustomerView
var _selected_plot := 0
var _active_tab := "Field"
var _shown_cash := 0.0
var _cash_tween: Tween = null
var _time_accum := 0.0
var _reduced_motion := false
var _particles := 1
var _particles_pool: Array[Dictionary] = []

func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_root)
	_room = RoomView.new()
	_room.set_anchors_preset(Control.PRESET_FULL_RECT)
	_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_room)
	for i in 6:
		var pv := PlotView.new()
		pv.index = i
		pv.pressed.connect(func(): _select_plot(i))
		_root.add_child(pv)
		_plots.append(pv)
	_build_hud()
	_build_dock()
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast_box.add_theme_constant_override("separation", 4)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast_box)
	_modal_layer = Control.new()
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_modal_layer)
	_customer = CustomerView.new()
	_customer.custom_minimum_size = Vector2(190, 96)
	_customer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_customer)
	_load_settings()
	_connect_game()
	_shown_cash = Game.get_cash()
	_refresh_static()
	_open_tab("Field")
	_layout()
	call_deferred("_second_frame")

func _second_frame() -> void:
	if not Save.last_offline_report.is_empty():
		_show_offline_report(Save.last_offline_report)

func _connect_game() -> void:
	Game.cash_changed.connect(func(_v): _bump_cash())
	Game.xp_changed.connect(func(_xp, _lvl, _title): _refresh_xp())
	Game.toast.connect(_on_toast)
	Game.theme_changed.connect(func(_k):
		_shown_cash = Game.get_cash()
		_refresh_static()
		_open_tab(_active_tab)
		_layout())
	Game.offline_report_ready.connect(_show_offline_report)
	Game.plot_changed.connect(func(_i, _st): _plots[_i].queue_redraw())
	Game.order_arrived.connect(func(_o): _flash("Order in!", Color.GOLD))
	Game.order_arrived.connect(func(_o): _refresh_customer())
	Game.order_completed.connect(func(_id, _r): _refresh_customer())
	Game.order_expired.connect(func(_id): _refresh_customer())
	Game.order_completed.connect(func(_id, reward: float): _flash("+$%.0f" % reward, Color.GOLD))
	Game.rank_up.connect(func(_i, title: String): _flash("RANK UP: " + title, Color.AQUA))
	Game.mission_completed.connect(func(_id, _r): _refresh_tab_if("Missions"))
	Game.venue_upgraded.connect(func(_lvl): _refresh_tab_if("Venue"))
	Game.staff_hired.connect(func(_r): _refresh_tab_if("Staff"))
	Game.day_changed.connect(func(_day: int, wages: float, _rep):
		if wages > 0.0:
			_on_toast("Day %d — wages paid: -$%.0f" % [_day, wages], "bad"))

func _process(delta: float) -> void:
	Game.tick(delta)
	_time_accum += delta
	if _time_accum >= 0.1:
		_time_accum = 0.0
		var dp := Game.get_day_progress()
		_hud_time.text = "Day %d  %02d:%02d" % [Game.get_day(), int(dp * 24.0), int(fmod(dp * 1440.0, 60.0))]
		for pv in _plots:
			pv.queue_redraw()
		_room.night = dp
		_room.queue_redraw()
		_step_particles()
		if _active_tab == "Orders":
			_open_tab("Orders")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode >= KEY_1 and k.keycode <= KEY_6:
			_select_plot(k.keycode - KEY_1)
		elif k.keycode == KEY_W:
			Game.water(_selected_plot)
		elif k.keycode == KEY_E:
			var y: Dictionary = Game.harvest(_selected_plot)
			if y.is_empty():
				_on_toast("Nothing ready to harvest", "bad")
		elif k.keycode == KEY_Q:
			_open_tab("Craft")
		elif k.keycode == KEY_T:
			_open_tab("Theme")

# ---------- layout ----------

func _layout() -> void:
	var size: Vector2 = _root.size
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var portrait := size.y > size.x
	var lay := LayoutConsts.for_portrait(portrait)
	var beds: Dictionary = lay.beds
	var room_h := size.y * 0.72  # room area above the bottom dock
	for i in 6:
		var r := LayoutConsts.bed_rect(beds, portrait, size.x, room_h, i)
		_plots[i].position = r.position
		_plots[i].size = r.size
	_room.theme_key = Game.get_theme()
	_room.room_style = str(Game.get_pack().room_style)
	_room.palette = Game.get_pack().palette
	_room.floor_line = float(lay.floor)
	_room.queue_redraw()
	_dock.position = Vector2(0.0, size.y * 0.72)
	_dock.size = Vector2(size.x, size.y * 0.28)
	# customer vignette: standing on the floor line, clear of the beds
	if portrait:
		_customer.position = Vector2(size.x * 0.62, size.y * 0.30)
	else:
		_customer.position = Vector2(size.x * 0.30, size.y * 0.60 - 90.0)
	_customer.queue_redraw()

func _refresh_customer() -> void:
	var orders := Game.get_orders()
	if orders.is_empty():
		_customer.set_order("")
	else:
		var o: Dictionary = orders[0]
		var pname := _prod_name(str(o.product))
		if pname.length() > 12:
			pname = pname.substr(0, 11) + "."
		_customer.set_order("%s: %d x %s" % [str(o.customer), int(o.qty), pname])
		if not _reduced_motion:
			_customer.walk_in()

# ---------- HUD ----------

func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	return sb

func _pal() -> Dictionary:
	return Game.get_pack().palette

func _build_hud() -> void:
	var hud := PanelContainer.new()
	hud.name = "HUD"
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_stylebox_override("panel", _panel_style(Color(_pal().ui_panel).darkened(0.1), Color(_pal().plot_frame)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo: Texture2D = RoomView._tex("res://assets/art/ui_logo.png")
	if logo != null:
		var tr := TextureRect.new()
		tr.texture = logo
		tr.custom_minimum_size = Vector2(84, 28)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tr)
	_hud_theme = Label.new()
	_hud_theme.add_theme_font_size_override("font_size", 20)
	_hud_theme.add_theme_color_override("font_color", Color(_pal().accent))
	row.add_child(_hud_theme)
	_hud_cash = Label.new()
	_hud_cash.add_theme_font_size_override("font_size", 22)
	_hud_cash.add_theme_color_override("font_color", Color(_pal().glow))
	row.add_child(_hud_cash)
	var xp_box := VBoxContainer.new()
	xp_box.custom_minimum_size = Vector2(200, 10)
	xp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_rank = Label.new()
	_hud_rank.add_theme_font_size_override("font_size", 12)
	xp_box.add_child(_hud_rank)
	var bar_bg := Control.new()
	bar_bg.custom_minimum_size = Vector2(200, 6)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.draw.connect(func():
		bar_bg.draw_rect(Rect2(Vector2.ZERO, bar_bg.size), Color(_pal().ui_panel).lightened(0.15)))
	_hud_xp_fill = ColorRect.new()
	_hud_xp_fill.color = Color(_pal().glow)
	_hud_xp_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_bg.add_child(_hud_xp_fill)
	xp_box.add_child(bar_bg)
	row.add_child(xp_box)
	_hud_time = Label.new()
	_hud_time.add_theme_font_size_override("font_size", 14)
	_hud_time.add_theme_color_override("font_color", Color(_pal().ui_text))
	row.add_child(_hud_time)
	_hud_event = Label.new()
	_hud_event.add_theme_font_size_override("font_size", 12)
	_hud_event.add_theme_color_override("font_color", Color.GOLD)
	row.add_child(_hud_event)
	hud.add_child(row)
	_root.add_child(hud)

func _bump_cash() -> void:
	if _cash_tween != null and _cash_tween.is_valid():
		_cash_tween.kill()
	var target := Game.get_cash()
	if _reduced_motion or absf(target - _shown_cash) < 0.01:
		_shown_cash = target
		_hud_cash.text = "$%.0f" % _shown_cash
		return
	_cash_tween = create_tween()
	_cash_tween.tween_method(func(v: float):
		_shown_cash = v
		_hud_cash.text = "$%.0f" % v, _shown_cash, target, 0.4)

const RANK_THRESH := [0, 50, 150, 400, 900, 2000, 4500, 9000]

func _refresh_xp() -> void:
	var idx := Game.get_rank_index()
	var nxt := Game.get_next_rank_xp()
	var cur: int = RANK_THRESH[clampi(idx, 0, 7)]
	_hud_rank.text = "%s (Lv %d)" % [Game.get_rank_title(), Game.get_level()]
	var denom := maxi(1, nxt - cur) if nxt > cur else 1
	_hud_xp_fill.scale.x = clampf(float(Game.get_xp() - cur) / float(denom), 0.0, 1.0)

func _refresh_static() -> void:
	var pack := Game.get_pack()
	_hud_theme.text = "%s — %s" % [pack.name, pack.tagline]
	_bump_cash()
	_refresh_xp()
	var ev := ""
	for e in Game.get_events():
		if e.active:
			ev = "* " + e.name
	_hud_event.text = ev
	for pv in _plots:
		pv.queue_redraw()
	_refresh_customer()

# ---------- dock / tabs ----------

func _build_dock() -> void:
	_dock = PanelContainer.new()
	_dock.name = "Dock"
	_dock.add_theme_stylebox_override("panel", _panel_style(Color(_pal().ui_panel), Color(_pal().plot_frame)))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_tab_bar = HFlowContainer.new()
	_tab_bar.add_theme_constant_override("separation", 4)
	for t in TABS:
		var b := Button.new()
		b.text = t
		b.toggle_mode = true
		b.pressed.connect(func(): _open_tab(t))
		b.add_theme_font_size_override("font_size", 13)
		_tab_bar.add_child(b)
	col.add_child(_tab_bar)
	_tab_body = ScrollContainer.new()
	_tab_body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_body_inner = VBoxContainer.new()
	_tab_body_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_body_inner.add_theme_constant_override("separation", 6)
	_tab_body.add_child(_tab_body_inner)
	col.add_child(_tab_body)
	_dock.add_child(col)
	_root.add_child(_dock)

func _refresh_tab_if(tab: String) -> void:
	if _active_tab == tab:
		_open_tab(tab)

func _open_tab(tab: String) -> void:
	_active_tab = tab
	for b in _tab_bar.get_children():
		b.button_pressed = str(b.text) == tab
	for c in _tab_body_inner.get_children():
		c.queue_free()
	match tab:
		"Field": _tab_field()
		"Craft": _tab_craft()
		"Market": _tab_market()
		"Orders": _tab_orders()
		"Staff": _tab_staff()
		"Upgrades": _tab_upgrades()
		"Venue": _tab_venue()
		"Missions": _tab_missions()
		"Theme": _tab_theme()
		"Menu": _tab_menu()

func _row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	return h

func _lbl(t: String, size := 14) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(_pal().ui_text))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _btn(t: String, cb: Callable, disabled := false, accent := false) -> Button:
	var b := Button.new()
	b.text = t
	b.disabled = disabled
	b.pressed.connect(cb)
	b.add_theme_font_size_override("font_size", 13)
	if accent:
		b.add_theme_color_override("font_color", Color(_pal().accent))
	return b

func _tab_field() -> void:
	var pack := Game.get_pack()
	_tab_body_inner.add_child(_lbl("Plot %d selected — pick a seed:" % (_selected_plot + 1), 15))
	for crop in pack.crops:
		var row := _row()
		var afford: bool = Game.get_cash() >= float(crop.seed_cost)
		row.add_child(_lbl("%s  ($%d seed, %ds grow, yields %d)" % [crop.name, crop.seed_cost, int(crop.grow_time), crop.base_yield]))
		row.add_child(_btn("Plant", func(): _do_plant(str(crop.id)), not afford, true))
		_tab_body_inner.add_child(row)
	var st: Dictionary = Game.get_plots()[_selected_plot]
	if st.locked:
		_tab_body_inner.add_child(_btn("Unlock plot %d ($%d)" % [_selected_plot + 1, _unlock_cost(_selected_plot)], func():
			if Game.unlock_plot(_selected_plot):
				_refresh_static()))
	_tab_body_inner.add_child(_lbl("Water: W    Harvest: E    Select plots: 1-6", 12))

func _unlock_cost(i: int) -> int:
	var base: int = [0, 0, 0, 30, 80, 200][i]
	return int(roundf(base * (1.0 - 0.2 * Game.get_venue_level())))

func _do_plant(crop_id: String) -> void:
	if Game.plant(_selected_plot, crop_id):
		_spawn_particles(_plots[_selected_plot].position + _plots[_selected_plot].size * 0.5, Color(_pal().accent))
		_plots[_selected_plot].queue_redraw()
		if _active_tab == "Field":
			_open_tab("Field")

func _tab_craft() -> void:
	var stock: Dictionary = Game.get_stock()
	var icon: Texture2D = RoomView._tex("res://assets/art/product_%s.png" % Game.get_theme())
	for prod: Dictionary in Game.get_pack().products:
		var recipe_txt := ""
		var can := true
		for cid in prod.recipe:
			recipe_txt += "%dx %s  " % [int(prod.recipe[cid]), _crop_name(str(cid))]
			if int(stock.get(cid, 0)) < int(prod.recipe[cid]):
				can = false
		var row := _row()
		if icon != null:
			var tr := TextureRect.new()
			tr.texture = icon
			tr.custom_minimum_size = Vector2(22, 22)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(tr)
		row.add_child(_lbl("%s  ($%.0f) — %s" % [prod.name, prod.price, recipe_txt]))
		row.add_child(_btn("Craft 1", func(): _do_craft(str(prod.id), 1), not can))
		row.add_child(_btn("Craft 5", func(): _do_craft(str(prod.id), 5), not can))
		_tab_body_inner.add_child(row)

func _crop_name(cid: String) -> String:
	for c in Game.get_pack().crops:
		if str(c.id) == cid:
			return str(c.name)
	return cid

func _do_craft(pid: String, qty: int) -> void:
	var n: int = Game.craft(pid, qty)
	if n > 0 and _active_tab == "Craft":
		_open_tab("Craft")

func _tab_market() -> void:
	_tab_body_inner.add_child(_lbl("Products:", 15))
	for pid in Game.get_inventory():
		var prod = _find_prod(str(pid))
		if prod == null:
			continue
		var qty := int(Game.get_inventory()[pid])
		var row := _row()
		row.add_child(_lbl("%s x%d  ($%.0f each)" % [prod.name, qty, prod.price]))
		row.add_child(_btn("Sell 1", func(): Game.sell(str(pid), 1)))
		row.add_child(_btn("Sell all +%s" % _money(float(prod.price) * qty * _venue_mult()), func(): Game.sell(str(pid), qty), false, true))
		_tab_body_inner.add_child(row)
	_tab_body_inner.add_child(_lbl("Raw stock:", 15))
	for cid in Game.get_stock():
		var crop = _find_crop(str(cid))
		if crop == null:
			continue
		var qty := int(Game.get_stock()[cid])
		var row := _row()
		row.add_child(_lbl("%s x%d  ($%.1f each)" % [crop.name, qty, crop.price_raw]))
		row.add_child(_btn("Sell all +%s" % _money(float(crop.price_raw) * qty * _venue_mult()), func(): Game.sell_stock(str(cid), qty), false, true))
		_tab_body_inner.add_child(row)
	if Game.get_inventory().is_empty() and Game.get_stock().is_empty():
		_tab_body_inner.add_child(_lbl("Nothing to sell yet — harvest some crops.", 13))

func _money(v: float) -> String:
	return "$%.0f" % v

func _venue_mult() -> float:
	return 1.0 + 0.10 * Game.get_venue_level()

func _find_prod(pid: String):
	for p in Game.get_pack().products:
		if str(p.id) == pid:
			return p
	return null

func _find_crop(cid: String):
	for c in Game.get_pack().crops:
		if str(c.id) == cid:
			return c
	return null

func _tab_orders() -> void:
	var orders := Game.get_orders()
	if orders.is_empty():
		_tab_body_inner.add_child(_lbl("No active orders. New ones arrive each day.", 14))
		return
	for o in orders:
		var row := _row()
		var have := int(Game.get_inventory().get(str(o.product), 0))
		var can: bool = have >= int(o.qty)
		row.add_child(_lbl("%s (%s) wants %d x %s — $%.0f  [%d s left]" % [o.customer, o.mood, o.qty, _prod_name(str(o.product)), o.reward, int(maxf(0.0, o.expires_in))]))
		row.add_child(_btn("Fulfill +%s" % _money(float(o.reward)), func(): Game.fulfill_order(str(o.id)), not can, true))
		_tab_body_inner.add_child(row)

func _prod_name(pid: String) -> String:
	var p = _find_prod(pid)
	return str(p.name) if p != null else pid

func _tab_staff() -> void:
	var hired: Dictionary = Game.get_staff()
	for st in Game.get_pack().staff:
		var is_in: bool = bool(hired.get(str(st.role_id), false))
		var row := _row()
		row.add_child(_lbl("%s — %s ($%d/day)" % [st.name, st.desc, int(st.salary_per_day)]))
		if is_in:
			row.add_child(_lbl("HIRED", 13))
		else:
			var cost: float = Game.staff_hire_cost(str(st.role_id))
			row.add_child(_btn("Hire ($%.0f)" % cost, func():
				if Game.hire_staff(str(st.role_id)):
					_open_tab("Staff"), Game.get_cash() < cost))
		_tab_body_inner.add_child(row)
	_tab_body_inner.add_child(_lbl("Staff keep working while you're away (offline, 0.8x rate).", 12))

func _tab_upgrades() -> void:
	var lvls: Dictionary = Game.get_upgrades()
	for upg in Game.get_pack().upgrades:
		var lvl := int(lvls.get(str(upg.id), 0))
		var maxed: bool = lvl >= int(upg.max_level)
		var cost: float = Game.upgrade_cost(str(upg.id))
		var row := _row()
		row.add_child(_lbl("%s  Lv %d/%d — %s" % [upg.name, lvl, upg.max_level, upg.desc]))
		if maxed:
			row.add_child(_lbl("MAX", 13))
		else:
			row.add_child(_btn("Buy ($%.0f)" % cost, func():
				if Game.buy_upgrade(str(upg.id)):
					_open_tab("Upgrades"), Game.get_cash() < cost))
		_tab_body_inner.add_child(row)

func _tab_venue() -> void:
	var venues: Array = Game.get_pack().venues
	var cur := Game.get_venue_level()
	for i in venues.size():
		var v: Dictionary = venues[i]
		var row := _row()
		row.add_child(_lbl("%s — %s" % [v.name, v.desc]))
		if i == cur:
			row.add_child(_lbl("CURRENT", 13))
		elif i == cur + 1:
			row.add_child(_btn("Expand ($%.0f)" % v.cost, func():
				if Game.upgrade_venue():
					_open_tab("Venue"), Game.get_cash() < float(v.cost), true))
		else:
			row.add_child(_lbl("locked", 12))
		_tab_body_inner.add_child(row)
	_tab_body_inner.add_child(_lbl("Each venue level: +10% sale prices, -20% plot unlock cost.", 12))

func _tab_missions() -> void:
	for m in Game.get_missions():
		var row := _row()
		var status := "DONE" if m.done else "%d/%d" % [m.progress, m.target]
		row.add_child(_lbl("%s  [%s]  ($%.0f + %d xp)" % [m.desc, status, m.reward_cash, m.reward_xp]))
		_tab_body_inner.add_child(row)

func _tab_theme() -> void:
	var seen: Dictionary = Game.get_theme_seen()
	var keys := ["chilli", "coffee", "flowers", "potions", "lollies"]
	for k in keys:
		var pack := Themes.pack(k)
		var row := _row()
		row.add_child(_lbl("%s — %s%s" % [pack.name, pack.tagline, "" if seen.get(k, false) else "  (new)"]))
		row.add_child(_btn("Switch", func(): Game.switch_theme(k), k == Game.get_theme(), true))
		_tab_body_inner.add_child(row)
	_tab_body_inner.add_child(_lbl("Each business keeps its own cash, plots, staff and ranks.", 12))

func _tab_menu() -> void:
	var row1 := _row()
	var cb := CheckButton.new()
	cb.text = "Reduced motion"
	cb.button_pressed = _reduced_motion
	cb.toggled.connect(func(on: bool):
		_reduced_motion = on
		_save_settings())
	row1.add_child(cb)
	_tab_body_inner.add_child(row1)
	var row2 := _row()
	row2.add_child(_lbl("Particles:", 14))
	for lvl in 3:
		var b := _btn(str(lvl), func(): _set_particles(lvl))
		b.toggle_mode = true
		b.button_pressed = _particles == lvl
		row2.add_child(b)
	_tab_body_inner.add_child(row2)
	var row3 := _row()
	row3.add_child(_btn("Save now", func():
		Save.save_now()
		_on_toast("Saved", "good")))
	_tab_body_inner.add_child(row3)
	var row4 := _row()
	var edit := LineEdit.new()
	edit.placeholder_text = "Type RESET to confirm"
	edit.custom_minimum_size = Vector2(180, 0)
	row4.add_child(edit)
	row4.add_child(_btn("Reset save", func():
		if edit.text.to_upper() == "RESET":
			Save.reset_save()
			get_tree().reload_current_scene()
		else:
			_on_toast("Type RESET first", "bad")))
	_tab_body_inner.add_child(row4)
	_tab_body_inner.add_child(_lbl("Heat Firm v" + VERSION, 11))

func _set_particles(lvl: int) -> void:
	_particles = lvl
	_save_settings()
	_open_tab("Menu")

func _save_settings() -> void:
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"reduced_motion": _reduced_motion, "particles": _particles}))
		f.close()

func _load_settings() -> void:
	var f := FileAccess.open("user://settings.json", FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if d is Dictionary:
		_reduced_motion = bool(d.get("reduced_motion", false))
		_particles = int(d.get("particles", 1))

# ---------- toasts / flashes / particles ----------

func _on_toast(msg: String, kind: String) -> void:
	var l := Label.new()
	l.text = msg
	l.add_theme_font_size_override("font_size", 14)
	var col := Color(_pal().ui_text)
	if kind == "good":
		col = Color(0.6, 1.0, 0.6)
	elif kind == "bad":
		col = Color(1.0, 0.5, 0.5)
	l.add_theme_color_override("font_color", col)
	_toast_box.add_child(l)
	var tw := get_tree().create_timer(3.0)
	tw.timeout.connect(func():
		if is_instance_valid(l):
			l.queue_free())

func _flash(msg: String, col: Color) -> void:
	var l := Label.new()
	l.text = msg
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", col)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.reset_size()
	l.position = _root.size * 0.5 - Vector2(90, 20)
	_modal_layer.add_child(l)
	if not _reduced_motion:
		var tw := create_tween()
		tw.tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.4)
		tw.tween_callback(l.queue_free)
	else:
		var t := get_tree().create_timer(1.5)
		t.timeout.connect(l.queue_free)

func _show_offline_report(rep: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(_pal().ui_panel), Color(_pal().accent)))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.add_child(_lbl("Welcome back!", 22))
	col.add_child(_lbl(str(rep.get("summary", "")), 14))
	col.add_child(_btn("Nice", func(): panel.queue_free(), false, true))
	panel.add_child(col)
	_modal_layer.add_child(panel)
	panel.reset_size()
	panel.position = (_root.size - panel.size) * 0.5

func _spawn_particles(at: Vector2, col: Color) -> void:
	if _reduced_motion or _particles <= 0:
		return
	var n := 6 * _particles
	for i in n:
		_particles_pool.append({
			"pos": at,
			"vel": Vector2(randf_range(-60, 60), randf_range(-140, -30)),
			"life": 0.7,
			"col": col,
		})

func _step_particles() -> void:
	for i in range(_particles_pool.size() - 1, -1, -1):
		var p: Dictionary = _particles_pool[i]
		p.life = float(p.life) - 0.1
		if p.life <= 0.0:
			_particles_pool.remove_at(i)
			continue
		var vel: Vector2 = p.vel
		vel.y += 30.0
		p.vel = vel
		p.pos = (p.pos as Vector2) + vel * 0.1
	_room.particles = _particles_pool

func _select_plot(i: int) -> void:
	_selected_plot = i
	for j in 6:
		_plots[j].selected = j == i
		_plots[j].queue_redraw()
	if _active_tab == "Field":
		_open_tab("Field")

# ---------- customer vignette: silhouette + speech bubble when an order waits ----------

class CustomerView extends Control:
	var order_text := ""
	var _t := 0.0
	var _walk := 0.0  # 1 = fully walked in

	func set_order(t: String) -> void:
		order_text = t
		queue_redraw()

	func walk_in() -> void:
		_walk = 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _walk < 1.0:
			_walk = minf(_walk + delta * 1.6, 1.0)
			queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x <= 1.0:
			return
		var pal: Dictionary = Game.get_pack().palette
		var ink := Color(str(pal.ui_panel)).darkened(0.45)
		var x := (1.0 - _walk) * -70.0
		# silhouette: head + shoulders, standing on the baseline
		draw_circle(Vector2(s.x * 0.22 + x, s.y - 62.0), 11.0, ink)
		draw_rect(Rect2(s.x * 0.22 - 15.0 + x, s.y - 52.0, 30.0, 52.0), ink)
		if order_text == "":
			return
		# speech bubble with tail, gently bobbing
		var bob := sin(_t * 2.2) * 3.0
		var br := Rect2(s.x * 0.38, 4.0 + bob, s.x * 0.60, 34.0)
		var bub := Color(str(pal.ui_panel)).lightened(0.12)
		var style := StyleBoxFlat.new()
		style.bg_color = bub
		style.border_color = Color(str(pal.plot_frame))
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 4.0
		style.content_margin_bottom = 4.0
		draw_style_box(style, br)
		var pts := PackedVector2Array([Vector2(br.position.x + 8.0, br.position.y + br.size.y),
			Vector2(br.position.x - 8.0, br.position.y + br.size.y + 14.0),
			Vector2(br.position.x + 22.0, br.position.y + br.size.y)])
		draw_colored_polygon(pts, bub)
		draw_string(ThemeDB.fallback_font, br.position + Vector2(8.0, 21.0), order_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(str(pal.ui_text)))

# ---------- procedural views (drawn art, with generated-texture upgrade) ----------

class RoomView extends Control:
	static func _tex(path: String) -> Texture2D:
		# Asset contract: existence-checked load, silent fallback to _draw() art.
		if ResourceLoader.exists(path, "Texture2D"):
			return load(path) as Texture2D
		return null

	var palette := {}
	var room_style := "heat_lab"
	var floor_line := 0.60
	var night := 0.0
	var particles: Array = []
	var theme_key := "chilli"
	var _bg: Texture2D = null
	var _tex_key := ""

	func _draw() -> void:
		var s := size
		if s.x <= 1.0:
			return
		# generated backdrop if available (distinct landscape/portrait art)
		var want := "%s|%s" % [theme_key, "pt" if s.y > s.x else "ls"]
		if want != _tex_key:
			_tex_key = want
			var file := "res://assets/art/backdrop_%s%s.png" % [theme_key, "_mobile" if s.y > s.x else ""]
			_bg = _tex(file)
		if _bg != null:
			draw_texture_rect(_bg, Rect2(Vector2.ZERO, s), false)
		else:
			var top := Color(str(palette.get("sky_top", "#222222")))
			var bot := Color(str(palette.get("sky_bottom", "#444444")))
			var steps := 24
			for i in steps:
				var t := float(i) / float(steps)
				var col := top.lerp(bot, t)
				draw_rect(Rect2(0.0, t * s.y, s.x, s.y / steps + 1.0), col)
			var floor_y := floor_line * s.y
			draw_rect(Rect2(0.0, floor_y, s.x, s.y - floor_y), Color(str(palette.get("floor", "#333333"))))
			draw_rect(Rect2(0.0, floor_y, s.x, 3.0), Color(str(palette.get("plot_frame", "#666666"))))
		if night > 0.55 and night < 0.95:
			draw_rect(Rect2(Vector2.ZERO, s), Color(0.05, 0.05, 0.2, 0.35))
		for p in particles:
			draw_circle(p.pos, 3.0, Color(p.col, float(p.life)))

class PlotView extends Control:
	signal pressed
	static func _tex(path: String) -> Texture2D:
		if ResourceLoader.exists(path, "Texture2D"):
			return load(path) as Texture2D
		return null

	var index := 0
	var selected := false
	var _hover := false
	var _stage_tex: Texture2D = null
	var _stage_key := ""

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x <= 1.0:
			return
		var pal: Dictionary = Game.get_pack().palette
		var st: Dictionary = Game.get_plots()[index]
		var frame := Color(str(pal.plot_frame))
		if selected:
			frame = Color(str(pal.accent))
		draw_rect(Rect2(Vector2.ZERO, s), Color(str(pal.soil)).darkened(0.15))
		draw_rect(Rect2(Vector2(2, 2), s - Vector2(4, 4)), Color(str(pal.soil)), false, 2.0)
		draw_rect(Rect2(Vector2.ZERO, s), frame, false, 3.0 if selected else 1.0)
		if st.locked:
			draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.55))
			draw_string(ThemeDB.fallback_font, Vector2(s.x * 0.15, s.y * 0.55), "Locked", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))
			return
		if _hover:
			draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, 0.06))
		var prog: float = float(st.progress)
		if str(st.crop) != "":
			# generated 5-stage sprite if available, else drawn plant
			var stage_i: int = clampi(int(st.stage), 0, 4)
			var key := "%s|%d" % [Game.get_theme(), stage_i]
			if key != _stage_key:
				_stage_key = key
				var stg: Array = ["seedling", "leafy", "flowering", "mature", "ready"]
				_stage_tex = _tex("res://assets/art/stage_%s_%s.png" % [Game.get_theme(), stg[stage_i]])
			if _stage_tex != null:
				var tx := s.x * 0.5 - s.y * 0.45
				draw_texture_rect(_stage_tex, Rect2(tx, s.y * 0.1, s.y * 0.9, s.y * 0.9), false)
			else:
				var cols: Array = Game.get_pack().get("plant_colors", ["#4f9e3f", "#2f7a2f", "#ff5a2a"])
				var cx := s.x * 0.5
				var cy := s.y * 0.85
				var h := s.y * (0.2 + 0.55 * prog)
				draw_line(Vector2(cx, cy), Vector2(cx, cy - h), Color(str(cols[1])), maxf(2.0, s.y * 0.03))
				for side in [-1.0, 1.0]:
					draw_line(Vector2(cx, cy - h * 0.2), Vector2(cx + side * s.x * 0.14, cy - h * 0.2 - s.y * 0.06), Color(str(cols[0])), 2.0)
				if prog >= 0.6:
					draw_circle(Vector2(cx, cy - h), s.y * (0.05 + 0.04 * prog), Color(str(cols[2])))
			if prog >= 1.0:
				var t := float(Time.get_ticks_msec() % 1200) / 1200.0
				var glow_a := 0.25 + 0.2 * sin(t * TAU)
				draw_rect(Rect2(Vector2(3, 3), s - Vector2(6, 6)), Color(str(pal.glow), glow_a), false, 2.0)
			draw_rect(Rect2(Vector2(4, s.y - 6), Vector2((s.x - 8) * prog, 3)), Color(str(pal.glow)))
		var tag := ""
		if str(st.crop) == "":
			tag = "plot %d — empty" % (index + 1)
		elif st.ready:
			tag = "plot %d — READY (%s)" % [index + 1, str(st.quality)]
		else:
			tag = "plot %d — %d%%" % [index + 1, int(round(prog * 100))]
		draw_string(ThemeDB.fallback_font, Vector2(6, 14), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(str(pal.ui_text)))
