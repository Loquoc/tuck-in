extends Screen
## Title screen. No words beyond the name: buttons are pictures.

var _title: Label
var _play: RoundButton
var _levels: RoundButton
var _shelf: RoundButton
var _settings: RoundButton
var _kid: RoundButton
var _softies: Array[PieceView] = []


func _build() -> void:
	show_moon = true
	_title = UIKit.label("Tuck-In", 190)
	add_child(_title)

	# A few softies dozing under the title.
	for n in [1, 8, 15, 23, 30]:
		var pv := PieceView.new()
		add_child(pv)
		pv.setup(Rewards.def_for(n), 125.0)
		pv.mood = Faces.Mood.ASLEEP if n % 2 == 0 else Faces.Mood.CONTENT
		_softies.append(pv)

	_play = RoundButton.new("play", 230.0)
	_play.fill = Palette.GLOW
	_play.pressed.connect(func() -> void: Router.go("game", {"level": SaveData.next_unsolved()}))
	add_child(_play)
	_levels = _small("levels", func() -> void: Router.go("levels"))
	_shelf = _small("heart", func() -> void: Router.go("shelf"))
	_settings = _small("settings", func() -> void: Router.go("settings"))

	_kid = RoundButton.new("kid", 130.0)
	_kid.toggle_mode = true
	_kid.button_pressed = SaveData.kid_mode
	_kid.toggled.connect(func(on: bool) -> void: SaveData.set_flag("kid_mode", on))
	add_child(_kid)


func _small(icon: String, action: Callable) -> RoundButton:
	var b := RoundButton.new(icon, 130.0)
	b.pressed.connect(action)
	add_child(b)
	return b


func _arrange(screen: Vector2) -> void:
	var cx := screen.x * 0.5
	_title.position = Vector2(0.0, screen.y * 0.1)
	_title.size = Vector2(screen.x, 240.0)

	var row_y := screen.y * 0.52
	var spread := minf(340.0, screen.x / 5.8)
	for i in _softies.size():
		_softies[i].position = Vector2(cx + (i - 2) * spread, row_y + (20.0 if i % 2 == 0 else -20.0))
		_softies[i].rotation = (i - 2) * 0.06

	var base_y := screen.y - 300.0
	_play.position = Vector2(cx - 115.0, base_y)
	_levels.position = Vector2(cx - 115.0 - 190.0, base_y + 60.0)
	_shelf.position = Vector2(cx + 115.0 + 60.0, base_y + 60.0)
	_settings.position = Vector2(screen.x - 170.0, screen.y - 170.0)
	_kid.position = Vector2(40.0, screen.y - 170.0)
