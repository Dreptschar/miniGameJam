extends Node


signal beat_hit(index: int)

@export var bpm : float = 60.0
@export var beat_sound: AudioStream = preload("res://test_import/assets/sounds/tap.wav")
@export_range(-40.0, 6.0, 0.5) var beat_volume_db: float = -8.0

var _beat_time: float = 0.0
var _beat_index: int = 0
var _audio_player: AudioStreamPlayer

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = beat_sound
	_audio_player.volume_db = beat_volume_db
	add_child(_audio_player)

func _process(delta: float) -> void:
	var seconds_per_beat := 60.0 / bpm
	_beat_time += delta

	while _beat_time >= seconds_per_beat:
			_beat_time -= seconds_per_beat
			_beat_index += 1
			_play_beat_sound()
			beat_hit.emit(_beat_index)

func _play_beat_sound() -> void:
	if _audio_player == null or beat_sound == null:
		return
	if _audio_player.stream != beat_sound:
		_audio_player.stream = beat_sound
	_audio_player.volume_db = beat_volume_db
	_audio_player.play()

func get_seconds_per_beat() -> float:
	return 60.0 / bpm

func get_time_since_last_beat() -> float:
	return _beat_time

func get_time_until_next_beat() -> float:
	return get_seconds_per_beat() - _beat_time
