extends Node

## Autoload singleton. The one place that plays SFX and music.
##
## Prompt 4.2: replaces the plain AudioStreamPlayer node Prompt 2.2
## dropped on the tree sprite (`HitSfx` in scenes/main.tscn). Call sites
## go through the play_*() methods below so a later swap of clips, buses,
## or mute state never has to touch chopping / upgrade / enchantment
## logic. Volumes and mute flags persist in user://audio.cfg independently
## of Prompt 5.3's full run save: 5.3 can fold this file in later, but
## audio settings have to survive a restart from this prompt onward.

signal settings_changed

const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const SAVE_PATH := "user://audio.cfg"
const POOL_SIZE := 8

const HIT_PATH := "res://assets/audio/axe-impact.mp3"
const SWING_PATH := "res://assets/audio/axe-slash.mp3"

const DEFAULT_SFX_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 0.35

var sfx_volume: float = DEFAULT_SFX_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_muted: bool = false
var music_muted: bool = false

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _music_player: AudioStreamPlayer

var _hit_stream: AudioStream
var _swing_stream: AudioStream
var _hit_fallback: AudioStream
var _swing_fallback: AudioStream
var _tree_crack: AudioStream
var _tree_fall: AudioStream
var _collect: AudioStream
var _upgrade: AudioStream
var _enchantment: AudioStream
var _ui_click: AudioStream
var _music: AudioStream


func _ready() -> void:
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_MUSIC)
	_build_players()
	_load_streams()
	_load_settings()
	_apply_buses()
	start_music()


## Axe whoosh. Uses axe-slash.mp3 when present, otherwise a short
## procedural sweep, with pitch variation so repeated swings do not
## machine-gun the exact same sample.
func play_swing() -> void:
	var stream := _swing_stream if _swing_stream else _swing_fallback
	_play_sfx(stream, randf_range(0.94, 1.12), -6.0)


## Axe-on-wood impact. Uses axe-impact.mp3 when present, otherwise a
## procedural thud. Pitch is jittered so a tap-spam of hits still reads
## as a set of distinct swings rather than one sample on loop.
func play_hit() -> void:
	var stream := _hit_stream if _hit_stream else _hit_fallback
	_play_sfx(stream, randf_range(0.88, 1.12), -2.0)


## Mid-hit wood crack, distinct from the axe impact itself. Procedural
## (there is no dedicated crack clip on disk yet).
func play_tree_crack() -> void:
	_play_sfx(_tree_crack, randf_range(0.92, 1.08), -4.0)


## Tree going down: a heavier, lower crack plus the existing impact
## sample dropped in pitch so the kill reads as a different event from
## a regular hit, without needing a third recorded clip.
func play_tree_fall() -> void:
	play_tree_crack()
	if _hit_stream:
		_play_sfx(_hit_stream, randf_range(0.52, 0.64), -1.0)
	else:
		_play_sfx(_tree_fall, randf_range(0.85, 1.05), -2.0)


## Currency pickup after a tree falls. Not used for Auto Chopper's
## passive CPS trickle: that would fire constantly and drown everything.
func play_collect() -> void:
	_play_sfx(_collect, randf_range(0.96, 1.04), -4.0)


## Successful upgrade purchase (Better Axe, Auto Chopper, Element Power,
## Prestige Reset). Afford-gated buttons should not reach this on a
## failed buy; the call site still checks the buy_*() return value.
func play_upgrade() -> void:
	_play_sfx(_upgrade, 1.0, -3.0)


## Enchantment banner reveal. A little brighter than a regular collect
## so the two kill-end sounds do not collapse into one.
func play_enchantment() -> void:
	_play_sfx(_enchantment, 1.0, -3.0)


## Light tick for the five element buttons (and anything else that is a
## UI press rather than a world event).
func play_ui_click() -> void:
	_play_sfx(_ui_click, randf_range(0.95, 1.05), -8.0)


func start_music() -> void:
	if _music_player.stream != _music:
		_music_player.stream = _music
	if not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_buses()
	_save_settings()
	settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_buses()
	_save_settings()
	settings_changed.emit()


func set_sfx_muted(muted: bool) -> void:
	sfx_muted = muted
	_apply_buses()
	_save_settings()
	settings_changed.emit()


func set_music_muted(muted: bool) -> void:
	music_muted = muted
	_apply_buses()
	_save_settings()
	settings_changed.emit()


func toggle_sfx_mute() -> void:
	set_sfx_muted(not sfx_muted)


func toggle_music_mute() -> void:
	set_music_muted(not music_muted)


func _build_players() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)


