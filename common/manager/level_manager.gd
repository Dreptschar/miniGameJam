extends CanvasLayer 
class_name LevelManager

@export var levels: Array[PackedScene] = []
@export var fade_time: float = 0.25

var _current_index: int = -1
var _is_transitioning: bool = false

@onready var fade_rect: ColorRect = $FadeRect


func _ready() -> void:
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0)
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_sync_current_index_from_current_scene()

func _sync_current_index_from_current_scene() -> void:
	var current := get_tree().current_scene
	if current == null:
		return 
	var current_path := current.scene_file_path
	for i in range(levels.size()):
		if levels[i] and levels[i].resource_path == current_path:
			_current_index = i
			return
func _fade_out() -> void:
	if fade_rect == null:
		return
	var t := create_tween()
	t.tween_property(fade_rect, "color:a", 1.0, fade_time)
	await t.finished
	
func _fade_in() -> void:
	if fade_rect == null:
		return
	var t := create_tween()
	t.tween_property(fade_rect, "color:a", 0.0, fade_time)
	await t.finished

func load_next_level() -> void:
	if levels.size() == 0:
		return
	var next_index := _current_index + 1
	if next_index >= levels.size():
		next_index = 0
	load_level(next_index)
		
func load_level(index: int) -> void:
	if _is_transitioning: 
		return
	if index < 0 or index >= levels.size():
		return 
	var packed := levels[index]
	if not packed:
		return
	_is_transitioning = true
	await _fade_out()
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	_current_index = index
	await _fade_in()
	_is_transitioning = false

func restart_level() -> void:
	if _current_index >= 0:
		load_level(_current_index)
