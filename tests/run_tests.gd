extends SceneTree
## Headless tests for core/.  Run:  godot --headless -s tests/run_tests.gd

var _failed := 0
var _passed := 0


func _init() -> void:
	_test_shape()
	_test_loader()
	_test_board()
	_test_rules()
	_test_undo()
	_test_solver()
	print("\n%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func check(cond: bool, what: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: " + what)


func cells(list: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in list:
		out.append(Vector2i(c[0], c[1]))
	return out


func level(d: Dictionary) -> LevelData:
	var errors := []
	var lv := LevelLoader.parse(d, errors)
	if lv == null:
		printerr("level did not parse: ", errors)
	return lv


const L := [[0, 0], [0, 1], [0, 2], [1, 2]]
const SQUARE := [[0, 0], [1, 0], [0, 1], [1, 1]]
const BAR := [[0, 0], [1, 0], [2, 0]]
const S := [[1, 0], [2, 0], [0, 1], [1, 1]]


func _test_shape() -> void:
	var l := cells(L)
	var r1 := Shape.transform_cells(l, 1, false)
	check(Shape.key(r1) == Shape.key(cells([[2, 0], [1, 0], [0, 0], [0, 1]])), "L rotates clockwise")
	check(r1[3] == Vector2i(0, 1), "cell order is kept through rotation")
	check(Shape.key(Shape.transform_cells(l, 4, false)) == Shape.key(l), "four turns is identity")
	check(Shape.key(Shape.transform_cells(l, -1, false)) == Shape.key(Shape.transform_cells(l, 3, false)), "negative rotation wraps")
	var m := Shape.transform_cells(l, 0, true)
	check(Shape.key(m) == Shape.key(cells([[1, 0], [1, 1], [1, 2], [0, 2]])), "L mirrors")
	check(Shape.key(Shape.transform_cells(m, 0, true)) == Shape.key(l), "mirroring twice is identity")
	check(Shape.size_of(r1) == Vector2i(3, 2), "size after rotation")
	check(Shape.orientations(l, true).size() == 8, "L has 8 orientations with flips")
	check(Shape.orientations(l).size() == 4, "L has 4 orientations by turning alone")
	check(Shape.orientations(cells(SQUARE)).size() == 1, "square has 1 orientation")
	check(Shape.orientations(cells(BAR)).size() == 2, "bar has 2 orientations")
	check(Shape.orientations(cells(S), true).size() == 4, "S has 4 orientations with flips")
	var found := Shape.find_orientation(l, m, true)
	check(not found.is_empty() and found.flip, "find_orientation needs a flip for a mirrored L")
	check(Shape.find_orientation(l, m).is_empty(), "a mirrored L cannot be reached by turning alone")
	check(Shape.find_orientation(l, cells(BAR)).is_empty(), "find_orientation fails for a different shape")
	check(Shape.is_contiguous(l), "L is connected")
	check(not Shape.is_contiguous(cells([[0, 0], [1, 1]])), "diagonal cells are not connected")
	# Mirroring what is on screen: (rot, flip) -> (-rot, not flip).
	for rot in 4:
		var shown := Shape.transform_cells(l, rot, false)
		var mirrored := Shape.transform_cells(shown, 0, true)
		check(Shape.key(mirrored) == Shape.key(Shape.transform_cells(l, -rot, true)), "screen mirror identity, rot %d" % rot)


func _base_level() -> Dictionary:
	return {
		"board": ["P...", "....", "#..N"],
		"pieces": [
			{"id": "bunny", "cells": L, "head": [0, 0]},
			{"id": "bear", "cells": BAR, "head": [0, 0]},
			{"id": "fox", "cells": [[0, 0], [1, 0]], "head": [1, 0]},
		],
		"rules": [],
	}


func _test_loader() -> void:
	var lv := level(_base_level())
	check(lv != null and lv.width == 4 and lv.height == 3, "board size")
	check(lv.open.size() == 9, "open cell count")
	check(lv.features.get(Vector2i(0, 0)) == "pillow", "pillow parsed")
	check(lv.features.get(Vector2i(3, 2)) == "nightlight", "night-light parsed")
	check(lv.blocked.has(Vector2i(0, 2)), "blocked cell parsed")
	check(lv.piece("bunny").cells.size() == 4, "piece cells parsed")
	check(lv.is_exact(), "9 cells of softies in 9 open cells is exact")

	var bad := _base_level()
	bad.board = ["P..", "...."]
	check(LevelLoader.parse(bad) == null, "ragged board rejected")
	bad = _base_level()
	bad.pieces[1].id = "bunny"
	check(LevelLoader.parse(bad) == null, "duplicate id rejected")
	bad = _base_level()
	bad.pieces[0].cells = [[0, 0], [1, 1]]
	check(LevelLoader.parse(bad) == null, "disconnected piece rejected")
	bad = _base_level()
	bad.rules = [{"type": "likes", "piece": "bunny", "target": {"feature": "sofa"}}]
	check(LevelLoader.parse(bad) == null, "unknown feature rejected")
	bad = _base_level()
	bad.rules = [{"type": "dislikes", "piece": "bunny", "target": {"piece": "bunny"}}]
	check(LevelLoader.parse(bad) == null, "self-targeting rule rejected")
	bad = _base_level()
	bad.board = ["P..", "...", "#.N"]
	check(LevelLoader.parse(bad) == null, "too many softie cells rejected")


func _test_board() -> void:
	var st := BoardState.new(level(_base_level()))
	check(st.can_place("bear", Vector2i(1, 0), 0, false), "bar fits on the top row")
	check(not st.can_place("bear", Vector2i(0, 0), 0, false), "cannot cover the pillow")
	check(not st.can_place("bear", Vector2i(2, 0), 0, false), "cannot hang off the board")
	check(not st.can_place("bear", Vector2i(0, 2), 0, false), "cannot cover a blocked cell")
	check(not st.can_place("ghost", Vector2i(1, 0), 0, false), "unknown piece cannot be placed")
	check(st.place("bear", Vector2i(1, 0), 0, false), "place bar")
	check(st.occupancy.get(Vector2i(3, 0)) == "bear", "occupancy recorded")
	check(not st.can_place("fox", Vector2i(2, 0), 0, false), "overlap rejected")
	check(st.can_place("fox", Vector2i(2, 1), 0, false), "free spot accepted")
	check(st.can_place("bear", Vector2i(1, 1), 0, false), "a softie may move over its own cells")
	check(st.place("bear", Vector2i(1, 1), 0, false), "moving a placed softie")
	check(not st.occupancy.has(Vector2i(1, 0)) and st.occupancy.size() == 3, "old cells are released on move")
	check(st.place("fox", Vector2i(1, 0), 1, false) == false, "rotated domino blocked by bar")
	check(st.place("fox", Vector2i(0, 1), 1, false) == false, "rotated domino blocked by wall")
	st.remove("bear")
	check(st.occupancy.is_empty() and not st.is_placed("bear"), "remove clears occupancy")
	# Mirrored L in the 3x3 open area.
	check(st.place("bunny", Vector2i(1, 0), 0, true), "mirrored L placed")
	check(st.occupancy.get(Vector2i(1, 2)) == "bunny" and st.occupancy.get(Vector2i(2, 0)) == "bunny", "mirrored L cells")


func _test_rules() -> void:
	var d := _base_level()
	d.rules = [
		{"type": "likes", "piece": "bear", "target": {"feature": "pillow"}},
		{"type": "dislikes", "piece": "fox", "target": {"feature": "nightlight"}},
		{"type": "likes", "piece": "fox", "target": {"piece": "bear"}},
		{"type": "dislikes", "piece": "bunny", "target": {"piece": "fox"}},
	]
	var lv := level(d)
	var st := BoardState.new(lv)
	var likes_pillow: Dictionary = lv.rules[0]
	var hates_light: Dictionary = lv.rules[1]
	var likes_bear: Dictionary = lv.rules[2]
	var hates_fox: Dictionary = lv.rules[3]

	check(not Rules.satisfied(st, likes_pillow), "unplaced softie is not satisfied")
	check(not Rules.violated(st, likes_pillow), "unplaced softie is not violated")

	st.place("bear", Vector2i(1, 0), 0, false)
	check(Rules.satisfied(st, likes_pillow), "likes feature: touching")
	st.place("bear", Vector2i(1, 1), 0, false)
	check(not Rules.satisfied(st, likes_pillow) and Rules.violated(st, likes_pillow), "likes feature: not touching")

	st.place("fox", Vector2i(1, 2), 0, false)
	check(not Rules.satisfied(st, hates_light) and Rules.violated(st, hates_light), "dislikes feature: touching")
	check(Rules.satisfied(st, likes_bear), "likes piece: touching")
	check(not Rules.piece_happy(st, "fox"), "one broken rule makes a softie unhappy")

	st.remove("bear")
	check(not Rules.satisfied(st, likes_bear), "likes piece: target not placed is unsatisfied")
	check(not Rules.violated(st, likes_bear), "likes piece: target not placed is not yet violated")

	st.clear()
	st.place("fox", Vector2i(1, 0), 0, false)
	check(Rules.satisfied(st, hates_light), "dislikes feature: apart")
	st.place("bunny", Vector2i(1, 0), 0, false)
	check(not st.is_placed("bunny"), "blocked placement leaves the softie unplaced")
	st.place("bear", Vector2i(1, 1), 0, false)
	check(Rules.satisfied(st, likes_bear), "fox touches bear below it")
	check(not Rules.touches(st, "fox", "piece", "bunny"), "diagonal contact is not touching")
	check(Rules.piece_happy(st, "bear") == false, "bear is away from the pillow")
	check(not Rules.is_solved(st), "not solved while a softie is unplaced")

	# A full, valid arrangement.
	var solved := level({
		"board": ["P..", "...", "..N"],
		"pieces": [
			{"id": "bear", "cells": [[0, 0], [1, 0]]},
			{"id": "fox", "cells": [[0, 0], [1, 0], [2, 0]]},
			{"id": "bunny", "cells": [[0, 0], [1, 0]]},
		],
		"rules": [
			{"type": "likes", "piece": "bear", "target": {"feature": "pillow"}},
			{"type": "dislikes", "piece": "bear", "target": {"piece": "bunny"}},
			{"type": "dislikes", "piece": "fox", "target": {"feature": "pillow"}},
		],
	})
	var s2 := BoardState.new(solved)
	s2.place("bear", Vector2i(1, 0), 0, false)
	s2.place("fox", Vector2i(0, 1), 0, false)
	s2.place("bunny", Vector2i(0, 2), 0, false)
	check(not Rules.is_solved(s2), "fox touching the pillow breaks a dislike")
	s2.place("fox", Vector2i(0, 2), 0, false)
	check(not s2.is_placed("fox") or s2.placements.fox.at == Vector2i(0, 1), "fox cannot move onto bunny")
	s2.remove("bunny")
	s2.place("fox", Vector2i(2, 0), 1, false)
	check(not s2.is_placed("fox") or s2.placements.fox.at != Vector2i(2, 0), "upright fox cannot overlap bear or the night-light")
	s2.clear()
	s2.place("bear", Vector2i(1, 0), 0, false)
	s2.place("bunny", Vector2i(0, 2), 0, false)
	s2.place("fox", Vector2i(0, 1), 0, false)
	check(Rules.violated(s2, solved.rules[2]), "fox on row 1 touches the pillow")


func _test_undo() -> void:
	var st := BoardState.new(level(_base_level()))
	var before := st.snapshot()
	st.place("bear", Vector2i(1, 0), 0, false)
	st.push_history(before)
	before = st.snapshot()
	st.place("fox", Vector2i(1, 1), 0, false)
	st.push_history(before)
	before = st.snapshot()
	st.push_history(before)
	check(st.history.size() == 2, "an unchanged board adds no history")
	check(st.undo() and not st.is_placed("fox") and st.is_placed("bear"), "undo removes the last softie")
	check(st.occupancy.size() == 3, "undo rebuilds occupancy")
	check(st.undo() and st.placements.is_empty(), "second undo empties the board")
	check(not st.undo(), "nothing left to undo")
	# Undo restores orientation as well as position.
	st.place("bunny", Vector2i(1, 0), 0, true)
	before = st.snapshot()
	st.place("bunny", Vector2i(1, 0), 0, false)
	st.push_history(before)
	st.undo()
	check(st.placements.bunny.flip == true, "undo restores a flip")


func _test_solver() -> void:
	var d := _base_level()
	# The base level's L only fits mirrored, and the game cannot mirror.
	check(Solver.solve(level(d), 100).count == 0, "base level cannot be solved without a flip")
	d.pieces[0].cells = [[1, 0], [1, 1], [1, 2], [0, 2]]
	d.pieces[0].head = [1, 0]
	var res := Solver.solve(level(d), 100)
	check(res.count > 0, "base level is solvable")
	var lv := level(d)
	var st := BoardState.new(lv)
	st.restore(res.solution)
	check(Rules.is_solved(st), "solver's solution really solves the level")

	# Rules cut the solution count without removing every solution.
	var roomy := _base_level()
	roomy.pieces.remove_at(0)
	var free := Solver.solve(level(roomy), 1000)
	roomy.rules = [{"type": "likes", "piece": "fox", "target": {"feature": "pillow"}}]
	var res2 := Solver.solve(level(roomy), 1000)
	check(res2.count > 0 and res2.count < free.count, "a rule narrows the solutions (%d -> %d)" % [free.count, res2.count])
	roomy.rules = [{"type": "dislikes", "piece": "fox", "target": {"feature": "pillow"}}]
	var res2b := Solver.solve(level(roomy), 1000)
	check(res2.count + res2b.count == free.count, "likes and dislikes split the solutions exactly")

	# Impossible: two softies that each need the single pillow-side cell.
	var impossible := level({
		"board": ["P.#", "#..", "#.."],
		"pieces": [
			{"id": "bear", "cells": [[0, 0], [1, 0]]},
			{"id": "fox", "cells": [[0, 0], [1, 0]]},
		],
		"rules": [
			{"type": "likes", "piece": "bear", "target": {"feature": "pillow"}},
			{"type": "likes", "piece": "fox", "target": {"feature": "pillow"}},
		],
	})
	check(Solver.solve(impossible, 10).count == 0, "contradictory rules have no solution")

	# The game has no mirror control, so a hole that needs a mirrored softie
	# must count as unsolvable.
	var chiral := level({
		"board": ["#..", "..#"],
		"pieces": [{"id": "cat", "cells": [[0, 0], [1, 0], [1, 1], [2, 1]]}],
	})
	check(Solver.solve(chiral, 10).count == 0, "solver never mirrors a softie")
	var fits := level({
		"board": ["..#", "#.."],
		"pieces": [{"id": "cat", "cells": [[0, 0], [1, 0], [1, 1], [2, 1]]}],
	})
	check(Solver.solve(fits, 10).count == 1, "the same softie fits its own-handed hole")

	# Slack board, general search.
	var slack := level({
		"board": ["...", "..."],
		"pieces": [{"id": "cat", "cells": [[0, 0], [1, 0]]}],
	})
	check(Solver.solve(slack, 100).count == 7, "a domino has 7 spots on a 3x2 board")
