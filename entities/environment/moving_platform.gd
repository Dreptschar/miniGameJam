extends Freezable
class_name MovingPlatform

@export var move_offset: Vector2 = Vector2(200.0, 0.0)
@export var move_speed: float = 100.0

var _start_position: Vector2
var _target_position: Vector2
var _moving_to_target: bool = true


func _ready() -> void:
	super._ready()
	_start_position = global_position
	_target_position = _start_position + move_offset


func _process(delta: float) -> void:
	super._process(delta)

	if is_any_color_frozen():
		return

	var current_target := _target_position if _moving_to_target else _start_position
	global_position = global_position.move_toward(current_target, move_speed * delta)

	if global_position.is_equal_approx(current_target):
		_moving_to_target = not _moving_to_target
		
func _on_color_frozen(color: NoteColor) -> void:
	print("Platform frozen due to color: %s" % color)

func _on_color_unfrozen(color: NoteColor) -> void:
	print("Platform unfrozen for color: %s" % color)