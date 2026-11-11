extends Node2D
## The level scene. Wires the board state to the views and handles touch.
## All game state lives in `state`; views are told where to go.

const LEFT_BAR := 190.0
const TAP_SLOP := 22.0
const TAP_MS := 300
## How far ahead of the finger a carried softie is drawn, in seconds of motion.
const LEAD_SECONDS := 0.06

var level: LevelData
var state: BoardState
var kid := false
var won := false
var cell := 150.0
var pieces := {}                    # id -> PieceView
var order: Array[PieceView] = []    # back to front
var last_touched: PieceView
var drag := {}

var _backdrop: Painter
var _board: BoardView
var _ghosts: GhostLayer
var _dim: ColorRect
var _piece_layer: Node2D
var _hud: Hud
var _tray := Rect2()
var _overlay: Control
var _coach: Coach


func _ready() -> void:
	var number := int(Router.params.get("level", SaveData.next_unsolved()))
	level = LevelLoader.load_level(number)
	if level == null:
		Router.go.call_deferred("levels")
		return
	kid = SaveData.kid_mode
	state = BoardState.new(level)

	_backdrop = Painter.new()
	_backdrop.paint = _paint_backdrop
	add_child(_backdrop)
	_board = BoardView.new()
	add_child(_board)
	_board.setup(level, cell)
	_ghosts = GhostLayer.new()
	_ghosts.visible = kid
	add_child(_ghosts)
	_dim = ColorRect.new()
	_dim.color = Color(Palette.NIGHT_DEEP, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_piece_layer = Node2D.new()
	add_child(_piece_layer)
	for def in level.pieces:
		var pv := PieceView.new()
		_piece_layer.add_child(pv)
		pv.setup(def, cell, level)
		pieces[def.id] = pv
		order.append(pv)
		_reset_orientation(pv)

	_hud = Hud.new()
	add_child(_hud)
	_hud.setup(number)
	_hud.back_pressed.connect(func() -> void: Router.go("levels"))
	_hud.undo_pressed.connect(_on_undo)
	_hud.restart_pressed.connect(_on_restart)
	_hud.hint_pressed.connect(_on_hint)

	if level.coach:
		_coach = Coach.new()
		_coach.game = self
		add_child(_coach)

	state.restore(SaveData.get_progress(number))
	_apply_dev_args()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_after_change()


func _apply_dev_args() -> void:
	var count := -1
	if Router.dev.has("solve"):
		count = level.pieces.size()
	elif Router.dev.has("place"):
		count = int(Router.dev.place)
	for i in mini(count, level.pieces.size()):
		var id: String = level.pieces[i].id
		var s: Dictionary = level.solution[id]
		state.place(id, s.at, s.rot, s.flip)


# --- layout ----------------------------------------------------------------

func _layout() -> void:
	var vp := get_viewport_rect().size
	_tray = Tray.rect_for(vp)
	var area := Rect2(LEFT_BAR, 0.0, _tray.position.x - LEFT_BAR, vp.y)
	cell = floorf(minf(minf(
		(area.size.x - 90.0) / (level.width + 0.5),
		(area.size.y - 120.0) / (level.height + 0.5)), 210.0))
	_board.set_cell(cell)
	_board.position = (area.position + (area.size - _board.grid_size()) * 0.5).round()
	_ghosts.position = _board.position
	_ghosts.setup(level, cell)
	_dim.size = vp
	var count := level.pieces.size()
	var shared := 1.0
	for i in count:
		var pv: PieceView = pieces[level.pieces[i].id]
		pv.set_cell(cell)
		pv.home = Tray.slot_centre(_tray, count, i)
		shared = minf(shared, Tray.fit_scale(_tray, count, Vector2(pv.size) * cell))
	# Every waiting softie is shown at the same scale, so their sizes can be
	# compared by eye.
	for id in pieces:
		pieces[id].home_scale = shared
	_hud.layout(vp)
	if _overlay != null:
		_overlay.size = vp
	_backdrop.queue_redraw()
	_sync(false)


func _paint_backdrop(ci: Brush) -> void:
	var vp := get_viewport_rect().size
	UIKit.paint_night(ci, vp, 11 + level.number)
	# A round rug under the crib.
	var centre := _board.position + _board.grid_size() * 0.5
	var g := _board.grid_size()
	var rug := Vector2(g.x * 0.5 + cell * 1.1, g.y * 0.5 + cell * 0.75)
	ci.draw_ellipse(centre, rug.x, rug.y, Color(Palette.NIGHT_SOFT, 0.55))
	ci.draw_ellipse(centre, rug.x * 0.93, rug.y * 0.93, Color(Palette.NIGHT, 0.22))
	ci.draw_ellipse(centre, rug.x * 0.9, rug.y * 0.9, Color(Palette.NIGHT_SOFT, 0.4))
	Tray.paint(ci, _tray)


# --- keeping the views in step with the state ------------------------------

func _sync(animated: bool) -> void:
	for id in pieces:
		var pv: PieceView = pieces[id]
		if drag.get("piece") == pv:
			continue
		if state.is_placed(id):
			var p: Dictionary = state.placements[id]
			pv.set_orientation(p.rot, p.flip)
			pv.placed = true
			var target := _board.centre_of(p.at, pv.size)
			if animated:
				pv.glide(target, 1.0)
			else:
				pv.jump_to(target, 1.0)
		else:
			if pv.placed:
				_reset_orientation(pv)
			pv.placed = false
			if animated:
				pv.glide(pv.home, pv.home_scale)
			else:
				pv.jump_to(pv.home, pv.home_scale)
	_refresh()


## In kid mode softies always wait in the orientation they will be placed in.
func _reset_orientation(pv: PieceView) -> void:
	if kid and level.solution.has(pv.id):
		var s: Dictionary = level.solution[pv.id]
		pv.set_orientation(s.rot, s.flip)


func _refresh() -> void:
	for id in pieces:
		var pv: PieceView = pieces[id]
		var is_placed := state.is_placed(id)
		var states: Array[int] = []
		for rule in level.rules_for(id):
			states.append(0 if not is_placed else (1 if Rules.satisfied(state, rule) else 2))
		pv.set_rule_states(states)
		if won:
			continue
		if not is_placed:
			pv.mood = Faces.Mood.AWAKE
		elif Rules.piece_happy(state, id):
			pv.mood = Faces.Mood.CONTENT
		else:
			pv.mood = Faces.Mood.FUSSY
	_ghosts.refresh(state)
	_hud.set_can_undo(state.can_undo() and not won)


func _after_change() -> void:
	if won:
		return
	SaveData.set_progress(level.number, state.snapshot())
	if Rules.is_solved(state):
		_win()


func _raise(pv: PieceView) -> void:
	order.erase(pv)
	order.append(pv)
	_piece_layer.move_child(pv, -1)


# --- touch -----------------------------------------------------------------
# A softie pops up the moment it is touched. Letting go quickly without
# moving is a tap, which turns it; anything else is a carry.

func _unhandled_input(event: InputEvent) -> void:
	if won or level == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed and drag.is_empty():
			_press(event.index, event.position)
		elif not event.pressed and drag.get("index", -1) == event.index:
			# Land exactly under the finger, without any lead.
			drag.pos = event.position
			drag.vel = Vector2.ZERO
			_follow(0.0)
			_release()
	elif event is InputEventScreenDrag and drag.get("index", -1) == event.index:
		_track(event.position)
		if not drag.moved and drag.pos.distance_to(drag.start) > TAP_SLOP:
			drag.moved = true
		_follow(0.0)


## Records a new finger position and keeps a smoothed finger velocity.
func _track(point: Vector2) -> void:
	var now := Time.get_ticks_usec()
	var dt := (now - int(drag.at_us)) / 1000000.0
	if dt > 0.002:
		var v: Vector2 = (point - drag.pos) / dt
		drag.vel = drag.vel.lerp(v, 0.6)
	drag.pos = point
	drag.at_us = now


func _piece_at(point: Vector2) -> PieceView:
	for i in range(order.size() - 1, -1, -1):
		if order[i].contains_point(point, not order[i].placed):
			return order[i]
	return null


func _press(index: int, point: Vector2) -> void:
	var pv := _piece_at(point)
	if pv == null:
		return
	last_touched = pv
	drag = {
		"index": index, "piece": pv, "start": point, "pos": point, "moved": false,
		"time": Time.get_ticks_msec(), "rise": 0.0, "before": state.snapshot(),
		"vel": Vector2.ZERO, "at_us": Time.get_ticks_usec(),
		# The point of the softie under the finger, in its own unscaled space.
		"grip": (point - pv.position) / pv.scale.x,
	}
	state.remove(pv.id)
	pv.placed = false
	_raise(pv)
	pv.scale_to(1.0)
	pv.raise(true)
	pv.squish(0.6)
	Audio.play("pick")
	_refresh()


func _process(delta: float) -> void:
	if not drag.is_empty():
		_follow(delta)


func _follow(delta: float) -> void:
	var pv: PieceView = drag.piece
	drag.rise = move_toward(drag.rise, 1.0, delta * 9.0)
	# A finger that has stopped sends no more events, so let the lead fade.
	if Time.get_ticks_usec() - int(drag.at_us) > 50000:
		drag.vel = drag.vel.lerp(Vector2.ZERO, minf(1.0, delta * 20.0))
	# A frame reaches the screen a few frames after the touch it shows, so
	# the softie is drawn where the finger is heading, not where it was.
	var lead: Vector2 = (drag.vel * LEAD_SECONDS).limit_length(cell * 0.8)
	# Hold the softie a little above the finger so it stays visible.
	pv.position = drag.pos + lead - drag.grip * pv.scale.x + Vector2(0, -cell * 0.2 * drag.rise)
	var anchor := _board.anchor_for(pv.top_left())
	var cells := state.cells_at(pv.id, anchor, pv.rot, pv.flip)
	var on_board := cells.filter(func(c: Vector2i) -> bool: return level.open.has(c))
	if on_board.is_empty() or not drag.moved:
		_board.clear_preview()
	else:
		_board.set_preview(on_board, state.cells_free(pv.id, cells))


func _release() -> void:
	var d := drag
	drag = {}
	var pv: PieceView = d.piece
	_board.clear_preview()
	pv.raise(false)
	if not d.moved and Time.get_ticks_msec() - d.time < TAP_MS:
		# A tap: put it back exactly where it was, then turn it.
		state.restore(d.before)
		_turn(pv)
		_sync(true)
		return
	var landed := false
	if kid and level.solution.has(pv.id):
		# Forgiving snap: near enough to its ghost is good enough.
		var s: Dictionary = level.solution[pv.id]
		if pv.position.distance_to(_board.centre_of(s.at, pv.size)) < cell * 1.3:
			landed = state.place(pv.id, s.at, s.rot, s.flip)
	if not landed:
		landed = state.place(pv.id, _board.anchor_for(pv.top_left()), pv.rot, pv.flip)
	state.push_history(d.before)
	_sync(true)
	if landed:
		pv.squish()
		Audio.play("drop")
	elif _board.get_rect_in_scene().grow(cell * 0.3).has_point(pv.position):
		Audio.play("nope")
	_after_change()


# --- actions ---------------------------------------------------------------

func _turn(pv: PieceView) -> void:
	if kid:
		pv.squish()
		return
	_reorient(pv)


## Quarter-turns a softie. One on the board stays put if the new shape fits
## around the same centre; otherwise it goes back to the tray.
func _reorient(pv: PieceView) -> void:
	var before := state.snapshot()
	var was_placed := state.is_placed(pv.id)
	var centre := pv.position
	if was_placed:
		centre = _board.centre_of(state.placements[pv.id].at, pv.size)
	pv.turn_cw()
	Audio.play("turn")
	if not was_placed:
		return
	state.remove(pv.id)
	var anchor := _board.anchor_for(centre - Vector2(pv.size) * cell * 0.5)
	state.place(pv.id, anchor, pv.rot, pv.flip)
	state.push_history(before)
	_sync(true)
	_after_change()


func _on_undo() -> void:
	if won or not drag.is_empty():
		return
	if state.undo():
		Audio.play("turn", 0.8)
		_sync(true)
		_after_change()


func _on_restart() -> void:
	if won or not drag.is_empty() or state.placements.is_empty():
		return
	var before := state.snapshot()
	state.clear()
	state.push_history(before)
	Audio.play("pick", 0.8)
	_sync(true)
	_after_change()


## Puts one softie where the stored solution has it, moving aside anything
## in its way.
func _on_hint() -> void:
	if won or not drag.is_empty():
		return
	var pick := ""
	for want_unplaced in [true, false]:
		for def in level.pieces:
			if pick == "" and state.is_placed(def.id) != want_unplaced and not _is_solved_spot(def.id):
				pick = def.id
	if pick == "" or not level.solution.has(pick):
		return
	var before := state.snapshot()
	var s: Dictionary = level.solution[pick]
	for c in state.cells_at(pick, s.at, s.rot, s.flip):
		var holder: Variant = state.occupancy.get(c)
		if holder != null and holder != pick:
			state.remove(holder)
	state.place(pick, s.at, s.rot, s.flip)
	state.push_history(before)
	var pv: PieceView = pieces[pick]
	last_touched = pv
	_raise(pv)
	_sync(true)
	pv.squish()
	Audio.note(7.0)
	_after_change()


func _is_solved_spot(id: String) -> bool:
	if not state.is_placed(id) or not level.solution.has(id):
		return false
	var s: Dictionary = level.solution[id]
	var want := state.cells_at(id, s.at, s.rot, s.flip)
	var have: Array = state.placements[id].cells
	for c in want:
		if not have.has(c):
			return false
	return true


# --- winning ---------------------------------------------------------------

func _win() -> void:
	won = true
	var first_time := not SaveData.is_earned(level.number)
	SaveData.mark_done(level.number)
	_hud.lock()
	_refresh()
	Audio.win()
	create_tween().tween_property(_dim, "color:a", 0.55, 1.4)
	await get_tree().create_timer(0.6).timeout
	var scale_notes := [0, 2, 4, 7, 9, 12]
	for i in level.pieces.size():
		if not is_inside_tree():
			return
		var pv: PieceView = pieces[level.pieces[i].id]
		pv.fall_asleep()
		Audio.note(scale_notes[i % scale_notes.size()], "Sfx", -8.0)
		await get_tree().create_timer(0.26).timeout
	await get_tree().create_timer(0.45).timeout
	if is_inside_tree():
		_show_win(first_time)


func _show_win(first_time: bool) -> void:
	var vp := get_viewport_rect().size
	_overlay = Control.new()
	_overlay.size = vp
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# The tray is empty now: use it for the new softie and what comes next.
	var mid := _tray.get_center()
	var sky := Painter.new()
	sky.paint = func(b: Brush) -> void:
		Icons.draw(b, "moon", Vector2(mid.x, _tray.position.y + 120.0), 150.0, Palette.GLOW)
		if first_time:
			for spark in [Vector2(-190, -330), Vector2(200, -290), Vector2(-210, -70), Vector2(190, -60)]:
				b.draw_colored_polygon(Icons.star(mid + spark, 26.0, 11.0), Palette.GLOW)
	_overlay.add_child(sky)

	var last := level.number >= LevelLoader.LEVEL_COUNT
	var next := RoundButton.new("levels" if last else "play", 200.0)
	next.fill = Palette.GLOW
	next.position = mid + Vector2(-100.0, 150.0)
	next.pressed.connect(func() -> void:
		if last:
			Router.go("shelf")
		else:
			Router.go("game", {"level": level.number + 1}))
	_overlay.add_child(next)
	var shelf := RoundButton.new("heart", 110.0)
	shelf.position = mid + Vector2(-55.0, 400.0)
	shelf.pressed.connect(func() -> void: Router.go("shelf"))
	_overlay.add_child(shelf)

	var reward := PieceView.new()
	_overlay.add_child(reward)
	reward.setup(Rewards.def_for(level.number), 170.0)
	reward.position = mid + Vector2(0.0, -190.0)
	reward.mood = Faces.Mood.CONTENT

	_overlay.modulate.a = 0.0
	reward.scale = Vector2(0.4, 0.4)
	var t := create_tween().set_parallel()
	t.tween_property(_overlay, "modulate:a", 1.0, 0.35)
	t.tween_property(reward, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reward.squish()
