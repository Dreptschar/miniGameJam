extends CharacterBody2D

@export var note_1_color: NoteColor
@export var note_2_color: NoteColor
@export var note_3_color: NoteColor

@export var move_speed: float = 220.0
@export var jump_velocity: float = -360.0
@export var freeze_duration: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

const FLOATING_NOTE_SCENE := preload("res://entities/player/vfx/floating_note.tscn")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement()
	_update_animation()
	move_and_slide()
	_handle_note_input()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity


func _handle_horizontal_movement() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * move_speed


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
		_play_whistle(note_1_color)	
	
	if Input.is_action_just_pressed("play_note_2"):
		_play_whistle(note_2_color)	
	
	if Input.is_action_just_pressed("play_note_3"):
		_play_whistle(note_3_color)
	
func _play_whistle(note_color: NoteColor) -> void:
	FreezeManager.request_freeze_color(note_color, freeze_duration)
	_spawn_floating_note(note_color)
	audio_player.stream = note_color.sound
	audio_player.play()	


func _spawn_floating_note(note_color: NoteColor) -> void:
	var floating_note := FLOATING_NOTE_SCENE.instantiate() 
	get_tree().current_scene.add_child(floating_note)
	floating_note.global_position = global_position + Vector2(0, -16)
	floating_note.play(note_color)
