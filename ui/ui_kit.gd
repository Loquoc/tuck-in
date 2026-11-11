class_name UIKit
extends RefCounted
## Shared bits for the menu screens.


static func label(text: String, font_size: int, colour := Palette.CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Night wall with a scatter of stars. The same seed gives the same sky.
static func paint_night(ci: Brush, size: Vector2, star_seed := 7, moon := false) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), Palette.NIGHT)
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	for i in 90:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var r := rng.randf_range(1.5, 4.5)
		ci.draw_circle(p, r, Color(1.0, 0.97, 0.85, rng.randf_range(0.08, 0.3)))
	if moon:
		var at := Vector2(size.x - 250.0, 220.0)
		for i in 5:
			ci.draw_circle(at, 230.0 - i * 28.0, Color(Palette.GLOW, 0.035))
		Icons.draw(ci, "moon", at, 300.0, Palette.GLOW)
