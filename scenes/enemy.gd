extends CharacterBody2D

# --- Constantes ---
const SPEED := 50.0
const GRAVITY := 800.0

# --- Variables ---
var direction := 1
var is_dead := false
var left_limit := 0.0
var right_limit := 300.0  # Modifie selon ton niveau

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var head_hitbox: Area2D = $HitBoxTop

func _ready() -> void:
	head_hitbox.connect("body_entered", Callable(self, "_on_head_hitbox_body_entered"))

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravité
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Déplacement horizontal
	velocity.x = direction * SPEED
	move_and_slide()

	# Flip du sprite selon la direction
	sprite.flip_h = direction < 0

	# Animation marche
	if anim.current_animation != "walk":
		anim.play("walk")

	# --- Vérifie les limites pour tourner ---
	if global_position.x < left_limit and direction < 0:
		direction = 1
	elif global_position.x > right_limit and direction > 0:
		direction = -1

func _on_head_hitbox_body_entered(body: Node) -> void:
	if body is CharacterBody2D and not is_dead:
		die()
		body.velocity.y = -300

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("explode")
	anim.animation_finished.connect(Callable(self, "_on_explode_finished"))

func _on_explode_finished(anim_name: String) -> void:
	if anim_name == "explode":
		queue_free()
		anim.animation_finished.disconnect(Callable(self, "_on_explode_finished"))
