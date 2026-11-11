class_name RoundButton
extends BaseButton
## A round, code-drawn button with an icon, a caption, or both.
## In toggle mode the "off" state is dimmed with a slash through the icon.

var icon := "": set = set_icon
var caption := "": set = set_caption
var badge := "": set = set_badge
var fill := Palette.CREAM: set = set_fill
var ink := Palette.INK

var _press: Tween


func _init(icon_name := "", diameter := 120.0) -> void:
	icon = icon_name
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	focus_mode = Control.FOCUS_NONE


func _ready() -> void:
	pivot_offset = size * 0.5
	button_down.connect(_squeeze.bind(0.9))
	button_up.connect(_squeeze.bind(1.0))
	toggled.connect(func(_on: bool) -> void: queue_redraw())


func set_icon(value: String) -> void:
	icon = value
	queue_redraw()


func set_caption(value: String) -> void:
	caption = value
	queue_redraw()


func set_badge(value: String) -> void:
	badge = value
	queue_redraw()


func set_fill(value: Color) -> void:
	fill = value
	queue_redraw()


func set_enabled(on: bool) -> void:
	if disabled == (not on):
		return
	disabled = not on
	queue_redraw()


func centre() -> Vector2:
	return position + size * 0.5


func _squeeze(to: float) -> void:
	if _press != null:
		_press.kill()
	_press = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_press.tween_property(self, "scale", Vector2(to, to), 0.12)


func _draw() -> void:
	var b := Brush.new()
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var off := toggle_mode and not button_pressed
	var bg := fill
	var fg := ink
	if off:
		bg = fill.lerp(Palette.NIGHT, 0.45)
		fg = Color(ink, 0.55)
	if disabled:
		bg.a = 0.3
		fg.a = 0.35
	else:
		b.draw_circle(c + Vector2(0, r * 0.1), r, Color(0.03, 0.04, 0.12, 0.3))
	b.draw_circle(c, r, bg)
	if not disabled:
		b.draw_arc(c, r - 1.0, 0.0, TAU, 48, bg.darkened(0.12), 2.0)

	if icon == "kid":
		b.draw_set_transform(c + Vector2(0, r * 0.1))
		Faces.draw(b, "bear", r * 0.48, Palette.fabric("honey"), Faces.Mood.ASLEEP if off else Faces.Mood.CONTENT)
		b.draw_set_transform(Vector2.ZERO)
	elif icon != "":
		Icons.draw(b, icon, c, r * 1.25, fg)
	if off and icon != "kid":
		b.draw_line(c + Vector2(-r, r) * 0.5, c + Vector2(r, -r) * 0.5, fg, r * 0.1)
	if badge != "":
		var at := c + Vector2(r, -r) * 0.7
		b.draw_circle(at, r * 0.34, Palette.OK)
		Icons.draw(b, badge, at, r * 0.6, Palette.CREAM)
	b.flush(self)

	if caption != "":
		var font := ThemeDB.fallback_font
		var font_size := int(r * 0.8)
		draw_string(font, Vector2(0, c.y + font_size * 0.36), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, fg)
