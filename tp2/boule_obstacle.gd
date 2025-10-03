extends RigidBody2D  # ou KinematicBody2D

@export var speed = 150
var is_dead := false
var direction = Vector2.RIGHT

func _ready():

	gravity_scale = 0.1  # si RigidBody2D

	linear_velocity = direction * speed

func _physics_process(delta):

	var velocity = direction * speed

	var collision = move_and_collide(velocity * delta)
	$Roue.rotation += direction.x * -0.2

	if collision:

		direction = -direction
		$Roue.rotation += -direction.x * 0.2

func _on_Area2D_body_entered(body):

	# Si l'area détecte un StaticBody (mur), on inverse la direction

	if body is StaticBody2D:

		direction = -direction

		linear_velocity = direction * speed  # pour RigidBody2D
 



	

		


func _on_hit_box_body_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_dead:
		if body.has_method("_die_hit_and_reset"):
			body._die_hit_and_reset(global_position)
	pass # Replace with function body.
