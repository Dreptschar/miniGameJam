extends CanvasLayer 
class_name LevelManager

@export var levels: Array[PackedScene] = []
@export var fade_time: float = 0.25
@export var beat_pulse_color: Color = Color(1, 0.92, 0.75, 0.0)
@export_range(0.0, 1.0, 0.01) var beat_pulse_alpha: float = 0.14
@export_range(0.01, 0.5, 0.01) var beat_pulse_duration: float = 0.16
@export_range(0.0, 0.5, 0.01) var beat_zoom_amount: float = 0.01
@export_range(0.01, 0.25, 0.01) var beat_zoom_in_time: float = 0.05
@export_range(0.01, 0.4, 0.01) var beat_zoom_out_time: float = 0.12

var _current_index: int = -1
var _is_transitioning: bool = false
var _beat_pulse_tween: Tween
var _camera_tween: Tween
var _base_camera_zoom: Vector2 = Vector2.ONE

@onready var fade_rect: ColorRect = $FadeRect
@onready var beat_pulse_rect: ColorRect = $BeatPulseRect


func _ready() -> void:
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0)
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if beat_pulse_rect:
		beat_pulse_rect.color = beat_pulse_color
		beat_pulse_rect.color.a = 0.0
		beat_pulse_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if BeatManger:
		BeatManger.beat_hit.connect(_on_beat_hit)

	_sync_current_index_from_current_scene()
	_cache_camera_zoom()

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
	_cache_camera_zoom()
	await _fade_in()
	_is_transitioning = false

func restart_level() -> void:
	if _current_index >= 0:
		load_level(_current_index)

func _on_beat_hit(_index: int) -> void:
	if beat_pulse_rect == null or beat_pulse_alpha <= 0.0:
		pass
	else:
		if _beat_pulse_tween != null:
			_beat_pulse_tween.kill()

		beat_pulse_rect.color = beat_pulse_color
		beat_pulse_rect.color.a = beat_pulse_alpha

		_beat_pulse_tween = create_tween()
		_beat_pulse_tween.tween_property(beat_pulse_rect, "color:a", 0.0, beat_pulse_duration)

	_pulse_camera()

func _cache_camera_zoom() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		_base_camera_zoom = camera.zoom

func _pulse_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null or beat_zoom_amount <= 0.0:
		return

	_base_camera_zoom = camera.zoom if _camera_tween == null else _base_camera_zoom

	if _camera_tween != null:
		_camera_tween.kill()

	var hit_zoom := _base_camera_zoom * (1.0 - beat_zoom_amount)
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "zoom", hit_zoom, beat_zoom_in_time)
	_camera_tween.tween_property(camera, "zoom", _base_camera_zoom, beat_zoom_out_time)
