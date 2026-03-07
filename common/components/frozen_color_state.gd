extends RefCounted
class_name FrozenColorState

var note_color: NoteColor
var is_frozen: bool = false
var active_beats_left: int = 0

func _init(color: NoteColor) -> void:
	note_color = color
