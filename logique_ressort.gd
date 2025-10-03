extends Area2D
@export var spring_force := Vector2(0, -800)  # + fort que jump_force
 
func _ready():
	$"../AnimatedSprite2D".stop()
	connect("body_entered", Callable(self, "_on_body_entered"))
	
func _on_body_entered(body: Node) -> void:
   # Vérifie si le corps a la méthode, peu importe sa scène d’origine
	if body.has_method("apply_spring_force"):
		body.apply_spring_force(spring_force)
		$"../AudioStreamPlayer2D".play()
		$"../AnimatedSprite2D".play("ressort")


func _on_animated_sprite_2d_animation_finished() -> void:
	pass # Replace with function body.
