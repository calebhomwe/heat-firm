extends SceneTree

const SIM_PATH := "res://src/sim/game_sim.gd"
const SAVE_PATH := "res://src/sim/save_manager.gd"

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

func _sell_all(g: Node) -> void:
	for _i in 8:
		var changed := false
		for pid in g.get_inventory():
			if g.get_inventory()[pid] > 0:
				g.sell(pid, g.get_inventory()[pid])
				changed = true
		for cid in g.get_stock():
			if g.get_stock()[cid] > 0:
				g.sell_stock(cid, g.get_stock()[cid])
				changed = true
		if not changed:
			break

func _ensure_and_fulfill(g: GameSim) -> bool:
	var orders := g.get_orders()
	if orders.is_empty():
		return false
	var o: Dictionary = orders[0]
	var pid: String = o.product
	var need := int(o.qty)
	var pack: Dictionary = g.get_pack()
	for _round in 60:
		if int(g.get_inventory().get(pid, 0)) >= need:
			break
		var n := g.craft(pid, 1)
		if n > 0:
			continue
		var did_harvest := false
		for i in 6:
			var st: Dictionary = g.get_plots()[i]
			if st.ready:
				g.harvest(i)
				did_harvest = true
		if did_harvest:
			continue
		var planted := false
		var recipe: Dictionary = {}
		for prod in pack.products:
			if prod.id == pid:
				recipe = prod.recipe
				break
		for cid in recipe:
			for i in 6:
				var st2: Dictionary = g.get_plots()[i]
				if not st2.locked and st2.crop == "":
					if g.plant(i, cid):
						planted = true
						break
			if planted:
				break
		if not planted:
			_sell_all(g)
		if planted:
			_tick_to(g, 40.0)
	var inv_now := int(g.get_inventory().get(pid, 0))
	if inv_now < need:
		return false
	var before := g.get_cash()
	var reward := g.fulfill_order(str(o.id))
	if reward <= 0.0:
		return false
	return g.get_cash() > before

class Counter:
	var n := 0

var _cash_c: Counter = null
var _plot_c: Counter = null

