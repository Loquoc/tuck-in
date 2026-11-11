class_name PieceView
extends Node2D
## One softie on screen. Its position is the centre of its bounding box.
## Holds no game state beyond its own orientation; the game scene decides
## where it may go.

const INSET := 0.045    # gap to the cell edge, as a fraction of a cell
const RADIUS := 0.2

var def := {}
var id := ""
var level: LevelData
var cell := 150.0
var rot := 0
var flip := false
var cells: Array[Vector2i] = []
var size := Vector2i.ONE
var placed := false
var home := Vector2.ZERO
var home_scale := 0.5
var mood: int = Faces.Mood.AWAKE: set = set_mood
var lift := 0.0: set = set_lift
## Seconds between habits, as (shortest, longest).
var antic_gap := Vector2(4.0, 11.0)
## Which of the animal's two habits this softie favours; -1 for no favourite.
var favourite := -1

var _rules: Array[Dictionary] = []
var _rule_states: Array[int] = []    # per rule: 0 waiting, 1 holds, 2 broken
var _base := Color.WHITE
var _outline := PackedVector2Array()
var _stitches: Array[PackedVector2Array] = []
var _material: ShaderMaterial
var _vis: Node2D
var _shadow: Painter
var _body: Painter
var _detail: Painter
var _face: Painter
var _bubbles: Array[Painter] = []
var _blink := false
var _breath := 0.0
var _pose := {}
var _face_home := Vector2.ZERO
var _face_shift := Vector2.ZERO    # in cells
var _face_tilt := 0.0
var _antic := ""
var _antic_t := 0.0
var _antic_in := 4.0
var _blink_in := 3.0
var _move: Tween
var _fx: Tween
var _lift_tween: Tween


func setup(piece_def: Dictionary, cell_size: float, lv: LevelData = null) -> void:
	def = piece_def
	id = def.id
	level = lv
	cell = cell_size
	_base = Palette.fabric(def.colour)
	if lv != null:
		_rules = lv.rules_for(id)
	_rule_states.resize(_rules.size())
	_rule_states.fill(0)

	_vis = Node2D.new()
	add_child(_vis)
	_shadow = _painter(_paint_shadow)
	_body = _painter(_paint_body)
	_material = ShaderMaterial.new()
	_material.shader = preload("res://art/shaders/fabric.gdshader")
	_material.set_shader_parameter("base", _base)
	_material.set_shader_parameter("pattern", maxi(0, Palette.FABRICS.find(def.fabric)))
	_body.material = _material
	_detail = _painter(_paint_detail)
	_face = _painter(_paint_face)
	for i in _rules.size():
		_bubbles.append(_painter(_paint_bubble.bind(i)))
	_blink_in = randf_range(1.0, 5.0)
	_antic_in = randf_range(2.0, antic_gap.y)
	_rebuild()


func _painter(paint: Callable) -> Painter:
	var p := Painter.new()
	p.paint = paint
	_vis.add_child(p)
	return p


func _rebuild() -> void:
	cells = Shape.transform_cells(def.cells, rot, flip)
	size = Shape.size_of(cells)
	var half := Vector2(size) * cell * 0.5
	var o := SoftieDrawer.outline(cells, cell, cell * INSET, cell * RADIUS)
	for i in o.size():
		o[i] -= half
	_outline = o
	_stitches = SoftieDrawer.dashes(SoftieDrawer.inset_path(o, cell * 0.07), cell * 0.075, cell * 0.055)

	var head: Vector2i = cells[maxi(0, def.cells.find(def.head))]
	_face_home = _centre_of(head)
	# Preference bubbles sit on the cells furthest from the head.
	var others: Array[Vector2i] = cells.duplicate()
	others.erase(head)
	others.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - head).length_squared() > (b - head).length_squared())
	for i in _bubbles.size():
		_bubbles[i].position = _centre_of(others[mini(i, others.size() - 1)])

	_material.set_shader_parameter("unit", cell)
	for p in [_shadow, _body, _detail, _face]:
		p.queue_redraw()
	for b in _bubbles:
		b.queue_redraw()


func _centre_of(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5) - Vector2(size) * 0.5) * cell


# --- drawing ---------------------------------------------------------------

func _paint_shadow(ci: Brush) -> void:
	ci.draw_set_transform(Vector2(0, cell * (0.045 + 0.13 * lift)))
	ci.draw_colored_polygon(_outline, Color(0.05, 0.06, 0.16, 0.24 - 0.06 * lift))
	ci.draw_set_transform(Vector2.ZERO)


func _paint_body(ci: Brush) -> void:
	ci.draw_colored_polygon(_outline, Color.WHITE)


func _paint_detail(ci: Brush) -> void:
	ci.draw_polyline(SoftieDrawer.closed(_outline), _base.darkened(0.2), maxf(2.0, cell * 0.022), true)
	var thread := _base.darkened(0.32)
	for d in _stitches:
		ci.draw_polyline(d, thread, maxf(1.5, cell * 0.016), true)


