extends Node

signal freeze_color_requested(color: NoteColor, duration: float)

func request_freeze_color(color: NoteColor, duration: float) -> void:
	print("Requesting freeze for color: %s, duration: %f" % [color, duration])
	emit_signal("freeze_color_requested", color, duration)
