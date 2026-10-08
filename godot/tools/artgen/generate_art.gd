extends SceneTree

const STAGES := ["seedling", "leafy", "flowering", "mature", "ready"]
const OUT := "res://assets/art/"

var _themes
var _manifest: Array[Dictionary] = []
var _count := 0

func _init() -> void:
	_themes = load("res://src/data/theme_packs.gd").new()
	var t0 := Time.get_ticks_msec()
	_generate_all()
	print("ARTGEN DONE: %d files in %dms" % [_count, Time.get_ticks_msec() - t0])
	quit(0)

func _smooth(e0: float, e1: float, x: float) -> float:
	var t := clampf((x - e0) / (e1 - e0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _sd_roundbox(p: Vector2, c: Vector2, h: Vector2, r: float) -> float:
	var q := Vector2(absf(p.x - c.x) - h.x + r, absf(p.y - c.y) - h.y + r)
	var outside := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0))
	return minf(maxf(q.x, q.y), 0.0) + outside.length() - r

func _sd_seg(p: Vector2, a: Vector2, b: Vector2, r: float) -> float:
	var ba := b - a
	var h := clampf((p - a).dot(ba) / maxf(ba.length_squared(), 0.00001), 0.0, 1.0)
	return (a + ba * h - p).length() - r

func _sd_ellipse(p: Vector2, c: Vector2, rx: float, ry: float, angle: float) -> float:
	var d := p - c
	var cos_a := cos(-angle)
	var sin_a := sin(-angle)
	var lx := (d.x * cos_a - d.y * sin_a) / rx
	var ly := (d.x * sin_a + d.y * cos_a) / ry
	return Vector2(lx, ly).length() - 1.0

func _sd_diamond(p: Vector2, c: Vector2, r: float) -> float:
	return (absf(p.x - c.x) + absf(p.y - c.y)) / 1.41421 - r

func _draw_shape(img: Image, x: int, y: int, d: float, col: Color, alpha: float) -> void:
	if d < 1.2:
		var a := alpha * (1.0 - _smooth(-1.0, 1.2, d))
		if a > 0.003:
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, a))

