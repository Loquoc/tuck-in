class_name Faces
extends RefCounted
## Animal heads, drawn from circles, ellipses and arcs around (0, 0).
##
## `pose` animates a face without changing its mood. All keys are optional:
##   look   Vector2, where the eyes point (-1..1 each way)
##   ear    float, ear wiggle / flap (-1..1)
##   yawn   float 0..1, mouth opening wide (eyes squeeze shut past 0.3)
##   trunk  float -1..1, elephant trunk swing
##   blink  bool, both eyes shut
##   wink   bool, one eye shut
##   blush  float 0..1, extra-rosy cheeks

enum Mood { AWAKE, CONTENT, FUSSY, ASLEEP }


static func draw(ci: Brush, animal: String, r: float, base: Color, mood: int, blink := false, pose := {}) -> void:
	var ink := Palette.INK
	var fur := base.lerp(Color.WHITE, 0.38)
	var shade := base.darkened(0.14)
	var cream := Palette.CREAM
	var look: Vector2 = pose.get("look", Vector2.ZERO)
	var ear: float = pose.get("ear", 0.0)
	var yawn: float = pose.get("yawn", 0.0)
	var blush: float = pose.get("blush", 0.0)
	var wink: bool = pose.get("wink", false)
	if pose.get("blink", false) or yawn > 0.3:
		blink = true

	# Ears, behind the head.
	match animal:
		"bunny":
			for s in [-1.0, 1.0]:
				var lean: float = s * 0.16 + ear * 0.3
				var root := Vector2(s * 0.42, -0.5) * r
				var mid := root + Vector2(0, -0.52 * r).rotated(lean)
				ci.draw_ellipse(mid, 0.25 * r, 0.62 * r, fur, lean)
				ci.draw_ellipse(mid, 0.12 * r, 0.42 * r, Palette.BLUSH.lerp(fur, 0.45), lean)
		"bear":
			for s in [-1.0, 1.0]:
				var size: float = 1.0 + ear * 0.18 * s
				ci.draw_circle(Vector2(s * 0.72, -0.7) * r, 0.36 * r * size, fur)
				ci.draw_circle(Vector2(s * 0.72, -0.7) * r, 0.19 * r * size, shade)
		"fox":
			for s in [-1.0, 1.0]:
				var tip: float = ear * 0.16
				ci.draw_colored_polygon(_tri(s, r, 0.98, -0.3, 0.78 + s * tip, -1.32, 0.12, -0.82), fur)
				ci.draw_colored_polygon(_tri(s, r, 0.82, -0.62, 0.74 + s * tip, -1.14, 0.4, -0.86), ink.lerp(fur, 0.25))
		"elephant":
			for s in [-1.0, 1.0]:
				var flap := 1.0 + absf(ear) * 0.3
				ci.draw_ellipse(Vector2(s * (0.86 + 0.14 * flap), -0.12) * r, 0.52 * r * flap, 0.72 * r, fur)
				ci.draw_ellipse(Vector2(s * (0.86 + 0.14 * flap), -0.1) * r, 0.32 * r * flap, 0.5 * r, shade)
		"lamb":
			for s in [-1.0, 1.0]:
				ci.draw_ellipse(Vector2(s * 1.0, -0.05 - absf(ear) * 0.12) * r, 0.42 * r, 0.2 * r, shade, s * (0.5 - ear * 0.5))
		"cat":
			for s in [-1.0, 1.0]:
				var tip: float = ear * 0.14
				ci.draw_colored_polygon(_tri(s, r, 0.96, -0.2, 0.8 + s * tip, -1.12, 0.2, -0.8), fur)
				ci.draw_colored_polygon(_tri(s, r, 0.8, -0.55, 0.74 + s * tip, -0.95, 0.42, -0.8), Palette.BLUSH.lerp(fur, 0.4))

	ci.draw_circle(Vector2.ZERO, r, fur)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, base.darkened(0.16), maxf(1.5, r * 0.045))

	# Markings, on top of the head.
	var nose_colour := ink
	var nose_y := 0.2
	match animal:
		"bunny":
			ci.draw_ellipse(Vector2(0, 0.36) * r, 0.36 * r, 0.27 * r, cream)
			nose_colour = Palette.BLUSH
		"bear":
			ci.draw_ellipse(Vector2(0, 0.36) * r, 0.42 * r, 0.32 * r, cream)
		"fox":
			for s in [-1.0, 1.0]:
				ci.draw_ellipse(Vector2(s * 0.4, 0.4) * r, 0.46 * r, 0.36 * r, cream, s * -0.5)
		"elephant":
			var swing: float = pose.get("trunk", 0.0)
			var trunk := PackedVector2Array([
				Vector2(0, 0.12) * r,
				Vector2(swing * 0.1, 0.62) * r,
				Vector2(0.12 + swing * 0.34, 0.92 - absf(swing) * 0.1) * r,
			])
			ci.draw_polyline(trunk, shade, 0.34 * r)
			for p in trunk:
				ci.draw_circle(p, 0.17 * r, shade)
		"lamb":
			for p in [Vector2(-0.48, -0.74), Vector2(0.0, -0.9), Vector2(0.48, -0.74), Vector2(-0.24, -0.62), Vector2(0.24, -0.62)]:
				ci.draw_circle(p * r, 0.3 * r, cream)
			nose_colour = Palette.BLUSH
		"cat":
			for s in [-1.0, 1.0]:
				for dy in [0.0, 0.14]:
					ci.draw_line(Vector2(s * 0.5, 0.3 + dy) * r, Vector2(s * 1.02, 0.22 + dy * 2.0) * r, ink.lerp(fur, 0.35), maxf(1.0, 0.035 * r))
			nose_colour = Palette.BLUSH

	# Cheeks.
	var rosy := blush
	if mood == Mood.CONTENT or mood == Mood.ASLEEP:
		rosy = maxf(rosy, 0.55)
	if rosy > 0.0:
		for s in [-1.0, 1.0]:
			ci.draw_circle(Vector2(s * 0.62, 0.26) * r, (0.13 + 0.06 * rosy) * r, Color(Palette.BLUSH, 0.8 * rosy))

	# Eyes.
	var eye_w := maxf(1.0, 0.065 * r)
	for s in [-1.0, 1.0]:
		var e := Vector2(s * 0.38, -0.1) * r
		if animal == "elephant":
			e.y = -0.2 * r
		var shut: bool = blink or (wink and s > 0.0)
		match mood:
			Mood.CONTENT:
				ci.draw_arc(e + Vector2(0, 0.05 * r), 0.14 * r, PI * 1.08, PI * 1.92, 12, ink, eye_w)
			Mood.ASLEEP:
				ci.draw_arc(e - Vector2(0, 0.05 * r), 0.14 * r, PI * 0.08, PI * 0.92, 12, ink, eye_w)
			Mood.FUSSY:
				if shut:
					ci.draw_line(e - Vector2(0.14 * r, 0), e + Vector2(0.14 * r, 0), ink, eye_w)
				else:
					ci.draw_circle(e, 0.19 * r, Color.WHITE)
					ci.draw_circle(e, 0.09 * r, ink)
				ci.draw_line(e + Vector2(-s * 0.22, -0.34) * r, e + Vector2(s * 0.12, -0.24) * r, ink, eye_w)
			_:
				if shut:
					ci.draw_arc(e - Vector2(0, 0.04 * r), 0.12 * r, PI * 0.1, PI * 0.9, 10, ink, eye_w)
				else:
					var pupil := e + look * 0.07 * r
					ci.draw_circle(pupil, 0.125 * r, ink)
					ci.draw_circle(pupil + Vector2(-0.045, -0.05) * r, 0.045 * r, Color.WHITE)

	# Nose and mouth (the elephant's trunk stands in for both).
	if animal != "elephant":
		ci.draw_ellipse(Vector2(0, nose_y) * r, 0.1 * r, 0.075 * r, nose_colour)
		var m := Vector2(0, nose_y + 0.16) * r
		if yawn > 0.05:
			ci.draw_ellipse(m + Vector2(0, 0.08 * r * yawn), 0.11 * r, (0.04 + 0.16 * yawn) * r, ink)
			if yawn > 0.5:
				ci.draw_ellipse(m + Vector2(0, 0.15 * r * yawn), 0.065 * r, 0.06 * r * yawn, Palette.BLUSH)
		else:
			match mood:
				Mood.FUSSY:
					ci.draw_arc(m + Vector2(0, 0.16 * r), 0.13 * r, PI * 1.15, PI * 1.85, 10, ink, eye_w * 0.9)
				Mood.ASLEEP:
					ci.draw_arc(m - Vector2(0, 0.02 * r), 0.07 * r, PI * 0.1, PI * 0.9, 8, ink, eye_w * 0.9)
				_:
					ci.draw_arc(m - Vector2(0, 0.04 * r), 0.13 * r, PI * 0.15, PI * 0.85, 10, ink, eye_w * 0.9)


## A plain head-shaped blob, for ghosts and locked shelf slots.
static func silhouette(ci: Brush, r: float, colour: Color) -> void:
	ci.draw_circle(Vector2.ZERO, r, colour)
	for s in [-1.0, 1.0]:
		ci.draw_circle(Vector2(s * 0.72, -0.7) * r, 0.34 * r, colour)


static func _tri(side: float, r: float, ax: float, ay: float, bx: float, by: float, cx: float, cy: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(side * ax, ay) * r, Vector2(side * bx, by) * r, Vector2(side * cx, cy) * r])