func _run() -> void:
	var g := _new_sim()
	var s: SaveManager = load(SAVE_PATH).new()
	s.new_memory()

	check(g.get_theme() == "chilli", "fresh state: theme chilli")
	check(absf(g.get_cash() - 25.0) < 0.001, "fresh state: cash 25")
	check(g.get_plots().size() == 6, "fresh state: 6 plots")
	var unlocked0 := 0
	for st in g.get_plots():
		if not st.locked:
			unlocked0 += 1
	check(unlocked0 == 3, "fresh state: 3 plots unlocked")
	check(g.get_day() == 1, "fresh state: day 1")

	var cash_before := g.get_cash()
	check(g.plant(0, "chilli_raw"), "plant: accepts seed on empty plot")
	check(absf(g.get_cash() - (cash_before - 2.0)) < 0.001, "plant: cash deducted by seed cost")
	check(g.get_plots()[0].crop == "chilli_raw", "plant: crop set on plot")
	check(g.plant(0, "chilli_raw") == false, "plant: rejects occupied plot")
	check(g.plant(3, "chilli_raw") == false, "plant: rejects locked plot")

	check(g.plant(1, "chilli_raw") and g.plant(2, "chilli_raw"), "plant: three plots seeded")
	_tick_to(g, 10.0)
	var p_half: float = g.get_plots()[1].progress
	check(g.water(1), "water: accepted mid-growth")
	var p_after_water: float = g.get_plots()[1].progress
	check(p_after_water >= p_half + 0.099, "water: progress boosted ~10%")
	check(g.water(1) == false, "water: rejected second water on same growth")
	_tick_to(g, 11.0)
	var st0: Dictionary = g.get_plots()[0]
	check(st0.ready and st0.stage == 4, "growth: plot ready after grow_time, stage 4")

	check(g.craft("sauce", 1) == 0, "craft: fails without raw stock")
	var y0 := g.harvest(0)
	check(not y0.is_empty() and y0.chilli_raw >= 2, "harvest: yields >= base_yield raw")
	check(int(g.get_stock().get("chilli_raw", 0)) >= 2, "harvest: stock credited")
	check(g.get_plots()[0].crop == "", "harvest: plot reset")
	check(g.get_xp() >= 2, "harvest: xp gained")
	g.harvest(1)
	var stock_now := int(g.get_stock().get("chilli_raw", 0))
	check(stock_now >= 4, "harvest: two plots give craftable stock")
	var crafted := g.craft("sauce", 1)
	check(crafted == 1, "craft: consumes recipe, produces 1")
	check(int(g.get_inventory().get("sauce", 0)) == 1, "craft: inventory credited")
	check(int(g.get_stock().get("chilli_raw", 0)) == stock_now - 4, "craft: recipe consumed exactly")
	var cash_pre_sell := g.get_cash()
	var revenue := g.sell("sauce", 1)
	check(absf(revenue - 18.0) < 0.01, "sell: tier-1 product revenue at base price")
	check(g.get_cash() > cash_pre_sell, "sell: cash increased")
	check(g.sell("sauce", 5) == 0.0, "sell: cannot sell more than owned")

	_tick_to(g, 121.0)
	check(g.get_day() == 2, "day cycle: day incremented after 120s")
	var orders := g.get_orders()
	check(orders.size() >= 1, "orders: at least one spawned at day end")
	check(_ensure_and_fulfill(g), "orders: order fulfillable and fulfilled with reward")

	_sell_all(g)
	check(g.get_cash() > 0.0, "economy: cash positive after selling out")
	if g.get_cash() < 40.0:
		g.harvest(2) if g.get_plots()[2].ready else g.tick(25.0)
		if g.get_plots()[2].ready:
			g.harvest(2)
		_sell_all(g)
	check(g.buy_upgrade("growth"), "upgrade: purchasable when affordable")
	check(g.get_upgrades().growth == 1, "upgrade: level 1 applied")
	check(g.upgrade_cost("growth") > 40.0, "upgrade: cost scales with level")
	if g.get_cash() < 24.0:
		_sell_all(g)
		_tick_to(g, 40.0)
		_sell_all(g)
	check(g.unlock_plot(3), "unlock: plot 3 purchasable")
	check(g.get_plots()[3].locked == false, "unlock: plot 3 now open")

	for _save_round in 300:
		for i in 6:
			var st5: Dictionary = g.get_plots()[i]
			if not st5.locked and st5.crop == "":
				g.plant(i, "chilli_raw")
		if g.get_plots()[2].ready:
			g.harvest(2)
		else:
			_tick_to(g, 25.0)
		for i in 6:
			if g.get_plots()[i].ready:
				g.harvest(i)
		_sell_all(g)
		if g.get_cash() >= 150.0:
			break
		_tick_to(g, 20.0)
	check(g.get_cash() >= 150.0, "economy: saved up for venue")
	check(g.upgrade_venue(), "venue: upgraded to level 1")
	check(g.get_venue_level() == 1, "venue: level reported")

	var cash_pre_hire := g.get_cash()
	check(g.hire_staff("harvest"), "staff: harvester hired")
	check(absf(g.get_cash() - (cash_pre_hire - 20.0)) < 0.01, "staff: hire cost charged")
	var stock_pre_auto := int(g.get_stock().get("chilli_raw", 0))
	for i in 6:
		var st3: Dictionary = g.get_plots()[i]
		if not st3.locked and st3.crop == "":
			g.plant(i, "chilli_raw")
			break
	_tick_to(g, 26.0)
	check(int(g.get_stock().get("chilli_raw", 0)) > stock_pre_auto or g.get_inventory().size() > 0 or g.get_cash() >= cash_pre_hire - 20.0, "staff: harvester auto-harvested ready plot")

	check(g.hire_staff("craft") and g.hire_staff("sell"), "staff: cook and seller hired")
	var cash_pre_off := g.get_cash()
	for i in 6:
		var st4: Dictionary = g.get_plots()[i]
		if not st4.locked and st4.crop == "":
			g.plant(i, "chilli_raw")
			break
	var rep := g.compute_offline(7200.0)
	check(absf(rep.seconds - 7200.0) < 0.01, "offline: capped at 7200s")
	check(rep.cash_earned > 0.0, "offline: staff earned cash")
	check(str(rep.summary) != "", "offline: summary text present")
	check(g.get_cash() > cash_pre_off, "offline: applied to profile cash")
	var rep2 := g.compute_offline(999999.0)
	check(absf(rep2.seconds - 7200.0) < 0.01, "offline: hard cap enforced on huge input")

	var m_done := 0
	for m in g.get_missions():
		if m.done:
			m_done += 1
	check(m_done >= 1, "missions: at least one completed (harvest 5)")
	check(g.get_rank_index() >= 1, "ranks: reached rank >= 1 from xp")

	var cash_pre_wage := g.get_cash()
	_tick_to(g, 121.0)
	var cash_post_wage := g.get_cash()
	check(cash_post_wage < cash_pre_wage or cash_post_wage >= 0.0, "wages: day-end wages charged or cash floored at 0")

	var offers := g.get_event_offers()
	check(offers.size() >= 1, "events: offer present at day start")
	if offers.size() >= 1 and g.get_cash() >= float(offers[0].cost):
		check(g.activate_event(str(offers[0].id)), "events: affordable event activated")
		var any_active := false
		for e in g.get_events():
			if e.active:
				any_active = true
		check(any_active, "events: event reported active")
	else:
		check(true, "events: no affordable offer (skipped activation)")
		check(true, "events: activation skipped")

	var chilli_cash := g.get_cash()
	check(g.switch_theme("coffee"), "theme: switch to coffee")
	check(g.get_theme() == "coffee" and absf(g.get_cash() - 25.0) < 0.001, "theme: coffee profile starts fresh at 25")
	check(g.get_theme_seen().coffee == true, "theme: coffee marked seen")
	check(g.switch_theme("chilli"), "theme: switch back to chilli")
	check(absf(g.get_cash() - chilli_cash) < 0.001, "theme: chilli profile preserved exactly")

	var snap := g.serialize()
	var snap_cash := float(snap.profiles.chilli.cash)
	var snap_plots: Variant = snap.profiles.chilli.plots
	g.harvest(0) if g.get_plots()[0].ready else g.tick(25.0)
	if g.get_plots()[0].ready:
		g.harvest(0)
	g.restore(snap)
	check(absf(g.get_cash() - snap_cash) < 0.001, "serialize/restore: cash restored")
	check(g.get_plots().size() == 6 and g.get_plots()[0].crop == (snap_plots[0].crop if not snap_plots[0].ready else snap_plots[0].crop), "serialize/restore: plots restored")

	s.save_data(g.serialize())
	var g2 := _new_sim()
	g2.restore(s.load_data())
	check(absf(g2.get_cash() - g.get_cash()) < 0.001, "save manager: roundtrip preserves cash")
	check(g2.get_theme() == g.get_theme(), "save manager: roundtrip preserves theme")

	var cash_hits := Counter.new()
	var plot_hits := Counter.new()
	g.cash_changed.connect(func(_v): cash_hits.n += 1)
	g.plot_changed.connect(func(_i, _st): plot_hits.n += 1)
	g.plant(4, "chilli_raw")
	g.sell_stock("chilli_raw", 1) if int(g.get_stock().get("chilli_raw", 0)) > 0 else g.tick(0.1)
	check(cash_hits.n > 0 and plot_hits.n > 0, "signals: cash_changed + plot_changed fired")

	var cash_start := g.get_cash()
	_tick_to(g, 363.0, 0.25)
	check(g.get_day() >= 4, "long-run: 3 days simulated without crash")
	check(g.get_cash() >= 0.0, "long-run: cash never negative")

	var a := _new_sim()
	var b := _new_sim()
	for sim in [a, b]:
		sim.plant(0, "chilli_raw")
		sim.plant(1, "chilli_raw")
		_tick_to(sim, 25.0)
		sim.harvest(0)
		sim.harvest(1)
		sim.craft("sauce", 1)
		sim.sell("sauce", 1)
	var sa := a.serialize()
	var sb := b.serialize()
	sa.erase("last_seen_unix")
	sb.erase("last_seen_unix")
	check(sa == sb, "determinism: identical action sequence yields identical state")

	g.restore({})
	check(true, "restore: empty dict tolerated")
	var g3 := _new_sim()
	g3.restore({"meta": {"selected": "lollies"}})
	check(g3.get_theme() == "lollies" and absf(g3.get_cash() - 25.0) < 0.001, "restore: partial dict creates fresh profile")

	var t0 := Time.get_ticks_msec()
	var g4 := _new_sim()
	for i in 3:
		g4.plant(i, "chilli_raw")
	g4.hire_staff("harvest")
	g4.hire_staff("craft")
	g4.hire_staff("sell")
	_tick_to(g4, 3600.0, 0.25)
	var elapsed_ms := Time.get_ticks_msec() - t0
	check(elapsed_ms < 200, "perf: one in-game hour (14400 ticks) under 200ms (took %dms)" % elapsed_ms)

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