func _rects_for(theme_key: String, portrait: bool, w: int, h: int) -> Array:
	var r := 0.0
	var out: Array = []
	match theme_key:
		"chilli":
			if not portrait:
				out.append({"t": "seg", "a": [0.06, 0.0], "b": [0.06, 0.62], "r": 0.02, "col": "#6a3a20", "al": 0.9})
				out.append({"t": "seg", "a": [0.0, 0.13], "b": [1.0, 0.13], "r": 0.014, "col": "#6a3a20", "al": 0.9})
				out.append({"t": "circle", "c": [0.06, 0.33], "r": 0.035, "col": "#7a4526", "al": 1.0})
				out.append({"t": "rr", "c": [0.82, 0.32], "hw": [0.085, 0.17], "r": 0.03, "col": "#5a2e18", "al": 1.0})
				out.append({"t": "rr", "c": [0.82, 0.42], "hw": [0.085, 0.018], "r": 0.012, "col": "#ff5a2a", "al": 0.5})
				out.append({"t": "rr", "c": [0.55, 0.30], "hw": [0.09, 0.012], "r": 0.008, "col": "#6a3a20", "al": 1.0})
				for i in 3:
					out.append({"t": "rr", "c": [0.50 + i * 0.05, 0.265], "hw": [0.015, 0.028], "r": 0.007, "col": "#8a4a2a", "al": 1.0})
				for i in 3:
					out.append({"t": "rr", "c": [0.16 + i * 0.05, 0.52], "hw": [0.01, 0.05], "r": 0.008, "col": "#ff5a2a", "al": 0.65})
				out.append({"t": "circle", "c": [0.95, 0.55], "r": 0.04, "col": "#3a1c0c", "al": 1.0})
			else:
				out.append({"t": "seg", "a": [0.93, 0.0], "b": [0.93, 0.52], "r": 0.02, "col": "#6a3a20", "al": 0.9})
				out.append({"t": "rr", "c": [0.30, 0.14], "hw": [0.16, 0.10], "r": 0.04, "col": "#5a2e18", "al": 1.0})
				out.append({"t": "rr", "c": [0.30, 0.20], "hw": [0.16, 0.015], "r": 0.01, "col": "#ff5a2a", "al": 0.5})
				out.append({"t": "rr", "c": [0.45, 0.34], "hw": [0.30, 0.012], "r": 0.008, "col": "#6a3a20", "al": 1.0})
				for i in 3:
					out.append({"t": "rr", "c": [0.35 + i * 0.10, 0.305], "hw": [0.015, 0.028], "r": 0.007, "col": "#8a4a2a", "al": 1.0})
				for i in 3:
					out.append({"t": "rr", "c": [0.07, 0.40 + i * 0.06], "hw": [0.01, 0.035], "r": 0.008, "col": "#ff5a2a", "al": 0.65})
				out.append({"t": "circle", "c": [0.72, 0.45], "r": 0.05, "col": "#3a1c0c", "al": 1.0})
		"coffee":
			if not portrait:
				out.append({"t": "circle", "c": [0.80, 0.35], "r": 0.09, "col": "#6b4a2a", "al": 1.0})
				out.append({"t": "circle", "c": [0.80, 0.35], "r": 0.045, "col": "#c98a4a", "al": 0.9})
				out.append({"t": "rr", "c": [0.80, 0.22], "hw": [0.05, 0.03], "r": 0.01, "col": "#5a3c22", "al": 1.0})
				for i in 3:
					out.append({"t": "rr", "c": [0.10 + i * 0.06, 0.545], "hw": [0.032, 0.05], "r": 0.015, "col": "#8a6a42", "al": 1.0})
					out.append({"t": "rr", "c": [0.10 + i * 0.06, 0.53], "hw": [0.034, 0.008], "r": 0.005, "col": "#c98a4a", "al": 0.8})
				for lx in [0.35, 0.55]:
					out.append({"t": "seg", "a": [lx, 0.0], "b": [lx, 0.075], "r": 0.004, "col": "#3a2a1c", "al": 1.0})
					out.append({"t": "circle", "c": [lx, 0.10], "r": 0.022, "col": "#e8b06a", "al": 1.0})
				out.append({"t": "rr", "c": [0.30, 0.35], "hw": [0.12, 0.012], "r": 0.008, "col": "#5a3c22", "al": 1.0})
				for i in 4:
					out.append({"t": "rr", "c": [0.21 + i * 0.055, 0.315], "hw": [0.012, 0.026], "r": 0.006, "col": "#8a6a42", "al": 1.0})
			else:
				out.append({"t": "circle", "c": [0.28, 0.16], "r": 0.11, "col": "#6b4a2a", "al": 1.0})
				out.append({"t": "circle", "c": [0.28, 0.16], "r": 0.055, "col": "#c98a4a", "al": 0.9})
				out.append({"t": "rr", "c": [0.28, 0.03], "hw": [0.06, 0.03], "r": 0.01, "col": "#5a3c22", "al": 1.0})
				for i in 3:
					out.append({"t": "rr", "c": [0.75, 0.30 + i * 0.09], "hw": [0.05, 0.04], "r": 0.015, "col": "#8a6a42", "al": 1.0})
					out.append({"t": "rr", "c": [0.75, 0.285 + i * 0.09], "hw": [0.052, 0.008], "r": 0.005, "col": "#c98a4a", "al": 0.8})
				for lx in [0.50, 0.85]:
					out.append({"t": "seg", "a": [lx, 0.0], "b": [lx, 0.07], "r": 0.004, "col": "#3a2a1c", "al": 1.0})
					out.append({"t": "circle", "c": [lx, 0.095], "r": 0.025, "col": "#e8b06a", "al": 1.0})
				out.append({"t": "rr", "c": [0.42, 0.40], "hw": [0.25, 0.012], "r": 0.008, "col": "#5a3c22", "al": 1.0})
				for i in 4:
					out.append({"t": "rr", "c": [0.32 + i * 0.065, 0.365], "hw": [0.012, 0.026], "r": 0.006, "col": "#8a6a42", "al": 1.0})
		"flowers":
			if not portrait:
				out.append({"t": "rr", "c": [0.50, 0.24], "hw": [0.29, 0.17], "r": 0.03, "col": "#8a7a5a", "al": 1.0})
				out.append({"t": "rr", "c": [0.50, 0.24], "hw": [0.27, 0.15], "r": 0.02, "col": "#bfe0cf", "al": 1.0})
				out.append({"t": "seg", "a": [0.50, 0.09], "b": [0.50, 0.39], "r": 0.006, "col": "#8a7a5a", "al": 1.0})
				out.append({"t": "seg", "a": [0.36, 0.24], "b": [0.64, 0.24], "r": 0.006, "col": "#8a7a5a", "al": 1.0})
				out.append({"t": "rr", "c": [0.42, 0.55], "hw": [0.018, 0.14], "r": 0.01, "col": "#ffffff", "al": 0.06})
				out.append({"t": "rr", "c": [0.58, 0.55], "hw": [0.018, 0.14], "r": 0.01, "col": "#ffffff", "al": 0.06})
				out.append({"t": "circle", "c": [0.84, 0.48], "r": 0.05, "col": "#55c06a", "al": 1.0})
				out.append({"t": "rr", "c": [0.84, 0.555], "hw": [0.032, 0.03], "r": 0.008, "col": "#b06a4a", "al": 1.0})
				out.append({"t": "circle", "c": [0.14, 0.12], "r": 0.04, "col": "#4aa05a", "al": 1.0})
				out.append({"t": "seg", "a": [0.14, 0.0], "b": [0.14, 0.09], "r": 0.004, "col": "#6a5a3a", "al": 1.0})
			else:
				out.append({"t": "rr", "c": [0.50, 0.18], "hw": [0.32, 0.11], "r": 0.03, "col": "#8a7a5a", "al": 1.0})
				out.append({"t": "rr", "c": [0.50, 0.18], "hw": [0.30, 0.09], "r": 0.02, "col": "#bfe0cf", "al": 1.0})
				out.append({"t": "seg", "a": [0.50, 0.09], "b": [0.50, 0.27], "r": 0.006, "col": "#8a7a5a", "al": 1.0})
				out.append({"t": "seg", "a": [0.34, 0.18], "b": [0.66, 0.18], "r": 0.006, "col": "#8a7a5a", "al": 1.0})
				out.append({"t": "circle", "c": [0.15, 0.42], "r": 0.055, "col": "#55c06a", "al": 1.0})
				out.append({"t": "rr", "c": [0.15, 0.495], "hw": [0.035, 0.032], "r": 0.008, "col": "#b06a4a", "al": 1.0})
				out.append({"t": "circle", "c": [0.85, 0.38], "r": 0.05, "col": "#4aa05a", "al": 1.0})
				out.append({"t": "rr", "c": [0.85, 0.45], "hw": [0.032, 0.03], "r": 0.008, "col": "#b06a4a", "al": 1.0})
				out.append({"t": "circle", "c": [0.50, 0.045], "r": 0.04, "col": "#4aa05a", "al": 1.0})
				out.append({"t": "seg", "a": [0.50, 0.0], "b": [0.50, 0.02], "r": 0.004, "col": "#6a5a3a", "al": 1.0})
		"potions":
			if not portrait:
				for sy in [0.20, 0.30]:
					out.append({"t": "rr", "c": [0.25, sy], "hw": [0.15, 0.011], "r": 0.007, "col": "#3a2a5a", "al": 1.0})
					for i in 4:
						var bc := "#8a5aff" if sy < 0.25 else "#4af0d0"
						out.append({"t": "rr", "c": [0.14 + i * 0.07, sy - 0.035], "hw": [0.013, 0.026], "r": 0.007, "col": bc, "al": 0.95})
				out.append({"t": "circle", "c": [0.78, 0.50], "r": 0.08, "col": "#241a3e", "al": 1.0})
				out.append({"t": "circle", "c": [0.78, 0.435], "r": 0.035, "col": "#4af0d0", "al": 0.85})
				for rr in [0.09, 0.065, 0.04]:
					out.append({"t": "ring", "c": [0.50, 0.74], "r": rr, "w": 0.008, "col": "#4af0d0", "al": 0.14})
				for mx in [[0.12, 0.44], [0.45, 0.12], [0.62, 0.40], [0.90, 0.25], [0.35, 0.50]]:
					out.append({"t": "glow", "c": mx, "r": 0.012, "col": "#4af0d0", "al": 0.5})
			else:
				for sy in [0.10, 0.18, 0.26]:
					out.append({"t": "rr", "c": [0.50, sy], "hw": [0.30, 0.011], "r": 0.007, "col": "#3a2a5a", "al": 1.0})
					for i in 5:
						var bc2 := "#8a5aff" if sy < 0.15 else ("#4af0d0" if sy < 0.22 else "#8a5aff")
						out.append({"t": "rr", "c": [0.30 + i * 0.10, sy - 0.035], "hw": [0.013, 0.026], "r": 0.007, "col": bc2, "al": 0.95})
				out.append({"t": "circle", "c": [0.30, 0.42], "r": 0.10, "col": "#241a3e", "al": 1.0})
				out.append({"t": "circle", "c": [0.30, 0.34], "r": 0.045, "col": "#4af0d0", "al": 0.85})
				for rr2 in [0.11, 0.08, 0.05]:
					out.append({"t": "ring", "c": [0.68, 0.72], "r": rr2, "w": 0.009, "col": "#4af0d0", "al": 0.14})
				for mx2 in [[0.15, 0.35], [0.75, 0.12], [0.85, 0.30], [0.55, 0.45], [0.20, 0.52]]:
					out.append({"t": "glow", "c": mx2, "r": 0.014, "col": "#4af0d0", "al": 0.5})
		"lollies":
			if not portrait:
				for i in 8:
					var sc := "#ff4f9a" if i % 2 == 0 else "#fff0f8"
					out.append({"t": "rr", "c": [0.0625 + i * 0.125, 0.03], "hw": [0.062, 0.028], "r": 0.01, "col": sc, "al": 0.9})
				out.append({"t": "rr", "c": [0.30, 0.50], "hw": [0.19, 0.018], "r": 0.01, "col": "#4a2038", "al": 1.0})
				for i in 6:
					out.append({"t": "circle", "c": [0.16 + i * 0.053, 0.535], "r": 0.016, "col": "#2a0f22", "al": 1.0})
				var ccands := ["#ff4f9a", "#ffe14a", "#4ad0ff", "#ff4f9a", "#ffe14a"]
				for i in 5:
					out.append({"t": "circle", "c": [0.19 + i * 0.055, 0.465], "r": 0.015, "col": ccands[i], "al": 1.0})
				out.append({"t": "rr", "c": [0.75, 0.46], "hw": [0.12, 0.06], "r": 0.02, "col": "#8a4a7a", "al": 1.0})
				for i in 3:
					out.append({"t": "rr", "c": [0.68 + i * 0.07, 0.375], "hw": [0.024, 0.034], "r": 0.012, "col": "#ffffff", "al": 0.28})
					out.append({"t": "rr", "c": [0.68 + i * 0.07, 0.352], "hw": [0.026, 0.01], "r": 0.006, "col": ["#ff4f9a", "#ffe14a", "#4ad0ff"][i], "al": 1.0})
				for sx in [[0.15, 0.20], [0.52, 0.12], [0.90, 0.30], [0.40, 0.40]]:
					out.append({"t": "glow", "c": sx, "r": 0.014, "col": "#ffe14a", "al": 0.55})
			else:
				for i in 6:
					var sc2 := "#ff4f9a" if i % 2 == 0 else "#fff0f8"
					out.append({"t": "rr", "c": [0.0833 + i * 0.1666, 0.03], "hw": [0.083, 0.028], "r": 0.01, "col": sc2, "al": 0.9})
				out.append({"t": "rr", "c": [0.16, 0.34], "hw": [0.018, 0.15], "r": 0.01, "col": "#4a2038", "al": 1.0})
				for i in 5:
					out.append({"t": "circle", "c": [0.125, 0.22 + i * 0.058], "r": 0.015, "col": "#2a0f22", "al": 1.0})
				var ccands2 := ["#ff4f9a", "#ffe14a", "#4ad0ff", "#ff4f9a", "#ffe14a"]
				for i in 5:
					out.append({"t": "circle", "c": [0.195, 0.215 + i * 0.058], "r": 0.014, "col": ccands2[i], "al": 1.0})
				out.append({"t": "rr", "c": [0.62, 0.42], "hw": [0.14, 0.06], "r": 0.02, "col": "#8a4a7a", "al": 1.0})
				for i in 3:
					out.append({"t": "rr", "c": [0.54 + i * 0.08, 0.33], "hw": [0.026, 0.036], "r": 0.013, "col": "#ffffff", "al": 0.28})
					out.append({"t": "rr", "c": [0.54 + i * 0.08, 0.305], "hw": [0.028, 0.011], "r": 0.006, "col": ["#ff4f9a", "#ffe14a", "#4ad0ff"][i], "al": 1.0})
				out.append({"t": "circle", "c": [0.78, 0.16], "r": 0.075, "col": "#ff4f9a", "al": 1.0})
				out.append({"t": "circle", "c": [0.755, 0.135], "r": 0.03, "col": "#fff0f8", "al": 0.9})
				out.append({"t": "seg", "a": [0.78, 0.23], "b": [0.78, 0.33], "r": 0.008, "col": "#fff0f8", "al": 1.0})
				for sx2 in [[0.35, 0.12], [0.90, 0.30], [0.45, 0.50], [0.85, 0.50]]:
					out.append({"t": "glow", "c": sx2, "r": 0.014, "col": "#ffe14a", "al": 0.55})
	return out

