class_name Brush
extends RefCounted
## Collects shapes into one triangle list and draws them in a single call.
##
## Drawing each circle, dash and line through CanvasItem costs one draw call
## apiece, which a tablet GPU cannot keep up with (a level was ~2000 calls).
## A Brush has the same method names as CanvasItem's draw_* functions, so
## drawing code can be handed either; `flush` sends everything at once.
## Edges get a thin transparent fringe, which stands in for antialiasing.

var feather := 1.1

var _pts := PackedVector2Array()
var _cols := PackedColorArray()
var _idx := PackedInt32Array()
var _xf := Transform2D.IDENTITY


func flush(ci: CanvasItem) -> void:
	if _idx.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), _idx, _pts, _cols)


func draw_set_transform(pos: Vector2, rot := 0.0, scl := Vector2.ONE) -> void:
	_xf = Transform2D(rot, scl, 0.0, pos)


func draw_circle(centre: Vector2, radius: float, colour: Color) -> void:
	draw_ellipse(centre, radius, radius, colour)


func draw_ellipse(centre: Vector2, rx: float, ry: float, colour: Color, angle := 0.0) -> void:
	var n := clampi(int(10.0 + maxf(rx, ry) * 0.45), 12, 56)
	var loop := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		loop.append(centre + Vector2(cos(a) * rx, sin(a) * ry).rotated(angle))
	_fill(loop, colour, true)


func draw_colored_polygon(points: PackedVector2Array, colour: Color) -> void:
	_fill(points, colour, false)


func draw_rect(rect: Rect2, colour: Color) -> void:
	_fill(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), colour, true)


func draw_line(from: Vector2, to: Vector2, colour: Color, width := 1.0, _antialiased := true) -> void:
	var along := to - from
	if along.length_squared() < 0.000001:
		return
	var side := Vector2(along.y, -along.x).normalized() * maxf(width * 0.5 - feather * 0.5, 0.15)
	_fill(PackedVector2Array([from + side, to + side, to - side, from - side]), colour, true)


func draw_polyline(points: PackedVector2Array, colour: Color, width := 1.0, _antialiased := true) -> void:
	for i in points.size() - 1:
		draw_line(points[i], points[i + 1], colour, width)


## Stroked arc, built as one strip so a full ring has no seams.
func draw_arc(centre: Vector2, radius: float, from_angle: float, to_angle: float, point_count: int, colour: Color, width := 1.0, _antialiased := true) -> void:
	var n := maxi(point_count, int(absf(to_angle - from_angle) * radius * 0.25))
	n = clampi(n, 4, 72)
	var half := maxf(width * 0.5 - feather * 0.5, 0.15)
	var clear := Color(colour, 0.0)
	var base := _pts.size()
	for i in n + 1:
		var a := lerpf(from_angle, to_angle, float(i) / n)
		var dir := Vector2(cos(a), sin(a))
		_v(centre + dir * (radius + half + feather), clear)
		_v(centre + dir * (radius + half), colour)
		_v(centre + dir * (radius - half), colour)
		_v(centre + dir * (radius - half - feather), clear)
	for i in n:
		var a := base + i * 4
		var b := a + 4
		for row in 3:
			_idx.append_array([a + row, b + row, b + row + 1, a + row, b + row + 1, a + row + 1])


## Rounded box with optional border and soft drop shadow.
func draw_box(rect: Rect2, colour: Color, radius: float, border := Color.TRANSPARENT, border_w := 0.0,
		shadow := Color.TRANSPARENT, shadow_size := 0.0, shadow_offset := Vector2.ZERO) -> void:
	if shadow.a > 0.0 and shadow_size > 0.0:
		var layers := 4
		for i in layers:
			var grow := shadow_size * float(i + 1) / layers
			var r := Rect2(rect.position + shadow_offset, rect.size).grow(grow)
			_fill(_round_rect(r, radius + grow), Color(shadow, shadow.a * 0.3), true)
	if border.a > 0.0 and border_w > 0.0:
		if colour.a <= 0.0:
			var loop := _round_rect(rect.grow(-border_w * 0.5), radius - border_w * 0.5)
			loop.append(loop[0])
			draw_polyline(loop, border, border_w)
			return
		_fill(_round_rect(rect, radius), border, true)
		rect = rect.grow(-border_w)
		radius -= border_w
	_fill(_round_rect(rect, radius), colour, true)


func _round_rect(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	var loop := PackedVector2Array()
	if r < 0.5:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var steps := clampi(int(r * 0.35) + 3, 4, 14)
	var corners := [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI / 2.0],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI / 2.0],
		[Vector2(rect.position.x + r, rect.position.y + r), PI],
	]
	for corner in corners:
		for i in steps + 1:
			var a: float = corner[1] + (PI / 2.0) * i / steps
			loop.append(corner[0] + Vector2(cos(a), sin(a)) * r)
	return loop


func _v(p: Vector2, colour: Color) -> void:
	_pts.append(_xf * p)
	_cols.append(colour)


func _fill(loop: PackedVector2Array, colour: Color, convex: bool) -> void:
	var n := loop.size()
	if n < 3 or colour.a <= 0.0:
		return
	var base := _pts.size()
	for p in loop:
		_v(p, colour)
	var tris := PackedInt32Array()
	if not convex:
		tris = Geometry2D.triangulate_polygon(loop)
	if tris.is_empty():
		for i in range(1, n - 1):
			_idx.append_array([base, base + i, base + i + 1])
	else:
		for t in tris:
			_idx.append(base + t)
	if feather <= 0.0:
		return

	# Fringe: a strip from the edge outwards, fading to transparent.
	var area := 0.0
	for i in n:
		var p := loop[i]
		var q := loop[(i + 1) % n]
		area += p.x * q.y - q.x * p.y
	var outward := 1.0 if area > 0.0 else -1.0
	var clear := Color(colour, 0.0)
	var outer := _pts.size()
	for i in n:
		var d1 := (loop[i] - loop[(i - 1 + n) % n]).normalized()
		var d2 := (loop[(i + 1) % n] - loop[i]).normalized()
		var normal := Vector2(d1.y, -d1.x) + Vector2(d2.y, -d2.x)
		if normal.length_squared() < 0.0001:
			normal = Vector2(d1.y, -d1.x)
		_v(loop[i] + normal.normalized() * outward * feather, clear)
	for i in n:
		var j := (i + 1) % n
		_idx.append_array([base + i, base + j, outer + j, base + i, outer + j, outer + i])
