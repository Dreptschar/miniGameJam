@tool
extends AnimatableBody2D 
class_name MovingPlatform

const FROZEN_PLATFORM_SHADER := preload("res://assets/shaders/frozen_platform.gdshader")

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
@export_range(0.0, 1.0, 0.01) var partial_freeze_amount: float = 0.45:
	set(value):
		partial_freeze_amount = clampf(value, 0.0, 1.0)
		_sync_freeze_visual_state()
@export var freeze_shader_tint: Color = Color(0.35, 0.35, 0.38, 1.0):
	set(value):
		freeze_shader_tint = value
		_sync_freeze_shader()
@export_range(0.0, 1.0, 0.01) var freeze_darken_strength: float = 0.28:
	set(value):
		freeze_darken_strength = clampf(value, 0.0, 1.0)
		_sync_freeze_shader()
@export_range(0.0, 1.0, 0.01) var freeze_desaturate_strength: float = 0.22:
	set(value):
		freeze_desaturate_strength = clampf(value, 0.0, 1.0)
		_sync_freeze_shader()
@export_range(0.0, 1.0, 0.01) var freeze_accent_strength: float = 0.18:
	set(value):
		freeze_accent_strength = clampf(value, 0.0, 1.0)
		_sync_freeze_shader()
@export_range(0.0, 1.0, 0.01) var full_freeze_amount: float = 1.0:
	set(value):
		full_freeze_amount = clampf(value, 0.0, 1.0)
		_sync_freeze_visual_state()
@export_range(0.0, 12.0, 0.1) var frozen_beat_shake_distance: float = 2.0
@export_range(0.01, 0.3, 0.01) var frozen_beat_shake_duration: float = 0.12

@onready var freezeable_component: Freezable = $FreezableComponent
@onready var sprite2d: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _start: Vector2
var _end: Vector2
var _current_step: int = 0
var _direction: int = 1
var _move_tween: Tween
var _current_motion: Vector2 = Vector2.ZERO
var _freeze_material: ShaderMaterial
var _shake_tween: Tween
var _base_sprite_position: Vector2

func _ready() -> void:
	set_notify_transform(true)
	_start = global_position
	_end = _start + move_offset
	_apply_configuration()
	global_position = _get_step_position()
	if sprite2d != null:
		_base_sprite_position = sprite2d.position
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
	_sync_freeze_visual_state()

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
	_ensure_freeze_shader_material()

func _ensure_unique_shape() -> void:
	if collision_shape == null or collision_shape.shape == null:
		return

	if not collision_shape.shape.resource_local_to_scene:
		collision_shape.shape = collision_shape.shape.duplicate()

func _on_beat_hit(_index: int) -> void:
	if freezeable_component.are_all_colors_frozen():
		_play_frozen_beat_shake()
		return

	var beat_duration: float = 60.0 / BeatManger.bpm
	var snap_duration: float = beat_duration * snap_fraction

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

	_current_motion = next_position - global_position
	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", next_position, snap_duration)
	_move_tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	_move_tween = null
	_current_motion = Vector2.ZERO

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
	_update_visuals()
	_sync_freeze_shader()
	_sync_freeze_visual_state()

func _get_effective_move_offset() -> Vector2:
	match path_mode:
		PathMode.HORIZONTAL:
			return Vector2(travel_distance, 0.0)
		PathMode.VERTICAL:
			return Vector2(0.0, travel_distance)
		_:
			return move_offset


func is_moving_towards(point: Vector2) -> bool:
	if _current_motion == Vector2.ZERO:
		return false

	var to_point := point - global_position
	return _current_motion.normalized().dot(to_point.normalized()) > 0.35


func is_moving_down() -> bool:
	return _current_motion.y > 0.0


func get_current_motion() -> Vector2:
	return _current_motion


func _sync_freeze_visual_state() -> void:
	if sprite2d == null or freezeable_component == null:
		return

	freezeable_component.apply_freeze_shader_state(
		sprite2d,
		_freeze_material,
		partial_freeze_amount,
		full_freeze_amount,
		freeze_shader_tint,
		freeze_darken_strength,
		freeze_desaturate_strength,
		freeze_accent_strength
	)


func _play_frozen_beat_shake() -> void:
	if sprite2d == null or frozen_beat_shake_distance <= 0.0:
		return

	if _shake_tween != null:
		_shake_tween.kill()

	sprite2d.position = _base_sprite_position
	var shake_offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	if shake_offset == Vector2.ZERO:
		shake_offset = Vector2(0.0, -1.0)
	shake_offset = shake_offset.normalized() * frozen_beat_shake_distance

	_shake_tween = create_tween()
	_shake_tween.tween_property(sprite2d, "position", _base_sprite_position + shake_offset, frozen_beat_shake_duration * 0.35)
	_shake_tween.tween_property(sprite2d, "position", _base_sprite_position, frozen_beat_shake_duration * 0.65)
	_shake_tween.finished.connect(_on_shake_finished)


func _on_shake_finished() -> void:
	_shake_tween = null
	if sprite2d != null:
		sprite2d.position = _base_sprite_position


func _ensure_freeze_shader_material() -> void:
	if sprite2d == null:
		return
	_freeze_material = freezeable_component.get_or_create_freeze_shader_material(sprite2d, FROZEN_PLATFORM_SHADER, _freeze_material)
	_sync_freeze_shader()


func _sync_freeze_shader() -> void:
	if _freeze_material == null:
		return

	freezeable_component.apply_freeze_shader_state(
		sprite2d,
		_freeze_material,
		partial_freeze_amount,
		full_freeze_amount,
		freeze_shader_tint,
		freeze_darken_strength,
		freeze_desaturate_strength,
		freeze_accent_strength
	)
