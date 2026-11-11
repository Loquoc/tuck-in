extends Screen
## Settings: three big toggles (music, sound, kid mode), each with a short
## label, and an erase button that must be pressed twice.

var _toggles: Array[RoundButton] = []
var _labels: Array[Label] = []
var _notes: Array[Label] = []
var _erase: RoundButton
var _erase_label: Label
var _armed := false


func _build() -> void:
	sky_seed = 45
	add_back("menu")
	_toggle("music", "music", "Music", "")
	_toggle("sound", "sfx", "Sounds", "")
	_toggle("kid", "kid_mode", "Kid mode", "Outlines show where\neach softie goes")
	_erase = RoundButton.new("erase", 120.0)
	_erase.fill = Palette.fabric("rose")
	_erase.pressed.connect(_on_erase)
	add_child(_erase)
	_erase_label = UIKit.label("Erase progress", 38, Color(Palette.CREAM, 0.7))
	_erase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_erase_label)


func _toggle(icon: String, flag: String, title: String, note: String) -> void:
	var b := RoundButton.new(icon, 220.0)
	b.toggle_mode = true
	b.button_pressed = SaveData.get(flag)
	b.toggled.connect(func(on: bool) -> void:
		SaveData.set_flag(flag, on)
		if on:
			Audio.note(4.0))
	add_child(b)
	_toggles.append(b)
	var l := UIKit.label(title, 52)
	add_child(l)
	_labels.append(l)
	var small := UIKit.label(note, 34, Color(Palette.CREAM, 0.65))
	add_child(small)
	_notes.append(small)


## First press arms the button (it turns red with a tick); a second press
## within three seconds erases all progress.
func _on_erase() -> void:
	if not _armed:
		_armed = true
		_erase.icon = "check"
		_erase.fill = Palette.NOT_OK
		_erase_label.text = "Tap again to erase everything"
		get_tree().create_timer(3.0).timeout.connect(_reset_erase.bind("Erase progress"))
		return
	SaveData.reset_all()
	Audio.play("drop")
	_reset_erase("Progress erased")


func _reset_erase(text: String) -> void:
	if not _armed:
		return
	_armed = false
	_erase.icon = "erase"
	_erase.fill = Palette.fabric("rose")
	_erase_label.text = text


func _arrange(screen: Vector2) -> void:
	var gap := minf(420.0, screen.x / 4.2)
	for i in _toggles.size():
		var x := screen.x * 0.5 + (i - 1) * gap
		var y := screen.y * 0.36
		_toggles[i].position = Vector2(x - 110.0, y - 110.0)
		_labels[i].position = Vector2(x - gap * 0.5, y + 130.0)
		_labels[i].size = Vector2(gap, 70.0)
		_notes[i].position = Vector2(x - gap * 0.5, y + 205.0)
		_notes[i].size = Vector2(gap, 100.0)
	_erase.position = Vector2(screen.x - 170.0, screen.y - 170.0)
	_erase_label.position = Vector2(screen.x - 900.0, screen.y - 136.0)
	_erase_label.size = Vector2(700.0, 54.0)
