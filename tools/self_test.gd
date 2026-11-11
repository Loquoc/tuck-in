extends Node
## End-to-end check that plays levels through real touch events.
## Run:  godot --headless --path . -- --selftest
## The Router starts this when it sees --selftest. Nothing is saved.

var _failed := 0
var _passed := 0
var _game: Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _wait(0.3)

	# Level 29: buttons first, then a full solve by dragging.
	await _open(29, false)
	var first: String = _game.level.pieces[0].id
	await _place(first)
	check(_game.state.is_placed(first), "a dragged softie lands on the board")
	check(SaveData.get_progress(29).has(first), "progress is recorded after a move")
	_game._hud.undo_pressed.emit()
	await _wait(0.4)
	check(not _game.state.is_placed(first), "undo takes it back off")
	check(not _game.pieces[first].placed, "undo sends the view back to the tray")
	_game._hud.hint_pressed.emit()
	await _wait(0.4)
	check(_game.state.placements.size() == 1, "hint places one softie")
	_game._hud.restart_pressed.emit()
	await _wait(0.4)
	check(_game.state.placements.is_empty(), "restart clears the board")
	_game._hud.undo_pressed.emit()
	await _wait(0.4)
	check(_game.state.placements.size() == 1, "restart can be undone")
	_game._hud.restart_pressed.emit()
	await _wait(0.4)

	# A drop that overlaps is refused.
	await _place(first)
	var second: String = _game.level.pieces[1].id
	await _drag(_game.pieces[second], _game.pieces[first].position)
	check(not _game.state.is_placed(second), "dropping onto another softie is refused")
	check(_game.pieces[second].position.distance_to(_game.pieces[second].home) < 2.0, "the refused softie returns to the tray")

	# Tapping a placed softie turns it in place or sends it home, never overlapping.
	var before_rot: int = _game.pieces[first].rot
	await _tap(_game.pieces[first].position)
	check(_game.pieces[first].rot == (before_rot + 1) % 4, "tap turns a softie a quarter turn")
	_game._hud.restart_pressed.emit()
	await _wait(0.4)

	await _solve()
	check(_game.won, "level 29 is won by dragging every softie home")
	check(SaveData.is_done(29), "the win is recorded")

	# Tutorials, the gentle run, and the full-size levels.
	for n in [1, 2, 5, 12, 18, 26, 38, 44, 51, 56]:
		await _open(n, false)
		await _solve()
		check(_game.won, "level %d is won" % n)

	# Kid mode: softies arrive oriented, and a sloppy drop still snaps home.
	await _open(53, true)
	var all_oriented := true
	for def in _game.level.pieces:
		var s: Dictionary = _game.level.solution[def.id]
		var pv: PieceView = _game.pieces[def.id]
		if pv.rot != s.rot or pv.flip != s.flip:
			all_oriented = false
	check(all_oriented, "kid mode hands softies out in their solved orientation")
	var kid_first: String = _game.level.pieces[0].id
	var rot_before: int = _game.pieces[kid_first].rot
	await _tap(_game.pieces[kid_first].position)
	check(_game.pieces[kid_first].rot == rot_before, "kid mode ignores tap-to-turn")
	for def in _game.level.pieces:
		await _place(def.id, Vector2(0.55, -0.45))
	check(_game.won, "kid mode: off-target drops snap to the ghosts and win")
	check(SaveData.is_done(53, "kid") and not SaveData.is_done(53, "normal"), "kid mode progress is kept apart from normal mode")

	print("\nself-test: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func check(ok: bool, what: String) -> void:
	if ok:
		_passed += 1
		print("  ok    " + what)
	else:
		_failed += 1
		printerr("  FAIL  " + what)


func _open(number: int, kid: bool) -> void:
	SaveData.kid_mode = kid
	Router.params = {"level": number}
	get_tree().change_scene_to_file("res://game/game.tscn")
	await _wait(0.4)
	_game = get_tree().current_scene


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _touch(point: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = point
	e.pressed = pressed
	get_viewport().push_input(e, true)


func _tap(point: Vector2) -> void:
	_touch(point, true)
	await get_tree().process_frame
	_touch(point, false)
	await _wait(0.35)


func _drag(pv: PieceView, to: Vector2) -> void:
	var from := pv.position
	# The game holds a softie slightly above the finger; aim the finger lower.
	var finger_to := to + Vector2(0, _game.cell * 0.2)
	_touch(from, true)
	await get_tree().process_frame
	for i in range(1, 13):
		var e := InputEventScreenDrag.new()
		e.index = 0
		e.position = from.lerp(finger_to, i / 12.0)
		get_viewport().push_input(e, true)
		await get_tree().process_frame
	await _wait(0.25)
	_touch(finger_to, false)
	await _wait(0.45)


## Turns and drags one softie to its solution spot, as a player would.
func _place(id: String, miss := Vector2.ZERO) -> void:
	var pv: PieceView = _game.pieces[id]
	var s: Dictionary = _game.level.solution[id]
	var want := Shape.key(Shape.transform_cells(pv.def.cells, s.rot, s.flip))
	for turn in 4:
		if Shape.key(pv.cells) == want:
			break
		await _tap(pv.position)
	var size := Shape.size_of(pv.cells)
	await _drag(pv, _game._board.centre_of(s.at, size) + miss * _game.cell)


func _solve() -> void:
	for def in _game.level.pieces:
		await _place(def.id)
	await _wait(0.3)