func _prop_sdf(pr: Dictionary, p: Vector2, w: float, h: float) -> float:
	var mn := minf(w, h)
	match pr.t:
		"circle":
			return (p - Vector2(pr.c[0] * w, pr.c[1] * h)).length() - float(pr.r) * mn
		"rr":
			return _sd_roundbox(p, Vector2(pr.c[0] * w, pr.c[1] * h), Vector2(pr.hw[0] * w, pr.hw[1] * h), float(pr.r) * mn)
		"seg":
			return _sd_seg(p, Vector2(pr.a[0] * w, pr.a[1] * h), Vector2(pr.b[0] * w, pr.b[1] * h), float(pr.r) * mn)
		"ring":
			var d := (p - Vector2(pr.c[0] * w, pr.c[1] * h)).length() - float(pr.r) * mn
			return absf(d) - float(pr.w) * mn * 0.5
		"glow":
			return (p - Vector2(pr.c[0] * w, pr.c[1] * h)).length() - float(pr.r) * mn
	return 999.0

func _beds_for(portrait: bool, w: int, h: int) -> Array:
	var L := LayoutConsts.for_portrait(portrait)
	var beds: Dictionary = L.beds
	var out := []
	for i in 6:
		var r: Rect2 = LayoutConsts.bed_rect(beds, portrait, float(w), float(h), i)
		out.append({"c": r.get_center(), "h": r.size * 0.5})
	return out

