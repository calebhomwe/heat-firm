class_name GameSim
extends Node

const DAY_LEN := 120.0
const OFFLINE_CAP := 7200.0
const OFFLINE_RATE := 0.8
const RANK_XP := [0, 50, 150, 400, 900, 2000, 4500, 9000]
const QUALITY_MULT := {"normal": 1.0, "premium": 2.5, "legendary": 7.0}
const UNLOCK_COSTS := [0, 0, 0, 30, 80, 200]
const SAVE_VERSION := "heat_firm_godot_save_v1"

signal cash_changed(value: float)
signal xp_changed(xp: int, level: int, rank_title: String)
signal plot_changed(index: int, state: Dictionary)
signal harvested(index: int, yields: Dictionary)
signal crafted(product_id: String, qty: int)
signal sold(product_id: String, qty: int, revenue: float)
signal stock_sold(crop_id: String, qty: int, revenue: float)
signal order_arrived(order: Dictionary)
signal order_completed(order_id: String, reward: float)
signal order_expired(order_id: String)
signal upgrade_purchased(upg_id: String, level: int)
signal staff_hired(role_id: String)
signal venue_upgraded(level: int)
signal mission_completed(mission_id: String, reward: Dictionary)
signal rank_up(index: int, title: String)
signal theme_changed(key: String)
signal toast(msg: String, kind: String)
signal offline_report_ready(report: Dictionary)
signal day_changed(day: int, wages: float, report: Dictionary)
signal plot_unlocked(index: int)

var _themes := preload("res://src/data/theme_packs.gd").new()
var _rng := RandomNumberGenerator.new()
var _meta := {"seen": {"chilli": true}, "selected": "chilli", "seed": 1234567}
var _profiles := {}

func _init() -> void:
	_rng.seed = int(_meta.seed)
	if not _profiles.has("chilli"):
		_profiles["chilli"] = _new_profile("chilli")

func _new_profile(key: String) -> Dictionary:
	var plots := []
	for i in 6:
		plots.append({"locked": i >= 3, "crop": "", "progress": 0.0, "watered": false, "quality": "normal"})
	return {
		"cash": 25.0, "xp": 0, "day": 1, "day_t": 0.0,
		"plots": plots,
		"stock": {}, "inv": {}, "orders": [], "order_seq": 1,
		"upgrades": {}, "staff": {}, "venue": 0,
		"missions": {}, "missions_done": {},
		"event_active": null, "event_offers": [],
		"staff_t": {"harvest": 0.0, "craft": 0.0, "sell": 0.0},
		"stats": {"harvests": 0, "crafted": 0, "sold": 0, "revenue": 0.0},
		"daily": {"harvests": 0, "crafted": 0, "sold": 0, "revenue": 0.0},
		"_rank": 0,
		"_key": key,
	}

func _cur() -> Dictionary:
	return _profiles[_meta.selected]

func get_theme() -> String:
	return _meta.selected

func get_pack() -> Dictionary:
	return _themes.pack(_meta.selected)

func get_cash() -> float:
	return _cur().cash

func get_xp() -> int:
	return int(_cur().xp)

func get_level() -> int:
	return rank_index_from_xp(int(_cur().xp)) + 1

func get_rank_index() -> int:
	return rank_index_from_xp(int(_cur().xp))

func get_rank_title() -> String:
	return get_pack().ranks[get_rank_index()]

func get_next_rank_xp() -> int:
	var i := get_rank_index()
	return RANK_XP[i + 1] if i + 1 < RANK_XP.size() else 0

func get_day() -> int:
	return int(_cur().day)

func get_day_progress() -> float:
	return clampf(float(_cur().day_t) / DAY_LEN, 0.0, 1.0)

func get_plots() -> Array:
	var out := []
	for i in 6:
		out.append(_plot_pub(i))
	return out

func _plot_pub(i: int) -> Dictionary:
	var p: Variant = _cur().plots[i]
	var progress := clampf(float(p.progress), 0.0, 1.0)
	return {
		"locked": p.locked, "crop": p.crop,
		"stage": int(minf(progress, 0.999) * 5.0),
		"progress": progress, "ready": progress >= 1.0, "quality": p.quality,
	}

