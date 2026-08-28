extends Node

const _CHILLI := {
	"key": "chilli", "name": "Chilli Co.", "tagline": "Industrial heat lab",
	"palette": {"sky_top": "#2a1410", "sky_bottom": "#5a2a16", "floor": "#4a2410", "soil": "#3a1c0c", "accent": "#ff5a2a", "glow": "#ffb347", "ui_panel": "#241009", "ui_text": "#ffe8d6", "plot_frame": "#8a4a22"},
	"room_style": "heat_lab",
	"plant_colors": ["#4f9e3f", "#2f7a2f", "#ff5a2a"],
	"crops": [
		{"id": "chilli_raw", "name": "Chilli", "seed_cost": 2, "grow_time": 20.0, "base_yield": 2, "price_raw": 1.5},
		{"id": "chilli_hab", "name": "Habanero", "seed_cost": 5, "grow_time": 35.0, "base_yield": 3, "price_raw": 3.5},
	],
	"products": [
		{"id": "sauce", "name": "Chilli Sauce", "recipe": {"chilli_raw": 4}, "price": 18.0, "tier": 1},
		{"id": "hot_jam", "name": "Inferno Jam", "recipe": {"chilli_raw": 2, "chilli_hab": 2}, "price": 42.0, "tier": 2},
		{"id": "inferno_ketchup", "name": "Inferno Ketchup", "recipe": {"chilli_hab": 3}, "price": 95.0, "tier": 3},
	],
	"upgrades": [
		{"id": "growth", "name": "Growth Lights", "base_cost": 40.0, "cost_mult": 1.8, "max_level": 5, "desc": "-8% grow time per level"},
		{"id": "yield", "name": "Rich Soil", "base_cost": 60.0, "cost_mult": 1.9, "max_level": 5, "desc": "+50% yield per level"},
		{"id": "quality", "name": "Museum Pickers", "base_cost": 80.0, "cost_mult": 2.2, "max_level": 3, "desc": "+2% premium chance per level"},
	],
	"staff": [
		{"role_id": "harvest", "name": "Rita the Picker", "salary_per_day": 4.0, "desc": "Auto-harvests ready plots", "does": "harvest"},
		{"role_id": "craft", "name": "Sous Chef Dom", "salary_per_day": 6.0, "desc": "Auto-crafts the best product", "does": "craft"},
		{"role_id": "sell", "name": "Peddler Yara", "salary_per_day": 5.0, "desc": "Auto-sells stock and fills orders", "does": "sell"},
	],
	"venues": [
		{"name": "Shed", "cost": 0.0, "desc": "A humble leaky shed"},
		{"name": "Greenhouse", "cost": 150.0, "desc": "Glass and steel with heat lamps"},
		{"name": "Workshop", "cost": 1200.0, "desc": "Bottling line and staff room"},
		{"name": "Factory", "cost": 8000.0, "desc": "Empire-scale heat works"},
	],
	"ranks": ["Seedling", "Sprout", "Grower", "Bottler", "Distributor", "Regional Heat", "Heat Baron", "Empire"],
	"missions": [
		{"id": "m1", "desc": "Harvest 5 chillies", "type": "harvest", "target": 5, "reward_cash": 10.0, "reward_xp": 10},
		{"id": "m2", "desc": "Bottle 3 sauces", "type": "craft", "target": 3, "reward_cash": 25.0, "reward_xp": 20},
		{"id": "m3", "desc": "Bank $100", "type": "cash", "target": 100, "reward_cash": 30.0, "reward_xp": 30},
		{"id": "m4", "desc": "Fill 2 orders", "type": "order", "target": 2, "reward_cash": 40.0, "reward_xp": 25},
		{"id": "m5", "desc": "Sell 10 products", "type": "sell", "target": 10, "reward_cash": 50.0, "reward_xp": 35},
		{"id": "m6", "desc": "Expand to the Workshop", "type": "venue", "target": 2, "reward_cash": 120.0, "reward_xp": 60},
	],
	"customers": [
		{"name": "Rita", "mood": "hungry"}, {"name": "Marcus", "mood": "spicy"}, {"name": "Lena", "mood": "delicate"},
		{"name": "Tom", "mood": "festive"}, {"name": "Aiko", "mood": "loyal"}, {"name": "Bruno", "mood": "urgent"},
	],
	"events": [
		{"id": "heatwave", "name": "Heat Wave", "cost": 5.0, "desc": "Growth x1.6 for a day", "effect": "growth_boost"},
		{"id": "festival", "name": "Street Food Festival", "cost": 15.0, "desc": "Sales x1.25 for a day", "effect": "price_boost"},
		{"id": "monsoon", "name": "Monsoon Bloom", "cost": 10.0, "desc": "+1 yield for a day", "effect": "yield_boost"},
	],
}