func _render_backdrop(theme_key: String, w: int, h: int, portrait: bool) -> Image:
	var pack: Dictionary = _themes.pack(theme_key)
	var pal: Dictionary = pack.palette
	var sky1 := Color(pal.sky_top)
	var sky2 := Color(pal.sky_bottom)
	var floorc := Color(pal.floor)
	var soil := Color(pal.soil)
	var frame := Color(pal.plot_frame)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var props := _rects_for(theme_key, portrait, w, h)
	var beds := _beds_for(portrait, w, h)
	var floor_y := float(LAYOUT_FLOOR(theme_key, portrait) * h)
	var mn := minf(float(w), float(h))
	var center := Vector2(w * 0.5, h * 0.55)
	var vrad := Vector2(w * 0.62, h * 0.62)
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var c := sky1.lerp(sky2, float(y) / float(h))
			if float(y) > floor_y:
				var ft := (float(y) - floor_y) / maxf(float(h) - floor_y, 1.0)
				c = floorc.darkened(0.15 * ft)
				if fmod(p.x + (p.y - floor_y) * 0.35, 90.0) < 2.0:
					c = c.darkened(0.10)
			if p.y < floor_y + 2.0:
				for pr in props:
					var d := _prop_sdf(pr, p, float(w), float(h))
					if d < 1.2:
						var a: float = pr.al * (1.0 - _smooth(-1.0, 1.2, d))
						if a > 0.003:
							c = c.lerp(Color(str(pr.col)), a)
			for bd in beds:
				var d2 := _sd_roundbox(p, bd.c, bd.h, 6.0)
				if d2 < 9.0:
					if d2 < 0.0:
						c = soil.darkened(0.12 * clampf((p.y - (bd.c.y - bd.h.y)) / maxf(bd.h.y * 2.0, 1.0), 0.0, 1.0))
					else:
						var a2 := 1.0 - _smooth(0.0, 3.0, d2)
						if a2 > 0.0:
							c = c.lerp(frame, a2 * 0.9)
						var sh := 1.0 - _smooth(3.0, 9.0, d2)
						if sh > 0.0:
							c = c.darkened(0.08 * sh)
			var vc := (p - center) / vrad
			var v := _smooth(0.75, 1.15, vc.length())
			if v > 0.0:
				c = c.darkened(0.18 * v)
			img.set_pixel(x, y, c)
	return img

