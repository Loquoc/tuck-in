class_name BoardView
extends Node2D
## Draws the crib. Its position is the top-left corner of the grid.
## The crib itself is one batched draw; the landing preview is a child so
## that moving it does not rebuild the crib.

var level: LevelData
var cell := 150.0

var _preview: Array = []
var _preview_ok := true
var _preview_layer: Painter


func _ready() -> void:
	_preview_layer = Painter.new()
	_preview_layer.paint = _paint_preview
	add_child(_preview_layer)


func setup(lv: LevelData, cell_size: float) -> void:
	level = lv
	cell = cell_size
	queue_redraw()


func set_cell(cell_size: float) -> void:
	cell = cell_size
	queue_redraw()


func grid_size() -> Vector2:
	return Vector2(level.width, level.height) * cell


## The grid cell nearest to a softie's top-left corner (in scene coordinates).
func anchor_for(top_left: Vector2) -> Vector2i:
	var local := (top_left - position) / cell
	return Vector2i(roundi(local.x), roundi(local.y))


## Scene position of the centre of a softie of `size` cells placed at `at`.
func centre_of(at: Vector2i, size: Vector2i) -> Vector2:
	return position + (Vector2(at) + Vector2(size) * 0.5) * cell


func get_rect_in_scene() -> Rect2:
	return Rect2(position, grid_size())


func set_preview(cells: Array, ok: bool) -> void:
	if cells == _preview and ok == _preview_ok:
		return
	_preview = cells
	_preview_ok = ok
	_preview_layer.queue_redraw()


func clear_preview() -> void:
	set_preview([], true)


## Where the softie in hand would land.
func _paint_preview(b: Brush) -> void:
	var tint := Color(Palette.OK, 0.45) if _preview_ok else Color(Palette.NOT_OK, 0.3)
	for c in _preview:
		b.draw_box(Rect2(Vector2(c) * cell, Vector2(cell, cell)).grow(-cell * 0.07), tint, cell * 0.16)


func _draw() -> void:
	if level == null:
		return
	var b := Brush.new()
	var g := grid_size()
	var t := cell * 0.2

	# Wooden frame.
	b.draw_box(Rect2(-t, -t, g.x + t * 2.0, g.y + t * 2.0), Palette.WOOD, cell * 0.32,
		Palette.WOOD_DARK, maxf(2.0, cell * 0.035), Color(0.03, 0.04, 0.12, 0.35), cell * 0.14, Vector2(0, cell * 0.07))
	b.draw_box(Rect2(-t * 0.55, -t * 0.55, g.x + t * 1.1, g.y + t * 1.1), Color.TRANSPARENT, cell * 0.22,
		Palette.WOOD_LIGHT, maxf(2.0, cell * 0.02))

	# Sheet, with quilting lines between cells.
	for y in level.height:
		for x in level.width:
			var c := Vector2i(x, y)
			if level.open.has(c) or level.features.has(c):
				b.draw_rect(Rect2(Vector2(c) * cell, Vector2(cell, cell)), Palette.SHEET)
	var line_w := maxf(1.5, cell * 0.014)
	for y in level.height:
		for x in level.width:
			var c := Vector2i(x, y)
			if not level.open.has(c):
				continue
			var p := Vector2(c) * cell
			if level.open.has(c + Vector2i(1, 0)):
				b.draw_line(p + Vector2(cell, cell * 0.12), p + Vector2(cell, cell * 0.88), Palette.SHEET_LINE, line_w)
			if level.open.has(c + Vector2i(0, 1)):
				b.draw_line(p + Vector2(cell * 0.12, cell), p + Vector2(cell * 0.88, cell), Palette.SHEET_LINE, line_w)

	# Toy blocks on blocked cells.
	for c in level.blocked:
		var r := Rect2(Vector2(c) * cell, Vector2(cell, cell)).grow(-cell * 0.1)
		b.draw_box(r, Palette.WOOD_LIGHT, cell * 0.14, Palette.WOOD_DARK, maxf(2.0, cell * 0.025),
			Color(0.2, 0.12, 0.05, 0.25), cell * 0.05)
		b.draw_colored_polygon(Icons.star(r.get_center(), cell * 0.2, cell * 0.095), Palette.WOOD)

	for c in level.features:
		var centre := (Vector2(c) + Vector2(0.5, 0.5)) * cell
		if level.features[c] == "pillow":
			b.draw_box(Rect2(centre - Vector2(0.4, 0.34) * cell, Vector2(0.8, 0.68) * cell), Color.WHITE, cell * 0.26,
				Color("C3D2E6"), maxf(2.0, cell * 0.03), Color(0.3, 0.3, 0.45, 0.25), cell * 0.05, Vector2(0, cell * 0.025))
			for s in [-1.0, 1.0]:
				b.draw_arc(centre + Vector2(s * 0.5, 0) * cell, cell * 0.36, PI * (0.5 + s * 0.5) - 0.42, PI * (0.5 + s * 0.5) + 0.42, 10, Color("D7E1EF"), line_w * 1.4)
		else:
			for i in 6:
				b.draw_circle(centre, cell * (0.95 - i * 0.12), Color(Palette.GLOW, 0.07))
			var star := Icons.star(centre, cell * 0.36, cell * 0.19)
			b.draw_colored_polygon(star, Palette.GLOW)
			b.draw_polyline(SoftieDrawer.closed(star), Palette.GLOW.darkened(0.18), line_w * 1.4)
			for s in [-1.0, 1.0]:
				b.draw_arc(centre + Vector2(s * 0.09, 0.02) * cell, cell * 0.04, PI * 1.1, PI * 1.9, 8, Palette.INK, line_w * 1.6)
			b.draw_arc(centre + Vector2(0, 0.07) * cell, cell * 0.05, PI * 0.15, PI * 0.85, 8, Palette.INK, line_w * 1.6)
	b.flush(self)
