class_name Icons
extends RefCounted
## Line icons drawn in code. `s` is the icon's overall size in pixels.


static func draw(ci: Brush, icon: String, c: Vector2, s: float, col: Color) -> void:
	var w := s * 0.11
	match icon:
		"back":
			_stroke(ci, c, s, [[0.14, -0.34], [-0.2, 0.0], [0.14, 0.34]], col, w)
		"next":
			_stroke(ci, c, s, [[-0.14, -0.34], [0.2, 0.0], [-0.14, 0.34]], col, w)
		"play":
			_fill(ci, c, s, [[-0.2, -0.36], [0.38, 0.0], [-0.2, 0.36]], col)
			_stroke(ci, c, s, [[-0.2, -0.36], [0.38, 0.0], [-0.2, 0.36], [-0.2, -0.36]], col, w * 0.8)
		"undo":
			var r := s * 0.28
			var a0 := -PI * 0.95
			ci.draw_arc(c + Vector2(0, s * 0.04), r, a0, PI * 0.5, 24, col, w, true)
			_arrow(ci, c + Vector2(0, s * 0.04) + Vector2(cos(a0), sin(a0)) * r, Vector2(sin(a0), -cos(a0)), s * 0.2, col)
			ci.draw_circle(c + Vector2(0, s * 0.04) + Vector2(0, r), w * 0.5, col)
		"restart":
			var r2 := s * 0.28
			var a1 := PI * 1.25
			ci.draw_arc(c, r2, -PI * 0.3, a1, 28, col, w, true)
			_arrow(ci, c + Vector2(cos(a1), sin(a1)) * r2, Vector2(-sin(a1), cos(a1)), s * 0.2, col)
			ci.draw_circle(c + Vector2(cos(-PI * 0.3), sin(-PI * 0.3)) * r2, w * 0.5, col)
		"flip":
			_fill(ci, c, s, [[-0.09, -0.32], [-0.09, 0.32], [-0.42, 0.32]], col)
			_stroke(ci, c, s, [[-0.09, -0.32], [-0.09, 0.32], [-0.42, 0.32], [-0.09, -0.32]], col, w * 0.6)
			_stroke(ci, c, s, [[0.09, -0.32], [0.09, 0.32], [0.42, 0.32], [0.09, -0.32]], col, w * 0.6)
		"hint":
			ci.draw_arc(c + Vector2(0, -s * 0.08), s * 0.22, PI * 0.72, PI * 2.28, 24, col, w, true)
			_stroke(ci, c, s, [[-0.13, 0.1], [-0.1, 0.22], [0.1, 0.22], [0.13, 0.1]], col, w)
			_stroke(ci, c, s, [[-0.07, 0.36], [0.07, 0.36]], col, w)
		"levels":
			for y in 3:
				for x in 3:
					ci.draw_circle(c + Vector2(x - 1, y - 1) * s * 0.24, s * 0.075, col)
		"settings":
			var knobs := [0.14, -0.16, 0.04]
			for i in 3:
				var y := (i - 1) * s * 0.24
				_stroke(ci, c + Vector2(0, y), s, [[-0.32, 0.0], [0.32, 0.0]], col, w * 0.7)
				ci.draw_circle(c + Vector2(knobs[i] * s, y), s * 0.1, col)
		"music":
			_stroke(ci, c, s, [[-0.06, 0.22], [-0.06, -0.3], [0.26, -0.22], [0.26, 0.12]], col, w * 0.8)
			ci.draw_circle(c + Vector2(-0.16, 0.24) * s, s * 0.12, col)
			ci.draw_circle(c + Vector2(0.16, 0.14) * s, s * 0.12, col)
		"sound":
			_fill(ci, c, s, [[-0.36, -0.1], [-0.2, -0.1], [0.0, -0.28], [0.0, 0.28], [-0.2, 0.1], [-0.36, 0.1]], col)
			ci.draw_arc(c + Vector2(0.02 * s, 0), s * 0.17, -PI * 0.3, PI * 0.3, 10, col, w * 0.7, true)
			ci.draw_arc(c + Vector2(0.02 * s, 0), s * 0.32, -PI * 0.3, PI * 0.3, 12, col, w * 0.7, true)
		"check":
			_stroke(ci, c, s, [[-0.28, 0.02], [-0.08, 0.24], [0.3, -0.22]], col, w)
		"lock":
			_fill(ci, c, s, [[-0.24, -0.02], [0.24, -0.02], [0.24, 0.32], [-0.24, 0.32]], col)
			ci.draw_arc(c + Vector2(0, -s * 0.04), s * 0.16, PI, TAU, 14, col, w * 0.8, true)
		"moon":
			ci.draw_colored_polygon(_crescent(c, s * 0.34), col)
		"star", "nightlight":
			var star_col := Palette.GLOW if icon == "nightlight" else col
			ci.draw_colored_polygon(star(c, s * 0.4, s * 0.19), star_col)
		"heart":
			ci.draw_colored_polygon(_heart(c, s * 0.36), col)
		"pillow":
			ci.draw_box(Rect2(c - Vector2(0.4, 0.27) * s, Vector2(0.8, 0.54) * s), Color.WHITE, s * 0.16, Color("B9C9DF"), maxf(1.0, s * 0.06))
		"erase":
			_stroke(ci, c, s, [[-0.26, -0.2], [0.26, -0.2]], col, w)
			_stroke(ci, c, s, [[-0.2, -0.2], [-0.15, 0.34], [0.15, 0.34], [0.2, -0.2]], col, w * 0.8)
			_stroke(ci, c, s, [[-0.08, -0.32], [0.08, -0.32]], col, w)


## Points of a five-pointed star.
static func star(c: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (outer if i % 2 == 0 else inner))
	return pts


static func _pts(c: Vector2, s: float, raw: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in raw:
		pts.append(c + Vector2(p[0], p[1]) * s)
	return pts


## Polyline with round joins and caps.
static func _stroke(ci: Brush, c: Vector2, s: float, raw: Array, col: Color, w: float) -> void:
	var pts := _pts(c, s, raw)
	ci.draw_polyline(pts, col, w, true)
	for p in pts:
		ci.draw_circle(p, w * 0.5, col)


static func _fill(ci: Brush, c: Vector2, s: float, raw: Array, col: Color) -> void:
	ci.draw_colored_polygon(_pts(c, s, raw), col)


static func _arrow(ci: Brush, tip_base: Vector2, dir: Vector2, size: float, col: Color) -> void:
	var n := Vector2(-dir.y, dir.x)
	ci.draw_colored_polygon(PackedVector2Array([
		tip_base + dir * size * 0.8,
		tip_base - dir * size * 0.3 + n * size * 0.62,
		tip_base - dir * size * 0.3 - n * size * 0.62,
	]), col)


static func _crescent(c: Vector2, r: float) -> PackedVector2Array:
	# A disc with a smaller disc, shifted right, bitten out of it.
	var d := r * 0.5
	var r2 := r * 0.85
	var x := (d * d + r * r - r2 * r2) / (2.0 * d)
	var theta := acos(clampf(x / r, -1.0, 1.0))
	var phi := atan2(r * sin(theta), x - d)
	var pts := PackedVector2Array()
	for i in 25:
		var a := lerpf(theta, TAU - theta, i / 24.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	for i in range(1, 16):
		var a := lerpf(TAU - phi, phi, i / 16.0)
		pts.append(c + Vector2(d, 0) + Vector2(cos(a), sin(a)) * r2)
	return pts


static func _heart(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var t := TAU * i / 28.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * r / 17.0)
	return pts
