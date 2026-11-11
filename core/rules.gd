class_name Rules
extends RefCounted
## Softie preferences. "Touching" means sharing an edge.
##   likes:    the softie must touch its target.
##   dislikes: the softie must not touch its target.
## A target is a feature type or another softie.


static func touches(state: BoardState, id: String, kind: String, target: String) -> bool:
	if not state.placements.has(id):
		return false
	for c in state.placements[id].cells:
		for d in Shape.NEIGHBOURS:
			var n: Vector2i = c + d
			if kind == "feature":
				if state.level.features.get(n) == target:
					return true
			elif state.occupancy.get(n) == target:
				return true
	return false


## Whether the rule holds right now. A rule on an unplaced softie does not hold.
static func satisfied(state: BoardState, rule: Dictionary) -> bool:
	if not state.is_placed(rule.piece):
		return false
	var touching := touches(state, rule.piece, rule.kind, rule.target)
	return touching if rule.type == "likes" else not touching


## Whether the rule can no longer come true without moving a placed softie.
static func violated(state: BoardState, rule: Dictionary) -> bool:
	if not state.is_placed(rule.piece):
		return false
	var touching := touches(state, rule.piece, rule.kind, rule.target)
	if rule.type == "dislikes":
		return touching
	if rule.kind == "piece" and not state.is_placed(rule.target):
		return false
	return not touching


static func any_violated(state: BoardState) -> bool:
	for r in state.level.rules:
		if violated(state, r):
			return true
	return false


static func all_satisfied(state: BoardState) -> bool:
	for r in state.level.rules:
		if not satisfied(state, r):
			return false
	return true


## A placed softie is happy when every one of its own rules holds.
static func piece_happy(state: BoardState, id: String) -> bool:
	for r in state.level.rules_for(id):
		if not satisfied(state, r):
			return false
	return true


static func is_solved(state: BoardState) -> bool:
	return state.all_placed() and all_satisfied(state)