func _paint_face(ci: Brush) -> void:
	Faces.draw(ci, def.animal, cell * 0.3, _base, mood, _blink, _pose)


func _paint_bubble(ci: Brush, i: int) -> void:
	var rule := _rules[i]
	var r := cell * 0.25
	var ring := Color(Palette.INK, 0.3)
	if _rule_states[i] == 1:
		ring = Palette.OK
	elif _rule_states[i] == 2:
		ring = Palette.NOT_OK
	ci.draw_circle(Vector2(0, r * 0.08), r * 1.04, Color(0.05, 0.06, 0.16, 0.2))
	ci.draw_circle(Vector2.ZERO, r, Palette.CREAM)
	if rule.kind == "feature":
		Icons.draw(ci, rule.target, Vector2.ZERO, r * 1.5, Palette.INK)
	elif level != null:
		var other := level.piece(rule.target)
		ci.draw_set_transform(Vector2(0, r * 0.14))
		Faces.draw(ci, other.animal, r * 0.5, Palette.fabric(other.colour), Faces.Mood.AWAKE)
		ci.draw_set_transform(Vector2.ZERO)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, ring, cell * 0.035, true)
	if rule.type == "likes":
		var at := Vector2(r * 0.78, -r * 0.74)
		ci.draw_circle(at, r * 0.42, Palette.CREAM)
		Icons.draw(ci, "heart", at, r * 0.78, Palette.NOT_OK)
	else:
		var k := r * 0.7
		ci.draw_line(Vector2(-k, -k), Vector2(k, k), Palette.CREAM, cell * 0.075, true)
		ci.draw_line(Vector2(-k, -k), Vector2(k, k), Palette.NOT_OK, cell * 0.045, true)


func _process(delta: float) -> void:
	# Faces and bubbles stay upright while the blanket turns under them, and
	# grow when the softie is shrunk into the tray so they stay readable.
	var grow := clampf(0.6 / maxf(scale.x, 0.01), 1.0, 1.55)
	for b in _bubbles:
		b.rotation = -_vis.rotation
		b.scale = Vector2(grow, grow)
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink = not _blink
		_blink_in = 0.13 if _blink else randf_range(2.0, 6.0)
		if mood == Faces.Mood.AWAKE or mood == Faces.Mood.FUSSY:
			_face.queue_redraw()
	_animate(delta)
	var breathe := 1.0
	if mood == Faces.Mood.ASLEEP:
		_breath += delta
		breathe = 1.0 + 0.035 * sin(_breath * 2.2)
	_face.rotation = -_vis.rotation + _face_tilt
	_face.scale = Vector2(grow, grow) * breathe
	_face.position = _face_home + _face_shift * cell


# --- personality -----------------------------------------------------------
# Each animal has its own little habits, played now and then while it is
# awake: the bunny hops and waggles its ears, the bear yawns and nods off,
# the fox glances about and winks, the elephant swings its trunk and flaps
# its ears, the lamb goes shy or bounces, the cat twitches and gazes around.

const ANTICS := {
	"bunny": ["hop", "ears"],
	"bear": ["yawn", "nod"],
	"fox": ["glance", "wink"],
	"elephant": ["sway", "flap"],
	"lamb": ["shy", "bounce"],
	"cat": ["twitch", "look"],
}
const ANTIC_SECONDS := {
	"hop": 0.9, "ears": 0.9, "yawn": 1.9, "nod": 2.6, "glance": 1.6, "wink": 1.0,
	"sway": 1.8, "flap": 1.1, "shy": 1.8, "bounce": 1.0, "twitch": 1.2, "look": 1.7,
}


## Plays one of this animal's habits now. `which` picks one by name.
func play_antic(which := "") -> void:
	var mine: Array = ANTICS.get(def.get("animal", ""), [])
	if mine.is_empty() or mood == Faces.Mood.ASLEEP or mood == Faces.Mood.FUSSY:
		return
	if which == "":
		which = mine[favourite] if favourite >= 0 and randf() < 0.75 else mine[randi() % mine.size()]
	_antic = which
	_antic_t = 0.0


func _end_antic() -> void:
	_antic = ""
	_pose = {}
	_face_shift = Vector2.ZERO
	_face_tilt = 0.0
	_antic_in = randf_range(antic_gap.x, antic_gap.y)
	_face.queue_redraw()


