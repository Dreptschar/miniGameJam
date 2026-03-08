@tool
extends StaticBody2D

@export var size: Vector2 = Vector2(64, 16):
	set(value):
		size = value
		_update_visuals()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
func _ready() -> void:
	_update_visuals()
	
func _update_visuals() -> void:
	collision_shape.shape.size = size
	var tex_size := sprite.texture.get_size()
	sprite.scale = size / tex_size
