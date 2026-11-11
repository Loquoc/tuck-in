extends SceneTree
## Writes level files from the spec tables below. Levels 01-02 are hand-made
## tutorials and are never touched.
## Run:  godot --headless -s tools/generate_levels.gd             gentle run, 03-26
##       godot --headless -s tools/generate_levels.gd -- 7 12     only these levels
##       godot --headless -s tools/generate_levels.gd -- --classic
## --classic rewrites the full-size levels 27-56 from SPECS. Do not run it
## casually: those files are the original thirty puzzles (converted by hand
## when mirroring was removed) and regenerating gives different puzzles.
##
## Each level is built backwards from a solution: carve the crib into softie
## shapes, hand them out in a different orientation, then pick preferences
## that are true in that solution and cut down the other solutions.
## Generation is seeded by level number, so output is repeatable.

const ANIMALS := ["bunny", "bear", "fox", "elephant", "lamb", "cat"]
const COLOURS := ["rose", "sage", "lavender", "honey", "sky", "biscuit"]
const FABRICS := ["gingham", "dots", "stripes", "fleece"]

# w, h: crib size.  k: softies.  slack: cells left empty.  blocked: toy blocks.
# feat: P pillow, N night-light.  orient: how softies are handed out
# (none = as solved, rot = rotated, flip = mirrored and rotated).
# rules: lf/lp = likes feature/softie, df/dp = dislikes feature/softie.
# big: largest softie in cells.
const SPECS := [
	{"w": 3, "h": 3, "k": 3, "slack": 1, "blocked": 0, "feat": "", "orient": "none", "rules": [], "big": 3},
	{"w": 4, "h": 3, "k": 3, "slack": 1, "blocked": 0, "feat": "", "orient": "none", "rules": [], "big": 4},
	{"w": 4, "h": 4, "k": 4, "slack": 2, "blocked": 0, "feat": "", "orient": "rot", "rules": [], "big": 4},
	{"w": 4, "h": 4, "k": 4, "slack": 1, "blocked": 0, "feat": "", "orient": "rot", "rules": [], "big": 4},
	{"w": 5, "h": 4, "k": 4, "slack": 2, "blocked": 0, "feat": "", "orient": "rot", "rules": [], "big": 5},
	{"w": 5, "h": 4, "k": 5, "slack": 2, "blocked": 0, "feat": "", "orient": "flip", "rules": [], "big": 4},
	{"w": 5, "h": 4, "k": 5, "slack": 1, "blocked": 0, "feat": "", "orient": "flip", "rules": [], "big": 4},
	{"w": 5, "h": 5, "k": 5, "slack": 2, "blocked": 0, "feat": "", "orient": "flip", "rules": [], "big": 5},

	{"w": 4, "h": 4, "k": 4, "slack": 0, "blocked": 0, "feat": "", "orient": "flip", "rules": [], "big": 4},
	{"w": 5, "h": 4, "k": 5, "slack": 0, "blocked": 0, "feat": "", "orient": "flip", "rules": [], "big": 5},
	{"w": 5, "h": 4, "k": 5, "slack": 0, "blocked": 1, "feat": "", "orient": "flip", "rules": [], "big": 5},
	{"w": 5, "h": 5, "k": 5, "slack": 0, "blocked": 2, "feat": "", "orient": "flip", "rules": [], "big": 5},
	{"w": 6, "h": 4, "k": 5, "slack": 0, "blocked": 0, "feat": "", "orient": "flip", "rules": [], "big": 6},
	{"w": 6, "h": 5, "k": 6, "slack": 0, "blocked": 3, "feat": "", "orient": "flip", "rules": [], "big": 5},
	{"w": 6, "h": 5, "k": 6, "slack": 0, "blocked": 2, "feat": "", "orient": "flip", "rules": [], "big": 5},
	{"w": 6, "h": 5, "k": 6, "slack": 0, "blocked": 0, "feat": "", "orient": "flip", "rules": [], "big": 6},
	{"w": 7, "h": 5, "k": 6, "slack": 0, "blocked": 3, "feat": "", "orient": "flip", "rules": [], "big": 6},
	{"w": 6, "h": 6, "k": 6, "slack": 0, "blocked": 4, "feat": "", "orient": "flip", "rules": [], "big": 6},

	{"w": 5, "h": 4, "k": 4, "slack": 2, "blocked": 0, "feat": "P", "orient": "flip", "rules": ["lf"], "big": 5},
	{"w": 5, "h": 4, "k": 4, "slack": 1, "blocked": 0, "feat": "P", "orient": "flip", "rules": ["lf", "lf"], "big": 5},
	{"w": 5, "h": 5, "k": 5, "slack": 2, "blocked": 0, "feat": "PN", "orient": "flip", "rules": ["lf", "lf"], "big": 5},
	{"w": 5, "h": 5, "k": 5, "slack": 1, "blocked": 0, "feat": "P", "orient": "flip", "rules": ["lf", "lp"], "big": 5},
	{"w": 6, "h": 4, "k": 5, "slack": 1, "blocked": 0, "feat": "PN", "orient": "flip", "rules": ["df"], "big": 5},
	{"w": 6, "h": 5, "k": 5, "slack": 2, "blocked": 0, "feat": "P", "orient": "flip", "rules": ["df", "dp"], "big": 6},
	{"w": 6, "h": 5, "k": 6, "slack": 1, "blocked": 0, "feat": "PN", "orient": "flip", "rules": ["lf", "df", "dp"], "big": 5},
	{"w": 6, "h": 5, "k": 6, "slack": 1, "blocked": 1, "feat": "P", "orient": "flip", "rules": ["lf", "lp", "dp"], "big": 5},
	{"w": 6, "h": 6, "k": 6, "slack": 2, "blocked": 2, "feat": "PN", "orient": "flip", "rules": ["lf", "df", "dp"], "big": 6},
	{"w": 7, "h": 5, "k": 6, "slack": 1, "blocked": 2, "feat": "PN", "orient": "flip", "rules": ["lf", "lf", "df", "dp"], "big": 6},
	{"w": 7, "h": 6, "k": 6, "slack": 2, "blocked": 4, "feat": "PN", "orient": "flip", "rules": ["lf", "lp", "df", "dp"], "big": 6},
	{"w": 7, "h": 6, "k": 6, "slack": 1, "blocked": 5, "feat": "PN", "orient": "flip", "rules": ["lf", "lp", "df", "dp"], "big": 6},
]