const _COFFEE := {
	"key": "coffee", "name": "Roast & Bloom", "tagline": "Warm brass roastery",
	"palette": {"sky_top": "#2a1c12", "sky_bottom": "#4a3220", "floor": "#3a2a1c", "soil": "#2e2016", "accent": "#c98a4a", "glow": "#e8b06a", "ui_panel": "#20160e", "ui_text": "#f5e6d0", "plot_frame": "#7a5a3a"},
	"room_style": "roastery",
	"plant_colors": ["#5a8a4a", "#3f6a38", "#c98a4a"],
	"crops": [
		{"id": "coffee_bean", "name": "Coffee Bean", "seed_cost": 2, "grow_time": 22.0, "base_yield": 2, "price_raw": 1.6},
		{"id": "coffee_robusta", "name": "Robusta", "seed_cost": 5, "grow_time": 38.0, "base_yield": 3, "price_raw": 3.8},
	],
	"products": [
		{"id": "espresso_mix", "name": "Espresso Mix", "recipe": {"coffee_bean": 4}, "price": 20.0, "tier": 1},
		{"id": "caramel_latte", "name": "Caramel Latte Tonic", "recipe": {"coffee_bean": 2, "coffee_robusta": 2}, "price": 48.0, "tier": 2},
		{"id": "midnight_brew", "name": "Midnight Brew", "recipe": {"coffee_robusta": 3}, "price": 105.0, "tier": 3},
	],
	"upgrades": [
		{"id": "growth", "name": "Warm Shelf", "base_cost": 40.0, "cost_mult": 1.8, "max_level": 5, "desc": "-8% grow time per level"},
		{"id": "yield", "name": "Deep Roast", "base_cost": 60.0, "cost_mult": 1.9, "max_level": 5, "desc": "+50% yield per level"},
		{"id": "quality", "name": "Master Roaster", "base_cost": 80.0, "cost_mult": 2.2, "max_level": 3, "desc": "+2% premium chance per level"},
	],
	"staff": [
		{"role_id": "harvest", "name": "Bean Picker Nia", "salary_per_day": 4.0, "desc": "Auto-harvests ready beans", "does": "harvest"},
		{"role_id": "craft", "name": "Roaster Bo", "salary_per_day": 6.0, "desc": "Auto-crafts the best blend", "does": "craft"},
		{"role_id": "sell", "name": "Cafe Waiter Jun", "salary_per_day": 5.0, "desc": "Auto-sells and fills orders", "does": "sell"},
	],
	"venues": [
		{"name": "Market Cart", "cost": 0.0, "desc": "A rusty market cart"},
		{"name": "Roastery", "cost": 180.0, "desc": "Drum roaster on the wall"},
		{"name": "Corner Cafe", "cost": 1400.0, "desc": "Brass, beans and regulars"},
		{"name": "Coffee Chain", "cost": 9000.0, "desc": "A city-wide coffee barony"},
	],
	"ranks": ["First Cracks", "Grind Hand", "Roaster", "Blendmaker", "Cafe Boss", "City Grinder", "Roast Tycoon", "Empire"],
	"missions": [
		{"id": "m1", "desc": "Harvest 5 beans", "type": "harvest", "target": 5, "reward_cash": 10.0, "reward_xp": 10},
		{"id": "m2", "desc": "Bottle 3 espresso mixes", "type": "craft", "target": 3, "reward_cash": 25.0, "reward_xp": 20},
		{"id": "m3", "desc": "Bank $120", "type": "cash", "target": 120, "reward_cash": 30.0, "reward_xp": 30},
		{"id": "m4", "desc": "Fill 2 orders", "type": "order", "target": 2, "reward_cash": 40.0, "reward_xp": 25},
		{"id": "m5", "desc": "Sell 10 products", "type": "sell", "target": 10, "reward_cash": 50.0, "reward_xp": 35},
		{"id": "m6", "desc": "Expand to the Corner Cafe", "type": "venue", "target": 2, "reward_cash": 120.0, "reward_xp": 60},
	],
	"customers": [
		{"name": "Mona", "mood": "morning"}, {"name": "Dex", "mood": "cramped"}, {"name": "Ingrid", "mood": "warm"},
		{"name": "Sam", "mood": "loyal"}, {"name": "Felix", "mood": "urgent"}, {"name": "Clara", "mood": "delicate"},
	],
	"events": [
		{"id": "rain", "name": "Rainy Week", "cost": 5.0, "desc": "Growth x1.6 for a day", "effect": "growth_boost"},
		{"id": "fest", "name": "Coffee Fest", "cost": 15.0, "desc": "Sales x1.25 for a day", "effect": "price_boost"},
		{"id": "harvestmoon", "name": "Harvest Moon", "cost": 10.0, "desc": "+1 yield for a day", "effect": "yield_boost"},
	],
}

