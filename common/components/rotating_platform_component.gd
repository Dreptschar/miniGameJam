@tool
extends Node
class_name RotatingPlatformComponent

const FROZEN_PLATFORM_SHADER := preload("res://assets/shaders/frozen_platform.gdshader")

enum RotationDirection {
	CLOCKWISE,
	COUNTERCLOCKWISE,
}

@export_node_path("Freezable") var freezable_component_path: NodePath = NodePath("../FreezableComponent")
@export_node_path("Sprite2D") var sprite_path: NodePath = NodePath("../Sprite2D")
@export_node_path("CollisionShape2D") var collision_shape_path: NodePath = NodePath("../CollisionShape2D")
@export_node_path("CollisionPolygon2D") var collision_polygon_path: NodePath = NodePath("../CollisionPolygon2D")

var _root: Node2D
var _freezeable_component: Freezable
var _sprite2d: Sprite2D
var _collision_shape: CollisionShape2D
var _collision_polygon: CollisionPolygon2D
var _rotation_tween: Tween
var _freeze_material: ShaderMaterial
var _shake_tween: Tween
var _base_sprite_rotation_degrees: float = 0.0


func _ready() -> void:
	_root = get_parent() as Node2D
	_resolve_nodes()
	if _root == null:
		return
	if _root is AnimatableBody2D:
		(_root as AnimatableBody2D).sync_to_physics = true

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
	_sync_freeze_visual_state()


func _resolve_nodes() -> void:
	_freezeable_component = get_node_or_null(freezable_component_path) as Freezable
	_sprite2d = get_node_or_null(sprite_path) as Sprite2D
	_collision_shape = get_node_or_null(collision_shape_path) as CollisionShape2D
	_collision_polygon = get_node_or_null(collision_polygon_path) as CollisionPolygon2D


func _on_beat_hit(_index: int) -> void:
	if _freezeable_component != null and _freezeable_component.are_all_colors_frozen():
		_play_frozen_beat_shake()
		return

	if _root == null:
		return

	var beat_duration: float = 60.0 / BeatManger.bpm
	var snap_duration: float = beat_duration * _get_snap_fraction()
	var target_rotation_degrees := _root.rotation_degrees + _get_effective_rotation_offset()

	if _rotation_tween != null:
		_rotation_tween.kill()

	_rotation_tween = create_tween()
	_rotation_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
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


func refresh_from_root() -> void:
	_refresh_editor_state()


func _apply_configuration() -> void:
	if _freezeable_component != null:
		_freezeable_component.freeze_beats = _get_freeze_beats()
		_freezeable_component.combo_window_beats = _get_combo_window_beats()
		_freezeable_component.set_freeze_colors(_get_freeze_colors())

	_update_visuals()
	_sync_freeze_shader()
	_sync_freeze_visual_state()


func _update_visuals() -> void:
	_ensure_unique_shape()
	if _collision_shape != null:
		var shape := _collision_shape.shape as RectangleShape2D
		if shape != null:
			shape.size = _get_size()

	_update_collision_polygon_scale()

	if _sprite2d != null and _sprite2d.texture != null:
		var tex_size := _sprite2d.texture.get_size()
		if tex_size.x != 0.0 and tex_size.y != 0.0:
			_sprite2d.scale = _get_size() / tex_size

	_ensure_freeze_shader_material()


func _ensure_unique_shape() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return

	if not _collision_shape.shape.resource_local_to_scene:
		_collision_shape.shape = _collision_shape.shape.duplicate()


func _update_collision_polygon_scale() -> void:
	if _collision_polygon == null:
		return
	if _collision_polygon.polygon.is_empty():
		return

	var polygon_size := _get_polygon_size(_collision_polygon.polygon)
	if is_zero_approx(polygon_size.x) or is_zero_approx(polygon_size.y):
		return

	var target_size := _get_size()
	_collision_polygon.scale = Vector2(target_size.x / polygon_size.x, target_size.y / polygon_size.y)


func _get_polygon_size(polygon: PackedVector2Array) -> Vector2:
	var min_point := polygon[0]
	var max_point := polygon[0]
	for point in polygon:
		min_point.x = min(min_point.x, point.x)
		min_point.y = min(min_point.y, point.y)
		max_point.x = max(max_point.x, point.x)
		max_point.y = max(max_point.y, point.y)
	return max_point - min_point