func get_stock() -> Dictionary:
	return _cur().stock.duplicate(true)

func get_inventory() -> Dictionary:
	return _cur().inv.duplicate(true)

func get_orders() -> Array:
	return _cur().orders.duplicate(true)

func get_upgrades() -> Dictionary:
	return _cur().upgrades.duplicate(true)

func get_staff() -> Dictionary:
	return _cur().staff.duplicate(true)

func get_venue_level() -> int:
	return int(_cur().venue)

func get_missions() -> Array:
	var out := []
	for m in get_pack().missions:
		var done := bool(_cur().missions_done.get(m.id, false))
		var progress := 0
		if not done:
			progress = int(minf(float(_cur().missions.get(m.id, 0)), float(m.target)))
		out.append({"id": m.id, "desc": m.desc, "type": m.type, "target": m.target, "progress": progress, "done": done, "reward_cash": m.reward_cash, "reward_xp": m.reward_xp})
	return out

func get_events() -> Array:
	var out := []
	for e in get_pack().events:
		out.append({"id": e.id, "name": e.name, "active": _cur().event_active == e.id, "desc": e.desc, "cost": e.cost})
	return out

func get_event_offers() -> Array:
	var out := []
	for id in _cur().event_offers:
		for e in get_pack().events:
			if e.id == id:
				out.append(e.duplicate(true))
	return out

func get_theme_seen() -> Dictionary:
	return _meta.seen.duplicate(true)

func get_event_offers_raw() -> Array:
	return _cur().event_offers.duplicate(true)

func _find(list: Array, id: String):
	for it in list:
		var k: Variant = it.get("id", it.get("role_id", null))
		if k != null and str(k) == id:
			return it
	return null

func upg_level(id: String) -> int:
	return int(_cur().upgrades.get(id, 0))

func _venue_mult() -> float:
	return 1.0 + 0.10 * float(_cur().venue)

func _event_effect(effect: String) -> bool:
	var p := _cur()
	if p.event_active == null:
		return false
	for e in get_pack().events:
		if e.id == p.event_active and e.effect == effect:
			return true
	return false

func _price_mult() -> float:
	return 1.25 if _event_effect("price_boost") else 1.0

func rank_index_from_xp(xp: int) -> int:
	var idx := 0
	for i in RANK_XP.size():
		if xp >= RANK_XP[i]:
			idx = i
	return idx

func _emit_cash() -> void:
	cash_changed.emit(_cur().cash)

func _emit_xp() -> void:
	var p := _cur()
	var after := rank_index_from_xp(int(p.xp))
	var prev := int(p.get("_rank", 0))
	if after > prev:
		rank_up.emit(after, get_pack().ranks[after])
		toast.emit("Rank up: " + get_pack().ranks[after], "good")
	p["_rank"] = after
	xp_changed.emit(int(p.xp), get_level(), get_rank_title())

func _emit_plot(i: int) -> void:
	plot_changed.emit(i, _plot_pub(i))

func plant(index: int, crop_id: String) -> bool:
	var p := _cur()
	if index < 0 or index >= 6:
		return false
	var plot: Dictionary = p.plots[index]
	if plot.locked or str(plot.crop) != "":
		return false
	var crop: Variant = _find(get_pack().crops, crop_id)
	if crop == null or p.cash < float(crop.seed_cost):
		return false
	p.cash = float(p.cash) - float(crop.seed_cost)
	plot.crop = crop_id
	plot.progress = 0.0
	plot.watered = false
	plot.quality = "normal"
	_emit_cash()
	_emit_plot(index)
	return true

func water(index: int) -> bool:
	var p := _cur()
	if index < 0 or index >= 6:
		return false
	var plot: Dictionary = p.plots[index]
	if str(plot.crop) == "" or plot.progress >= 1.0 or bool(plot.watered):
		return false
	plot.progress = minf(1.0, float(plot.progress) + 0.10)
	plot.watered = true
	_emit_plot(index)
	return true

func _yield_for(crop: Dictionary) -> int:
	var base := float(crop.base_yield)
	if _event_effect("yield_boost"):
		base += 1.0
	return int(roundf(base * (1.0 + 0.5 * float(upg_level("yield")))))