func LAYOUT_FLOOR(_theme_key: String, portrait: bool) -> float:
	return float(LayoutConsts.for_portrait(portrait).floor)

func _render_stage(theme_key: String, stage_i: int) -> Image:
	var pack: Dictionary = _themes.pack(theme_key)
	var pc: Array = pack.plant_colors
	var leaf := Color(pc[0])
	var leaf2 := Color(pc[1])
	var fruit := Color(pc[2])
	var w := 256
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var stem_top: float = [196.0, 164.0, 140.0, 112.0, 112.0][stage_i]
	var stem_r: float = [4.0, 5.0, 5.0, 6.0, 6.0][stage_i]
	if stage_i >= 4:
		for y in h:
			for x in w:
				var p := Vector2(x + 0.5, y + 0.5)
				var d := p.distance_to(Vector2(128.0, 140.0))
				if d < 96.0:
					var a := 0.30 * (1.0 - _smooth(20.0, 96.0, d))
					if a > 0.003:
						img.set_pixel(x, y, Color(0, 0, 0, 0).lerp(fruit, a))
	var base := Vector2(128.0, 224.0)
	var top := Vector2(128.0, stem_top)
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := _sd_seg(p, base, top, stem_r)
			if d < 1.2:
				var a := 1.0 - _smooth(-1.0, 1.2, d)
				if a > 0.003:
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(leaf2, a))
			var leaf_spots: Array = []
			if stage_i >= 1:
				leaf_spots = [[114.0, 196.0, -0.5, 18.0], [142.0, 190.0, 0.5, 18.0], [112.0, 176.0, -0.6, 17.0], [144.0, 170.0, 0.6, 17.0]]
			if stage_i >= 3:
				leaf_spots = [[114.0, 196.0, -0.5, 18.0], [142.0, 190.0, 0.5, 18.0], [112.0, 176.0, -0.6, 17.0], [144.0, 170.0, 0.6, 17.0], [116.0, 150.0, -0.55, 16.0], [140.0, 144.0, 0.55, 16.0]]
			if stage_i == 0:
				leaf_spots = [[116.0, 206.0, -0.5, 15.0], [140.0, 202.0, 0.5, 15.0]]
			var ry := 7.0
			for ls in leaf_spots:
				var de := _sd_ellipse(p, Vector2(ls[0], ls[1]), float(ls[3]), ry, float(ls[2]))
				if de < 1.2:
					var a3 := 1.0 - _smooth(-1.2, 0.9, de)
					if a3 > 0.003:
						img.set_pixel(x, y, img.get_pixel(x, y).lerp(leaf, a3))
			if stage_i >= 2:
				var flowers_pts: Array = []
				if stage_i == 2:
					flowers_pts = [[118.0, 146.0, 6.0], [128.0, 136.0, 6.0], [138.0, 146.0, 6.0]]
				elif stage_i == 3:
					flowers_pts = [[120.0, 122.0, 7.0], [136.0, 116.0, 7.0]]
				else:
					flowers_pts = [[118.0, 126.0, 8.0], [128.0, 112.0, 8.5], [138.0, 126.0, 8.0]]
				for fp in flowers_pts:
					match theme_key:
						"chilli":
							var d4 := _sd_seg(p, Vector2(fp[0], fp[1] - 6.0), Vector2(fp[0], fp[1] + 6.0), 4.0)
							if d4 < 1.2:
								img.set_pixel(x, y, img.get_pixel(x, y).lerp(fruit, 1.0 - _smooth(-1.0, 1.2, d4)))
						"potions":
							var d5 := _sd_diamond(p, Vector2(fp[0], fp[1]), float(fp[2]))
							if d5 < 1.2:
								img.set_pixel(x, y, img.get_pixel(x, y).lerp(fruit, 1.0 - _smooth(-1.0, 1.2, d5)))
						"coffee":
							for off in [-5.0, 5.0]:
								var d6 := (p - Vector2(fp[0] + off, fp[1])).length() - 4.5
								if d6 < 1.2:
									img.set_pixel(x, y, img.get_pixel(x, y).lerp(fruit, 1.0 - _smooth(-1.0, 1.2, d6)))
						_:
							var d7 := (p - Vector2(fp[0], fp[1])).length() - float(fp[2])
							if d7 < 1.2:
								img.set_pixel(x, y, img.get_pixel(x, y).lerp(fruit, 1.0 - _smooth(-1.0, 1.2, d7)))
							if theme_key == "lollies":
								var d8 := (p - Vector2(fp[0], fp[1])).length() - float(fp[2]) * 0.5
								if d8 < 1.2:
									img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color.WHITE, 0.35 * (1.0 - _smooth(-1.0, 1.2, d8))))
	return img

