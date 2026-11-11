extends Screen
## The collection: one softie for every level finished, in either mode.
## The softies here are alive: each keeps up its own habits, a few are
## dozing, and a tap gets a reaction and a note.

const COLUMNS := 8
const TAP_NOTES := {"bunny": 12, "bear": 0, "fox": 7, "elephant": -5, "lamb": 9, "cat": 4}

var _count: Label
var _softies := {}    # level number -> PieceView
var _slots := {}      # level number -> Vector2, for the empty-slot drawing
var _plank_y: Array[float] = []
var _slot_w := 200.0


func _build() -> void:
	sky_seed = 33
	add_back("menu")
	_count = UIKit.label("%d / %d" % [SaveData.earned_count(), LevelLoader.LEVEL_COUNT], 60)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_count)
	for n in range(1, LevelLoader.LEVEL_COUNT + 1):
		if not SaveData.is_earned(n):
			continue
		var pv := PieceView.new()
		add_child(pv)
		# Livelier than in a puzzle, and each leans towards one habit, so two
		# softies of the same animal still behave differently.
		pv.antic_gap = Vector2(1.5 + (n * 7) % 5, 6.0 + (n * 3) % 6)
		pv.favourite = ((n - 1) / 6) % 2
		pv.setup(Rewards.def_for(n), 100.0)
		pv.hide_shadow()
		pv.mood = Faces.Mood.ASLEEP if _is_dozer(n) else Faces.Mood.AWAKE
		pv.rotation = sin(n * 2.3) * 0.07
		_softies[n] = pv


## Every seventh softie is asleep until tapped.
func _is_dozer(n: int) -> bool:
	return n % 7 == 4


func _arrange(screen: Vector2) -> void:
	_count.position = Vector2(screen.x * 0.5 + 10.0, 40.0)
	_count.size = Vector2(400.0, 80.0)
	var rows := ceili(LevelLoader.LEVEL_COUNT / float(COLUMNS))
	var area := Rect2(180.0, 130.0, screen.x - 260.0, screen.y - 150.0)
	_slot_w = area.size.x / COLUMNS
	var row_h := area.size.y / rows
	var cell := minf(_slot_w * 0.4, row_h * 0.4)
	_plank_y.clear()
	for row in rows:
		_plank_y.append(area.position.y + (row + 1) * row_h - 20.0)
	for n in range(1, LevelLoader.LEVEL_COUNT + 1):
		var col := (n - 1) % COLUMNS
		var row := (n - 1) / COLUMNS
		var at := area.position + Vector2((col + 0.5) * _slot_w, (row + 0.5) * row_h - 14.0)
		_slots[n] = at
		if _softies.has(n):
			var pv: PieceView = _softies[n]
			pv.set_cell(cell)
			pv.position = at


func _paint(b: Brush, screen: Vector2) -> void:
	Icons.draw(b, "heart", Vector2(screen.x * 0.5 - 46.0, 80.0), 90.0, Palette.BLUSH)
	for y in _plank_y:
		b.draw_box(Rect2(150.0, y, screen.x - 200.0, 16.0), Palette.WOOD, 8.0, Palette.WOOD_DARK, 3.0,
			Color(0.03, 0.04, 0.12, 0.3), 8.0, Vector2(0, 5))
	for n in _slots:
		if not _softies.has(n):
			b.draw_set_transform(_slots[n] + Vector2(0, 8.0))
			Faces.silhouette(b, _slot_w * 0.11, Color(Palette.NIGHT_SOFT, 0.7))
			b.draw_set_transform(Vector2.ZERO)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var nearest := 0
	var best := _slot_w * 0.55
	for n in _softies:
		var d: float = _softies[n].position.distance_to(event.position)
		if d < best:
			best = d
			nearest = n
	if nearest == 0:
		return
	var pv: PieceView = _softies[nearest]
	if pv.mood == Faces.Mood.ASLEEP:
		# Wake it for a little while.
		pv.mood = Faces.Mood.AWAKE
		get_tree().create_timer(7.0).timeout.connect(func() -> void:
			if is_instance_valid(pv):
				pv.mood = Faces.Mood.ASLEEP)
	pv.squish(0.8)
	pv.play_antic()
	Audio.note(TAP_NOTES.get(pv.def.animal, 0))
