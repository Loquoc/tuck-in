class_name BoardState
extends RefCounted
## Which softie is where. A placement's `at` is the top-left of the softie's
## bounding box in its current orientation.

var level: LevelData
## id -> {at: Vector2i, rot: int, flip: bool, cells: Array[Vector2i]}
var placements := {}
## Vector2i -> id
var occupancy := {}
var history: Array[Dictionary] = []


func _init(lv: LevelData) -> void:
	level = lv


func cells_at(id: String, at: Vector2i, rot: int, flip: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in Shape.transform_cells(level.piece(id).cells, rot, flip):
		out.append(c + at)
	return out


## Whether `cells` are all open and free (cells held by `id` itself count as free).
func cells_free(id: String, cells: Array) -> bool:
	for c in cells:
		if not level.open.has(c):
			return false
		var holder: Variant = occupancy.get(c)
		if holder != null and holder != id:
			return false
	return true


func can_place(id: String, at: Vector2i, rot: int, flip: bool) -> bool:
	if level.piece(id).is_empty():
		return false
	return cells_free(id, cells_at(id, at, rot, flip))


func place(id: String, at: Vector2i, rot: int, flip: bool) -> bool:
	if level.piece(id).is_empty():
		return false
	var cells := cells_at(id, at, rot, flip)
	if not cells_free(id, cells):
		return false
	remove(id)
	put(id, at, rot, flip, cells)
	return true


## Unchecked placement, for callers that have already validated `cells`.
func put(id: String, at: Vector2i, rot: int, flip: bool, cells: Array) -> void:
	placements[id] = {"at": at, "rot": posmod(rot, 4), "flip": flip, "cells": cells}
	for c in cells:
		occupancy[c] = id


func remove(id: String) -> void:
	if not placements.has(id):
		return
	for c in placements[id].cells:
		occupancy.erase(c)
	placements.erase(id)


func clear() -> void:
	placements.clear()
	occupancy.clear()


func is_placed(id: String) -> bool:
	return placements.has(id)


func all_placed() -> bool:
	return placements.size() == level.pieces.size()


## id -> {at, rot, flip}; safe to keep and to store as save data.
func snapshot() -> Dictionary:
	var snap := {}
	for id in placements:
		var p: Dictionary = placements[id]
		snap[id] = {"at": p.at, "rot": p.rot, "flip": p.flip}
	return snap


## Replaces all placements. Entries that no longer fit are skipped.
func restore(snap: Dictionary) -> void:
	clear()
	for id in snap:
		var p: Dictionary = snap[id]
		place(id, p.at, p.rot, p.flip)


func matches(snap: Dictionary) -> bool:
	if snap.size() != placements.size():
		return false
	for id in snap:
		if not placements.has(id):
			return false
		var a: Dictionary = snap[id]
		var b: Dictionary = placements[id]
		if a.at != b.at or a.rot != b.rot or a.flip != b.flip:
			return false
	return true


## Call with a snapshot taken before a change; ignored if nothing changed.
func push_history(before: Dictionary) -> void:
	if not matches(before):
		history.append(before)


func can_undo() -> bool:
	return not history.is_empty()


func undo() -> bool:
	if history.is_empty():
		return false
	restore(history.pop_back())
	return true
