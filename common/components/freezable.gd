extends Node
class_name Freezable

@export var freeze_colors: Array[NoteColor] = []

var freeze_colors_state: Array[FrozenColorState] = [] 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_build_color_states()
	if FreezeManager:
		FreezeManager.connect("freeze_color_requested", self._on_freeze_color_requested)

func _process(delta: float) -> void:
	for frozen_color in freeze_colors_state:
		if not frozen_color.is_frozen:
			continue
		
		frozen_color.freeze_time_left -= max(frozen_color.freeze_time_left - delta, 0.0)
		
		if frozen_color.freeze_time_left <= 0.0:
			frozen_color.is_frozen = false
			_on_color_unfrozen(frozen_color.note_color)	

func _build_color_states() -> void:
	freeze_colors_state.clear()
	for color in freeze_colors:
		freeze_colors_state.append(FrozenColorState.new(color))

func _on_freeze_color_requested(color: NoteColor, duration: float) -> void:
	var freeze_color_state := _get_color_state(color)
	if freeze_color_state == null:
		return
	var was_frozen := freeze_color_state.is_frozen

	freeze_color_state.is_frozen = true
	freeze_color_state.freeze_time_left = duration

	if not was_frozen:
		_on_color_frozen(color)

func _get_color_state(color: NoteColor) -> FrozenColorState:
	for freeze_color_state in freeze_colors_state:
		if freeze_color_state.note_color == color:
			return freeze_color_state
	return null

func _on_color_frozen(color: NoteColor) -> void:
	pass

func _on_color_unfrozen(color: NoteColor) -> void:
	pass	


