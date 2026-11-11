class_name Rewards
extends RefCounted
## The softie earned for finishing each level: 30 distinct combinations of
## animal, colour, fabric and shape, for the collection shelf.

const SHAPES := [
	[[0, 0], [0, 1]],
	[[0, 0], [1, 0], [0, 1]],
	[[0, 0], [1, 0]],
	[[1, 0], [0, 1], [1, 1]],
	[[0, 0], [0, 1], [1, 1]],
]


static func def_for(level_number: int) -> Dictionary:
	var i := (level_number - 1) % 6
	var row := (level_number - 1) / 6
	var cells: Array[Vector2i] = []
	for c in SHAPES[row % SHAPES.size()]:
		cells.append(Vector2i(c[0], c[1]))
	var animal := Palette.ANIMALS[i]
	return {
		"id": animal,
		"animal": animal,
		"cells": cells,
		"head": cells[0],
		"colour": Palette.COLOURS[(i + row) % Palette.COLOURS.size()],
		"fabric": Palette.FABRICS[row % Palette.FABRICS.size()],
	}