func _roll_quality() -> String:
	var p_leg := 0.02
	var p_prem := 0.18 + 0.02 * float(upg_level("quality"))
	var r := _rng.randf()
	if r < p_leg:
		return "legendary"
	if r < p_leg + p_prem:
		return "premium"
	return "normal"

func harvest(index: int) -> Dictionary:
	var p := _cur()
	if index < 0 or index >= 6:
		return {}
	var plot: Dictionary = p.plots[index]
	if str(plot.crop) == "" or float(plot.progress) < 1.0:
		return {}
	var crop: Variant = _find(get_pack().crops, str(plot.crop))
	if crop == null:
		return {}
	var qty := _yield_for(crop)
	var q := _roll_quality()
	plot.quality = q
	var cid: String = crop.id
	p.stock[cid] = int(p.stock.get(cid, 0)) + qty
	var bonus := float(qty) * float(crop.price_raw) * (float(QUALITY_MULT[q]) - 1.0)
	p.cash = float(p.cash) + bonus
	p.xp = int(p.xp) + 2
	p.stats.harvests = int(p.stats.harvests) + qty
	p.daily.harvests = int(p.daily.harvests) + qty
	plot.crop = ""
	plot.progress = 0.0
	plot.watered = false
	_missions_tick("harvest", qty)
	_emit_cash()
	_emit_plot(index)
	harvested.emit(index, {cid: qty, "quality": q})
	if q != "normal":
		toast.emit("%s harvest! +%d raw" % [q.to_upper(), qty], "good")
	return {cid: qty, "quality": q}

func craft(product_id: String, qty: int) -> int:
	var p := _cur()
	var prod: Variant = _find(get_pack().products, product_id)
	if prod == null or qty <= 0:
		return 0
	var maxc := qty
	for cid in prod.recipe:
		maxc = mini(maxc, int(p.stock.get(cid, 0)) / int(prod.recipe[cid]))
	if maxc <= 0:
		return 0
	for cid in prod.recipe:
		p.stock[cid] = int(p.stock[cid]) - int(prod.recipe[cid]) * maxc
		if int(p.stock[cid]) <= 0:
			p.stock.erase(cid)
	p.inv[product_id] = int(p.inv.get(product_id, 0)) + maxc
	p.xp = int(p.xp) + 3 * maxc
	p.stats.crafted = int(p.stats.crafted) + maxc
	p.daily.crafted = int(p.daily.crafted) + maxc
	_missions_tick("craft", maxc)
	_emit_xp()
	crafted.emit(product_id, maxc)
	return maxc

func sell(product_id: String, qty: int) -> float:
	var p := _cur()
	var prod: Variant = _find(get_pack().products, product_id)
	if prod == null or qty <= 0:
		return 0.0
	var doable := mini(qty, int(p.inv.get(product_id, 0)))
	if doable <= 0:
		return 0.0
	p.inv[product_id] = int(p.inv[product_id]) - doable
	if int(p.inv[product_id]) <= 0:
		p.inv.erase(product_id)
	var revenue := float(prod.price) * float(doable) * _venue_mult() * _price_mult()
	p.cash = float(p.cash) + revenue
	p.xp = int(p.xp) + doable
	p.stats.sold = int(p.stats.sold) + doable
	p.stats.revenue = float(p.stats.revenue) + revenue
	p.daily.sold = int(p.daily.sold) + doable
	p.daily.revenue = float(p.daily.revenue) + revenue
	_missions_tick("sell", doable)
	_missions_tick("cash", int(p.cash))
	_emit_cash()
	_emit_xp()
	sold.emit(product_id, doable, revenue)
	return revenue

func sell_stock(crop_id: String, qty: int) -> float:
	var p := _cur()
	var crop: Variant = _find(get_pack().crops, crop_id)
	if crop == null or qty <= 0:
		return 0.0
	var doable := mini(qty, int(p.stock.get(crop_id, 0)))
	if doable <= 0:
		return 0.0
	p.stock[crop_id] = int(p.stock[crop_id]) - doable
	if int(p.stock[crop_id]) <= 0:
		p.stock.erase(crop_id)
	var revenue := float(crop.price_raw) * float(doable) * _venue_mult() * _price_mult()
	p.cash = float(p.cash) + revenue
	p.stats.revenue = float(p.stats.revenue) + revenue
	p.daily.revenue = float(p.daily.revenue) + revenue
	_missions_tick("cash", int(p.cash))
	_emit_cash()
	stock_sold.emit(crop_id, doable, revenue)
	return revenue

