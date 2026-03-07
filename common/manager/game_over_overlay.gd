extends Control

signal restart_pressed

@onready var restart_button: Button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	restart_button.pressed.connect(_on_restart_button_pressed)


func show_overlay() -> void:
	show()
	restart_button.grab_focus()


func hide_overlay() -> void:
	hide()


func _on_restart_button_pressed() -> void:
	restart_pressed.emit()
