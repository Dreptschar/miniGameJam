extends Node2D

@export_node_path("Node2D") var player_path: NodePath = NodePath("Player")
@export_range(1.0, 300.0, 1.0) var min_bpm: float = 72.0
@export_range(1.0, 300.0, 1.0) var max_bpm: float = 132.0
@export var left_x: float = 32.0
@export var right_x: float = 624.0
@export_range(0.0, 8.0, 0.01) var bpm_smoothing_speed: float = 4.0

var _player: Node2D
var _current_bpm: float = 0.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_current_bpm = _sample_target_bpm()
	if BeatManger != null:
		BeatManger.set_bpm(_current_bpm, false)


func _process(delta: float) -> void:
	if BeatManger == null:
		return
	if _player == null:
		_player = get_node_or_null(player_path) as Node2D
		if _player == null:
			return

	var target_bpm: float = _sample_target_bpm()
	if bpm_smoothing_speed <= 0.0:
		_current_bpm = target_bpm
	else:
		var t: float = clamp(delta * bpm_smoothing_speed, 0.0, 1.0)
		_current_bpm = lerp(_current_bpm, target_bpm, t)

	BeatManger.set_bpm(_current_bpm, false)


func _sample_target_bpm() -> float:
	if _player == null:
		return min_bpm

	var span: float = right_x - left_x
	if is_zero_approx(span):
		return min_bpm

	var progress: float = clamp((_player.global_position.x - left_x) / span, 0.0, 1.0)
	return lerp(min_bpm, max_bpm, progress)