const _FLOWERS := {
	"key": "flowers", "name": "Bloom House", "tagline": "Bright glass conservatory",
	"palette": {"sky_top": "#1a2a1a", "sky_bottom": "#3a6a3a", "floor": "#2e4a2a", "soil": "#3a2a1e", "accent": "#ff7ab0", "glow": "#ffd0e0", "ui_panel": "#162214", "ui_text": "#e8ffe8", "plot_frame": "#5a8a4a"},
	"room_style": "conservatory",
	"plant_colors": ["#55c06a", "#3a9a50", "#ff7ab0"],
	"crops": [
		{"id": "rose", "name": "Rose", "seed_cost": 3, "grow_time": 26.0, "base_yield": 2, "price_raw": 2.2},
		{"id": "sunflower", "name": "Sunflower", "seed_cost": 4, "grow_time": 34.0, "base_yield": 3, "price_raw": 3.0},
	],
	"products": [
		{"id": "posy", "name": "Garden Posy", "recipe": {"rose": 3}, "price": 22.0, "tier": 1},
		{"id": "wedding_bundle", "name": "Wedding Bundle", "recipe": {"rose": 2, "sunflower": 2}, "price": 55.0, "tier": 2},
		{"id": "royal_arrangement", "name": "Royal Arrangement", "recipe": {"sunflower": 3}, "price": 120.0, "tier": 3},
	],
	"upgrades": [
		{"id": "growth", "name": "Sun Traps", "base_cost": 45.0, "cost_mult": 1.8, "max_level": 5, "desc": "-8% grow time per level"},
		{"id": "yield", "name": "Lush Roots", "base_cost": 65.0, "cost_mult": 1.9, "max_level": 5, "desc": "+50% yield per level"},
		{"id": "quality", "name": "Head Gardener", "base_cost": 85.0, "cost_mult": 2.2, "max_level": 3, "desc": "+2% premium chance per level"},
	],
	"staff": [
		{"role_id": "harvest", "name": "Pruner Ivy", "salary_per_day": 4.0, "desc": "Auto-harvests ready blooms", "does": "harvest"},
		{"role_id": "craft", "name": "Florist Wren", "salary_per_day": 6.0, "desc": "Auto-arranges the best bouquet", "does": "craft"},
		{"role_id": "sell", "name": "Stand Seller Mo", "salary_per_day": 5.0, "desc": "Auto-sells and fills orders", "does": "sell"},
	],
	"venues": [
		{"name": "Backyard Patch", "cost": 0.0, "desc": "A backyard patch of pots"},
		{"name": "Conservatory", "cost": 200.0, "desc": "Glasshouse with misters"},
		{"name": "Florist Shop", "cost": 1600.0, "desc": "Shopfront with a window display"},
		{"name": "Garden Empire", "cost": 10000.0, "desc": "The city's garden dynasty"},
	],
	"ranks": ["Seed Pouch", "Green Thumb", "Florist", "Bloom Merchant", "Garden Director", "Petal Baron", "Flower Dynasty", "Empire"],
	"missions": [
		{"id": "m1", "desc": "Harvest 5 roses", "type": "harvest", "target": 5, "reward_cash": 12.0, "reward_xp": 10},
		{"id": "m2", "desc": "Arrange 3 posies", "type": "craft", "target": 3, "reward_cash": 28.0, "reward_xp": 20},
		{"id": "m3", "desc": "Bank $130", "type": "cash", "target": 130, "reward_cash": 32.0, "reward_xp": 30},
		{"id": "m4", "desc": "Fill 2 orders", "type": "order", "target": 2, "reward_cash": 45.0, "reward_xp": 25},
		{"id": "m5", "desc": "Sell 10 products", "type": "sell", "target": 10, "reward_cash": 55.0, "reward_xp": 35},
		{"id": "m6", "desc": "Expand to the Florist Shop", "type": "venue", "target": 2, "reward_cash": 130.0, "reward_xp": 60},
	],
	"customers": [
		{"name": "Ada", "mood": "soft"}, {"name": "Big Pete", "mood": "gentle"}, {"name": "Sofia", "mood": "wedding"},
		{"name": "Theo", "mood": "delicate"}, {"name": "June", "mood": "loyal"}, {"name": "Ozzy", "mood": "urgent"},
	],
	"events": [
		{"id": "longsun", "name": "Long Sun", "cost": 5.0, "desc": "Growth x1.6 for a day", "effect": "growth_boost"},
		{"id": "marketday", "name": "Market Day", "cost": 15.0, "desc": "Sales x1.25 for a day", "effect": "price_boost"},
		{"id": "pollen", "name": "Pollen Boom", "cost": 10.0, "desc": "+1 yield for a day", "effect": "yield_boost"},
	],
}

