@tool
extends AnimatableBody2D
class_name RotatingPlatform

@export var rotation_direction: RotatingPlatformComponent.RotationDirection = RotatingPlatformComponent.RotationDirection.CLOCKWISE:
	set(value):
		rotation_direction = value
		_refresh_component()
@export_range(0.0, 360.0, 1.0) var rotation_degrees_offset: float = 90.0:
	set(value):
		rotation_degrees_offset = max(value, 0.0)
		_refresh_component()
@export_range(0.0, 1.0, 0.01) var snap_fraction: float = 0.15:
	set(value):
		snap_fraction = clampf(value, 0.0, 1.0)
		_refresh_component()
@export_range(1, 16, 1) var freeze_beats: int = 2:
	set(value):
		freeze_beats = max(value, 1)
		_refresh_component()
@export_range(1, 16, 1) var combo_window_beats: int = 2:
	set(value):
		combo_window_beats = max(value, 1)
		_refresh_component()
@export var freeze_colors: Array[NoteColor] = []:
	set(value):
		freeze_colors = value
		_refresh_component()
@export var size: Vector2 = Vector2(128, 128):
	set(value):
		size = Vector2(max(value.x, 1.0), max(value.y, 1.0))
		_refresh_component()
@export_range(0.0, 1.0, 0.01) var partial_freeze_amount: float = 0.45:
	set(value):
		partial_freeze_amount = clampf(value, 0.0, 1.0)
		_refresh_component()
@export var freeze_shader_tint: Color = Color(0.35, 0.35, 0.38, 1.0):
	set(value):
		freeze_shader_tint = value
		_refresh_component()
@export_range(0.0, 1.0, 0.01) var freeze_darken_strength: float = 0.28:
	set(value):
		freeze_darken_strength = clampf(value, 0.0, 1.0)
		_refresh_component()
@export_range(0.0, 1.0, 0.01) var freeze_desaturate_strength: float = 0.22:
	set(value):
		freeze_desaturate_strength = clampf(value, 0.0, 1.0)
		_refresh_component()
@export_range(0.0, 1.0, 0.01) var freeze_accent_strength: float = 0.18:
	set(value):
		freeze_accent_strength = clampf(value, 0.0, 1.0)
		_refresh_component()
@export_range(0.0, 1.0, 0.01) var full_freeze_amount: float = 1.0:
	set(value):
		full_freeze_amount = clampf(value, 0.0, 1.0)
		_refresh_component()
@export_range(0.0, 12.0, 0.1) var frozen_beat_shake_degrees: float = 4.0:
	set(value):
		frozen_beat_shake_degrees = max(value, 0.0)
		_refresh_component()
@export_range(0.01, 0.3, 0.01) var frozen_beat_shake_duration: float = 0.12:
	set(value):
		frozen_beat_shake_duration = max(value, 0.01)
		_refresh_component()

@onready var rotating_platform_component: RotatingPlatformComponent = $RotatingPlatformComponent


func _ready() -> void:
	_refresh_component()


func _refresh_component() -> void:
	if not is_node_ready():
		return
	if rotating_platform_component == null:
		return

	rotating_platform_component.refresh_from_root()
