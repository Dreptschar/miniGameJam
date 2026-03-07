extends Node

signal freeze_color_requested(color: NoteColor)

func request_freeze_color(color: NoteColor) -> void:
	print("Requesting freeze for color: %s" % [color])
	emit_signal("freeze_color_requested", color)
