extends CharacterBody2D

const SPEED = 130
const JUMP_VELOCITY = -300

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var interaction_area: InteractionArea = %InteractionArea
@onready var game_manager: Node = %GameManager
@onready var animation_platform: AnimationPlayer = %Animation_Platform

func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	

func _on_interact():
	if Input.is_action_just_pressed("interact") and game_manager.score == 10:
		animation_platform.play("move_up")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer.time_left > 0.0):
		velocity.y = JUMP_VELOCITY

	# Get the input direction.
	var direction := Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	var just_left_ledge = was_on_floor and not is_on_floor() and velocity.y >= 0
	if just_left_ledge:
		coyote_timer.start()
	
	
	
