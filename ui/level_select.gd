extends Screen
## Level picker. Chapters are marked by a picture, not a name:
##   star    first steps: tutorials, then small cribs with every feature
##   moon    roomy full-size cribs
##   pillow  snug fits, with toy blocks in the way
##   heart   full-size cribs where softies have wishes
## Each chapter unlocks on its own.

const PER_ROW := 12

var _buttons := {}    # level number -> RoundButton
var _icons: Array[Dictionary] = []    # {icon, at}


func _build() -> void:
	sky_seed = 21
	add_back("menu")
	for n in range(1, LevelLoader.LEVEL_COUNT + 1):
		var b := RoundButton.new("", 104.0)
		if SaveData.is_done(n):
			b.caption = str(n)
			b.fill = Palette.fabric("sage")
			b.badge = "moon"
		elif SaveData.is_unlocked(n):
			b.caption = str(n)
		else:
			b.icon = "lock"
			b.set_enabled(false)
		b.pressed.connect(func() -> void: Router.go("game", {"level": n}))
		add_child(b)
		_buttons[n] = b


func _arrange(screen: Vector2) -> void:
	var rows := 0
	for chapter in LevelLoader.CHAPTERS:
		rows += ceili((chapter.to - chapter.from + 1) / float(PER_ROW))
	var left := 310.0
	var step := minf(132.0, (screen.x - left - 30.0) / PER_ROW)
	var gap := 26.0    # extra space between chapters
	var pitch := minf(150.0, (screen.y - 70.0 - gap * (LevelLoader.CHAPTERS.size() - 1)) / rows)
	var y := (screen.y - (pitch * rows + gap * (LevelLoader.CHAPTERS.size() - 1))) * 0.5
	_icons.clear()
	for chapter in LevelLoader.CHAPTERS:
		_icons.append({"icon": chapter.icon, "at": Vector2(left - 78.0, y + 52.0)})
		var count: int = chapter.to - chapter.from + 1
		for i in count:
			_buttons[chapter.from + i].position = Vector2(left + (i % PER_ROW) * step, y + (i / PER_ROW) * pitch)
		y += ceili(count / float(PER_ROW)) * pitch + gap


func _paint(b: Brush, _screen: Vector2) -> void:
	for entry in _icons:
		Icons.draw(b, entry.icon, entry.at, 96.0, Palette.GLOW)
