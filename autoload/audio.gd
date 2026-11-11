extends Node
## All sound is synthesised here at start-up; the game ships no audio files.
## Sound effects are short generated clips. Music is a note sample played at
## different pitches by a small sequencer that works through a set of
## original lullabies, never the same one twice in a row.

const RATE := 22050

# Original pentatonic lullabies. `melody` is semitones above the tune's key
# note, one entry per beat, null for a rest. `bass` is one low note per bar.
#   beat   seconds per beat          bar    beats per bar
#   key    semitones above C5        voice  "note" (music box) or "soft" (chime)
const TUNES := [
	{
		"beat": 0.52, "bar": 3, "key": 0, "voice": "note",
		"melody": [
			4, 7, 9, 7, null, 4, 2, 4, 7, 4, null, null,
			0, 4, 7, 9, null, 7, 4, 2, 0, 2, null, null,
			4, 7, 9, 12, null, 9, 7, 4, 2, 4, null, null,
			0, 2, 4, 7, null, 4, 2, 0, 2, 0, null, null,
		],
		"bass": [-12, -12, -5, -12, -12, -3, -12, -5, -12, -3, -5, -12, -12, -5, -5, -12],
	},
	{
		"beat": 0.46, "bar": 4, "key": -3, "voice": "soft",
		"melody": [
			0, null, 4, 7, 9, null, 7, null, 4, null, 7, 4, 2, null, null, null,
			0, null, 4, 7, 12, null, 9, null, 7, 4, 2, 4, 0, null, null, null,
		],
		"bass": [-12, -3, -12, -5, -12, -3, -5, -12],
	},
	{
		"beat": 0.6, "bar": 3, "key": 5, "voice": "note",
		"melody": [
			7, null, null, 4, null, 2, 0, null, null, 2, null, 4,
			7, null, 9, 7, null, 4, 2, null, null, null, null, null,
			9, null, null, 7, null, 4, 2, null, 4, 0, null, null,
			4, null, 2, 0, null, -3, 0, null, null, null, null, null,
		],
		"bass": [-12, -12, -5, -12, -12, -5, -12, -5, -3, -3, -12, -12, -5, -5, -12, -12],
	},
	{
		"beat": 0.4, "bar": 4, "key": 2, "voice": "soft",
		"melody": [
			0, 4, 7, 4, 9, 7, 4, null, 2, 4, 7, 9, 7, null, null, null,
			12, 9, 7, 4, 7, 4, 2, null, 0, 2, 4, 2, 0, null, null, null,
		],
		"bass": [-12, -3, -5, -5, -12, -3, -5, -12],
	},
	{
		"beat": 0.56, "bar": 3, "key": -5, "voice": "note",
		"melody": [
			0, null, 2, 4, null, 7, 4, null, 2, 0, null, null,
			2, null, 4, 7, null, 9, 7, null, null, null, null, null,
			12, null, 9, 7, null, 4, 7, null, 4, 2, null, null,
			0, null, 2, 4, null, 2, 0, null, null, null, null, null,
		],
		"bass": [-12, -12, -5, -12, -12, -5, -12, -12, -3, -3, -12, -5, -12, -5, -12, -12],
	},
	{
		"beat": 0.5, "bar": 4, "key": 7, "voice": "note",
		"melody": [
			4, null, 2, 0, -3, null, 0, null, 2, null, 4, 7, 4, null, null, null,
			7, null, 9, 7, 4, null, 2, null, 4, 2, 0, -3, 0, null, null, null,
		],
		"bass": [-12, -15, -12, -5, -12, -8, -15, -12],
	},
]
## Times each lullaby repeats before the next one starts.
const REPEATS := 2
## Beats of silence between lullabies.
const BREATH := 5

var _streams := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _note_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _next_note := 0
var _clock := 0.0
var _step := 0
var _tune := 0
var _plays := 0
var _rest := 0
var _lp := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in ["Music", "Sfx"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -13.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), -4.0)
	_build_streams()
	for i in 4:
		_sfx_players.append(_player())
	for i in 8:
		_note_players.append(_player())
	_tune = randi() % TUNES.size()
	apply_settings()
	SaveData.changed.connect(apply_settings)


