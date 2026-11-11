extends SceneTree
## Draws the app icon from the game's own art and saves it as PNGs.
## Needs a real renderer, so run it without --headless:
##   godot --path . -s tools/make_icons.gd
## Writes icon/icon_192.png (launcher and window icon) and the two Android
## adaptive-icon layers, icon/icon_foreground_432.png and
## icon/icon_background_432.png.

const CANVAS := 432


func _initialize() -> void:
	_make.call_deferred()


func _make() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://icon"))
	await _render("res://icon/icon_192.png", 192, true, true, 150.0)
	await _render("res://icon/icon_foreground_432.png", CANVAS, false, true, 108.0)
	await _render("res://icon/icon_background_432.png", CANVAS, true, false, 108.0)
	quit()


func _render(path: String, pixels: int, with_sky: bool, with_softie: bool, cell: float) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(CANVAS, CANVAS)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	if with_sky:
		var sky := Painter.new()
		# The stand-alone icon has rounded corners; the adaptive background
		# is a full square that Android masks itself.
		var rounded := with_softie
		sky.paint = func(b: Brush) -> void:
			var full := Rect2(0, 0, CANVAS, CANVAS)
			b.draw_box(full, Palette.NIGHT, 96.0 if rounded else 0.0)
			var rng := RandomNumberGenerator.new()
			rng.seed = 5
			for i in 26:
				var p := Vector2(rng.randf_range(40, CANVAS - 40), rng.randf_range(40, CANVAS - 40))
				b.draw_circle(p, rng.randf_range(2.0, 5.0), Color(1.0, 0.97, 0.85, rng.randf_range(0.15, 0.4)))
			var moon := Vector2(318, 122) if rounded else Vector2(304, 140)
			for i in 4:
				b.draw_circle(moon, 100.0 - i * 16.0, Color(Palette.GLOW, 0.05))
			Icons.draw(b, "moon", moon, 150.0 if rounded else 110.0, Palette.GLOW)
		vp.add_child(sky)

	if with_softie:
		var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
		var softie := PieceView.new()
		vp.add_child(softie)
		softie.setup({
			"id": "bunny", "animal": "bunny", "cells": cells, "head": cells[0],
			"colour": "rose", "fabric": "gingham",
		}, cell / 0.4)
		# Drawn large then shrunk: a shrunken softie gets a bigger head (as
		# in the tray), which reads far better at icon size.
		softie.scale = Vector2(0.4, 0.4)
		softie.position = Vector2(CANVAS * 0.5 - (26.0 if with_sky else 0.0), CANVAS * 0.5 + 22.0)
		softie.rotation = -0.14
		softie.mood = Faces.Mood.ASLEEP

	for i in 4:
		await process_frame
	var image := vp.get_texture().get_image()
	if pixels != CANVAS:
		image.resize(pixels, pixels, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path(path))
	print("wrote ", path)
	vp.queue_free()
