extends RefCounted
class_name FrozenColorState

var note_color: NoteColor
var is_frozen: bool = false
var freeze_time_left: float = 0.0

func _init(color: NoteColor) -> void:
    note_color = color