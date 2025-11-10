extends Area2D

# Signal émis quand le checkpoint est activé
signal checkpoint_activated(checkpoint_position)

# Variables
@export var checkpoint_id: int = 0
@export var activation_color: Color = Color(0.2, 1.0, 0.3)
@export var inactive_color: Color = Color(0.6, 0.6, 0.6)

var is_activated: bool = false

# Références aux nœuds
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var particles: CPUParticles2D = $CPUParticles2D if has_node("CPUParticles2D") else null

func _ready():
	# Connecter le signal de collision
	body_entered.connect(_on_body_entered)
	
	# Initialiser la couleur inactive
	if sprite:
		sprite.modulate = inactive_color
	
	# S'assurer que l'AnimationPlayer est arrêté au début
	if animation_player:
		animation_player.stop()
	
	# Désactiver les particules au début
	if particles:
		particles.emitting = false

func _on_body_entered(body):
	# Vérifier si c'est le joueur qui entre
	if body.name == "joueur" or body.is_in_group("player"):
		activate_checkpoint(body)

func activate_checkpoint(player):
	if is_activated:
		return
	
	is_activated = true
	
	# Changer la couleur
	if sprite:
		sprite.modulate = activation_color
	
	# Jouer l'animation d'activation
	if animation_player and animation_player.has_animation("activate"):
		$AudioStreamPlayer2D.play()
		$AudioStreamPlayer2D2.play()
		animation_player.play("activate")
	
	# Activer les particules
	if particles:
		particles.emitting = true
		# Arrêter les particules après 1 seconde
		await get_tree().create_timer(1.0).timeout
		if particles:
			particles.emitting = false
	
	# ⭐ MISE À JOUR DE LA POSITION DE DÉPART DU JOUEUR
	# Ajuster la position Y pour éviter que le joueur spawn dans le sol
	var spawn_offset = Vector2(0, 0)  # 50 pixels au-dessus du checkpoint
	var checkpoint_pos = global_position + spawn_offset
	
	if player.has_method("set_checkpoint"):
		player.set_checkpoint(checkpoint_pos)
	else:
		player.start_position = checkpoint_pos
	
	print("✅ Checkpoint ", checkpoint_id, " activé à la position: ", checkpoint_pos)
	
	# Émettre le signal avec la position du checkpoint
	checkpoint_activated.emit(checkpoint_pos)

func deactivate():
	"""Désactive visuellement le checkpoint (utile si vous voulez réinitialiser)"""
	is_activated = false
	if sprite:
		sprite.modulate = inactive_color
	if animation_player:
		animation_player.stop()

# Fonction pour vérifier si ce checkpoint est actif
func is_checkpoint_active() -> bool:
	return is_activated