func _get_effective_rotation_offset() -> float:
	var direction_sign := 1.0 if _get_rotation_direction() == RotationDirection.CLOCKWISE else -1.0
	return _get_rotation_degrees_offset() * direction_sign


func _sync_freeze_visual_state() -> void:
	if _sprite2d == null or _freezeable_component == null:
		return

	_freezeable_component.apply_freeze_shader_state(
		_sprite2d,
		_freeze_material,
		_get_partial_freeze_amount(),
		_get_full_freeze_amount(),
		_get_freeze_shader_tint(),
		_get_freeze_darken_strength(),
		_get_freeze_desaturate_strength(),
		_get_freeze_accent_strength()
	)


func _ensure_freeze_shader_material() -> void:
	if _sprite2d == null:
		return
	_freeze_material = _freezeable_component.get_or_create_freeze_shader_material(_sprite2d, FROZEN_PLATFORM_SHADER, _freeze_material)
	_sync_freeze_shader()


func _sync_freeze_shader() -> void:
	if _freeze_material == null:
		return

	_freezeable_component.apply_freeze_shader_state(
		_sprite2d,
		_freeze_material,
		_get_partial_freeze_amount(),
		_get_full_freeze_amount(),
		_get_freeze_shader_tint(),
		_get_freeze_darken_strength(),
		_get_freeze_desaturate_strength(),
		_get_freeze_accent_strength()
	)


func _play_frozen_beat_shake() -> void:
	var shake_degrees := _get_frozen_beat_shake_degrees()
	if _sprite2d == null or shake_degrees <= 0.0:
		return

	if _shake_tween != null:
		_shake_tween.kill()

	_sprite2d.rotation_degrees = _base_sprite_rotation_degrees
	var shake_amount := randf_range(-shake_degrees, shake_degrees)
	if is_zero_approx(shake_amount):
		shake_amount = shake_degrees

	_shake_tween = create_tween()
	_shake_tween.tween_property(_sprite2d, "rotation_degrees", _base_sprite_rotation_degrees + shake_amount, _get_frozen_beat_shake_duration() * 0.35)
	_shake_tween.tween_property(_sprite2d, "rotation_degrees", _base_sprite_rotation_degrees, _get_frozen_beat_shake_duration() * 0.65)
	_shake_tween.finished.connect(_on_shake_finished)


func _on_shake_finished() -> void:
	_shake_tween = null
	if _sprite2d != null:
		_sprite2d.rotation_degrees = _base_sprite_rotation_degrees


func _get_rotation_direction() -> RotationDirection:
	return _get_root_value("rotation_direction", RotationDirection.CLOCKWISE)


func _get_rotation_degrees_offset() -> float:
	return _get_root_value("rotation_degrees_offset", 90.0)


func _get_snap_fraction() -> float:
	return _get_root_value("snap_fraction", 0.15)


func _get_freeze_beats() -> int:
	return _get_root_value("freeze_beats", 2)


func _get_combo_window_beats() -> int:
	return _get_root_value("combo_window_beats", 2)


func _get_freeze_colors() -> Array[NoteColor]:
	return _get_root_value("freeze_colors", [])


func _get_size() -> Vector2:
	return _get_root_value("size", Vector2(128, 128))


func _get_partial_freeze_amount() -> float:
	return _get_root_value("partial_freeze_amount", 0.45)


func _get_freeze_shader_tint() -> Color:
	return _get_root_value("freeze_shader_tint", Color(0.35, 0.35, 0.38, 1.0))


func _get_freeze_darken_strength() -> float:
	return _get_root_value("freeze_darken_strength", 0.28)


func _get_freeze_desaturate_strength() -> float:
	return _get_root_value("freeze_desaturate_strength", 0.22)


func _get_freeze_accent_strength() -> float:
	return _get_root_value("freeze_accent_strength", 0.18)


func _get_full_freeze_amount() -> float:
	return _get_root_value("full_freeze_amount", 1.0)


func _get_frozen_beat_shake_degrees() -> float:
	return _get_root_value("frozen_beat_shake_degrees", 4.0)


func _get_frozen_beat_shake_duration() -> float:
	return _get_root_value("frozen_beat_shake_duration", 0.12)


func _get_root_value(property_name: StringName, default_value: Variant) -> Variant:
	if _root == null:
		return default_value
	var value: Variant = _root.get(property_name)
	return default_value if value == null else value