# The gentle run: small cribs and few softies, but every feature of the game.
const GENTLE := [
	{"w": 3, "h": 3, "k": 2, "slack": 3, "blocked": 0, "feat": "", "orient": "rot", "rules": [], "big": 3},
	{"w": 3, "h": 3, "k": 2, "slack": 2, "blocked": 0, "feat": "", "orient": "rot", "rules": [], "big": 4},
	{"w": 3, "h": 3, "k": 3, "slack": 1, "blocked": 0, "feat": "", "orient": "rot", "rules": [], "big": 3},
	{"w": 4, "h": 3, "k": 3, "slack": 2, "blocked": 0, "feat": "", "orient": "rot", "rules": [], "big": 4},
	{"w": 3, "h": 3, "k": 3, "slack": 0, "blocked": 1, "feat": "", "orient": "rot", "rules": [], "big": 3},
	{"w": 4, "h": 3, "k": 3, "slack": 0, "blocked": 1, "feat": "", "orient": "rot", "rules": [], "big": 4},
	{"w": 4, "h": 3, "k": 3, "slack": 0, "blocked": 2, "feat": "", "orient": "rot", "rules": [], "big": 4},
	{"w": 4, "h": 4, "k": 4, "slack": 1, "blocked": 1, "feat": "", "orient": "rot", "rules": [], "big": 4},

	{"w": 3, "h": 3, "k": 2, "slack": 2, "blocked": 0, "feat": "P", "orient": "rot", "rules": ["lf"], "big": 3},
	{"w": 4, "h": 3, "k": 3, "slack": 2, "blocked": 0, "feat": "P", "orient": "rot", "rules": ["lf"], "big": 3},
	{"w": 4, "h": 3, "k": 3, "slack": 1, "blocked": 0, "feat": "P", "orient": "rot", "rules": ["lf"], "big": 4},
	{"w": 4, "h": 4, "k": 3, "slack": 3, "blocked": 0, "feat": "P", "orient": "rot", "rules": ["lf", "lf"], "big": 4},
	{"w": 3, "h": 3, "k": 2, "slack": 2, "blocked": 0, "feat": "N", "orient": "rot", "rules": ["df"], "big": 3},
	{"w": 4, "h": 3, "k": 3, "slack": 2, "blocked": 0, "feat": "N", "orient": "rot", "rules": ["df"], "big": 3},
	{"w": 4, "h": 3, "k": 3, "slack": 1, "blocked": 0, "feat": "PN", "orient": "rot", "rules": ["lf", "df"], "big": 3},
	{"w": 4, "h": 4, "k": 3, "slack": 2, "blocked": 0, "feat": "PN", "orient": "rot", "rules": ["lf", "df"], "big": 4},

	{"w": 4, "h": 3, "k": 3, "slack": 2, "blocked": 0, "feat": "", "orient": "rot", "rules": ["lp"], "big": 4},
	{"w": 4, "h": 3, "k": 3, "slack": 2, "blocked": 0, "feat": "", "orient": "rot", "rules": ["dp"], "big": 4},
	{"w": 4, "h": 4, "k": 3, "slack": 4, "blocked": 0, "feat": "", "orient": "rot", "rules": ["lp", "dp"], "big": 4},
	{"w": 4, "h": 4, "k": 4, "slack": 2, "blocked": 0, "feat": "", "orient": "rot", "rules": ["lp", "dp"], "big": 4},
	{"w": 4, "h": 4, "k": 3, "slack": 2, "blocked": 1, "feat": "P", "orient": "rot", "rules": ["lf", "dp"], "big": 4},
	{"w": 4, "h": 4, "k": 4, "slack": 1, "blocked": 0, "feat": "PN", "orient": "rot", "rules": ["lf", "df"], "big": 4},
	{"w": 4, "h": 4, "k": 4, "slack": 1, "blocked": 1, "feat": "P", "orient": "rot", "rules": ["lf", "lp", "dp"], "big": 4},
	{"w": 5, "h": 4, "k": 4, "slack": 2, "blocked": 0, "feat": "PN", "orient": "rot", "rules": ["lf", "df", "dp"], "big": 4},
]