func _find_order(order_id: String):
	for o in _cur().orders:
		if o.id == order_id:
			return o
	return null

func can_fulfill(order_id: String) -> bool:
	var o: Variant = _find_order(order_id)
	if o == null:
		return false
	return int(_cur().inv.get(str(o.product), 0)) >= int(o.qty)

func fulfill_order(order_id: String) -> float:
	var p := _cur()
	var o: Variant = _find_order(order_id)
	if o == null:
		return 0.0
	var pid: String = o.product
	if int(p.inv.get(pid, 0)) < int(o.qty):
		return 0.0
	p.inv[pid] = int(p.inv[pid]) - int(o.qty)
	if int(p.inv[pid]) <= 0:
		p.inv.erase(pid)
	p.orders.erase(o)
	p.cash = float(p.cash) + float(o.reward)
	p.xp = int(p.xp) + 8
	p.stats.sold = int(p.stats.sold) + int(o.qty)
	p.stats.revenue = float(p.stats.revenue) + float(o.reward)
	p.daily.sold = int(p.daily.sold) + int(o.qty)
	p.daily.revenue = float(p.daily.revenue) + float(o.reward)
	_missions_tick("order", 1)
	_missions_tick("sell", int(o.qty))
	_missions_tick("cash", int(p.cash))
	_emit_cash()
	_emit_xp()
	order_completed.emit(order_id, float(o.reward))
	toast.emit("Order filled for %s: +$%.0f" % [o.customer, o.reward], "good")
	return float(o.reward)

func _upg_cost(upg: Dictionary, lvl: int) -> float:
	return float(upg.base_cost) * pow(float(upg.cost_mult), float(lvl))

func upgrade_cost(upg_id: String) -> float:
	var upg: Variant = _find(get_pack().upgrades, upg_id)
	if upg == null:
		return -1.0
	return _upg_cost(upg, upg_level(upg_id))

func buy_upgrade(upg_id: String) -> bool:
	var p := _cur()
	var upg: Variant = _find(get_pack().upgrades, upg_id)
	if upg == null:
		return false
	var lvl := upg_level(upg_id)
	if lvl >= int(upg.max_level):
		return false
	var cost := _upg_cost(upg, lvl)
	if p.cash < cost:
		return false
	p.cash = float(p.cash) - cost
	p.upgrades[upg_id] = lvl + 1
	_emit_cash()
	upgrade_purchased.emit(upg_id, lvl + 1)
	toast.emit("%s -> level %d" % [upg.name, lvl + 1], "good")
	return true

func staff_hire_cost(role_id: String) -> float:
	var st: Variant = _find(get_pack().staff, role_id)
	if st == null:
		return -1.0
	return float(st.salary_per_day) * 5.0

func hire_staff(role_id: String) -> bool:
	var p := _cur()
	var st: Variant = _find(get_pack().staff, role_id)
	if st == null or bool(p.staff.get(role_id, false)):
		return false
	var cost := float(st.salary_per_day) * 5.0
	if p.cash < cost:
		return false
	p.cash = float(p.cash) - cost
	p.staff[role_id] = true
	_emit_cash()
	staff_hired.emit(role_id)
	toast.emit("Hired " + str(st.name), "good")
	return true

func upgrade_venue() -> bool:
	var p := _cur()
	var pack := get_pack()
	if p.venue >= pack.venues.size() - 1:
		return false
	var nxt: Dictionary = pack.venues[p.venue + 1]
	if p.cash < float(nxt.cost):
		return false
	p.cash = float(p.cash) - float(nxt.cost)
	p.venue = int(p.venue) + 1
	_missions_tick("venue", p.venue)
	_emit_cash()
	venue_upgraded.emit(p.venue)
	toast.emit("Expanded: " + str(nxt.name), "good")
	return true

