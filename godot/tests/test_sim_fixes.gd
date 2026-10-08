# Additive tests for wave2 sim fixes (B2): price_boost, best-margin crafting,
# order fulfillability. Run: godot --headless --path . --script res://tests/test_sim_fixes.gd
extends SceneTree

const SIM_PATH := "res://src/sim/game_sim.gd"

var _pass := 0
var _fail := 0
var _total := 0
var _fails: Array[String] = []

func check(cond: bool, msg: String) -> void:
	_total += 1
	if cond:
		_pass += 1
		print("PASS %d/%d: %s" % [_total, _total, msg])
	else:
		_fail += 1
		_fails.append(msg)
		print("FAIL %d/%d: %s" % [_total, _total, msg])

func _new_sim() -> GameSim:
	return load(SIM_PATH).new()

func _tick_to(g: Node, seconds: float, step: float = 0.1) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		g.tick(step)
		t += step

func _stock_up(g: GameSim, stock: Dictionary) -> void:
	var p: Dictionary = g._cur()
	p.stock = stock.duplicate(true)

func _run() -> void:
	# ---- Fix 1: price_boost applies to sell() and sell_stock(), expires at day end
	var g := _new_sim()
	for i in 3:
		g.plant(i, "chilli_raw")
	_tick_to(g, 21.0)
	for i in 3:
		g.harvest(i)
	check(g.craft("sauce", 1) == 1, "price_boost setup: sauce crafted")
	check(absf(g.sell("sauce", 1) - 18.0) < 0.01, "price_boost: baseline product sale is 18.0 (no event)")
	_stock_up(g, {"chilli_raw": 12})
	check(g.craft("sauce", 1) == 1, "price_boost: second sauce crafted from stocked raw")
	var p: Dictionary = g._cur()
	p.cash = 100.0
	p.event_offers = ["festival"]
	check(g.activate_event("festival"), "price_boost: festival event activated")
	check(absf(g.sell("sauce", 1) - 18.0 * 1.25) < 0.01, "price_boost: product sale x1.25 while event active")
	var raw_left := int(g.get_stock().get("chilli_raw", 0))
	if raw_left > 0:
		var base := 1.5 * float(raw_left)
		var got := g.sell_stock("chilli_raw", raw_left)
		check(absf(got - base * 1.25) < 0.01, "price_boost: raw stock sale x1.25 while event active")
	else:
		check(false, "price_boost: expected leftover raw stock to sell")
	# event expires at day end
	var day_now := g.get_day()
	_tick_to(g, 130.0)
	check(g.get_day() > day_now, "price_boost: day rolled over")
	check(g._cur().event_active == null, "price_boost: event cleared at day end")
	while int(g.get_stock().get("chilli_raw", 0)) < 4 and g.get_day() < day_now + 4:
		for i in 3:
			if not g.get_plots()[i].locked and g.get_plots()[i].crop == "":
				g.plant(i, "chilli_raw")
		_tick_to(g, 21.0)
		for i in 3:
			if g.get_plots()[i].ready:
				g.harvest(i)
	check(g.craft("sauce", 1) == 1, "price_boost expiry: sauce crafted after event expired")
	check(absf(g.sell("sauce", 1) - 18.0) < 0.01, "price_boost: sale back to 18.0 after event expired")

	# ---- Fix 2: staff craft picks best-margin craftable product, not pack order
	var g2 := _new_sim()
	_stock_up(g2, {"chilli_raw": 4, "chilli_hab": 3})
	check(g2._best_craftable_product() == "inferno_ketchup", "best-craft: ketchup is best margin (95 vs 12/42) when craftable")
	g2._staff_act("craft")
	check(int(g2.get_inventory().get("inferno_ketchup", 0)) == 1, "best-craft: staff crafted the best-margin product")
	check(int(g2.get_inventory().get("sauce", 0)) == 0, "best-craft: pack-order sauce NOT crafted when better margin exists")
	var g3 := _new_sim()
	_stock_up(g3, {"chilli_raw": 4})
	check(g3._best_craftable_product() == "sauce", "best-craft: falls back to only craftable product")
	g3._staff_act("craft")
	check(int(g3.get_inventory().get("sauce", 0)) == 1, "best-craft: fallback crafted when only sauce possible")
	# via the real tick path (hired craft staff)
	var g4 := _new_sim()
	g4._cur().cash = 1000.0
	check(g4.hire_staff("craft"), "best-craft: craft staff hired")
	_stock_up(g4, {"chilli_raw": 4, "chilli_hab": 3})
	_tick_to(g4, 8.5)
	check(int(g4.get_inventory().get("inferno_ketchup", 0)) >= 1, "best-craft: tick-driven staff crafts best-margin product")
	check(int(g4.get_inventory().get("sauce", 0)) == 0, "best-craft: tick-driven staff skips lower-margin sauce")
	var g5 := _new_sim()
	_stock_up(g5, {})
	check(g5._best_craftable_product() == "", "best-craft: empty stock -> no product")
	g5._staff_act("craft")
	check(g5.get_inventory().is_empty(), "best-craft: no-op with empty stock")

	# ---- Fix 3: order expiry always physically fulfillable at every venue level
	var themes: Node = load("res://src/data/theme_packs.gd").new()
	var keys: Array = themes.keys()
	for key in keys:
		var gg := _new_sim()
		gg.switch_theme(key)
		var pack: Dictionary = gg.get_pack()
		for venue in 4:
			gg._cur().venue = venue
			var max_qty := 3 + venue
			for prod in pack.products:
				# Worst-case from-cold-start time: sequential grow batches of 6 plots
				# at base yield for every crop the recipe needs.
				var grow_time := 0.0
				for cid in prod.recipe:
					var crop: Variant = null
					for c in pack.crops:
						if c.id == cid:
							crop = c
							break
					var need := int(prod.recipe[cid]) * max_qty
					var harvests := int(ceil(float(need) / float(crop.base_yield)))
					var batches := int(ceil(float(harvests) / 6.0))
					grow_time += float(crop.grow_time) * float(batches)
				var min_expiry := 60.0
				for cid in prod.recipe:
					for c in pack.crops:
						if c.id == cid:
							min_expiry += 2.0 * float(c.grow_time)
							break
				check(min_expiry > grow_time + 5.0, "orders: %s venue %d %s min expiry %.0fs covers worst-case grow %.0fs" % [key, venue, prod.id, min_expiry, grow_time])
	# dynamic spot check: spawned order honors the scaled minimum
	var g6 := _new_sim()
	g6._cur().venue = 3
	g6._spawn_order()
	var o: Dictionary = g6.get_orders()[0]
	var prod6: Dictionary = {}
	for prod in g6.get_pack().products:
		if prod.id == o.product:
			prod6 = prod
	var min_exp := 60.0
	for cid in prod6.recipe:
		for c in g6.get_pack().crops:
			if c.id == cid:
				min_exp += 2.0 * float(c.grow_time)
				break
	check(float(o.expires_in) >= min_exp - 0.001, "orders: spawned venue-3 order expiry >= scaled minimum (%.1f >= %.1f)" % [float(o.expires_in), min_exp])

	print("")
	if _fail == 0:
		print("PASS %d/%d" % [_total, _total])
	else:
		print("RESULT: %d/%d passed" % [_pass, _total])
		for f in _fails:
			print("  failed: %s" % f)
	quit(1 if _fail > 0 else 0)

func _init() -> void:
	_run()
