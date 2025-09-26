extends RigidBody2D  # ou KinematicBody2D

@export var speed = 150

var direction = Vector2.RIGHT

func _ready():

	gravity_scale = 0  # si RigidBody2D

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
 


func _on_static_body_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
