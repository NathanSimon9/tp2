class_name Coin
extends Area2D

var taken = false
func _ready():
	$AnimatedSprite2D.play("spin")

func _on_body_entered(body: Node2D) -> void:
	if not taken and body is CharacterBody2D:
		($AnimationPlayer as AnimationPlayer).play("taken")
