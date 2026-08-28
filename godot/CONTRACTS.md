# Heat Firm (Godot) — Build Contracts

Godot 4.7.2 (binary: `..\tools\godot\godot.exe`). GDScript only. 2D, GL Compatibility renderer.
Base viewport 1280x720, stretch canvas_items + expand. Main scene builds ALL UI in code (the .tscn is a 1-node root).

## Directory ownership (STRICT — never write outside your area)

| Area | Owner |
|---|---|
| `src/data/**`, `src/sim/**` | Agent A (sim core) |
| `src/scene/**` (all UI + room) | Agent B (scene/UI) |
| `tools/artgen/**`, `assets/art/**`, `assets/asset-manifest.json`, `docs/ART_DIRECTION.md` | Agent D (art) |
| `tools/qa/**`, `tests/**`, `docs/VISUAL_ACCEPTANCE.md`, `README.md`, `tools/*.bat`, `qa/**` | Agent C (QA/pipeline) |
| `project.godot`, this file | orchestrator (do not modify) |

## Autoloads (order matters)

- `Themes` = `res://src/data/theme_packs.gd` — data only, no state.
- `Game` = `res://src/sim/game_sim.gd` — all simulation state + public API.
- `Save` = `res://src/sim/save_manager.gd` — persistence + offline report; loads Game in `_ready` (order above guarantees Game exists).

Theme keys: `"chilli"`, `"coffee"`, `"flowers"`, `"potions"`, `"lollies"`.
Save file: `user://save.json`, version key `"heat_firm_godot_save_v1"`.

## Game API (Agent A implements; B/C call ONLY these — never touch Game internals)

```gdscript
# signals
signal cash_changed(value: float)
signal xp_changed(xp: int, level: int, rank_title: String)
signal plot_changed(index: int, state: Dictionary)   # state: {crop:String, stage:int, progress:float, ready:bool, locked:bool}
signal harvested(index: int, yields: Dictionary)      # {product_id: int}
signal crafted(product_id: String, qty: int)
signal sold(product_id: String, qty: int, revenue: float)
signal order_arrived(order: Dictionary)               # {id, product, qty, reward, customer, mood, expires_in}
signal order_completed(order_id: String, reward: float)
signal order_expired(order_id: String)
signal upgrade_purchased(upg_id: String, level: int)
signal staff_hired(role_id: String)
signal venue_upgraded(level: int)
signal mission_completed(mission_id: String, reward: Dictionary)
signal rank_up(index: int, title: String)
signal theme_changed(key: String)
signal toast(msg: String, kind: String)               # kind: "info"|"good"|"bad"
signal offline_report_ready(report: Dictionary)       # {seconds, cash_earned, harvests, crafted, sold, summary:String}
signal day_changed(day: int, wages: float, report: Dictionary)

# getters
func get_theme() -> String
func get_pack() -> Dictionary          # Themes.pack(get_theme())
func get_cash() -> float
func get_xp() -> int
func get_level() -> int
func get_rank_index() -> int
func get_rank_title() -> String
func get_next_rank_xp() -> int
func get_day() -> int                  # 1 day = 120 real seconds
func get_day_progress() -> float       # 0..1
func get_plots() -> Array              # 6 dicts: {locked:bool, crop:String, stage:int(0..4), progress:float(0..1), ready:bool, quality:String}
func get_stock() -> Dictionary         # {crop_id: int}
func get_inventory() -> Dictionary     # {product_id: int}
func get_orders() -> Array             # active orders
func get_upgrades() -> Dictionary      # {upg_id: int(level)}
func get_staff() -> Dictionary         # {role_id: bool(hired)}
func get_venue_level() -> int          # 0..3
func get_missions() -> Array           # {id, desc, type, target:int, progress:int, done:bool, reward_cash:float, reward_xp:int}
func get_events() -> Array             # {id, name, active:bool, desc}  (max 1 active)
func get_theme_seen() -> Dictionary    # {key: bool} discovered themes

# actions (all return bool unless noted)
func plant(index: int, crop_id: String) -> bool
func water(index: int) -> bool         # small progress boost, once per growth
func harvest(index: int) -> Dictionary # empty dict if not ready
func craft(product_id: String, qty: int) -> int   # actual qty crafted (0 if impossible)
func sell(product_id: String, qty: int) -> float  # revenue
func sell_stock(crop_id: String, qty: int) -> float
func fulfill_order(order_id: String) -> float
func buy_upgrade(upg_id: String) -> bool
func hire_staff(role_id: String) -> bool
func upgrade_venue() -> bool
func unlock_plot(index: int) -> bool
func switch_theme(key: String) -> bool # per-theme profiles; cash/xp/plots are PER THEME
func activate_event(event_id: String) -> bool  # spend cash to trigger an offered event
func get_event_offers() -> Array               # offered (not yet active) events

func tick(dt: float) -> void           # drives everything: growth, staff auto-work, day cycle, orders, missions, events
func serialize() -> Dictionary
func restore(d: Dictionary) -> void
func compute_offline(seconds: float) -> Dictionary  # staff-automated only, cap 7200s, rate 0.8x
```

Rules: Game is a `Node`, logic must work when instantiated headless (`load(...).new()`) with no autoloads and no main scene. Save has `new_memory()` for tests (no disk IO).

## Theme pack schema (`Themes.pack(key) -> Dictionary`)

