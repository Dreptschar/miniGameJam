extends Node2D

@export var note_1_color: NoteColor
@export var note_2_color: NoteColor
@export var note_3_color: NoteColor

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("play_note_1"):
		FreezeManager.request_freeze_color(note_1_color, 2.0)