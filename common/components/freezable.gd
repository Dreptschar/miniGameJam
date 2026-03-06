extends Node
class_name Freezable

@export var freeze_colors: Array[NoteColor] = []

var active_freeze_colors: Array[NoteColor] = [] 
var is_frozen: bool = false
var freeze_time_left: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if FreezeManager:
		FreezeManager.connect("freeze_color_requested", self._on_freeze_color_requested)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_frozen:
		return
	
	_while_frozen(delta)
	
	freeze_time_left -= delta

	if freeze_time_left <= 0.0:
		unfreeze()

func freeze(color: NoteColor, duration: float) -> void:		
	


func _while_frozen(delta: float) -> void:
	pass

func unfreeze() -> void:
	is_frozen = false


func _on_freeze_color_requested(color: NoteColor, duration: float) -> void:
	if color in freeze_colors:
		freeze(color, duration)
