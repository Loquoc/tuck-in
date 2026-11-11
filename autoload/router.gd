extends Node
## Scene changes with a short fade. `params` carries arguments to the next scene.
##
## Developer arguments (after `--` on the command line). Any of them makes
## the run read-only: nothing is written to the save file.
##   --scene=game|menu|levels|shelf|settings   start in this scene
##   --level=N        level for the game scene
##   --kid            force kid mode for this run
##   --earn=N         treat levels 1..N as finished for this run
##   --solve          game scene: place every softie from the stored solution
##   --place=N        game scene: place only the first N softies
##   --shot=PATH      save a screenshot to PATH, then quit
##   --delay=SECONDS  wait before the screenshot (default 1.2)
##   --selftest       play several levels through touch events, then quit

const SCENES := {
	"menu": "res://ui/main_menu.tscn",
	"levels": "res://ui/level_select.tscn",
	"game": "res://game/game.tscn",
	"shelf": "res://ui/shelf.tscn",
	"settings": "res://ui/settings.tscn",
}

var params := {}
var dev := {}
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.13, 0.16, 0.27, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_read_dev_args()


func go(scene: String, with_params := {}) -> void:
	if _busy:
		return
	_busy = true
	params = with_params
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, 0.18)
	await out.finished
	get_tree().change_scene_to_file(SCENES[scene])
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, 0.24)
	await back.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## Android back button: step back one screen; leave the app from the menu.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	var scene := get_tree().current_scene
	var path := scene.scene_file_path if scene != null else ""
	if path == SCENES.menu:
		get_tree().quit()
	elif path == SCENES.game:
		go("levels")
	else:
		go("menu")


func _read_dev_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		dev[parts[0]] = parts[1] if parts.size() > 1 else "1"
	if dev.is_empty():
		return
	SaveData.persist = false
	if dev.has("kid"):
		SaveData.kid_mode = true
	for n in range(1, int(dev.get("earn", "0")) + 1):
		SaveData.mark_done(n)
	if dev.has("selftest"):
		add_child(load("res://tools/self_test.gd").new())
		return
	if dev.has("level"):
		params = {"level": int(dev.level)}
	if dev.has("scene") and SCENES.has(dev.scene):
		get_tree().change_scene_to_file.call_deferred(SCENES[dev.scene])
	if dev.has("shot"):
		await get_tree().create_timer(float(dev.get("delay", "1.2"))).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dev.shot)
		get_tree().quit()
