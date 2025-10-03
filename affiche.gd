class_name PanneauMessage extends Area2D

@export var message := "Un message défaut."


func _ready() -> void:
	$Message.hide()


func show_message(_body):
	$AudioStreamPlayer2D.play()
	$Timer.start()
	$Message.show()
	$Message/fond/etiquette.text = message
	await $Timer.timeout
	$Message.hide()


func hide_message(_body) -> void:
	$Timer.stop()
	$Message.hide()
	$AudioStreamPlayer2D.play()
