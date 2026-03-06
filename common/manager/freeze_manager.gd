extends Node

signal freeze_color_requested(color: NoteColor, duration: float)

func request_freeze_color(color: NoteColor, duration: float) -> void:
	emit_signal("freeze_color_requested", color, duration)
