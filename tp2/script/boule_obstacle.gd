extends RigidBody2D

@export var speed = 150
var is_dead := false
var direction = Vector2.RIGHT

func _ready():
	gravity_scale = 0.1
	linear_velocity = direction * speed

func _physics_process(delta):
	var velocity = direction * speed
	var collision = move_and_collide(velocity * delta)
	
	# Rotation de la roue
	$Roue.rotation += direction.x * -0.2
	
	# Flip horizontal selon la direction
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = direction.x < 0
	elif has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = direction.x < 0
	
	# Si collision avec un mur
	if collision:
		direction = -direction
		$Roue.rotation += -direction.x * 0.2
		linear_velocity = direction * speed

func _on_Area2D_body_entered(body):
	# Si l'area détecte un StaticBody (mur), on inverse la direction
	if body is StaticBody2D:
		direction = -direction
		linear_velocity = direction * speed

func _on_hit_box_body_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	
	if body is CharacterBody2D:
		# Vérifier si le joueur est invincible
		if "is_invincible" in body and body.is_invincible:
			return
		
		if body.has_method("_die_hit_and_reset"):
			body._die_hit_and_reset(global_position)

# Nouvelle fonction : vérifier continuellement si le joueur est dans la zone
func _on_hit_box_body_exited(body: Node2D) -> void:
	pass  # On garde le joueur tracké

# Fonction pour détecter en continu
func _process(delta):
	if is_dead:
		return
	
	# Vérifier si le joueur est dans la zone de collision
	if has_node("hit_box"):
		var bodies = $hit_box.get_overlapping_bodies()
		for body in bodies:
			if body is CharacterBody2D:
				# Vérifier si le joueur est invincible
				if "is_invincible" in body and body.is_invincible:
					continue
				
				if body.has_method("_die_hit_and_reset"):
					body._die_hit_and_reset(global_position)
					return
