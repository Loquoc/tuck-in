class_name Solver
extends RefCounted
## Backtracking solver. Used by the level tools and tests; the game itself
## reads the solution stored in the level file.

var level: LevelData
var state: BoardState
var count := 0
var nodes := 0
## True when the search stopped at max_nodes before finishing.
var gave_up := false
## id -> {at, rot, flip} for the first solution found.
var first := {}

var _max_count := 1
var _max_nodes := 0
var _options := {}          # id -> Array of {at, rot, flip, cells}
var _options_by_cell := {}  # id -> cell -> Array of options
var _order: Array[String] = []
var _open_cells: Array[Vector2i] = []


## Returns {count, solution, gave_up}. `count` stops at max_count.
static func solve(lv: LevelData, max_count := 1, max_nodes := 2000000) -> Dictionary:
	var s := Solver.new()
	s.level = lv
	s.state = BoardState.new(lv)
	s._max_count = max_count
	s._max_nodes = max_nodes
	s._prepare()
	if lv.is_exact():
		s._search_cells()
	else:
		s._search_pieces(0)
	return {"count": s.count, "solution": s.first, "gave_up": s.gave_up}


func _prepare() -> void:
	for y in level.height:
		for x in level.width:
			if level.open.has(Vector2i(x, y)):
				_open_cells.append(Vector2i(x, y))
	for p in level.pieces:
		var opts: Array[Dictionary] = []
		var by_cell := {}
		for o in Shape.orientations(p.cells):
			var size := Shape.size_of(o.cells)
			for y in level.height - size.y + 1:
				for x in level.width - size.x + 1:
					var at := Vector2i(x, y)
					var cells: Array[Vector2i] = []
					var ok := true
					for c in o.cells:
						var cell: Vector2i = c + at
						if not level.open.has(cell):
							ok = false
							break
						cells.append(cell)
					if not ok:
						continue
					var opt := {"at": at, "rot": o.rot, "flip": o.flip, "cells": cells}
					opts.append(opt)
					for cell in cells:
						if not by_cell.has(cell):
							by_cell[cell] = []
						by_cell[cell].append(opt)
		_options[p.id] = opts
		_options_by_cell[p.id] = by_cell
		_order.append(p.id)
	_order.sort_custom(func(a: String, b: String) -> bool:
		return _options[a].size() < _options[b].size())


func _done() -> bool:
	return count >= _max_count or gave_up


func _fits(cells: Array) -> bool:
	for c in cells:
		if state.occupancy.has(c):
			return false
	return true


func _leaf() -> void:
	if Rules.all_satisfied(state):
		if count == 0:
			first = state.snapshot()
		count += 1


## General search: place softies one by one, anywhere they fit.
func _search_pieces(i: int) -> void:
	if i == _order.size():
		_leaf()
		return
	var id := _order[i]
	for opt in _options[id]:
		nodes += 1
		if nodes > _max_nodes:
			gave_up = true
			return
		if not _fits(opt.cells):
			continue
		state.put(id, opt.at, opt.rot, opt.flip, opt.cells)
		if not Rules.any_violated(state):
			_search_pieces(i + 1)
		state.remove(id)
		if _done():
			return


## Exact-fit search: always fill the first empty cell, which prunes far harder.
func _search_cells() -> void:
	var target := Vector2i(-1, -1)
	for c in _open_cells:
		if not state.occupancy.has(c):
			target = c
			break
	if target.x < 0:
		_leaf()
		return
	for id in _order:
		if state.is_placed(id):
			continue
		for opt in _options_by_cell[id].get(target, []):
			nodes += 1
			if nodes > _max_nodes:
				gave_up = true
				return
			if not _fits(opt.cells):
				continue
			state.put(id, opt.at, opt.rot, opt.flip, opt.cells)
			if not Rules.any_violated(state):
				_search_cells()
			state.remove(id)
			if _done():
				return
