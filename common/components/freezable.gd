@tool
extends Node
class_name Freezable

var freeze_colors: Array[NoteColor] = []
@export_range(1, 16, 1) var freeze_beats: int = 2
@export_range(1, 16, 1) var combo_window_beats: int = 2
@onready var freeze_particles: GPUParticles2D = $FreezeParticles 

var freeze_colors_state: Array[FrozenColorState] = [] 
var _object_freeze_beats_left: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if FreezeManager:
		FreezeManager.connect("freeze_color_requested", self._on_freeze_color_requested)
	if BeatManger:
		BeatManger.beat_hit.connect(_on_beat_hit)

func _build_color_states() -> void:
	freeze_colors_state.clear()
	_object_freeze_beats_left = 0
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
		_object_freeze_beats_left = max(freeze_beats, 1)
		if freeze_particles:
			freeze_particles.emitting = true
		_on_color_frozen(color)

func _on_beat_hit(_index: int) -> void:
	if _is_object_fully_frozen():
		_object_freeze_beats_left = max(_object_freeze_beats_left - 1, 0)
		print("Object Freeze Beats Left: %d" % _object_freeze_beats_left)

		if _object_freeze_beats_left <= 0:
			for frozen_color in freeze_colors_state:
				frozen_color.is_frozen = false
				frozen_color.active_beats_left = 0
			if freeze_particles:
				freeze_particles.emitting = false
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

func _on_color_frozen(color: NoteColor) -> void:
	pass

func _on_color_unfrozen(color: NoteColor) -> void:
	pass	