const COUNT_CAP := 40
const TRIAL_NODES := 120000

var rng := RandomNumberGenerator.new()


func _init() -> void:
	var only: Array[int] = []
	var classic := false
	for a in OS.get_cmdline_user_args():
		if a == "--classic":
			classic = true
		else:
			only.append(int(a))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://levels"))
	var specs: Array = SPECS if classic else GENTLE
	var first := LevelLoader.TUTORIAL_COUNT + 1 + (LevelLoader.GENTLE_COUNT if classic else 0)
	var failed := 0
	for i in specs.size():
		var n := first + i
		if not only.is_empty() and not only.has(n):
			continue
		var d := _make(n, specs[i])
		if d.is_empty():
			printerr("level %02d: FAILED to generate" % n)
			failed += 1
			continue
		var f := FileAccess.open(LevelLoader.path_for(n), FileAccess.WRITE)
		f.store_string(JSON.stringify(d, "  ", false) + "\n")
		f.close()
	quit(1 if failed > 0 else 0)


func _make(n: int, spec: Dictionary) -> Dictionary:
	for attempt in 600:
		rng.seed = n * 7919 + attempt
		var d := _attempt(spec)
		if d.is_empty():
			continue
		var lv := LevelLoader.parse(d)
		if lv == null:
			continue
		var res := Solver.solve(lv, COUNT_CAP, 3000000)
		if res.count == 0 or res.gave_up:
			continue
		print("level %02d: %dx%d, %d softies, %d rules, %s solutions (attempt %d)" % [
			n, spec.w, spec.h, spec.k, d.rules.size(),
			str(res.count) if res.count < COUNT_CAP else "%d+" % COUNT_CAP, attempt])
		return d
	return {}