func _animate(delta: float) -> void:
	if _antic == "":
		_antic_in -= delta
		if _antic_in <= 0.0:
			_antic_in = randf_range(antic_gap.x, antic_gap.y)
			play_antic()
		return
	_antic_t += delta
	var u := _antic_t / float(ANTIC_SECONDS[_antic])
	if u >= 1.0 or mood == Faces.Mood.ASLEEP:
		_end_antic()
		return
	var wave := sin(u * PI)
	match _antic:
		"hop":
			_face_shift = Vector2(0, -absf(sin(u * TAU)) * 0.13)
			_pose = {"ear": sin(u * TAU * 2.0) * 0.6}
		"ears":
			_pose = {"ear": sin(u * TAU * 3.0) * (1.0 - u)}
		"yawn":
			_pose = {"yawn": wave}
			_face_tilt = -0.12 * wave
		"nod":
			var droop := smoothstep(0.0, 0.6, u) * (1.0 - smoothstep(0.78, 0.86, u))
			_pose = {"blink": droop > 0.4}
			_face_shift = Vector2(0, 0.06 * droop)
			_face_tilt = 0.2 * droop
		"glance":
			_pose = {"look": Vector2(sin(u * TAU), 0)}
		"wink":
			_pose = {"wink": wave > 0.5}
			_face_tilt = 0.1 * wave
		"sway":
			_pose = {"trunk": sin(u * TAU * 1.5), "ear": absf(sin(u * TAU)) * 0.5}
		"flap":
			_pose = {"ear": absf(sin(u * TAU * 2.0))}
		"shy":
			_pose = {"blush": wave, "look": Vector2(0, wave)}
			_face_tilt = 0.22 * wave
		"bounce":
			_face_shift = Vector2(0, -absf(sin(u * TAU * 1.5)) * 0.08)
		"twitch":
			_pose = {"ear": sin(u * TAU * 4.0) * (1.0 - u), "blink": u > 0.4 and u < 0.7}
			_face_tilt = -0.1 * wave
		"look":
			_pose = {"look": Vector2(cos(u * TAU), sin(u * TAU))}
	_face.queue_redraw()


# --- state -----------------------------------------------------------------

func set_mood(value: int) -> void:
	if mood == value:
		return
	mood = value
	if _face != null:
		_face.queue_redraw()


func set_rule_states(states: Array[int]) -> void:
	if states == _rule_states:
		return
	_rule_states = states
	for b in _bubbles:
		b.queue_redraw()


func set_lift(value: float) -> void:
	lift = value
	if _shadow != null:
		_shadow.queue_redraw()


## Drops the soft shadow, which saves a draw call per softie where dozens
## are on screen at once.
func hide_shadow() -> void:
	_shadow.visible = false


func set_cell(cell_size: float) -> void:
	if is_equal_approx(cell, cell_size):
		return
	cell = cell_size
	_rebuild()


func set_orientation(new_rot: int, new_flip: bool) -> void:
	if rot == new_rot and flip == new_flip:
		return
	rot = new_rot
	flip = new_flip
	_rebuild()


## Top-left of the bounding box, valid when the softie is at full scale.
func top_left() -> Vector2:
	return position - Vector2(size) * cell * 0.5


## Hit test. `generous` accepts the whole bounding box plus a margin, which
## suits the small softies waiting in the tray.
func contains_point(point: Vector2, generous: bool) -> bool:
	var local := to_local(point) + Vector2(size) * cell * 0.5
	if cells.has(Vector2i(floori(local.x / cell), floori(local.y / cell))):
		return true
	if generous:
		var pad := cell * 0.3
		return Rect2(Vector2(-pad, -pad), Vector2(size) * cell + Vector2(pad, pad) * 2.0).has_point(local)
	return false


# --- motion ----------------------------------------------------------------

func jump_to(pos: Vector2, scl: float) -> void:
	if _move != null:
		_move.kill()
	position = pos
	scale = Vector2(scl, scl)


func glide(pos: Vector2, scl: float, seconds := 0.26) -> void:
	if _move != null:
		_move.kill()
	_move = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_move.tween_property(self, "position", pos, seconds)
	_move.tween_property(self, "scale", Vector2(scl, scl), seconds)


func scale_to(scl: float, seconds := 0.16) -> void:
	if _move != null:
		_move.kill()
	_move = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_move.tween_property(self, "scale", Vector2(scl, scl), seconds)


func raise(up: bool) -> void:
	if _lift_tween != null:
		_lift_tween.kill()
	_lift_tween = create_tween()
	_lift_tween.tween_property(self, "lift", 1.0 if up else 0.0, 0.15)


func _begin_fx() -> void:
	if _fx != null:
		_fx.kill()
	_vis.rotation = 0.0
	_vis.scale = Vector2.ONE
	_fx = create_tween()


func squish(strength := 1.0) -> void:
	_begin_fx()
	_vis.scale = Vector2(1.0 + 0.13 * strength, 1.0 - 0.11 * strength)
	_fx.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_fx.tween_property(_vis, "scale", Vector2.ONE, 0.5)


## Quarter turn clockwise. The new shape is drawn at once, turned back a
## quarter, then eased round, so it reads as the old shape rotating.
func turn_cw() -> void:
	rot = (rot + 1) % 4
	_rebuild()
	_begin_fx()
	_vis.rotation = -PI / 2.0
	_fx.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx.tween_property(_vis, "rotation", 0.0, 0.24)


func fall_asleep() -> void:
	mood = Faces.Mood.ASLEEP
	squish(0.5)
