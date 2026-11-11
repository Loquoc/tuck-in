class_name LevelLoader
extends RefCounted
## JSON -> LevelData, with validation. Board rows use:
##   '.' open   '#' blocked   'P' pillow   'N' night-light

const LEVEL_COUNT := 56
## The first levels are hand-made tutorials; the generator numbers after them.
const TUTORIAL_COUNT := 2
## How many gentle levels follow the tutorials (small cribs, every feature).
const GENTLE_COUNT := 24
## Chapters open independently, so nobody has to finish one to try another.
const CHAPTERS := [
	{"icon": "star", "from": 1, "to": 26},
	{"icon": "moon", "from": 27, "to": 34},
	{"icon": "pillow", "from": 35, "to": 44},
	{"icon": "heart", "from": 45, "to": 56},
]
const FEATURE_CHARS := {"P": "pillow", "N": "nightlight"}
const FEATURES: Array[String] = ["pillow", "nightlight"]


static func path_for(n: int) -> String:
	return "res://levels/%02d.json" % n


static func load_level(n: int, errors: Array = []) -> LevelData:
	var lv := load_file(path_for(n), errors)
	if lv != null:
		lv.number = n
	return lv


static func load_file(path: String, errors: Array = []) -> LevelData:
	if not FileAccess.file_exists(path):
		errors.append("missing file: " + path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		errors.append("not a JSON object: " + path)
		return null
	return parse(parsed, errors)


static func parse(d: Dictionary, errors: Array = []) -> LevelData:
	var start := errors.size()
	var lv := LevelData.new()
	lv.coach = bool(d.get("coach", false))

	var rows: Array = d.get("board", [])
	if rows.is_empty():
		errors.append("board is empty")
		return null
	lv.height = rows.size()
	lv.width = str(rows[0]).length()
	for y in rows.size():
		var row := str(rows[y])
		if row.length() != lv.width:
			errors.append("board row %d has a different width" % y)
			continue
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			if ch == ".":
				lv.open[cell] = true
			elif ch == "#":
				lv.blocked[cell] = true
			elif FEATURE_CHARS.has(ch):
				lv.features[cell] = FEATURE_CHARS[ch]
			else:
				errors.append("unknown board character '%s'" % ch)

	for raw in d.get("pieces", []):
		var id := str(raw.get("id", ""))
		if id == "" or lv.pieces.any(func(p: Dictionary) -> bool: return p.id == id):
			errors.append("piece id missing or duplicated: '%s'" % id)
			continue
		var cells: Array[Vector2i] = []
		for c in raw.get("cells", []):
			cells.append(_cell(c))
		if cells.size() < 2 or not Shape.is_contiguous(cells):
			errors.append("piece '%s' must be 2+ connected cells" % id)
			continue
		if Shape.key(cells) != Shape.key(Shape.transform_cells(cells, 0, false)):
			errors.append("piece '%s' cells must start at 0,0" % id)
		var head: Vector2i = _cell(raw.get("head", [cells[0].x, cells[0].y]))
		if not cells.has(head):
			errors.append("piece '%s' head is not one of its cells" % id)
		lv.pieces.append({
			"id": id,
			"cells": cells,
			"head": head,
			"animal": str(raw.get("animal", id)),
			"fabric": str(raw.get("fabric", "gingham")),
			"colour": str(raw.get("colour", "rose")),
		})
	if lv.pieces.is_empty():
		errors.append("level has no pieces")
	lv.index_pieces()

	for raw in d.get("rules", []):
		var type := str(raw.get("type", ""))
		var piece := str(raw.get("piece", ""))
		var target: Dictionary = raw.get("target", {})
		if type != "likes" and type != "dislikes":
			errors.append("unknown rule type '%s'" % type)
			continue
		if lv.piece(piece).is_empty():
			errors.append("rule names unknown piece '%s'" % piece)
			continue
		if target.has("feature"):
			var f := str(target.feature)
			if not FEATURES.has(f):
				errors.append("rule names unknown feature '%s'" % f)
				continue
			lv.rules.append({"type": type, "piece": piece, "kind": "feature", "target": f})
		elif target.has("piece"):
			var other := str(target.piece)
			if lv.piece(other).is_empty() or other == piece:
				errors.append("rule for '%s' has a bad target piece '%s'" % [piece, other])
				continue
			lv.rules.append({"type": type, "piece": piece, "kind": "piece", "target": other})
		else:
			errors.append("rule target needs 'feature' or 'piece'")

	for raw in d.get("solution", []):
		var id := str(raw.get("id", ""))
		if lv.piece(id).is_empty():
			errors.append("solution names unknown piece '%s'" % id)
			continue
		lv.solution[id] = {
			"at": _cell(raw.get("at", [0, 0])),
			"rot": int(raw.get("rot", 0)),
			"flip": bool(raw.get("flip", false)),
		}

	if lv.piece_cell_total() > lv.open.size():
		errors.append("softies need more cells than the crib has")
	return lv if errors.size() == start else null


static func _cell(v: Variant) -> Vector2i:
	if v is Array and v.size() == 2:
		return Vector2i(int(v[0]), int(v[1]))
	return Vector2i(-1, -1)
