class_name LayoutConsts
extends RefCounted

const LAND := {
	"floor": 0.60,
	"beds": {"x0": 0.042, "y0": 0.68, "cw": 0.285, "ch": 0.13, "gx": 0.03, "gy": 0.035, "cols": 3, "rows": 2},
}
const PORTRAIT := {
	"floor": 0.52,
	"beds": {"x0": 0.12, "y0": 0.56, "cw": 0.36, "ch": 0.125, "gx": 0.04, "gy": 0.0175, "cols": 2, "rows": 3},
}

static func for_portrait(portrait: bool) -> Dictionary:
	return PORTRAIT if portrait else LAND

static func bed_rect(beds: Dictionary, portrait: bool, w: float, h: float, i: int) -> Rect2:
	var cols: int = beds.cols
	var col := i % cols
	var row := i / cols
	var x0: float = beds.x0 * w
	var y0: float = beds.y0 * h
	var cw: float = beds.cw * w
	var ch: float = beds.ch * h
	var gx: float = beds.gx * w
	var gy: float = beds.gy * h
	return Rect2(x0 + col * (cw + gx), y0 + row * (ch + gy), cw, ch)