func _render_product(theme_key: String) -> Image:
	var w := 128
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var pack: Dictionary = _themes.pack(theme_key)
	var accent := Color(pack.palette.accent)
	var glow := Color(pack.palette.glow)
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var c := Color(0, 0, 0, 0)
			match theme_key:
				"chilli":
					var db := _sd_roundbox(p, Vector2(64.0, 80.0), Vector2(20.0, 28.0), 8.0)
					if db < 1.2:
						c = c.lerp(Color("#8a2a1a"), 1.0 - _smooth(-1.0, 1.2, db))
					var dl := _sd_roundbox(p, Vector2(64.0, 88.0), Vector2(16.0, 10.0), 2.0)
					if dl < 1.2:
						c = c.lerp(glow, 1.0 - _smooth(-1.0, 1.2, dl))
					var dn := _sd_roundbox(p, Vector2(64.0, 46.0), Vector2(6.0, 10.0), 2.0)
					if dn < 1.2:
						c = c.lerp(Color("#8a2a1a"), 1.0 - _smooth(-1.0, 1.2, dn))
					var dc := _sd_roundbox(p, Vector2(64.0, 32.0), Vector2(10.0, 6.0), 3.0)
					if dc < 1.2:
						c = c.lerp(accent, 1.0 - _smooth(-1.0, 1.2, dc))
				"coffee":
					var ds := _sd_ellipse(p, Vector2(64.0, 96.0), 26.0, 7.0, 0.0)
					if ds < 1.2:
						c = c.lerp(Color("#8a6a42"), 1.0 - _smooth(-1.0, 1.2, ds))
					var dcup := _sd_roundbox(p, Vector2(60.0, 74.0), Vector2(20.0, 16.0), 5.0)
					if dcup < 1.2:
						c = c.lerp(Color("#e8d8c0"), 1.0 - _smooth(-1.0, 1.2, dcup))
					var dbk := _sd_roundbox(p, Vector2(60.0, 70.0), Vector2(20.0, 5.0), 2.0)
					if dbk < 1.2:
						c = c.lerp(Color("#5a3c22"), 1.0 - _smooth(-1.0, 1.2, dbk))
					var dh := (p - Vector2(84.0, 76.0)).length()
					if absf(dh - 9.0) < 1.2:
						c = c.lerp(Color("#e8d8c0"), 1.0 - _smooth(-1.0, 1.2, absf(dh - 9.0)))
					for so in [[56.0, 48.0], [66.0, 42.0]]:
						var dst := _sd_seg(p, Vector2(so[0], 60.0), Vector2(so[1], 34.0), 3.0)
						if dst < 1.2:
							c = c.lerp(Color(1, 1, 1, 0.45), 1.0 - _smooth(-1.0, 1.2, dst))
				"flowers":
					var dw := _sd_roundbox(p, Vector2(64.0, 92.0), Vector2(13.0, 16.0), 3.0)
					if dw < 1.2:
						c = c.lerp(Color("#d8a868"), 1.0 - _smooth(-1.0, 1.2, dw))
					for fs in [[52.0, 58.0, 10.0, "#ff7ab0"], [68.0, 48.0, 12.0, "#ffd0e0"], [82.0, 60.0, 10.0, "#ff9ac8"]]:
						var df := (p - Vector2(fs[0], fs[1])).length() - float(fs[2])
						if df < 1.2:
							c = c.lerp(Color(fs[3]), 1.0 - _smooth(-1.0, 1.2, df))
						var dc2 := (p - Vector2(fs[0], fs[1])).length() - float(fs[2]) * 0.35
						if dc2 < 1.2:
							c = c.lerp(glow, 0.8 * (1.0 - _smooth(-1.0, 1.2, dc2)))
				"potions":
					var dneck := _sd_roundbox(p, Vector2(64.0, 46.0), Vector2(7.0, 12.0), 2.0)
					if dneck < 1.2:
						c = c.lerp(Color("#b0a0d0"), 1.0 - _smooth(-1.0, 1.2, dneck))
					var dbulb := (p - Vector2(64.0, 82.0)).length() - 24.0
					if dbulb < 1.2:
						c = c.lerp(Color("#b0a0d0"), 0.55 * (1.0 - _smooth(-1.0, 1.2, dbulb)))
					if dbulb < 1.2 and p.y > 82.0:
						c = c.lerp(glow, 0.85 * (1.0 - _smooth(-1.0, 1.2, dbulb)))
					var dck := _sd_roundbox(p, Vector2(64.0, 28.0), Vector2(9.0, 5.0), 2.0)
					if dck < 1.2:
						c = c.lerp(Color("#8a6a42"), 1.0 - _smooth(-1.0, 1.2, dck))
				"lollies":
					var dstick := _sd_seg(p, Vector2(64.0, 82.0), Vector2(64.0, 116.0), 3.5)
					if dstick < 1.2:
						c = c.lerp(Color("#fff0f8"), 1.0 - _smooth(-1.0, 1.2, dstick))
					var dpop := (p - Vector2(64.0, 54.0)).length() - 24.0
					if dpop < 1.2:
						c = c.lerp(accent, 1.0 - _smooth(-1.0, 1.2, dpop))
					var ang := atan2(p.y - 54.0, p.x - 64.0)
					var rad := p.distance_to(Vector2(64.0, 54.0))
					if rad < 22.0 and fmod(ang + 3.14159, 1.5708) < 0.7854:
						c = c.lerp(Color("#fff0f8"), 0.8)
					var dcore := (p - Vector2(64.0, 54.0)).length() - 4.0
					if dcore < 1.2:
						c = c.lerp(glow, 1.0 - _smooth(-1.0, 1.2, dcore))
			img.set_pixel(x, y, c)
	return img

