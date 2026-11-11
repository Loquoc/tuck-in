class_name Shape
extends RefCounted
## Polyomino maths. A shape is a list of Vector2i cells. An orientation is
## (rot, flip): mirror horizontally first if flip, then rotate rot quarter
## turns clockwise. Results are translated so the minimum x and y are 0, and
## keep the same cell order as the input, so an index (e.g. the head cell)
## stays valid across orientations.


static func transform_cells(cells: Array, rot: int, flip: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var min_x := 1 << 30
	var min_y := 1 << 30
	var turns := posmod(rot, 4)
	for c in cells:
		var p: Vector2i = c
		if flip:
			p.x = -p.x
		for i in turns:
			p = Vector2i(-p.y, p.x)
		out.append(p)
		min_x = mini(min_x, p.x)
		min_y = mini(min_y, p.y)
	var shift := Vector2i(min_x, min_y)
	for i in out.size():
		out[i] -= shift
	return out


static func size_of(cells: Array) -> Vector2i:
	var w := 0
	var h := 0
	for c in cells:
		var p: Vector2i = c
		w = maxi(w, p.x + 1)
		h = maxi(h, p.y + 1)
	return Vector2i(w, h)


## Order-independent identity of a normalised cell set.
static func key(cells: Array) -> String:
	var ids: Array[int] = []
	for c in cells:
		var p: Vector2i = c
		ids.append(p.y * 64 + p.x)
	ids.sort()
	return ",".join(ids.map(func(v: int) -> String: return str(v)))


## All distinct orientations: Array of {rot, flip, cells}. Up to 4 by turning
## alone, up to 8 with flips; symmetric shapes return fewer.
static func orientations(cells: Array, with_flips := ALLOW_FLIP) -> Array[Dictionary]:
	var seen := {}
	var out: Array[Dictionary] = []
	for flip in ([false, true] if with_flips else [false]):
		for rot in 4:
			var t := transform_cells(cells, rot, flip)
			var k := key(t)
			if not seen.has(k):
				seen[k] = true
				out.append({"rot": rot, "flip": flip, "cells": t})
	return out


## The (rot, flip) that turns `from` into the same cell set as `to`, or {}.
static func find_orientation(from: Array, to: Array, with_flips := ALLOW_FLIP) -> Dictionary:
	var want := key(transform_cells(to, 0, false))
	for flip in ([false, true] if with_flips else [false]):
		for rot in 4:
			if key(transform_cells(from, rot, flip)) == want:
				return {"rot": rot, "flip": flip}
	return {}


static func is_contiguous(cells: Array) -> bool:
	if cells.is_empty():
		return false
	var all := {}
	for c in cells:
		all[c] = true
	var start: Vector2i = cells[0]
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_back()
		for d in NEIGHBOURS:
			var n: Vector2i = p + d
			if all.has(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen.size() == all.size()


## The game has no mirror control: softies can be turned but not flipped, so
## the solver and level tools must not count mirrored placements either.
## The mirror maths stays, for tools that want it.
const ALLOW_FLIP := false

const NEIGHBOURS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