func unlock_plot(index: int) -> bool:
	var p := _cur()
	if index < 0 or index >= 6:
		return false
	var plot: Dictionary = p.plots[index]
	if not plot.locked:
		return false
	var cost := float(UNLOCK_COSTS[index]) * (1.0 - 0.2 * float(p.venue))
	if p.cash < cost:
		return false
	p.cash = float(p.cash) - cost
	plot.locked = false
	_emit_cash()
	_emit_plot(index)
	plot_unlocked.emit(index)
	toast.emit("Plot %d unlocked" % (index + 1), "good")
	return true

func switch_theme(key: String) -> bool:
	if not _themes.keys().has(key) or key == _meta.selected:
		return false
	_meta.selected = key
	_meta.seen[key] = true
	if not _profiles.has(key):
		_profiles[key] = _new_profile(key)
	_rng.seed = int(_meta.seed)
	theme_changed.emit(key)
	return true

func activate_event(event_id: String) -> bool:
	var p := _cur()
	if p.event_active != null:
		return false
	if not p.event_offers.has(event_id):
		return false
	var ev: Variant = _find(get_pack().events, event_id)
	if ev == null or p.cash < float(ev.cost):
		return false
	p.cash = float(p.cash) - float(ev.cost)
	p.event_active = event_id
	p.event_offers = []
	_emit_cash()
	toast.emit("Event: " + str(ev.name), "good")
	return true

func _growth_mult() -> float:
	var m := 1.0 - 0.08 * float(upg_level("growth"))
	if _event_effect("growth_boost"):
		m *= 1.6
	return m

func _product_margin(prod: Dictionary) -> float:
	# Margin = sale price minus the raw-crop market value consumed by the recipe.
	var raw_cost := 0.0
	for cid in prod.recipe:
		var crop: Variant = _find(get_pack().crops, cid)
		if crop != null:
			raw_cost += float(crop.price_raw) * float(prod.recipe[cid])
	return float(prod.price) - raw_cost

func _best_craftable_product() -> String:
	# Best-margin product that can actually be crafted from current raw stock.
	var p := _cur()
	var best_id := ""
	var best_margin := -INF
	for prod in get_pack().products:
		var craftable := true
		for cid in prod.recipe:
			if int(p.stock.get(cid, 0)) < int(prod.recipe[cid]):
				craftable = false
				break
		if craftable and _product_margin(prod) > best_margin:
			best_margin = _product_margin(prod)
			best_id = str(prod.id)
	return best_id

func _staff_act(role: String) -> void:
	var p := _cur()
	match role:
		"harvest":
			for i in 6:
				if _plot_pub(i).ready:
					harvest(i)
					return
		"craft":
			var pid := _best_craftable_product()
			if pid != "":
				craft(pid, 1)
		"sell":
			var best: Dictionary = {}
			var best_val := -1.0
			for o in p.orders:
				if int(p.inv.get(str(o.product), 0)) >= int(o.qty) and float(o.reward) > best_val:
					best = o
					best_val = float(o.reward)
			if not best.is_empty():
				fulfill_order(str(best.id))
				return
			for pid in p.inv:
				if int(p.inv[pid]) > 0:
					sell(pid, 2)
					return
			for cid in p.stock:
				if int(p.stock[cid]) > 0:
					sell_stock(cid, 2)
					return

func _spawn_order() -> void:
	var p := _cur()
	var prods: Array = get_pack().products
	var custs: Array = get_pack().customers
	var prod: Dictionary = prods[_rng.randi_range(0, prods.size() - 1)]
	var cust: Dictionary = custs[_rng.randi_range(0, custs.size() - 1)]
	var qty := _rng.randi_range(2, 3 + int(p.venue))
	# Expiry must leave room to physically grow the recipe's crops from scratch:
	# two full sequential grow cycles of every recipe crop, plus a 60s buffer.
	# (A venue-3 qty-6 mixed-recipe order needs two back-to-back crop cycles, which
	# the old flat 60s minimum could expire before.)
	var grow_need := 0.0
	for cid in prod.recipe:
		var rc: Variant = _find(get_pack().crops, cid)
		if rc != null:
			grow_need += float(rc.grow_time)
	var o := {
		"id": "o%d" % int(p.order_seq),
		"product": prod.id,
		"qty": qty,
		"reward": float(prod.price) * float(qty) * (1.35 + _rng.randf() * 0.25),
		"customer": cust.name,
		"mood": cust.mood,
		"expires_in": 60.0 + grow_need * 2.0 + _rng.randf() * 120.0,
	}
	p.order_seq = int(p.order_seq) + 1
	p.orders.append(o)
	order_arrived.emit(o)
	toast.emit("New order: %s wants %d x %s" % [cust.name, qty, prod.name], "info")