func apply_settings() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not SaveData.music)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sfx"), not SaveData.sfx)


func play(sound: String, pitch := 1.0) -> void:
	if not _streams.has(sound):
		return
	var p := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = _streams[sound]
	p.bus = "Sfx"
	p.pitch_scale = pitch * randf_range(0.96, 1.04)
	p.volume_db = 0.0
	p.play()


## One note, `semitones` above C5.
func note(semitones: float, bus := "Sfx", volume_db := 0.0, voice := "note") -> void:
	var p := _note_players[_next_note]
	_next_note = (_next_note + 1) % _note_players.size()
	p.stream = _streams[voice]
	p.bus = bus
	p.pitch_scale = pow(2.0, semitones / 12.0)
	p.volume_db = volume_db
	p.play()


func win() -> void:
	var chord := [0, 4, 7, 12, 16]
	for i in chord.size():
		get_tree().create_timer(i * 0.12).timeout.connect(note.bind(chord[i], "Sfx", -3.0))


func _process(delta: float) -> void:
	var tune: Dictionary = TUNES[_tune]
	_clock += delta
	if _clock < tune.beat:
		return
	_clock -= tune.beat
	if _rest > 0:
		_rest -= 1
		return
	var semis: Variant = tune.melody[_step]
	if semis != null:
		note(semis + tune.key, "Music", 0.0, tune.voice)
	if _step % tune.bar == 0:
		note(tune.bass[(_step / tune.bar) % tune.bass.size()] + tune.key, "Music", -5.0, tune.voice)
	_step += 1
	if _step < tune.melody.size():
		return
	_step = 0
	_plays += 1
	if _plays >= REPEATS:
		_plays = 0
		_rest = BREATH
		_tune = (_tune + 1 + randi() % (TUNES.size() - 1)) % TUNES.size()


func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p


func _build_streams() -> void:
	_streams.pick = _render(0.12, func(t: float, d: float) -> float:
		return sin(_sweep(t, d, 300.0, 540.0)) * sin(PI * t / d) * 0.45)
	_streams.drop = _render(0.2, func(t: float, _d: float) -> float:
		_lp = lerpf(_lp, randf_range(-1.0, 1.0), 0.18)
		return sin(TAU * (90.0 * t + 7.0 * (1.0 - exp(-t * 22.0)))) * exp(-t * 17.0) * 0.6 + _lp * exp(-t * 38.0) * 0.5)
	_streams.turn = _render(0.09, func(t: float, _d: float) -> float:
		return sin(TAU * 700.0 * t) * exp(-t * 42.0) * minf(t / 0.003, 1.0) * 0.32)
	_streams.nope = _render(0.24, func(t: float, d: float) -> float:
		return sin(_sweep(t, d, 200.0, 140.0)) * sin(PI * t / d) * 0.4)
	var f0 := 523.25
	# Music box: bright, quick attack.
	_streams.note = _render(1.7, func(t: float, d: float) -> float:
		var body := sin(TAU * f0 * t)
		body += 0.4 * sin(TAU * f0 * 2.0 * t) * exp(-t * 3.0)
		body += 0.15 * sin(TAU * f0 * 5.4 * t) * exp(-t * 12.0)
		return body * exp(-t * 3.2) * minf(t / 0.004, 1.0) * minf((d - t) / 0.2, 1.0) * 0.42)
	# Chime: rounder, slower to speak, with a gentle shimmer.
	_streams.soft = _render(2.0, func(t: float, d: float) -> float:
		var body := sin(TAU * f0 * t) * (1.0 + 0.12 * sin(TAU * 4.5 * t))
		body += 0.22 * sin(TAU * f0 * 3.0 * t) * exp(-t * 5.0)
		return body * exp(-t * 2.2) * minf(t / 0.03, 1.0) * minf((d - t) / 0.3, 1.0) * 0.4)


## Phase of a linear frequency sweep from f_from to f_to over duration d.
func _sweep(t: float, d: float, f_from: float, f_to: float) -> float:
	return TAU * (f_from * t + (f_to - f_from) * t * t / (2.0 * d))


func _render(seconds: float, wave: Callable) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var v: float = wave.call(float(i) / RATE, seconds)
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
