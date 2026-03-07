extends CharacterBody2D

@export var note_1_color: NoteColor
@export var note_2_color: NoteColor
@export var note_3_color: NoteColor

@export var move_speed: float = 240.0
@export var accel_ground: float = 2200.0
@export var decel_ground: float = 2800.0
@export var accel_air: float = 1100.0
@export var jump_velocity: float = -390.0
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.10
@export var fall_gravity_multiplier: float = 1.6
@export var jump_cut_multiplier: float = 2.2
@export var quantize_notes_to_beat: bool = true
@export_range(0.0, 0.25, 0.01) var beat_input_window: float = 0.1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D2

const FLOATING_NOTE_SCENE := preload("res://entities/player/vfx/floating_note.tscn")

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _queued_note_color: NoteColor
var _is_dead: bool = false


func _ready() -> void:
	if quantize_notes_to_beat:
		BeatManger.beat_hit.connect(_on_beat_hit)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_update_jump_timers(delta)
	_handle_jump_buffer_input()
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	_update_animation()
	move_and_slide()
	_check_crush_death()
	_handle_note_input()


func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)


func _handle_jump_buffer_input() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time


func _apply_gravity(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

	if not is_on_floor():
		var gravity_multiplier := 1.0

		if velocity.y > 0.0:
			gravity_multiplier = fall_gravity_multiplier
		elif Input.is_action_just_released("jump"):
			gravity_multiplier = jump_cut_multiplier

		velocity.y += gravity * gravity_multiplier * delta


func _handle_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0


func _handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var target_speed := direction * move_speed

	if abs(direction) > 0.01:
		var acceleration := accel_ground if is_on_floor() else accel_air
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel_ground * delta)


func _update_animation() -> void:
	if animated_sprite == null:
		return

	if velocity.x != 0.0:
		animated_sprite.flip_h = velocity.x < 0.0

	if not is_on_floor():
		animated_sprite.play("jump")
	elif abs(velocity.x) > 0.01:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")


func _handle_note_input() -> void:
	if Input.is_action_just_pressed("play_note_1"):
		_request_note_play(note_1_color)	
	
	if Input.is_action_just_pressed("play_note_2"):
		_request_note_play(note_2_color)	
	
	if Input.is_action_just_pressed("play_note_3"):
		_request_note_play(note_3_color)

func _request_note_play(note_color: NoteColor) -> void:
	if note_color == null:
		return

	# if quantize_notes_to_beat:
	# 	if _is_within_beat_input_window():
	# 		_play_whistle(note_color)
	# 		_queued_note_color = null
	# 		return
	# 	_queued_note_color = note_color
	# 	return

	_play_whistle(note_color)
	
func _play_whistle(note_color: NoteColor) -> void:
	FreezeManager.request_freeze_color(note_color)
	_spawn_floating_note(note_color)
	audio_player.stream = note_color.sound
	audio_player.play()	

func _on_beat_hit(_index: int) -> void:
	if _queued_note_color == null:
		return

	_play_whistle(_queued_note_color)
	_queued_note_color = null

func _is_within_beat_input_window() -> bool:
	var time_since_last_beat := BeatManger.get_time_since_last_beat()
	var time_until_next_beat := BeatManger.get_time_until_next_beat()
	return time_since_last_beat <= beat_input_window or time_until_next_beat <= beat_input_window


func _spawn_floating_note(note_color: NoteColor) -> void:
	var floating_note := FLOATING_NOTE_SCENE.instantiate() 
	get_tree().current_scene.add_child(floating_note)
	floating_note.global_position = global_position + Vector2(0, -16)
	floating_note.play(note_color)


func _check_crush_death() -> void:
	var player_shape := collision_shape.shape as RectangleShape2D
	if player_shape == null:
		return

	var nearby_platforms := _find_nearby_moving_platforms(player_shape.size)
	for platform in nearby_platforms:
		var motion: Vector2 = platform.get_current_motion()
		if _has_platform_on_push_side(player_shape.size, motion, platform) and _is_blocked_in_direction(player_shape.size, motion, [self, platform]):
			die()
			return


func _find_nearby_moving_platforms(player_size: Vector2) -> Array[MovingPlatform]:
	var query_shape := RectangleShape2D.new()
	query_shape.size = player_size + Vector2(8.0, 8.0)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.transform = Transform2D(0.0, global_position + collision_shape.position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self]

	var platforms: Array[MovingPlatform] = []
	var hits := get_world_2d().direct_space_state.intersect_shape(query, 16)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider is MovingPlatform and collider.get_current_motion() != Vector2.ZERO:
			platforms.append(collider)

	return platforms


func _has_platform_on_push_side(player_size: Vector2, motion: Vector2, platform: MovingPlatform) -> bool:
	if motion == Vector2.ZERO:
		return false

	var query_shape := RectangleShape2D.new()
	var query_offset := Vector2.ZERO

	if abs(motion.x) >= abs(motion.y):
		query_shape.size = Vector2(4.0, max(player_size.y - 2.0, 1.0))
		query_offset = Vector2(-signf(motion.x) * (player_size.x * 0.5 + 3.0), 0.0)
	else:
		query_shape.size = Vector2(max(player_size.x - 2.0, 1.0), 4.0)
		query_offset = Vector2(0.0, -signf(motion.y) * (player_size.y * 0.5 + 3.0))

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.transform = Transform2D(0.0, global_position + collision_shape.position + query_offset)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self]

	var hits := get_world_2d().direct_space_state.intersect_shape(query, 8)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == platform:
			return true

	return false


func _is_blocked_in_direction(player_size: Vector2, motion: Vector2, exclude: Array) -> bool:
	if motion == Vector2.ZERO:
		return false

	var direction := motion.normalized()
	var query_shape := RectangleShape2D.new()
	var query_offset := Vector2.ZERO

	if abs(direction.x) >= abs(direction.y):
		query_shape.size = Vector2(4.0, max(player_size.y - 2.0, 1.0))
		query_offset = Vector2(sign(direction.x) * (player_size.x * 0.5 + 3.0), 0.0)
	else:
		query_shape.size = Vector2(max(player_size.x - 2.0, 1.0), 4.0)
		query_offset = Vector2(0.0, sign(direction.y) * (player_size.y * 0.5 + 3.0))

	var block_query := PhysicsShapeQueryParameters2D.new()
	block_query.shape = query_shape
	block_query.transform = Transform2D(0.0, global_position + collision_shape.position + query_offset)
	block_query.collide_with_areas = false
	block_query.collide_with_bodies = true
	block_query.exclude = exclude

	var hits := get_world_2d().direct_space_state.intersect_shape(block_query, 8)
	return not hits.is_empty()


func die() -> void:
	if _is_dead:
		return

	_is_dead = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	LevelManagerAL.show_game_over()
