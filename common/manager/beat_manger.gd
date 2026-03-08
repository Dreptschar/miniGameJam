extends Node


signal beat_hit(index: int)

@export var bpm : float = 60.0
@export var beat_sound: AudioStream = preload("res://assets/audio/music/kick.wav")
@export var freeze_sound: AudioStream = preload("res://assets/audio/music/freeze.wav")
@export_range(-40.0, 6.0, 0.5) var beat_volume_db: float = -12.0
@export var music_stream: AudioStream
@export_range(-40.0, 6.0, 0.5) var music_volume_db: float = -1.0
@export var use_music_clock: bool = true
@export var music_autoplay: bool = true
@export_range(0.0, 8.0, 0.001) var music_start_offset_sec: float = 0.0

@export_group("Audio Buses")
@export var beat_bus: StringName = &"Beat"
@export var freeze_bus: StringName = &"Freeze"
@export var music_bus: StringName = &"Music"

var _beat_time: float = 0.0
var _beat_index: int = 0
var _audio_player: AudioStreamPlayer
var _freeze_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _active_frozen_objects: int = 0
var _last_song_time_sec: float = 0.0
var _pending_music_stream: AudioStream = null


func _ready() -> void:
	_ensure_bus(beat_bus)
	_ensure_bus(freeze_bus)
	_ensure_bus(music_bus)

	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = beat_sound
	_audio_player.volume_db = beat_volume_db
	_audio_player.bus = beat_bus
	_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_audio_player)

	_freeze_player = AudioStreamPlayer.new()
	_freeze_player.stream = freeze_sound
	_freeze_player.volume_db = beat_volume_db
	_freeze_player.bus = freeze_bus
	_freeze_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_freeze_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.stream = music_stream
	_ensure_music_stream_loop(_music_player.stream)
	_music_player.volume_db = music_volume_db
	_music_player.bus = music_bus
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_last_song_time_sec = 0.0


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, &"Master")


func _process(delta: float) -> void:
	if _is_music_clock_active():
		_process_music_clock()
		return

	var seconds_per_beat: float = 60.0 / bpm
	_beat_time += delta

	while _beat_time >= seconds_per_beat:
		_beat_time -= seconds_per_beat
		_beat_index += 1
		beat_hit.emit(_beat_index)
		_play_beat_sound()


func _process_music_clock() -> void:
	if _music_player == null or not _music_player.playing:
		return

	var song_time: float = _get_song_time_sec() - music_start_offset_sec
	if song_time < 0.0:
		return

	if song_time < _last_song_time_sec:
		_beat_index = 0

	var seconds_per_beat: float = get_seconds_per_beat()
	if seconds_per_beat <= 0.0:
		return

	var current_beat_index: int = int(floor(song_time / seconds_per_beat))
	_beat_time = fposmod(song_time, seconds_per_beat)

	while _beat_index < current_beat_index:
		_beat_index += 1
		beat_hit.emit(_beat_index)
		_play_beat_sound()

	_last_song_time_sec = song_time


func _play_beat_sound() -> void:
	if _pending_music_stream != null:
		music_stream = _pending_music_stream
		_pending_music_stream = null
		_music_player.stop()
		_music_player.stream = music_stream
		_ensure_music_stream_loop(_music_player.stream)
		_last_song_time_sec = 0.0

	if _active_frozen_objects > 0:
		if freeze_sound != null and _freeze_player != null:
			_freeze_player.play()
	else:
		if beat_sound != null and _audio_player != null:
			_audio_player.play()

	if not _music_player.playing and music_stream != null and music_autoplay:
		_music_player.play()
		_last_song_time_sec = 0.0


func notify_object_frozen_state_changed(is_frozen: bool) -> void:
	if is_frozen:
		_active_frozen_objects += 1
	else:
		_active_frozen_objects = max(_active_frozen_objects - 1, 0)


func get_seconds_per_beat() -> float:
	return 60.0 / bpm


func get_time_since_last_beat() -> float:
	return _beat_time


func get_time_until_next_beat() -> float:
	return get_seconds_per_beat() - _beat_time


func set_bpm(value: float, reset_phase: bool = true) -> void:
	bpm = max(value, 1.0)
	if reset_phase:
		_beat_time = 0.0
		_beat_index = 0
		_last_song_time_sec = 0.0


func set_music_stream(stream: AudioStream, restart: bool = true, start_position_sec: float = 0.0) -> void:
	_pending_music_stream = stream


func fire_beat_now() -> void:
	_beat_index += 1
	beat_hit.emit(_beat_index)
	_play_beat_sound()
	_beat_time = 0.0


func switch_music_now(stream: AudioStream) -> void:
	_pending_music_stream = null
	music_stream = stream
	if _music_player == null:
		return
	_music_player.stop()
	_music_player.stream = music_stream
	_ensure_music_stream_loop(_music_player.stream)
	_last_song_time_sec = 0.0
	if music_stream != null and music_autoplay:
		_music_player.play()


func _ensure_music_stream_loop(stream: AudioStream) -> void:
	if stream == null:
		return
	for property_info in stream.get_property_list():
		if property_info.get("name", "") == "loop":
			stream.set("loop", true)
			return


func _on_music_finished() -> void:
	if _music_player == null or music_stream == null or not music_autoplay:
		return
	_music_player.play(0.0)
	_last_song_time_sec = 0.0


func _is_music_clock_active() -> bool:
	return use_music_clock and music_stream != null and _music_player != null and _music_player.playing


func _get_song_time_sec() -> float:
	return _music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
