extends Node


signal beat_hit(index: int)

@export var bpm : float = 60.0
@export var beat_sound: AudioStream = preload("res://assets/audio/van_wiese-bass-ui-298402.mp3")
@export_range(-40.0, 6.0, 0.5) var beat_volume_db: float = -8.0
@export var music_stream: AudioStream
@export_range(-40.0, 6.0, 0.5) var music_volume_db: float = -8.0
@export var use_music_clock: bool = true
@export var music_autoplay: bool = true
@export_range(0.0, 8.0, 0.001) var music_start_offset_sec: float = 0.0
@export_range(200.0, 22000.0, 10.0) var normal_lowpass_cutoff_hz: float = 18000.0
@export_range(200.0, 22000.0, 10.0) var frozen_lowpass_cutoff_hz: float = 1800.0
@export_range(0.1, 4.0, 0.1) var normal_lowpass_resonance: float = 0.8
@export_range(0.1, 4.0, 0.1) var frozen_lowpass_resonance: float = 1.4
@export_range(0.5, 2.0, 0.01) var normal_pitch_scale: float = 1.0
@export_range(0.5, 2.0, 0.01) var frozen_pitch_scale: float = 0.96

var _beat_time: float = 0.0
var _beat_index: int = 0
var _audio_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _active_frozen_objects: int = 0
var _beat_bus_name: StringName = &"BeatMangerBus"
var _beat_bus_index: int = -1
var _lowpass_effect: AudioEffectLowPassFilter
var _last_song_time_sec: float = 0.0

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = beat_sound
	_audio_player.volume_db = beat_volume_db
	_ensure_audio_bus()
	if _beat_bus_index >= 0:
		_audio_player.bus = _beat_bus_name
	add_child(_audio_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = music_stream
	_ensure_music_stream_loop(_music_player.stream)
	_music_player.volume_db = music_volume_db
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	if music_stream != null and music_autoplay:
		_music_player.play()
	_last_song_time_sec = 0.0

func _process(delta: float) -> void:
	if _is_music_clock_active():
		_process_music_clock()
		return

	var seconds_per_beat: float = 60.0 / bpm
	_beat_time += delta

	while _beat_time >= seconds_per_beat:
		_beat_time -= seconds_per_beat
		_beat_index += 1
		_play_beat_sound()
		beat_hit.emit(_beat_index)


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
		_play_beat_sound()
		beat_hit.emit(_beat_index)

	_last_song_time_sec = song_time

func _play_beat_sound() -> void:
	if _audio_player == null or beat_sound == null:
		return
	if _audio_player.stream != beat_sound:
		_audio_player.stream = beat_sound
	_audio_player.volume_db = beat_volume_db
	_audio_player.pitch_scale = frozen_pitch_scale if _active_frozen_objects > 0 else normal_pitch_scale
	_audio_player.play()


func notify_object_frozen_state_changed(is_frozen: bool) -> void:
	if is_frozen:
		_active_frozen_objects += 1
	else:
		_active_frozen_objects = max(_active_frozen_objects - 1, 0)
	_update_frozen_audio_state()

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
	music_stream = stream
	if _music_player == null:
		return

	if _music_player.stream != music_stream:
		_music_player.stream = music_stream
	_ensure_music_stream_loop(_music_player.stream)

	if music_stream == null:
		_music_player.stop()
		return

	if music_autoplay and (restart or not _music_player.playing):
		_music_player.play(max(start_position_sec, 0.0))
		_last_song_time_sec = 0.0


func _ensure_music_stream_loop(stream: AudioStream) -> void:
	if stream == null:
		return

	for property_info in stream.get_property_list():
		if property_info.get("name", "") == "loop":
			stream.set("loop", true)
			return


func _on_music_finished() -> void:
	if _music_player == null:
		return
	if music_stream == null:
		return
	if not music_autoplay:
		return

	_music_player.play(0.0)
	_last_song_time_sec = 0.0


func _ensure_audio_bus() -> void:
	var existing_index: int = AudioServer.get_bus_index(_beat_bus_name)
	if existing_index >= 0:
		_beat_bus_index = existing_index
	else:
		_beat_bus_index = AudioServer.bus_count
		AudioServer.add_bus(_beat_bus_index)
		AudioServer.set_bus_name(_beat_bus_index, _beat_bus_name)
		AudioServer.set_bus_send(_beat_bus_index, &"Master")

	_lowpass_effect = AudioServer.get_bus_effect(_beat_bus_index, 0) as AudioEffectLowPassFilter
	if _lowpass_effect == null:
		_lowpass_effect = AudioEffectLowPassFilter.new()
		AudioServer.add_bus_effect(_beat_bus_index, _lowpass_effect, 0)
	_update_frozen_audio_state()


func _update_frozen_audio_state() -> void:
	if _lowpass_effect == null:
		return

	var is_frozen_audio: bool = _active_frozen_objects > 0
	_lowpass_effect.cutoff_hz = frozen_lowpass_cutoff_hz if is_frozen_audio else normal_lowpass_cutoff_hz
	_lowpass_effect.resonance = frozen_lowpass_resonance if is_frozen_audio else normal_lowpass_resonance


func _is_music_clock_active() -> bool:
	return use_music_clock and music_stream != null and _music_player != null


func _get_song_time_sec() -> float:
	return _music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