const _FONT := {
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
}

func _render_logo() -> Image:
	var w := 512
	var h := 256
	var word := "HEAT FIRM"
	var scale := 6
	var cw := 5 * scale
	var ch := 7 * scale
	var gap := 6
	var total_w := word.length() * cw + (word.length() - 1) * gap
	var x0 := (w - total_w) / 2
	var y0 := (h - ch) / 2
	var bits := PackedByteArray()
	bits.resize(w * h)
	for ci in word.length():
		var chs := word[ci]
		if chs == " ":
			continue
		var glyph: Array = _FONT[chs]
		var bx := x0 + ci * (cw + gap)
		for ry in 7:
			for rx in 5:
				if glyph[ry][rx] == "1":
					for yy in scale:
						for xx in scale:
							var px := int(bx) + rx * scale + xx
							var py := int(y0) + ry * scale + yy
							if px >= 0 and px < w and py >= 0 and py < h:
								bits[py * w + px] = 1
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var idx := y * w + x
			var c := Color(0, 0, 0, 0)
			if bits[idx] == 1:
				c = Color("#ff5a2a").lerp(Color("#ffb347"), float(y) / float(h))
			else:
				var near := false
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						var nx := x + ox
						var ny := y + oy
						if nx >= 0 and nx < w and ny >= 0 and ny < h and bits[ny * w + nx] == 1:
							near = true
							break
					if near:
						break
				if near:
					c = Color("#3a1408")
			var fx := absf(float(x) - 256.0)
			var fy := float(y)
			if fy > 62.0 and fy < float(y0) and fx < (float(y0) - fy) * 0.45:
				c = Color("#ff5a2a").lerp(Color("#ffb347"), (float(y0) - fy) / maxf(float(y0) - 62.0, 1.0))
			img.set_pixel(x, y, c)
	return img

