class_name GhostLayer
extends Node2D
## Kid mode: faint outlines showing where each softie goes. Shares the
## board's position and cell size.

var level: LevelData
var cell := 150.0
var _placed := {}


func setup(lv: LevelData, cell_size: float) -> void:
	level = lv
	cell = cell_size
	queue_redraw()


func refresh(state: BoardState) -> void:
	if state.placements.keys() == _placed.keys():
		return
	_placed = state.placements.duplicate()
	queue_redraw()


func _draw() -> void:
	if level == null or not visible:
		return
	var b := Brush.new()
	for id in level.solution:
		if _placed.has(id):
			continue
		var sol: Dictionary = level.solution[id]
		var def := level.piece(id)
		var cells := Shape.transform_cells(def.cells, sol.rot, sol.flip)
		var origin := Vector2(sol.at) * cell
		var outline := SoftieDrawer.outline(cells, cell, cell * 0.07, cell * 0.2)
		for i in outline.size():
			outline[i] += origin
		var colour := Palette.fabric(def.colour)
		b.draw_colored_polygon(outline, Color(colour, 0.3))
		for dash in SoftieDrawer.dashes(outline, cell * 0.1, cell * 0.07):
			b.draw_polyline(dash, Color(colour.darkened(0.3), 0.95), maxf(2.5, cell * 0.03))
		var head: Vector2i = cells[maxi(0, def.cells.find(def.head))]
		b.draw_set_transform(origin + (Vector2(head) + Vector2(0.5, 0.5)) * cell)
		Faces.silhouette(b, cell * 0.2, Color(colour.darkened(0.25), 0.5))
		b.draw_set_transform(Vector2.ZERO)
	b.flush(self)
