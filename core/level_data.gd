class_name LevelData
extends RefCounted
## A parsed level. Plain data, no scene-tree dependency.

var number := 0
var width := 0
var height := 0
## Vector2i -> true for every cell a softie may occupy.
var open := {}
## Vector2i -> true for plain blocked cells inside the grid.
var blocked := {}
## Vector2i -> feature name ("pillow", "nightlight"). Features occupy their cell.
var features := {}
## Each: {id, cells: Array[Vector2i], head: Vector2i, animal, fabric, colour}
var pieces: Array[Dictionary] = []
## Each: {type: "likes"|"dislikes", piece, kind: "feature"|"piece", target}
var rules: Array[Dictionary] = []
## id -> {at: Vector2i, rot: int, flip: bool}
var solution := {}
## Tutorial level: a pointing finger shows the next move.
var coach := false

var _by_id := {}


func index_pieces() -> void:
	_by_id.clear()
	for p in pieces:
		_by_id[p.id] = p


func piece(id: String) -> Dictionary:
	return _by_id.get(id, {})


func piece_ids() -> Array[String]:
	var out: Array[String] = []
	for p in pieces:
		out.append(p.id)
	return out


func piece_cell_total() -> int:
	var n := 0
	for p in pieces:
		n += p.cells.size()
	return n


## True when the softies fill the crib with no cell to spare.
func is_exact() -> bool:
	return piece_cell_total() == open.size()


func rules_for(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in rules:
		if r.piece == id:
			out.append(r)
	return out