func _save(img: Image, path: String, theme_key: String, stage: String, transparent: bool) -> void:
	img.save_png(path)
	_count += 1
	var sz_kb := float(len(FileAccess.get_file_as_bytes(path)) if FileAccess.file_exists(path) else img.get_width() * img.get_height() * 4) / 1024.0
	_manifest.append({"id": "%s_%s" % [theme_key, stage if stage != "" else "asset"], "file": path, "theme": theme_key, "stage": stage, "w": img.get_width(), "h": img.get_height(), "transparent": transparent, "anchor": "bottom" if stage != "" and stage != "ready" else "center", "max_kb": int(sz_kb) + 16})
	print("  wrote %s (%dx%d)" % [path, img.get_width(), img.get_height()])

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/art")
	for key in ["chilli", "coffee", "flowers", "potions", "lollies"]:
		print("theme: %s" % key)
		var land: Image = _render_backdrop(key, 800, 450, false)
		land.resize(1600, 900, Image.INTERPOLATE_BILINEAR)
		_save(land, OUT + "backdrop_%s.png" % key, key, "", false)
		var pt: Image = _render_backdrop(key, 450, 800, true)
		pt.resize(900, 1600, Image.INTERPOLATE_BILINEAR)
		_save(pt, OUT + "backdrop_%s_mobile.png" % key, key, "", false)
		for i in 5:
			_save(_render_stage(key, i), OUT + "stage_%s_%s.png" % [key, STAGES[i]], key, STAGES[i], true)
		_save(_render_product(key), OUT + "product_%s.png" % key, key, "", true)
	print("theme: logo")
	_save(_render_logo(), OUT + "ui_logo.png", "", "", true)
	var f := FileAccess.open("res://assets/asset-manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_manifest, "\t"))
	f.close()
	_count += 1
	print("  wrote res://assets/asset-manifest.json")
