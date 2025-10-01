class_name Coin
extends Area2D

var taken = false

func _ready():
	$AnimatedSprite2D.play("spin")

func _on_body_entered(body: Node) -> void:
	if taken:
		return
	if body is CharacterBody2D:
		taken = true
		$AnimationPlayer.play("taken")
		if body.has_method("add_coin"):
			body.add_coin()
