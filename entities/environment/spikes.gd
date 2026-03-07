extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("die"):
		print("Player hit spikes, calling die()")
		body.die()
	else:
		LevelManagerAL.restart_level()
