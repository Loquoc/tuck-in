extends Node
## Persistent progress and settings, stored in user://save.json.
## Progress is kept separately for normal mode and kid mode.

const PATH := "user://save.json"
## Version 2 put three tutorial levels in front of the original thirty.
## Version 3 dropped the flip tutorial and added the gentle run, so the
## original thirty now start at 27.
const VERSION := 3

signal changed

var kid_mode := false
var music := true
var sfx := true
## Turned off for developer screenshot runs so they never touch real progress.
var persist := true
var _done := {"normal": {}, "kid": {}}   # mode -> level number -> true
var _progress := {}                       # "mode:level" -> {id: {at:[x,y], rot, flip}}


func _ready() -> void:
	_load()


func mode() -> String:
	return "kid" if kid_mode else "normal"


func is_done(level: int, in_mode := "") -> bool:
	return _done[in_mode if in_mode != "" else mode()].has(level)


## Done in either mode: used for the softie shelf.
func is_earned(level: int) -> bool:
	return _done.normal.has(level) or _done.kid.has(level)


func done_count(in_mode := "") -> int:
	return _done[in_mode if in_mode != "" else mode()].size()


func earned_count() -> int:
	var n := 0
	for i in range(1, LevelLoader.LEVEL_COUNT + 1):
		if is_earned(i):
			n += 1
	return n


func mark_done(level: int) -> void:
	_done[mode()][level] = true
	_progress.erase(_key(level))
	save()


## A level is open while fewer than three earlier levels of its own chapter
## are unsolved. Chapters do not gate each other.
func is_unlocked(level: int) -> bool:
	var first := 1
	for chapter in LevelLoader.CHAPTERS:
		if level >= chapter.from and level <= chapter.to:
			first = chapter.from
	var unsolved := 0
	for i in range(first, level):
		if not is_done(i):
			unsolved += 1
	return unsolved < 3


func next_unsolved() -> int:
	for i in range(1, LevelLoader.LEVEL_COUNT + 1):
		if not is_done(i):
			return i
	return 1


func set_flag(flag: String, value: bool) -> void:
	set(flag, value)
	save()
	changed.emit()


func get_progress(level: int) -> Dictionary:
	var out := {}
	var raw: Dictionary = _progress.get(_key(level), {})
	for id in raw:
		var p: Dictionary = raw[id]
		out[id] = {"at": Vector2i(int(p.at[0]), int(p.at[1])), "rot": int(p.rot), "flip": bool(p.flip)}
	return out


func set_progress(level: int, snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		_progress.erase(_key(level))
	else:
		var raw := {}
		for id in snapshot:
			var p: Dictionary = snapshot[id]
			raw[id] = {"at": [p.at.x, p.at.y], "rot": p.rot, "flip": p.flip}
		_progress[_key(level)] = raw
	save()


func reset_all() -> void:
	_done = {"normal": {}, "kid": {}}
	_progress.clear()
	save()
	changed.emit()


func _key(level: int) -> String:
	return "%s:%d" % [mode(), level]


func save() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"version": VERSION,
		"kid_mode": kid_mode,
		"music": music,
		"sfx": sfx,
		"done": {"normal": _done.normal.keys(), "kid": _done.kid.keys()},
		"progress": _progress,
	}))


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		return
	kid_mode = bool(parsed.get("kid_mode", false))
	music = bool(parsed.get("music", true))
	sfx = bool(parsed.get("sfx", true))
	var version := int(parsed.get("version", 1))
	var done: Dictionary = parsed.get("done", {})
	for m in ["normal", "kid"]:
		for n in done.get(m, []):
			var moved := _migrate(int(n), version)
			if moved > 0:
				_done[m][moved] = true
	var progress: Variant = parsed.get("progress", {})
	if progress is Dictionary:
		for key in progress:
			var parts: PackedStringArray = str(key).split(":")
			if parts.size() == 2:
				var moved := _migrate(int(parts[1]), version)
				if moved > 0:
					_progress["%s:%d" % [parts[0], moved]] = progress[key]


## Where a level number from an older save lives now; 0 if it is gone.
func _migrate(n: int, version: int) -> int:
	if version >= VERSION:
		return n
	if version < 2:
		return n + 26
	if n <= 2:
		return n
	return 0 if n == 3 else n + 23
