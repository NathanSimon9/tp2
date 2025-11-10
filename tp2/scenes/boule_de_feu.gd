extends Area2D

@export var speed := 400.0  # Vitesse de déplacement
@export var lifetime := 5.0  # Durée de vie maximale (en secondes)

var direction := Vector2.RIGHT  # Direction par défaut
var velocity := Vector2.ZERO
var can_collide := false  # Empêche les collisions immédiates au spawn

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	# Jouer l'animation de la boule de feu
	if sprite:
		sprite.play("default")
	
	# Attendre un petit moment avant d'activer les collisions
	await get_tree().create_timer(0.15).timeout
	
	if is_instance_valid(self):
		# Maintenant on peut détecter les collisions
		can_collide = true
		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_area_entered)
		
		# Appliquer le flip selon la direction initiale
		if sprite:
			sprite.flip_h = direction.x < 0
	
	# Détruire automatiquement après le lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		_explode()

func _physics_process(delta: float):
	# Déplacer la boule de feu dans sa direction
	velocity = direction.normalized() * speed
	position += velocity * delta

func set_direction(new_direction: Vector2):
	"""Définir la direction de la boule de feu"""
	direction = new_direction.normalized()
	
	# Flip le sprite si la boule va vers la gauche
	if sprite:
		sprite.flip_h = direction.x < 0
		print("🔥 Direction: ", direction, " | Flip: ", sprite.flip_h)

func _on_body_entered(body):
	"""Quand la boule touche un corps physique (mur, sol, etc.)"""
	if not can_collide:
		return
	
	if body.is_in_group("player") or body.name == "Personnages":
		# Toucher le joueur
		if body.has_method("_die_hit_and_reset"):
			body._die_hit_and_reset(global_position)
			print("🔥 Boule de feu a touché le joueur!")
	
	# Exploser dans tous les cas (mur ou joueur)
	_explode()

func _on_area_entered(area):
	"""Quand la boule touche une autre Area2D"""
	if not can_collide:
		return
	
	# Exploser si elle touche quelque chose
	_explode()

func _explode():
	"""Effet d'explosion et destruction"""
	if not is_instance_valid(self):
		return
	
	print("💥 Boule de feu détruite!")
	
	# Effet visuel d'explosion (optionnel)
	if sprite:
		sprite.modulate = Color(2, 2, 1, 1)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
		await tween.finished
	
	queue_free()
