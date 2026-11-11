class_name Screen
extends Control
## Base for the menu screens: fills the viewport, paints the night sky, and
## calls `_arrange(size)` whenever the window changes shape.

var sky_seed := 7
var show_moon := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	resized.connect(_on_resized)
	_on_resized.call_deferred()


func _on_resized() -> void:
	_arrange(size)
	queue_redraw()


func _draw() -> void:
	var b := Brush.new()
	UIKit.paint_night(b, size, sky_seed, show_moon)
	_paint(b, size)
	b.flush(self)


## Create child nodes here.
func _build() -> void:
	pass


## Position child nodes here.
func _arrange(_screen: Vector2) -> void:
	pass


## Extra drawing over the sky, under the child nodes.
func _paint(_b: Brush, _screen: Vector2) -> void:
	pass


func add_back(target := "menu") -> RoundButton:
	var b := RoundButton.new("back", 104.0)
	b.position = Vector2(40.0, 40.0)
	b.pressed.connect(func() -> void: Router.go(target))
	add_child(b)
	return b
