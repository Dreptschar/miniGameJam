extends AnimatableBody2D 
class_name MovingPlatform

@export var move_offset: Vector2 = Vector2(200, 0)
@export var move_speed: float = 100.0
@export var freeze_colors: Array[NoteColor] = []

@onready var freezeable_component: Freezable = $FreezableComponent
@onready var sprite2d: Sprite2D = $Sprite2D

var _start: Vector2
var _target: Vector2
var _to_target := true

func _ready() -> void:
	_start = global_position
	_target = _start + move_offset
	freezeable_component.set_freeze_colors(freeze_colors)
	sprite2d.modulate = freezeable_component.get_tint()

func _physics_process(delta: float) -> void:
	if freezeable_component.are_all_colors_frozen():
		return
	var current_target := _target if _to_target else _start
	global_position = global_position.move_toward(current_target, move_speed * delta)
	if global_position.is_equal_approx(current_target):
			_to_target = !_to_target