const _POTIONS := {
	"key": "potions", "name": "Glimmerworks", "tagline": "Alchemist's moonlit lab",
	"palette": {"sky_top": "#16122a", "sky_bottom": "#3a2a6a", "floor": "#2a2050", "soil": "#241a3e", "accent": "#8a5aff", "glow": "#4af0d0", "ui_panel": "#140e24", "ui_text": "#e8dcff", "plot_frame": "#5a3a9a"},
	"room_style": "alchemy_lab",
	"plant_colors": ["#b06aff", "#7a4ad0", "#4af0d0"],
	"crops": [
		{"id": "moonherb", "name": "Moonherb", "seed_cost": 3, "grow_time": 28.0, "base_yield": 2, "price_raw": 2.6},
		{"id": "starroot", "name": "Starroot", "seed_cost": 6, "grow_time": 45.0, "base_yield": 3, "price_raw": 4.5},
	],
	"products": [
		{"id": "glow_draught", "name": "Glow Draught", "recipe": {"moonherb": 3}, "price": 26.0, "tier": 1},
		{"id": "moon_elixir", "name": "Moon Elixir", "recipe": {"moonherb": 2, "starroot": 2}, "price": 64.0, "tier": 2},
		{"id": "star_philosopher", "name": "Star Philosopher", "recipe": {"starroot": 3}, "price": 140.0, "tier": 3},
	],
	"upgrades": [
		{"id": "growth", "name": "Rune Lamps", "base_cost": 50.0, "cost_mult": 1.8, "max_level": 5, "desc": "-8% grow time per level"},
		{"id": "yield", "name": "Moon Soil", "base_cost": 70.0, "cost_mult": 1.9, "max_level": 5, "desc": "+50% yield per level"},
		{"id": "quality", "name": "Arcanist", "base_cost": 90.0, "cost_mult": 2.2, "max_level": 3, "desc": "+2% premium chance per level"},
	],
	"staff": [
		{"role_id": "harvest", "name": "Forager Vex", "salary_per_day": 4.0, "desc": "Auto-harvests glowing herbs", "does": "harvest"},
		{"role_id": "craft", "name": "Adept Mira", "salary_per_day": 7.0, "desc": "Auto-brews the best draught", "does": "craft"},
		{"role_id": "sell", "name": "Hag Market Fenn", "salary_per_day": 6.0, "desc": "Auto-sells and fills orders", "does": "sell"},
	],
	"venues": [
		{"name": "Damp Cellar", "cost": 0.0, "desc": "A damp cellar with one cauldron"},
		{"name": "Rune Lab", "cost": 240.0, "desc": "Rune-lined laboratory"},
		{"name": "Apothecary", "cost": 2000.0, "desc": "A licensed apothecary shop"},
		{"name": "The Arcanum", "cost": 12000.0, "desc": "The city's hidden magical power"},
	],
	"ranks": ["Novice", "Herbalist", "Adept", "Alchemist", "Apothecary", "Arcanist", "Grand Magus", "Empire"],
	"missions": [
		{"id": "m1", "desc": "Harvest 5 moonherbs", "type": "harvest", "target": 5, "reward_cash": 14.0, "reward_xp": 10},
		{"id": "m2", "desc": "Brew 3 glow draughts", "type": "craft", "target": 3, "reward_cash": 30.0, "reward_xp": 20},
		{"id": "m3", "desc": "Bank $150", "type": "cash", "target": 150, "reward_cash": 35.0, "reward_xp": 30},
		{"id": "m4", "desc": "Fill 2 orders", "type": "order", "target": 2, "reward_cash": 50.0, "reward_xp": 25},
		{"id": "m5", "desc": "Sell 10 products", "type": "sell", "target": 10, "reward_cash": 60.0, "reward_xp": 35},
		{"id": "m6", "desc": "Expand to the Apothecary", "type": "venue", "target": 2, "reward_cash": 150.0, "reward_xp": 60},
	],
	"customers": [
		{"name": "Bramble", "mood": "quiet"}, {"name": "Ser Jor", "mood": "curious"}, {"name": "Wren", "mood": "loyal"},
		{"name": "Mossy", "mood": "urgent"}, {"name": "Petal", "mood": "delicate"}, {"name": "Corvin", "mood": "spicy"},
	],
	"events": [
		{"id": "fullmoon", "name": "Full Moon", "cost": 6.0, "desc": "Growth x1.6 for a day", "effect": "growth_boost"},
		{"id": "witchsmarket", "name": "Witch's Market", "cost": 18.0, "desc": "Sales x1.25 for a day", "effect": "price_boost"},
		{"id": "starrain", "name": "Star Rain", "cost": 12.0, "desc": "+1 yield for a day", "effect": "yield_boost"},
	],
}

