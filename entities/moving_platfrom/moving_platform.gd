@tool
extends AnimatableBody2D 
class_name MovingPlatform

enum PathMode {
	CUSTOM,
	HORIZONTAL,
	VERTICAL,
}

@export var path_mode: PathMode = PathMode.CUSTOM:
	set(value):
		path_mode = value
		_refresh_editor_state()
@export var move_offset: Vector2 = Vector2(200, 0):
	set(value):
		move_offset = value
		_refresh_editor_state()
@export var travel_distance: float = 200.0:
	set(value):
		travel_distance = value
		_refresh_editor_state()
@export_range(1, 64, 1) var steps_per_leg: int = 4:
	set(value):
		steps_per_leg = max(value, 1)
		queue_redraw()
@export_range(0.0, 1.0, 0.01) var snap_fraction: float = 0.15
@export_range(1, 16, 1) var freeze_beats: int = 2:
	set(value):
		freeze_beats = max(value, 1)
		_refresh_editor_state()
@export_range(1, 16, 1) var combo_window_beats: int = 2:
	set(value):
		combo_window_beats = max(value, 1)
		_refresh_editor_state()
@export var freeze_colors: Array[NoteColor] = []:
	set(value):
		freeze_colors = value
		_refresh_editor_state()
@export var size: Vector2 = Vector2(16, 16):
	set(value):
		size = Vector2(max(value.x, 1.0), max(value.y, 1.0))
		_refresh_editor_state()

@onready var freezeable_component: Freezable = $FreezableComponent
@onready var sprite2d: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _start: Vector2
var _end: Vector2
var _current_step: int = 0
var _direction: int = 1
var _move_tween: Tween

func _ready() -> void:
	set_notify_transform(true)
	_start = global_position
	_end = _start + move_offset
	_apply_configuration()
	global_position = _get_step_position()
	if not Engine.is_editor_hint():
		BeatManger.beat_hit.connect(_on_beat_hit)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if freezeable_component.are_all_colors_frozen() and _move_tween != null:
		_move_tween.kill()
		_move_tween = null

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var preview_offset := _get_effective_move_offset()
	draw_line(Vector2.ZERO, preview_offset, Color(1.0, 1.0, 1.0, 0.35), 2.0)
	draw_circle(Vector2.ZERO, 4.0, Color(0.9, 0.95, 1.0, 0.6))
	draw_circle(preview_offset, 4.0, Color(1.0, 0.85, 0.35, 0.75))

	for step in range(steps_per_leg + 1):
		var t := float(step) / float(steps_per_leg)
		draw_circle(Vector2.ZERO.lerp(preview_offset, t), 2.0, Color(1.0, 1.0, 1.0, 0.45))

func _update_visuals() -> void:
	_ensure_unique_shape()
	if collision_shape == null or sprite2d == null:
		return

	var shape := collision_shape.shape as RectangleShape2D
	if shape:
		shape.size = size

	var tex_size := sprite2d.texture.get_size()
	sprite2d.scale = size / tex_size

func _ensure_unique_shape() -> void:
	if collision_shape == null or collision_shape.shape == null:
		return

	if not collision_shape.shape.resource_local_to_scene:
		collision_shape.shape = collision_shape.shape.duplicate()

func _on_beat_hit(_index: int) -> void:
	if freezeable_component.are_all_colors_frozen():
		return

	var beat_duration := 60.0 / BeatManger.bpm
	var snap_duration := beat_duration * snap_fraction

	_current_step += _direction

	if _current_step >= steps_per_leg:
		_current_step = steps_per_leg
		_direction = -1
	elif _current_step <= 0:
		_current_step = 0
		_direction = 1

	var next_position := _get_step_position()

	if _move_tween != null:
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", next_position, snap_duration)
	_move_tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	_move_tween = null

func _get_step_position() -> Vector2:
	var t := float(_current_step) / float(steps_per_leg)
	return _start.lerp(_end, t)

func _refresh_editor_state() -> void:
	if not is_node_ready():
		return
	_apply_configuration()
	queue_redraw()

func _apply_configuration() -> void:
	_start = global_position
	_end = _start + _get_effective_move_offset()
	freezeable_component.freeze_beats = freeze_beats
	freezeable_component.combo_window_beats = combo_window_beats
	freezeable_component.set_freeze_colors(freeze_colors)
	sprite2d.modulate = freezeable_component.get_tint()
	_update_visuals()

func _get_effective_move_offset() -> Vector2:
	match path_mode:
		PathMode.HORIZONTAL:
			return Vector2(travel_distance, 0.0)
		PathMode.VERTICAL:
			return Vector2(0.0, travel_distance)
		_:
			return move_offset
