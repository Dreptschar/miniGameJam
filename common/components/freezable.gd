@tool
extends Node
class_name Freezable

const MAX_DISPLAY_COLORS := 4

var freeze_colors: Array[NoteColor] = []
@export_range(1, 16, 1) var freeze_beats: int = 2
@export_range(1, 16, 1) var combo_window_beats: int = 2

var freeze_colors_state: Array[FrozenColorState] = [] 
var _object_freeze_beats_left: int = 0
var _freeze_activation_queued: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if FreezeManager:
		FreezeManager.connect("freeze_color_requested", self._on_freeze_color_requested)
	if BeatManger:
		BeatManger.beat_hit.connect(_on_beat_hit)

func _build_color_states() -> void:
	freeze_colors_state.clear()
	_object_freeze_beats_left = 0
	_freeze_activation_queued = false
	for color in freeze_colors:
		freeze_colors_state.append(FrozenColorState.new(color))

func _on_freeze_color_requested(color: NoteColor) -> void:
	var freeze_color_state := get_color_state(color)
	if freeze_color_state == null:
		return

	if _is_object_fully_frozen():
		return

	freeze_color_state.is_frozen = true
	freeze_color_state.active_beats_left = max(combo_window_beats, 1)

	if _are_all_colors_armed():
		_freeze_activation_queued = true

func _on_beat_hit(_index: int) -> void:
	if _freeze_activation_queued:
		if _are_all_colors_armed():
			_freeze_activation_queued = false
			_object_freeze_beats_left = max(freeze_beats, 1)
			_on_color_frozen(null)
			return
		_freeze_activation_queued = false

	if _is_object_fully_frozen():
		_object_freeze_beats_left = max(_object_freeze_beats_left - 1, 0)
		print("Object Freeze Beats Left: %d" % _object_freeze_beats_left)

		if _object_freeze_beats_left <= 0:
			for frozen_color in freeze_colors_state:
				frozen_color.is_frozen = false
				frozen_color.active_beats_left = 0
			_on_color_unfrozen(null)
		return

	for frozen_color in freeze_colors_state:
		if not frozen_color.is_frozen:
			continue

		frozen_color.active_beats_left = max(frozen_color.active_beats_left - 1, 0)
		print("Color: %s, Combo Beats Left: %d" % [frozen_color.note_color, frozen_color.active_beats_left])

		if frozen_color.active_beats_left <= 0:
			frozen_color.is_frozen = false
			_on_color_unfrozen(frozen_color.note_color)

func set_freeze_colors(colors: Array[NoteColor]) -> void:
	freeze_colors = colors
	_build_color_states()

func get_color_state(color: NoteColor) -> FrozenColorState:
	for freeze_color_state in freeze_colors_state:
		if freeze_color_state.note_color == color:
			return freeze_color_state
	return null

func is_color_frozen(color: NoteColor) -> bool:
	var freeze_color_state := get_color_state(color)
	return freeze_color_state != null and freeze_color_state.is_frozen

func is_any_color_frozen() -> bool:
	for freeze_color_state in freeze_colors_state:
		if freeze_color_state.is_frozen:
			return true
	return false

func are_all_colors_frozen() -> bool:
	return _is_object_fully_frozen()


func is_partially_frozen() -> bool:
	return is_any_color_frozen() and not _is_object_fully_frozen()

func _are_all_colors_armed() -> bool:
	for freeze_color_state in freeze_colors_state:
		if not freeze_color_state.is_frozen:
			return false
	return true

func _is_object_fully_frozen() -> bool:
	return _object_freeze_beats_left > 0 and _are_all_colors_armed()

func get_tint() -> Color:
	if freeze_colors.is_empty():
			return Color.WHITE

	var sum := Color(0, 0, 0, 1)
	for note_color in freeze_colors:
			sum.r += note_color.color.r
			sum.g += note_color.color.g
			sum.b += note_color.color.b
	var count := float(freeze_colors.size())
	return Color(sum.r / count, sum.g / count, sum.b / count, 1.0)


func get_stripe_colors(max_colors: int = 4) -> Array[Color]:
	var colors: Array[Color] = []
	if max_colors <= 0:
		return colors

	for note_color in freeze_colors:
		if note_color == null:
			continue
		colors.append(note_color.color)
		if colors.size() >= max_colors:
			return colors

	if colors.is_empty():
		colors.append(Color.WHITE)

	return colors


func get_stripe_frozen_mask(max_colors: int = 4) -> PackedFloat32Array:
	var frozen_mask := PackedFloat32Array()
	if max_colors <= 0:
		return frozen_mask

	for note_color in freeze_colors:
		if note_color == null:
			continue
		frozen_mask.append(1.0 if is_color_frozen(note_color) else 0.0)
		if frozen_mask.size() >= max_colors:
			return frozen_mask

	if frozen_mask.is_empty():
		frozen_mask.append(0.0)

	return frozen_mask


func get_or_create_freeze_shader_material(sprite: Sprite2D, shader: Shader, current_material: ShaderMaterial) -> ShaderMaterial:
	if sprite == null:
		return current_material
	if current_material != null:
		return current_material

	var material := ShaderMaterial.new()
	material.shader = shader
	sprite.material = material
	return material


func apply_freeze_shader_state(
	sprite: Sprite2D,
	material: ShaderMaterial,
	partial_freeze_amount: float,
	full_freeze_amount: float,
	freeze_tint: Color,
	darken_strength: float,
	desaturate_strength: float,
	accent_strength: float
) -> void:
	if sprite == null or material == null:
		return

	sprite.modulate = Color.WHITE
	_apply_stripe_shader_parameters(material)
	material.set_shader_parameter("freeze_tint", freeze_tint)
	material.set_shader_parameter("darken_strength", darken_strength)
	material.set_shader_parameter("desaturate_strength", desaturate_strength)
	material.set_shader_parameter("accent_strength", accent_strength)
	material.set_shader_parameter("freeze_amount", get_freeze_shader_amount(partial_freeze_amount, full_freeze_amount))


func get_freeze_shader_amount(partial_freeze_amount: float, full_freeze_amount: float) -> float:
	if are_all_colors_frozen():
		return full_freeze_amount
	if is_partially_frozen():
		return partial_freeze_amount
	return 0.0


func _apply_stripe_shader_parameters(material: ShaderMaterial) -> void:
	var stripe_colors := get_stripe_colors(MAX_DISPLAY_COLORS)
	var shader_colors := PackedColorArray()
	var stripe_frozen_mask := get_stripe_frozen_mask(MAX_DISPLAY_COLORS)
	for color in stripe_colors:
		shader_colors.append(color)
	while shader_colors.size() < MAX_DISPLAY_COLORS:
		shader_colors.append(shader_colors[shader_colors.size() - 1])
	while stripe_frozen_mask.size() < MAX_DISPLAY_COLORS:
		stripe_frozen_mask.append(0.0)

	material.set_shader_parameter("stripe_color_count", stripe_colors.size())
	material.set_shader_parameter("stripe_colors", shader_colors)
	material.set_shader_parameter("stripe_frozen", stripe_frozen_mask)

func _on_color_frozen(color: NoteColor) -> void:
	pass

func _on_color_unfrozen(color: NoteColor) -> void:
	pass
