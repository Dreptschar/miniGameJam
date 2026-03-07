@tool
extends Node
class_name RotatingPlatformComponent

const FROZEN_PLATFORM_SHADER := preload("res://assets/shaders/frozen_platform.gdshader")

enum RotationDirection {
	CLOCKWISE,
	COUNTERCLOCKWISE,
}

@export var rotation_direction: RotationDirection = RotationDirection.CLOCKWISE:
	set(value):
		rotation_direction = value
		_refresh_editor_state()
@export_range(0.0, 360.0, 1.0) var rotation_degrees_offset: float = 90.0:
	set(value):
		rotation_degrees_offset = max(value, 0.0)
		_refresh_editor_state()
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
@export var size: Vector2 = Vector2(48, 16):
	set(value):
		size = Vector2(max(value.x, 1.0), max(value.y, 1.0))
		_refresh_editor_state()
@export_range(0.0, 1.0, 0.01) var partial_freeze_amount: float = 0.45:
	set(value):
		partial_freeze_amount = clampf(value, 0.0, 1.0)
		_update_state_visuals()
@export var freeze_shader_tint: Color = Color(0.35, 0.35, 0.38, 1.0):
	set(value):
		freeze_shader_tint = value
		_update_shader_params()
@export_range(0.0, 1.0, 0.01) var freeze_darken_strength: float = 0.28:
	set(value):
		freeze_darken_strength = clampf(value, 0.0, 1.0)
		_update_shader_params()
@export_range(0.0, 1.0, 0.01) var freeze_desaturate_strength: float = 0.22:
	set(value):
		freeze_desaturate_strength = clampf(value, 0.0, 1.0)
		_update_shader_params()
@export_range(0.0, 1.0, 0.01) var freeze_accent_strength: float = 0.18:
	set(value):
		freeze_accent_strength = clampf(value, 0.0, 1.0)
		_update_shader_params()
@export_range(0.0, 1.0, 0.01) var full_freeze_amount: float = 1.0:
	set(value):
		full_freeze_amount = clampf(value, 0.0, 1.0)
		_update_state_visuals()
@export_range(0.0, 12.0, 0.1) var frozen_beat_shake_degrees: float = 4.0
@export_range(0.01, 0.3, 0.01) var frozen_beat_shake_duration: float = 0.12
@export_node_path("Freezable") var freezable_component_path: NodePath = NodePath("../FreezableComponent")
@export_node_path("Sprite2D") var sprite_path: NodePath = NodePath("../Sprite2D")
@export_node_path("CollisionShape2D") var collision_shape_path: NodePath = NodePath("../CollisionShape2D")

var _root: Node2D
var _freezeable_component: Freezable
var _sprite2d: Sprite2D
var _collision_shape: CollisionShape2D
var _rotation_tween: Tween
var _freeze_material: ShaderMaterial
var _shake_tween: Tween
var _base_sprite_rotation_degrees: float = 0.0


func _ready() -> void:
	_root = get_parent() as Node2D
	_resolve_nodes()
	if _root == null:
		return

	_apply_configuration()
	if _sprite2d != null:
		_base_sprite_rotation_degrees = _sprite2d.rotation_degrees

	if not Engine.is_editor_hint():
		BeatManger.beat_hit.connect(_on_beat_hit)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _freezeable_component != null and _freezeable_component.are_all_colors_frozen() and _rotation_tween != null:
		_rotation_tween.kill()
		_rotation_tween = null
	_update_state_visuals()


func _resolve_nodes() -> void:
	_freezeable_component = get_node_or_null(freezable_component_path) as Freezable
	_sprite2d = get_node_or_null(sprite_path) as Sprite2D
	_collision_shape = get_node_or_null(collision_shape_path) as CollisionShape2D


func _on_beat_hit(_index: int) -> void:
	if _freezeable_component != null and _freezeable_component.are_all_colors_frozen():
		_play_frozen_beat_shake()
		return

	if _root == null:
		return

	var beat_duration := 60.0 / BeatManger.bpm
	var snap_duration := beat_duration * snap_fraction
	var target_rotation_degrees := _root.rotation_degrees + _get_effective_rotation_offset()

	if _rotation_tween != null:
		_rotation_tween.kill()

	_rotation_tween = create_tween()
	_rotation_tween.tween_property(_root, "rotation_degrees", target_rotation_degrees, snap_duration)
	_rotation_tween.finished.connect(_on_rotation_finished)


