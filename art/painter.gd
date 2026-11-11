class_name Painter
extends Node2D
## A Node2D whose drawing is supplied by its owner: `paint` is called with a
## Brush whenever this node redraws, and everything painted goes to the GPU
## as one draw call.

var paint: Callable


func _draw() -> void:
	if not paint.is_valid():
		return
	var brush := Brush.new()
	paint.call(brush)
	brush.flush(self)