func _day_end() -> void:
	var p := _cur()
	var wages := 0.0
	for st in get_pack().staff:
		if bool(p.staff.get(str(st.role_id), false)):
			wages += float(st.salary_per_day)
	p.cash = maxf(0.0, float(p.cash) - wages)
	p.event_active = null
	var evs: Array = get_pack().events
	p.event_offers = [evs[_rng.randi_range(0, evs.size() - 1)].id]
	_spawn_order()
	if _rng.randf() < 0.5:
		_spawn_order()
	p.xp = int(p.xp)
	_missions_tick("venue", p.venue)
	_missions_tick("cash", int(p.cash))
	var report := {
		"harvests": int(p.daily.harvests), "crafted": int(p.daily.crafted),
		"sold": int(p.daily.sold), "revenue": float(p.daily.revenue), "wages": wages,
	}
	p.daily = {"harvests": 0, "crafted": 0, "sold": 0, "revenue": 0.0}
	_emit_cash()
	_emit_xp()
	day_changed.emit(int(p.day), wages, report)

func _missions_tick(type: String, amount: int) -> void:
	var p := _cur()
	for m in get_pack().missions:
		if bool(p.missions_done.get(m.id, false)):
			continue
		if m.type != type:
			continue
		var newp: int
		if type == "cash":
			newp = int(minf(float(amount), float(m.target)))
		elif type == "venue":
			newp = int(minf(float(amount), float(m.target)))
		else:
			newp = int(p.missions.get(m.id, 0)) + amount
		p.missions[m.id] = newp
		if newp >= int(m.target):
			p.missions_done[m.id] = true
			p.cash = float(p.cash) + float(m.reward_cash)
			p.xp = int(p.xp) + int(m.reward_xp)
			mission_completed.emit(m.id, {"cash": m.reward_cash, "xp": m.reward_xp})
			toast.emit("Mission complete: " + str(m.desc), "good")
	_emit_xp()

func tick(dt: float) -> void:
	var p := _cur()
	p.day_t = float(p.day_t) + dt
	var grow_mult := _growth_mult()
	var pack := get_pack()
	for i in 6:
		var plot: Dictionary = p.plots[i]
		if str(plot.crop) != "" and float(plot.progress) < 1.0:
			var crop: Variant = _find(pack.crops, str(plot.crop))
			if crop != null:
				plot.progress = minf(1.0, float(plot.progress) + dt * grow_mult / float(crop.grow_time))
				if float(plot.progress) >= 1.0:
					_emit_plot(i)
					toast.emit("Ready: plot %d" % (i + 1), "info")
	if not p.staff.is_empty():
		var intervals := {"harvest": 4.0, "craft": 8.0, "sell": 12.0}
		for role in ["harvest", "craft", "sell"]:
			if bool(p.staff.get(role, false)):
				p.staff_t[role] = float(p.staff_t[role]) + dt
				while float(p.staff_t[role]) >= float(intervals[role]):
					p.staff_t[role] = float(p.staff_t[role]) - float(intervals[role])
					_staff_act(role)
	var expired := []
	for o in p.orders:
		o.expires_in = float(o.expires_in) - dt
		if float(o.expires_in) <= 0.0:
			expired.append(o.id)
	for oid in expired:
		for j in range(p.orders.size() - 1, -1, -1):
			if p.orders[j].id == oid:
				p.orders.remove_at(j)
				order_expired.emit(oid)
				toast.emit("Order expired", "bad")
	if float(p.day_t) >= DAY_LEN:
		p.day_t = float(p.day_t) - DAY_LEN
		p.day = int(p.day) + 1
		_day_end()

