class_name SoftieDrawer
extends RefCounted
## Turns a polyomino into a soft blanket outline.


## Boundary of the union of `cells` on the unit grid, cell (0,0) at the origin.
static func trace(cells: Array) -> PackedVector2Array:
	var have := {}
	for c in cells:
		have[c] = true
	# Directed boundary edges, clockwise on screen: start corner -> end corner.
	var next := {}
	for c in cells:
		var p: Vector2i = c
		if not have.has(p + Vector2i(0, -1)):
			next[p] = p + Vector2i(1, 0)
		if not have.has(p + Vector2i(1, 0)):
			next[p + Vector2i(1, 0)] = p + Vector2i(1, 1)
		if not have.has(p + Vector2i(0, 1)):
			next[p + Vector2i(1, 1)] = p + Vector2i(0, 1)
		if not have.has(p + Vector2i(-1, 0)):
			next[p + Vector2i(0, 1)] = p
	var pts := PackedVector2Array()
	if next.is_empty():
		return pts
	var start: Vector2i = next.keys()[0]
	var at := start
	var prev_dir := Vector2i.ZERO
	for guard in next.size() + 1:
		var to: Vector2i = next[at]
		var dir := to - at
		if dir != prev_dir:
			pts.append(Vector2(at))
		prev_dir = dir
		at = to
		if at == start:
			break
	# The start corner may sit in the middle of a straight run.
	if pts.size() > 2 and next[start] - start == start - _source_of(next, start):
		pts.remove_at(0)
	return pts


static func _source_of(next: Dictionary, target: Vector2i) -> Vector2i:
	for k in next:
		if next[k] == target:
			return k
	return target


## Rounded outline in pixels. `inset` pulls the edge in from the cell border;
## `radius` rounds outer corners, and inner corners a little less.
static func outline(cells: Array, cell: float, inset: float, radius: float) -> PackedVector2Array:
	var raw := trace(cells)
	for i in raw.size():
		raw[i] *= cell
	var inner_r := radius * 0.55
	var a := _offset(raw, -(inset + radius), Geometry2D.JOIN_MITER)
	var b := _offset(a, radius + inner_r, Geometry2D.JOIN_ROUND)
	var c := _offset(b, -inner_r, Geometry2D.JOIN_ROUND)
	return c if c.size() >= 3 else raw


static func inset_path(poly: PackedVector2Array, amount: float) -> PackedVector2Array:
	var out := _offset(poly, -amount, Geometry2D.JOIN_ROUND)
	return out if out.size() >= 3 else poly


## Offsets a polygon and returns the largest resulting piece. Clipper treats
## one winding as a hole, so if the area moved the wrong way, flip and retry.
static func _offset(poly: PackedVector2Array, delta: float, join: int) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var best := _largest(Geometry2D.offset_polygon(poly, delta, join))
	var grew := _area(best) > _area(poly)
	if best.size() < 3 or grew != (delta > 0.0):
		var flipped := poly.duplicate()
		flipped.reverse()
		var retry := _largest(Geometry2D.offset_polygon(flipped, delta, join))
		if retry.size() >= 3:
			best = retry
	return best


static func _largest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_area := -1.0
	for p in polys:
		var a := _area(p)
		if a > best_area:
			best_area = a
			best = p
	return best


static func _area(poly: PackedVector2Array) -> float:
	var sum := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		sum += p.x * q.y - q.x * p.y
	return absf(sum) * 0.5


static func closed(poly: PackedVector2Array) -> PackedVector2Array:
	var out := poly.duplicate()
	if out.size() > 0:
		out.append(out[0])
	return out


## Splits a closed path into dashes, for a stitched look.
static func dashes(poly: PackedVector2Array, dash: float, gap: float) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	if poly.size() < 2:
		return out
	var total := 0.0
	for i in poly.size():
		total += poly[i].distance_to(poly[(i + 1) % poly.size()])
	# Stretch the period slightly so the dashes meet up evenly.
	var period := total / maxf(1.0, roundf(total / (dash + gap)))
	var on := period * dash / (dash + gap)
	var current := PackedVector2Array()
	var phase := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var length := a.distance_to(b)
		var walked := 0.0
		while walked < length:
			var drawing := phase < on
			var limit := (on - phase) if drawing else (period - phase)
			var step := minf(limit, length - walked)
			if drawing:
				if current.is_empty():
					current.append(a.lerp(b, walked / length))
				current.append(a.lerp(b, (walked + step) / length))
			walked += step
			phase += step
			if drawing and phase >= on - 0.0001:
				if current.size() >= 2:
					out.append(current)
				current = PackedVector2Array()
			if phase >= period - 0.0001:
				phase = 0.0
	if current.size() >= 2:
		out.append(current)
	return out
