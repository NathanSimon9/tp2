extends RigidBody2D

@export var speed: float = 100.0

var direction := Vector2.RIGHT

func _ready():

	linear_velocity = direction * speed
	gravity_scale = 0

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:

	for i in range(state.get_contact_count()):

		var collider = state.get_contact_collider_object(i)

		if collider and collider is StaticBody2D:

			# Inverse direction au contact

			direction = -direction

			break

	linear_velocity = direction * speed
	
