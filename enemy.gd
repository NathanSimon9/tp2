extends CharacterBody2D

# --- Constantes ---
const SPEED := 50.0
const GRAVITY := 800.0
const WALK_RANGE := 150.0

# --- Variables ---
var direction := 1
var is_dead := false
var start_position := Vector2.ZERO
var left_limit := 0.0
var right_limit := 0.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var head_hitbox: Area2D = $HitBoxTop
@onready var body_hitbox: Area2D = $HitBoxBody

func _ready() -> void:
	head_hitbox.connect("body_entered", Callable(self, "_on_head_hitbox_body_entered"))
	body_hitbox.connect("body_entered", Callable(self, "_on_body_hitbox_body_entered"))

	start_position = global_position
	left_limit = start_position.x - WALK_RANGE
	right_limit = start_position.x + WALK_RANGE

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = direction * SPEED
	move_and_slide()

	sprite.flip_h = direction < 0

	if anim.current_animation != "walk":
		anim.play("walk")

	if global_position.x < left_limit and direction < 0:
		direction = 1
	elif global_position.x > right_limit and direction > 0:
		direction = -1

# --- Joueur saute sur la tête ---
func _on_head_hitbox_body_entered(body: Node) -> void:
	if body is CharacterBody2D and not is_dead:
		die()
		body.velocity.y = -300

# --- Ennemi meurt ---
func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("explode")
	$AudioStreamPlayer2D.play()
	$AudioStreamPlayer2D2.play()
	anim.animation_finished.connect(Callable(self, "_on_explode_finished"))

func _on_explode_finished(anim_name: String) -> void:
	if anim_name == "explode":
		queue_free()
		anim.animation_finished.disconnect(Callable(self, "_on_explode_finished"))

# --- Frapper le joueur ---
func _on_body_hitbox_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_dead:
		if body.has_method("_die_hit_and_reset"):
			body._die_hit_and_reset(global_position)