func _attempt(spec: Dictionary) -> Dictionary:
	var w: int = spec.w
	var h: int = spec.h
	var grid := {}
	for y in h:
		for x in w:
			grid[Vector2i(x, y)] = "."

	# Features: pillow on the top row, night-light on another edge cell.
	if "P" in spec.feat:
		grid[Vector2i(rng.randi_range(0, w - 1), 0)] = "P"
	if "N" in spec.feat:
		var edge: Array[Vector2i] = []
		for c in grid:
			var on_edge: bool = c.x == 0 or c.y == 0 or c.x == w - 1 or c.y == h - 1
			if on_edge and grid[c] == "." and not _near(grid, c, "P", 2):
				edge.append(c)
		if edge.is_empty():
			return {}
		grid[edge[rng.randi_range(0, edge.size() - 1)]] = "N"

	var free := _cells_with(grid, ".")
	_shuffle(free)
	for i in spec.blocked:
		grid[free.pop_back()] = "#"
	var open := _cells_with(grid, ".")
	if not Shape.is_contiguous(open):
		return {}

	# Cells that stay empty in the solution.
	_shuffle(free)
	var usable := {}
	for c in free.slice(spec.slack):
		usable[c] = true
	if usable.size() != open.size() - spec.slack or not Shape.is_contiguous(usable.keys()):
		return {}

	var sizes := _sizes(usable.size(), spec.k, spec.big)
	if sizes.is_empty():
		return {}
	var regions := _partition(usable, sizes)
	if regions.is_empty():
		return {}

	var animals := ANIMALS.duplicate()
	var colours := COLOURS.duplicate()
	_shuffle(animals)
	_shuffle(colours)
	var pieces := []
	var solution := []
	var seen_shapes := {}
	for i in regions.size():
		var region: Array = regions[i]
		var at := Vector2i(1 << 20, 1 << 20)
		for c in region:
			at = Vector2i(mini(at.x, c.x), mini(at.y, c.y))
		var solved := Shape.transform_cells(region, 0, false)
		var given := solved
		if spec.orient == "rot":
			given = Shape.transform_cells(solved, rng.randi_range(1, 3), false)
		elif spec.orient == "flip":
			# Legacy spec value: the game no longer has mirroring, so this
			# is now just "any rotation".
			given = Shape.transform_cells(solved, rng.randi_range(0, 3), false)
		var o := Shape.find_orientation(given, solved)
		var id: String = animals[i]
		pieces.append({
			"id": id,
			"cells": given.map(func(c: Vector2i) -> Array: return [c.x, c.y]),
			"head": _head(given),
			"fabric": FABRICS[rng.randi_range(0, FABRICS.size() - 1)],
			"colour": colours[i],
		})
		solution.append({"id": id, "at": [at.x, at.y], "rot": o.rot, "flip": o.flip})
		var canon := _canonical(solved)
		seen_shapes[canon] = seen_shapes.get(canon, 0) + 1
	# Too many twins makes a dull level.
	for shape in seen_shapes:
		if seen_shapes[shape] > 2:
			return {}

	var rows := []
	for y in h:
		var row := ""
		for x in w:
			row += grid[Vector2i(x, y)]
		rows.append(row)
	var d := {"board": rows, "pieces": pieces, "rules": [], "solution": solution}
	if not spec.rules.is_empty() and not _add_rules(d, spec.rules):
		return {}
	return d


## Picks, for each wanted kind, the true-in-the-solution rule that leaves the
## fewest solutions. Returns false if the rules end up changing nothing.
func _add_rules(d: Dictionary, kinds: Array) -> bool:
	var lv := LevelLoader.parse(d)
	if lv == null:
		return false
	var solved := BoardState.new(lv)
	solved.restore(lv.solution)
	if not solved.all_placed():
		return false
	var before: int = Solver.solve(lv, COUNT_CAP, TRIAL_NODES).count
	var used := {}
	for kind in kinds:
		var best := {}
		var best_count := COUNT_CAP + 1
		var candidates := _candidates(lv, solved, kind)
		_shuffle(candidates)
		for cand in candidates:
			if used.get(cand.piece, 0) >= 1 or _has_rule(d.rules, cand):
				continue
			d.rules.append(cand)
			var res := Solver.solve(LevelLoader.parse(d), COUNT_CAP, TRIAL_NODES)
			d.rules.pop_back()
			var c: int = COUNT_CAP if res.gave_up else res.count
			if c > 0 and c < best_count:
				best_count = c
				best = cand
		if best.is_empty():
			return false
		d.rules.append(best)
		used[best.piece] = used.get(best.piece, 0) + 1
	var after: int = Solver.solve(LevelLoader.parse(d), COUNT_CAP, TRIAL_NODES).count
	return after > 0 and (after < before or before == 1)


