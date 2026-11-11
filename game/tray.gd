class_name Tray
extends RefCounted
## The panel on the right where unplaced softies wait. Pure layout maths
## plus its own drawing.

const COLUMNS := 2


static func rect_for(viewport: Vector2) -> Rect2:
	var w := clampf(viewport.x * 0.3, 500.0, 640.0)
	return Rect2(viewport.x - w, 36.0, w - 36.0, viewport.y - 72.0)


static func slot_size(rect: Rect2, count: int) -> Vector2:
	var rows := maxi(1, ceili(count / float(COLUMNS)))
	return Vector2(rect.size.x / COLUMNS, rect.size.y / rows)


## Centre of slot `i`. A lone softie on the last row sits in the middle.
static func slot_centre(rect: Rect2, count: int, i: int) -> Vector2:
	var slot := slot_size(rect, count)
	var col := i % COLUMNS
	var row := i / COLUMNS
	var x := (col + 0.5) * slot.x
	if count % COLUMNS == 1 and i == count - 1:
		x = rect.size.x * 0.5
	return rect.position + Vector2(x, (row + 0.5) * slot.y)


## Scale that fits a softie of `extent` pixels (at full size) into a slot,
## whichever way round it is turned.
static func fit_scale(rect: Rect2, count: int, extent: Vector2) -> float:
	var slot := slot_size(rect, count) * 0.86
	var longest := maxf(extent.x, extent.y)
	var shortest := minf(extent.x, extent.y)
	var upright := minf(slot.x / shortest, slot.y / longest)
	var sideways := minf(slot.x / longest, slot.y / shortest)
	return minf(minf(upright, sideways), 0.62)


static func paint(b: Brush, rect: Rect2) -> void:
	b.draw_box(rect, Color(Palette.NIGHT_DEEP, 0.8), 48.0, Palette.NIGHT_SOFT, 4.0)