func _load_streams() -> void:
	_hit_stream = _load_stream(HIT_PATH)
	_swing_stream = _load_stream(SWING_PATH)
	# Procedural stand-ins for everything we do not yet have a recorded
	# clip for (UI, collect, upgrade, enchantment, tree crack, and a
	# fallback hit/swing if the two mp3s fail to load). Real files can
	# drop in later by swapping these assignments; play_*() stays put.
	_hit_fallback = _make_thud()
	_swing_fallback = _make_whoosh()
	_tree_crack = _make_crack()
	_tree_fall = _make_thud()
	_collect = _make_arpeggio([523.25, 783.99], 0.09, 0.28)
	_upgrade = _make_arpeggio([392.00, 523.25, 659.25], 0.08, 0.26)
	_enchantment = _make_arpeggio([659.25, 783.99, 987.77], 0.11, 0.24)
	_ui_click = _make_click()
	_music = _make_music_loop()


func _load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _play_sfx(stream: AudioStream, pitch: float, volume_db: float) -> void:
	if stream == null:
		return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _apply_buses() -> void:
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, _linear_to_bus_db(sfx_volume))
		AudioServer.set_bus_mute(sfx_idx, sfx_muted)
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, _linear_to_bus_db(music_volume))
		AudioServer.set_bus_mute(music_idx, music_muted)


func _linear_to_bus_db(linear: float) -> float:
	if linear <= 0.0001:
		return -80.0
	return linear_to_db(linear)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	sfx_muted = bool(cfg.get_value("audio", "sfx_muted", false))
	music_muted = bool(cfg.get_value("audio", "music_muted", false))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_muted", sfx_muted)
	cfg.set_value("audio", "music_muted", music_muted)
	cfg.save(SAVE_PATH)


## --- Procedural one-shots ------------------------------------------------
## Tiny synthesized stand-ins so every play_*() has something to play
## before dedicated clips exist. Kept short and enveloped so they do not
## click at the edges.

func _make_thud() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.18
	var frames := int(duration * mix_rate)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / mix_rate
		var body := sin(TAU * 90.0 * t) * 0.7 + sin(TAU * 140.0 * t) * 0.3
		samples[i] = body * 0.55 * _envelope(t, duration, 0.004, 0.10)
	return _to_wav(samples, mix_rate)


func _make_whoosh() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.14
	var frames := int(duration * mix_rate)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var prev := 0.0
	for i in frames:
		var t := float(i) / mix_rate
		var white := randf_range(-1.0, 1.0)
		prev = prev * 0.6 + white * 0.4
		var sweep := 400.0 + 900.0 * (t / duration)
		samples[i] = (prev * 0.7 + sin(TAU * sweep * t) * 0.3) * 0.35 * _envelope(t, duration, 0.01, 0.05)
	return _to_wav(samples, mix_rate)


func _make_crack() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.12
	var frames := int(duration * mix_rate)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var prev := 0.0
	for i in frames:
		var t := float(i) / mix_rate
		var white := randf_range(-1.0, 1.0)
		prev = prev * 0.45 + white * 0.55
		samples[i] = prev * 0.5 * _envelope(t, duration, 0.002, 0.06)
	return _to_wav(samples, mix_rate)


func _make_click() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.045
	var frames := int(duration * mix_rate)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / mix_rate
		samples[i] = sin(TAU * 1400.0 * t) * 0.28 * _envelope(t, duration, 0.002, 0.02)
	return _to_wav(samples, mix_rate)


func _make_arpeggio(freqs: Array, note_len: float, volume: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var note_frames := int(note_len * mix_rate)
	var samples := PackedFloat32Array()
	samples.resize(note_frames * freqs.size())
	for n in freqs.size():
		var freq := float(freqs[n])
		for i in note_frames:
			var t := float(i) / mix_rate
			samples[n * note_frames + i] = sin(TAU * freq * t) * volume * _envelope(t, note_len, 0.004, 0.03)
	return _to_wav(samples, mix_rate)


func _make_music_loop() -> AudioStreamWAV:
	# Soft looping pad. Frequencies are integer-cycle at 22050 Hz over
	# 4 seconds (110 / 165 / 220) so the loop joins without a click.
	# There is no recorded BGM on disk yet; this is the "soft looping
	# background music that can be muted" Prompt 4.2 asks for, quiet
	# enough not to fight the axe hits. Swap _music for a real stream
	# later without touching start_music() / mute.
	var mix_rate := 22050
	var duration := 4.0
	var frames := int(duration * mix_rate)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / mix_rate
		var trem := 0.78 + 0.22 * sin(TAU * 0.5 * t)
		var mix := sin(TAU * 110.0 * t) + sin(TAU * 165.0 * t) * 0.65 + sin(TAU * 220.0 * t) * 0.25
		samples[i] = mix * 0.11 * trem
	return _to_wav(samples, mix_rate, true)


func _envelope(t: float, duration: float, attack: float = 0.005, release: float = 0.04) -> float:
	if t < attack:
		return t / attack
	if t > duration - release:
		return maxf(0.0, (duration - t) / release)
	return 1.0


func _to_wav(samples: PackedFloat32Array, mix_rate: int, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
