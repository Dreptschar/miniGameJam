extends Resource
class_name LevelResource

@export var scene: PackedScene
@export_range(1.0, 300.0, 1.0) var bpm: float = 60.0
@export var music_stream: AudioStream
@export var instant_music_switch: bool = false
@export var instant_first_beat: bool = false
@export var use_music_clock: bool = false
@export_range(0.0, 8.0, 0.001) var music_start_offset_sec: float = 0.0
@export_range(0.0, 300.0, 0.001) var music_seek_sec: float = 0.0
