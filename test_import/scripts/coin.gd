extends Area2D

@onready var game_manager: Node = %GameManager
@onready var coin_animation: AnimationPlayer = $coin_animation


func _on_body_entered(_body: Node2D) -> void:
	game_manager.add_point()
	coin_animation.play("pickup")
