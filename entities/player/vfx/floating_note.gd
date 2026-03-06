extends Sprite2D 

@export var lifetime: float = 0.8
@export var rise_distance: float = 60.0
@export var drift_x: float = 20.0
@export var notesTextures: Array[Texture2D] = []

func _ready() -> void:
	self.texture = notesTextures[randi() % notesTextures.size()]

func play(note_color: NoteColor) -> void:
	modulate = note_color.color

	var target := global_position + Vector2(randf_range(-drift_x, drift_x), -rise_distance)	

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target, lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"scale", Vector2(1.15,1.15), lifetime)
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.finished.connect(self.queue_free)