func compute_offline(seconds: float) -> Dictionary:
	var cap := minf(seconds, OFFLINE_CAP)
	var p := _cur()
	var rep := {"seconds": cap, "cash_earned": 0.0, "harvests": 0, "crafted": 0, "sold": 0, "summary": ""}
	if cap <= 0.0:
		return rep
	var hired := []
	for role in ["harvest", "craft", "sell"]:
		if bool(p.staff.get(role, false)):
			hired.append(role)
	if hired.is_empty():
		rep.summary = "No staff hired - the greenhouse slept peacefully."
		return rep
	var cash_before := float(p.cash)
	var grow_mult := _growth_mult()
	var pack := get_pack()
	var t := 0.0
	var dt := 1.0
	var h_acc := 0.0
	var c_acc := 0.0
	var s_acc := 0.0
	while t < cap:
		for i in 6:
			var plot: Dictionary = p.plots[i]
			if str(plot.crop) != "" and float(plot.progress) < 1.0:
				var crop: Variant = _find(pack.crops, str(plot.crop))
				if crop != null:
					plot.progress = minf(1.0, float(plot.progress) + dt * OFFLINE_RATE * grow_mult / float(crop.grow_time))
		if "harvest" in hired:
			h_acc += dt
			while h_acc >= 4.0 / OFFLINE_RATE:
				h_acc -= 4.0 / OFFLINE_RATE
				for i in 6:
					if _plot_pub(i).ready:
						var y := harvest(i)
						if not y.is_empty():
							rep.harvests += 1
						break
			if "craft" in hired:
				c_acc += dt
				while c_acc >= 8.0 / OFFLINE_RATE:
					c_acc -= 8.0 / OFFLINE_RATE
					var best_pid := _best_craftable_product()
					if best_pid != "":
						var n := craft(best_pid, 1)
						if n > 0:
							rep.crafted += n
		if "sell" in hired:
			s_acc += dt
			while s_acc >= 12.0 / OFFLINE_RATE:
				s_acc -= 12.0 / OFFLINE_RATE
				var did_order := false
				for o in p.orders:
					if int(p.inv.get(str(o.product), 0)) >= int(o.qty):
						fulfill_order(str(o.id))
						rep.sold += int(o.qty)
						did_order = true
						break
				if did_order:
					continue
				var did_prod := false
				for pid in p.inv:
					if int(p.inv[pid]) > 0:
						var r := sell(pid, 2)
						if r > 0.0:
							rep.sold += 2
						did_prod = true
						break
				if did_prod:
					continue
				for cid in p.stock:
					if int(p.stock[cid]) > 0:
						var r2 := sell_stock(cid, 2)
						if r2 > 0.0:
							rep.sold += 2
						break
		t += dt
	rep.cash_earned = float(p.cash) - cash_before
	rep.summary = "Your crew worked %d minutes: +%d harvests, +%d crafted, +%d sold, +$%.0f" % [int(cap / 60.0), rep.harvests, rep.crafted, rep.sold, rep.cash_earned]
	_emit_cash()
	_emit_xp()
	return rep

func serialize() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"meta": _meta.duplicate(true),
		"profiles": _profiles.duplicate(true),
		"last_seen_unix": int(Time.get_unix_time_from_system()),
	}

func restore(d: Dictionary) -> void:
	if not (d is Dictionary) or d.is_empty():
		return
	var m: Variant = d.get("meta", null)
	if m is Dictionary:
		var seen: Variant = m.get("seen", null)
		if seen is Dictionary:
			_meta.seen = seen.duplicate(true)
		var sel: Variant = m.get("selected", null)
		if sel is String and _themes.keys().has(sel):
			_meta.selected = sel
		var seed: Variant = m.get("seed", null)
		if seed != null:
			_meta.seed = seed
			_rng.seed = int(seed)
	var profs: Variant = d.get("profiles", null)
	if profs is Dictionary:
		for k in profs:
			if profs[k] is Dictionary:
				var merged := _new_profile(k)
				merged.merge(profs[k], true)
				_profiles[k] = merged
	if not _profiles.has(_meta.selected):
		if _themes.keys().has(_meta.selected):
			_profiles[_meta.selected] = _new_profile(_meta.selected)
		else:
			_meta.selected = "chilli"
	_profiles["chilli"] = _profiles.get("chilli", _new_profile("chilli"))
	_meta.seen["chilli"] = true
	if not _meta.seen.has(_meta.selected):
		_meta.seen[_meta.selected] = true
	_rng.seed = int(_meta.seed)