```
{ key, name, tagline,
  palette: { sky_top, sky_bottom, floor, soil, accent, glow, ui_panel, ui_text, plot_frame }  # "#rrggbb"
  room_style: "heat_lab"|"roastery"|"conservatory"|"alchemy_lab"|"candy_factory"
  crops:   [ {id, name, seed_cost:int, grow_time:float(s), base_yield:int, price_raw:float} ]  # 2-3 per theme
  products:[ {id, name, recipe:{crop_id:int}, price:float, tier:int} ]                        # 3 per theme
  upgrades:[ {id, name, base_cost:float, cost_mult:float, max_level:int, desc} ]              # 3 per theme
  staff:   [ {role_id, name, salary_per_day:float, desc, does:"harvest"|"craft"|"sell"} ]     # 3 per theme
  venues:  [ {name, cost:float, desc} x4 ]  # index 0 = starting venue
  ranks:   [ String x8 ]  # titles; thresholds = [0, 50, 150, 400, 900, 2000, 4500, 9000] xp
  missions:[ {id, desc, type:"harvest"|"craft"|"sell"|"order"|"cash"|"venue", target:int, reward_cash:float, reward_xp:int} x6 ]
  customers:[ {name, mood:String} x6 ]
  events:  [ {id, name, cost:float, desc, effect:"growth_boost"|"price_boost"|"yield_boost"} x3 ]
}
```

Chilli baseline (others scale by flavor): seed 2 / grow 20s / yield 2 / raw price 1.5; sauce recipe 4 raw → price 18; starting cash 25; starting plots unlocked = 3 (others cost 30/80/200).

## Asset contract (Agent D generates; B consumes with File-Existence fallback to `_draw()` placeholders)

```
assets/art/backdrop_<theme>.png            1600x900  room, landscape
assets/art/backdrop_<theme>_mobile.png     900x1600  room, portrait (distinct composition, NOT a stretched landscape)
assets/art/stage_<theme>_<stage>.png       256x256   transparent; stages: seedling, leafy, flowering, mature, ready
assets/art/product_<theme>.png             128x128   transparent icon of the tier-1 product
assets/art/ui_logo.png                     512x256   "HEAT FIRM" wordmark, transparent
assets/asset-manifest.json                 [{id,file,theme,stage,w,h,transparent,anchor,max_kb}]
```
Rules: uniform scale, preserve intrinsic aspect; never stretch one room between aspect ratios. Stylized flat shapes with 2x supersampled edges (no photorealism). Each theme palette must be instantly distinct (chilli red/amber, coffee brown/brass, flowers pink/green, potions purple/teal glow, lollies candy multi).

## Scene/UI contract (Agent B)

- `main.tscn`: single root `Node` named `Main` with `main.gd`. Everything else built in code.
- Plot grid: 6 stable plots `plot_0..plot_5`. Portrait (h>w): 2 cols x 3 rows. Landscape: 3 cols x 2 rows. Plots live in the lower half of the room, beds visible in both backdrops.
- UI: top HUD (theme name, cash w/ count-up tween, XP bar + rank, day/time, event chip). Bottom dock tabs: Field, Craft, Market, Orders, Staff, Upgrades, Venue, Missions, Theme, Menu. Toasts top-right. Center reward card pop (scale+fade). Offline-report modal on load. Customer vignettes: small drawn silhouettes + speech bubble when an order is active (walk in, wait, leave on fulfill).
- Motion: plant push-in, harvest punch + particles, ready glow pulse, rank-up flash, count-up numbers. Settings (Menu tab): reduced motion (default from OS if available else off), particles 0-2, save now, reset (typed confirm), version label. All motion respects reduced-motion.
- Day/night: tint overlay from palette, follows `get_day_progress()`.
- Must run headless without errors: guard `get_viewport().get_texture().get_image()` usage; never block the main loop; every texture load checks `ResourceLoader.exists`.

## QA contract (Agent C)

- `tests/run_tests.gd`: `extends SceneTree`, run via `godot.exe --headless --path <proj> -s res://tests/run_tests.gd`... NOTE: `-s` with res:// path: use `--script res://tests/run_tests.gd`. Instantiates `load("res://src/sim/game_sim.gd").new()` + memory Save; >= 20 assertions covering plant→grow→harvest→craft→sell→order→upgrade→venue→staff→offline→mission→rank→save/restore→theme-switch isolation. Prints `PASS n/n` (or `FAIL i/n: msg` lines) and `quit(0/1)`.
- `tools/qa/screenshot_matrix.gd`: runs the real main scene (NOT headless), resizes window to 390x844, 768x1024, 844x390, 1366x768, waits ~2s each, `get_viewport().get_texture().get_image().save_png("res://qa/shots/shot_<w>x<h>.png")`, quits.
- `tools/run_tests.bat`, `tools/run_game.bat`, `tools/run_screenshots.bat` (call `..\tools\godot\godot.exe`, `chcp 65001`).
- `docs/VISUAL_ACCEPTANCE.md`: gate checklist (4 sizes, zero console errors, no overflow, beds visible, loop works, tests pass).

## Definition of done (orchestrator gates)

1. `godot --headless --import` clean.
2. `tests/run_tests.gd` prints `PASS n/n` (n>=20).
3. `screenshot_matrix` produces 4 PNGs; all 6 plots + HUD visible, no overflow, theme art present.
4. No script errors in stdout of any run.