func _candidates(lv: LevelData, solved: BoardState, kind: String) -> Array:
	var type := "likes" if kind[0] == "l" else "dislikes"
	var out := []
	for p in lv.pieces:
		if kind[1] == "f":
			var present := {}
			for f in lv.features.values():
				present[f] = true
			for f in present:
				if Rules.touches(solved, p.id, "feature", f) == (type == "likes"):
					out.append({"type": type, "piece": p.id, "target": {"feature": f}})
		else:
			for q in lv.pieces:
				if q.id != p.id and Rules.touches(solved, p.id, "piece", q.id) == (type == "likes"):
					out.append({"type": type, "piece": p.id, "target": {"piece": q.id}})
	return out


func _has_rule(rules: Array, cand: Dictionary) -> bool:
	for r in rules:
		if r.piece == cand.piece and r.target == cand.target:
			return true
		# "A dislikes B" and "B dislikes A" say the same thing.
		if r.target.has("piece") and cand.target.has("piece") \
				and r.piece == cand.target.piece and r.target.piece == cand.piece:
			return true
	return false


## k sizes between 2 and big that add up to total, or [].
func _sizes(total: int, k: int, big: int) -> Array[int]:
	var out: Array[int] = []
	if total < 2 * k or total > big * k:
		return out
	for i in k:
		out.append(2)
	var left := total - 2 * k
	while left > 0:
		var i := rng.randi_range(0, k - 1)
		if out[i] < big:
			out[i] += 1
			left -= 1
	return out


## Splits `cells` into connected regions of the given sizes, or [].
func _partition(cells: Dictionary, sizes: Array[int]) -> Array:
	var left := cells.duplicate()
	var regions := []
	for i in sizes.size() - 1:
		# Start in the tightest corner so no cell gets stranded.
		var start := Vector2i(-1, -1)
		var fewest := 99
		var keys := left.keys()
		_shuffle(keys)
		for c in keys:
			var free := _free_neighbours(left, c).size()
			if free < fewest:
				fewest = free
				start = c
		var region: Array[Vector2i] = [start]
		left.erase(start)
		while region.size() < sizes[i]:
			var frontier := {}
			for c in region:
				for nb in _free_neighbours(left, c):
					frontier[nb] = true
			if frontier.is_empty():
				return []
			var pick: Vector2i = frontier.keys()[rng.randi_range(0, frontier.size() - 1)]
			region.append(pick)
			left.erase(pick)
		if left.is_empty() or not Shape.is_contiguous(left.keys()):
			return []
		regions.append(region)
	if left.size() != sizes[-1]:
		return []
	var last: Array[Vector2i] = []
	for c in left:
		last.append(c)
	regions.append(last)
	return regions


func _free_neighbours(left: Dictionary, c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in Shape.NEIGHBOURS:
		if left.has(c + d):
			out.append(c + d)
	return out


## The head goes on an end of the softie: a cell with the fewest neighbours.
func _head(cells: Array[Vector2i]) -> Array:
	var best: Array[Vector2i] = []
	var fewest := 9
	for c in cells:
		var n := 0
		for d in Shape.NEIGHBOURS:
			if cells.has(c + d):
				n += 1
		if n < fewest:
			fewest = n
			best = [c]
		elif n == fewest:
			best.append(c)
	var pick := best[rng.randi_range(0, best.size() - 1)]
	return [pick.x, pick.y]


func _canonical(cells: Array) -> String:
	var keys: Array[String] = []
	for o in Shape.orientations(cells):
		keys.append(Shape.key(o.cells))
	keys.sort()
	return keys[0]


func _cells_with(grid: Dictionary, ch: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in grid:
		if grid[c] == ch:
			out.append(c)
	return out


func _near(grid: Dictionary, c: Vector2i, ch: String, dist: int) -> bool:
	for other in grid:
		if grid[other] == ch and absi(other.x - c.x) + absi(other.y - c.y) <= dist:
			return true
	return false


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t
