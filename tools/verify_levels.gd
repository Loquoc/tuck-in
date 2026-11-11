extends SceneTree
## Checks every level file.  Run:  godot --headless -s tools/verify_levels.gd
## For each level: it parses, the stored solution places every softie and
## satisfies every rule, and the solver agrees it is solvable. Also reports
## how many solutions exist (capped) so dull or over-tight levels stand out.

const CAP := 50


func _init() -> void:
	var bad := 0
	for n in range(1, LevelLoader.LEVEL_COUNT + 1):
		var errors := []
		var lv := LevelLoader.load_level(n, errors)
		if lv == null:
			printerr("level %02d: does not load: %s" % [n, ", ".join(errors)])
			bad += 1
			continue
		var problems: Array[String] = []
		if lv.solution.size() != lv.pieces.size():
			problems.append("solution does not cover every softie")
		var st := BoardState.new(lv)
		for id in lv.solution:
			var s: Dictionary = lv.solution[id]
			if not st.place(id, s.at, s.rot, s.flip):
				problems.append("stored solution cannot place '%s'" % id)
		if problems.is_empty() and not Rules.is_solved(st):
			problems.append("stored solution breaks a rule")
		var res := Solver.solve(lv, CAP)
		if res.gave_up:
			problems.append("solver gave up")
		elif res.count == 0:
			problems.append("solver finds no solution")
		if problems.is_empty():
			print("level %02d: ok   %dx%d  %d softies  %d rules  %s solutions%s" % [
				n, lv.width, lv.height, lv.pieces.size(), lv.rules.size(),
				str(res.count) if res.count < CAP else "%d+" % CAP,
				"  (exact fit)" if lv.is_exact() else ""])
		else:
			printerr("level %02d: %s" % [n, "; ".join(problems)])
			bad += 1
	print("\n%d of %d levels ok" % [LevelLoader.LEVEL_COUNT - bad, LevelLoader.LEVEL_COUNT])
	quit(1 if bad > 0 else 0)
