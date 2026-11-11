class_name Coach
extends Node2D
## Tutorial levels only: a wordless fingertip that acts out the next move.
## It works out what the first waiting softie needs (a turn, or a carry to
## its spot) and loops that gesture until the player does it.

const TAP_LOOP := 1.5
const DRAG_LOOP := 2.6
const IDLE_BEFORE := 0.8

var game: Node

var _gesture := ""
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0
var _quiet := 0.0


func _process(delta: float) -> void:
	var next := _decide()
	if next.is_empty():
		_quiet = 0.0
		if _gesture != "":
			_gesture = ""
			queue_redraw()
		return
	# Give the player a moment before showing them again.
	_quiet += delta
	if next.gesture != _gesture or not next.from.is_equal_approx(_from) or not next.to.is_equal_approx(_to):
		_gesture = next.gesture
		_from = next.from
		_to = next.to
		_t = 0.0
	if _quiet < IDLE_BEFORE:
		return
	_t = fmod(_t + delta, TAP_LOOP if _gesture == "tap" else DRAG_LOOP)
	queue_redraw()


func _decide() -> Dictionary:
	if game.won or not game.drag.is_empty():
		return {}
	var level: LevelData = game.level
	for def in level.pieces:
		if game.state.is_placed(def.id) or not level.solution.has(def.id):
			continue
		var pv: PieceView = game.pieces[def.id]
		var s: Dictionary = level.solution[def.id]
		var solved := Shape.transform_cells(def.cells, s.rot, s.flip)
		var want := Shape.key(solved)
		if Shape.key(pv.cells) == want:
			return {"gesture": "drag", "from": pv.home, "to": game._board.centre_of(s.at, Shape.size_of(solved))}
		for turns in range(1, 4):
			if Shape.key(Shape.transform_cells(def.cells, pv.rot + turns, pv.flip)) == want:
				return {"gesture": "tap", "from": pv.home, "to": pv.home}
		return {}
	return {}


func _draw() -> void:
	if _gesture == "" or _quiet < IDLE_BEFORE:
		return
	var b := Brush.new()
	if _gesture == "tap":
		var u := _t / TAP_LOOP
		var down := smoothstep(0.15, 0.3, u) * (1.0 - smoothstep(0.42, 0.55, u))
		if u > 0.3:
			var spread := (u - 0.3) / 0.7
			b.draw_arc(_from, 40.0 + spread * 90.0, 0.0, TAU, 48, Color(Palette.GLOW, 0.9 * (1.0 - spread)), 8.0)
		_finger(b, _from, down, 1.0)
	else:
		var u := _t / DRAG_LOOP
		var travel := smoothstep(0.22, 0.72, u)
		var alpha := smoothstep(0.0, 0.1, u) * (1.0 - smoothstep(0.85, 1.0, u))
		var down := smoothstep(0.08, 0.2, u) * (1.0 - smoothstep(0.74, 0.84, u))
		var at := _from.lerp(_to, travel)
		if travel > 0.0 and travel < 1.0:
			for i in 5:
				var back := _from.lerp(_to, maxf(travel - 0.035 * (i + 1), 0.0))
				b.draw_circle(back, 16.0 - i * 2.0, Color(Palette.CREAM, 0.3 * alpha * (1.0 - i / 5.0)))
		_finger(b, at, down, alpha)
	b.flush(self)


## A fingertip: a soft round pad that shrinks a little while pressing.
func _finger(b: Brush, at: Vector2, down: float, alpha: float) -> void:
	var r := 46.0 - 9.0 * down
	b.draw_circle(at + Vector2(0, 8.0 - 5.0 * down), r + 3.0, Color(0.03, 0.04, 0.12, 0.3 * alpha))
	b.draw_circle(at, r, Color(Palette.CREAM, 0.92 * alpha))
	b.draw_arc(at, r, 0.0, TAU, 40, Color(Palette.INK, 0.45 * alpha), 4.0)
	b.draw_circle(at + Vector2(-r * 0.28, -r * 0.3), r * 0.2, Color(1, 1, 1, 0.7 * alpha))
