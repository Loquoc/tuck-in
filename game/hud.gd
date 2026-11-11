class_name Hud
extends Control
## In-level buttons, down the left edge where a thumb can reach them.

signal back_pressed
signal undo_pressed
signal restart_pressed
signal hint_pressed

const BIG := 124.0
const GAP := 26.0

var _back: RoundButton
var _undo: RoundButton
var _restart: RoundButton
var _hint: RoundButton
var _label: Label
var _column: Array[RoundButton] = []


func setup(level_number: int) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back = _button("back", back_pressed, 104.0)
	_undo = _button("undo", undo_pressed)
	_restart = _button("restart", restart_pressed)
	_hint = _button("hint", hint_pressed)
	_hint.fill = Palette.GLOW
	_column = [_undo, _restart, _hint]
	_label = UIKit.label(str(level_number), 46, Color(Palette.CREAM, 0.75))
	add_child(_label)


func _button(icon: String, sig: Signal, diameter := BIG) -> RoundButton:
	var b := RoundButton.new(icon, diameter)
	b.pressed.connect(sig.emit)
	add_child(b)
	return b


func layout(viewport: Vector2) -> void:
	size = viewport
	_back.position = Vector2(40.0, 40.0)
	_label.position = Vector2(40.0, 150.0)
	_label.size = Vector2(104.0, 60.0)
	var y := viewport.y - 44.0 - _column.size() * BIG - (_column.size() - 1) * GAP
	for b in _column:
		b.position = Vector2(34.0, y)
		y += BIG + GAP


func set_can_undo(on: bool) -> void:
	_undo.set_enabled(on)


## Called when the level is won: only the back button stays live.
func lock() -> void:
	for b in _column:
		b.set_enabled(false)