const _LOLLIES := {
	"key": "lollies", "name": "Sugar Rush Co.", "tagline": "Colourful candy factory",
	"palette": {"sky_top": "#30122e", "sky_bottom": "#7a3a6a", "floor": "#6a3054", "soil": "#4a2038", "accent": "#ff4f9a", "glow": "#ffe14a", "ui_panel": "#2a0f22", "ui_text": "#ffeef8", "plot_frame": "#a04878"},
	"room_style": "candy_factory",
	"plant_colors": ["#6ac04a", "#4a9a3a", "#ff4f9a"],
	"crops": [
		{"id": "sugar_berry", "name": "Sugar Berry", "seed_cost": 2, "grow_time": 18.0, "base_yield": 2, "price_raw": 1.4},
		{"id": "rainbow_shroom", "name": "Rainbow Shroom", "seed_cost": 5, "grow_time": 40.0, "base_yield": 3, "price_raw": 4.0},
	],
	"products": [
		{"id": "berry_gummies", "name": "Berry Gummies", "recipe": {"sugar_berry": 4}, "price": 16.0, "tier": 1},
		{"id": "rainbow_wraps", "name": "Rainbow Wraps", "recipe": {"sugar_berry": 2, "rainbow_shroom": 2}, "price": 46.0, "tier": 2},
		{"id": "galaxy_pops", "name": "Galaxy Pops", "recipe": {"rainbow_shroom": 3}, "price": 110.0, "tier": 3},
	],
	"upgrades": [
		{"id": "growth", "name": "Sugar Humidifier", "base_cost": 38.0, "cost_mult": 1.8, "max_level": 5, "desc": "-8% grow time per level"},
		{"id": "yield", "name": "Ferment Barrels", "base_cost": 58.0, "cost_mult": 1.9, "max_level": 5, "desc": "+50% yield per level"},
		{"id": "quality", "name": "Head Chocolatier", "base_cost": 78.0, "cost_mult": 2.2, "max_level": 3, "desc": "+2% premium chance per level"},
	],
	"staff": [
		{"role_id": "harvest", "name": "Berry Picker Pip", "salary_per_day": 4.0, "desc": "Auto-harvests ready berries", "does": "harvest"},
		{"role_id": "craft", "name": "Lollipop Lee", "salary_per_day": 6.0, "desc": "Auto-crafts the best sweet", "does": "craft"},
		{"role_id": "sell", "name": "Candy Cart Kit", "salary_per_day": 5.0, "desc": "Auto-sells and fills orders", "does": "sell"},
	],
	"venues": [
		{"name": "Kitchen Bench", "cost": 0.0, "desc": "A home kitchen bench"},
		{"name": "Sweet Shop", "cost": 160.0, "desc": "Shopfront with a show window"},
		{"name": "Candy Factory", "cost": 1800.0, "desc": "Conveyors and wrapper machines"},
		{"name": "Candy Empire", "cost": 11000.0, "desc": "A sugar empire with a theme park"},
	],
	"ranks": ["Licky Finger", "Wrapper", "Confectioner", "Sweet Boss", "Candy Mogul", "Sugar Baron", "Treat Tycoon", "Empire"],
	"missions": [
		{"id": "m1", "desc": "Harvest 5 sugar berries", "type": "harvest", "target": 5, "reward_cash": 10.0, "reward_xp": 10},
		{"id": "m2", "desc": "Bag 3 gummy packs", "type": "craft", "target": 3, "reward_cash": 24.0, "reward_xp": 20},
		{"id": "m3", "desc": "Bank $110", "type": "cash", "target": 110, "reward_cash": 28.0, "reward_xp": 30},
		{"id": "m4", "desc": "Fill 2 orders", "type": "order", "target": 2, "reward_cash": 38.0, "reward_xp": 25},
		{"id": "m5", "desc": "Sell 10 products", "type": "sell", "target": 10, "reward_cash": 48.0, "reward_xp": 35},
		{"id": "m6", "desc": "Expand to the Candy Factory", "type": "venue", "target": 2, "reward_cash": 120.0, "reward_xp": 60},
	],
	"customers": [
		{"name": "Dotty", "mood": "bubbly"}, {"name": "Mr. Grumps", "mood": "grumpy"}, {"name": "Tilly", "mood": "loyal"},
		{"name": "Flash", "mood": "urgent"}, {"name": "Bubbles", "mood": "delicate"}, {"name": "Gus", "mood": "soft"},
	],
	"events": [
		{"id": "candyrush", "name": "Candy Rush", "cost": 5.0, "desc": "Growth x1.6 for a day", "effect": "growth_boost"},
		{"id": "fairday", "name": "Fair Day", "cost": 15.0, "desc": "Sales x1.25 for a day", "effect": "price_boost"},
		{"id": "sugarstorm", "name": "Sugar Storm", "cost": 10.0, "desc": "+1 yield for a day", "effect": "yield_boost"},
	],
}

const _PACKS := {
	"chilli": _CHILLI,
	"coffee": _COFFEE,
	"flowers": _FLOWERS,
	"potions": _POTIONS,
	"lollies": _LOLLIES,
}

func pack(key: String) -> Dictionary:
	return _PACKS.get(key, _CHILLI)

func keys() -> Array:
	return _PACKS.keys()