func _on_rotation_finished() -> void:
	_rotation_tween = null


func _refresh_editor_state() -> void:
	if not is_node_ready():
		return

	_resolve_nodes()
	if _root == null:
		_root = get_parent() as Node2D
	if _root == null:
		return

	_apply_configuration()


func _apply_configuration() -> void:
	if _freezeable_component != null:
		_freezeable_component.freeze_beats = freeze_beats
		_freezeable_component.combo_window_beats = combo_window_beats
		_freezeable_component.set_freeze_colors(freeze_colors)

	_update_visuals()
	_update_shader_params()
	_update_state_visuals()


func _update_visuals() -> void:
	_ensure_unique_shape()
	if _collision_shape != null:
		var shape := _collision_shape.shape as RectangleShape2D
		if shape != null:
			shape.size = size

	if _sprite2d != null and _sprite2d.texture != null:
		var tex_size := _sprite2d.texture.get_size()
		if tex_size.x != 0.0 and tex_size.y != 0.0:
			_sprite2d.scale = size / tex_size

	_ensure_shader_material()


func _ensure_unique_shape() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return

	if not _collision_shape.shape.resource_local_to_scene:
		_collision_shape.shape = _collision_shape.shape.duplicate()


func _get_effective_rotation_offset() -> float:
	var direction_sign := 1.0 if rotation_direction == RotationDirection.CLOCKWISE else -1.0
	return rotation_degrees_offset * direction_sign


func _update_state_visuals() -> void:
	if _sprite2d == null or _freezeable_component == null:
		return

	var base_tint := _freezeable_component.get_tint()
	_sprite2d.modulate = base_tint

	var freeze_amount := 0.0
	if _freezeable_component.are_all_colors_frozen():
		freeze_amount = full_freeze_amount
	elif _freezeable_component.is_partially_frozen():
		freeze_amount = partial_freeze_amount

	if _freeze_material != null:
		_freeze_material.set_shader_parameter("freeze_amount", freeze_amount)


func _ensure_shader_material() -> void:
	if _sprite2d == null:
		return
	if _freeze_material != null:
		return

	_freeze_material = ShaderMaterial.new()
	_freeze_material.shader = FROZEN_PLATFORM_SHADER
	_sprite2d.material = _freeze_material
	_update_shader_params()


func _update_shader_params() -> void:
	if _freeze_material == null:
		return

	_freeze_material.set_shader_parameter("freeze_tint", freeze_shader_tint)
	_freeze_material.set_shader_parameter("darken_strength", freeze_darken_strength)
	_freeze_material.set_shader_parameter("desaturate_strength", freeze_desaturate_strength)
	_freeze_material.set_shader_parameter("accent_strength", freeze_accent_strength)


func _play_frozen_beat_shake() -> void:
	if _sprite2d == null or frozen_beat_shake_degrees <= 0.0:
		return

	if _shake_tween != null:
		_shake_tween.kill()

	_sprite2d.rotation_degrees = _base_sprite_rotation_degrees
	var shake_amount := randf_range(-frozen_beat_shake_degrees, frozen_beat_shake_degrees)
	if is_zero_approx(shake_amount):
		shake_amount = frozen_beat_shake_degrees

	_shake_tween = create_tween()
	_shake_tween.tween_property(_sprite2d, "rotation_degrees", _base_sprite_rotation_degrees + shake_amount, frozen_beat_shake_duration * 0.35)
	_shake_tween.tween_property(_sprite2d, "rotation_degrees", _base_sprite_rotation_degrees, frozen_beat_shake_duration * 0.65)
	_shake_tween.finished.connect(_on_shake_finished)


func _on_shake_finished() -> void:
	_shake_tween = null
	if _sprite2d != null:
		_sprite2d.rotation_degrees = _base_sprite_rotation_degrees
