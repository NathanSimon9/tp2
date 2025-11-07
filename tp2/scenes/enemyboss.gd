extends CharacterBody2D

# === PARAMÈTRES DU BOSS ===
@export var max_health: float = 500.0
@export var speed: float = 200.0
@export var detection_range: float = 800.0
@export var attack_range: float = 120.0
@export var attack_cooldown: float = 1.5
@export var gravity: float = 980.0
@export var jump_velocity: float = -450.0

# === VARIABLES INTERNES ===
var current_health: float = 0.0
var player: CharacterBody2D = null
var can_attack: bool = true
var is_attacking: bool = false
var attack_timer: float = 0.0
var is_dead := false

# États du boss
enum BossState { IDLE, CHASE, ATTACK, RETREAT }
var current_state: BossState = BossState.IDLE

# === NŒUDS ===
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ray_wall: RayCast2D = $RayWallCheck
@onready var ray_ground: RayCast2D = $RayGroundCheck

# ===========================================================
# READY
# ===========================================================
func _ready():
	current_health = max_health
	_update_health_bar()
	_setup_areas()
	print("=== BOSS PRÊT ===")

# ===========================================================
# BARRE DE VIE
# ===========================================================
func _update_health_bar():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

# ===========================================================
# AREAS
# ===========================================================
func _setup_areas():
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_body_entered)
		attack_area.body_exited.connect(_on_attack_body_exited)

# ===========================================================
# PHYSICS PROCESS
# ===========================================================
func _physics_process(delta):
	if current_health <= 0:
		_die()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	_update_attack_timer(delta)
	_update_state()
	_execute_state(delta)

	move_and_slide()

# ===========================================================
# ATTACK COOLDOWN
# ===========================================================
func _update_attack_timer(delta):
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0

# ===========================================================
# MACHINE À ÉTATS
# ===========================================================
func _update_state():
	if not player or not is_instance_valid(player):
		current_state = BossState.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	# Nouvelle logique : attaque si joueur dans attack_range
	if distance <= attack_range and can_attack and not is_attacking:
		current_state = BossState.ATTACK
	elif distance <= detection_range:
		current_state = BossState.CHASE
	else:
		current_state = BossState.IDLE

func _execute_state(delta):
	match current_state:
		BossState.IDLE:
			_idle_behavior()
		BossState.CHASE:
			_chase_behavior()
		BossState.ATTACK:
			_attack_behavior()
		BossState.RETREAT:
			_retreat_behavior()

# ===========================================================
# COMPORTEMENTS
# ===========================================================
func _idle_behavior():
	velocity.x = move_toward(velocity.x, 0, speed * 0.5)
	_play_animation("idle")

func _chase_behavior():
	if not player:
		return

	# Suivi gauche/droite sans exception
	var direction = sign(player.global_position.x - global_position.x)
	if direction == 0:
		direction = 1

	velocity.x = direction * speed
	_flip_sprite(direction)

	# Saut automatique si obstacle devant ou pas de sol
	if ray_wall.is_colliding() and is_on_floor():
		velocity.y = jump_velocity
	elif not ray_ground.is_colliding() and is_on_floor():
		velocity.y = jump_velocity

	_play_animation("walk")

func _attack_behavior():
	if is_attacking or not player:
		return

	is_attacking = true
	can_attack = false
	velocity.x = 0
	_play_animation("attaque")

	await get_tree().create_timer(0.3).timeout
	_deal_damage_to_player()
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

func _retreat_behavior():
	var direction = -sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed * 0.8
	_flip_sprite(direction)
	_play_animation("walk")

# ===========================================================
# FLIP SPRITE
# ===========================================================
func _flip_sprite(direction):
	if animated_sprite:
		animated_sprite.flip_h = direction < 0
	elif sprite:
		sprite.flip_h = direction < 0

# ===========================================================
# DÉGÂTS
# ===========================================================
func _deal_damage_to_player():
	if not player or not is_instance_valid(player):
		return
	if player.has_method("_die_hit_and_reset"):
		player._die_hit_and_reset(global_position)

func take_damage(amount: float):
	current_health -= amount
	current_health = max(current_health, 0)
	_update_health_bar()
	_flash_sprite()
	if current_health <= 0:
		_die()

func _flash_sprite():
	var s = animated_sprite if animated_sprite else sprite
	if s:
		s.modulate = Color(1, 0.2, 0.2)
		await get_tree().create_timer(0.15).timeout
		s.modulate = Color(1,1,1,1)

# ===========================================================
# MORT DU BOSS
# ===========================================================
func _die():
	_play_animation("meurt")
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	await get_tree().create_timer(2.0).timeout
	queue_free()

# ===========================================================
# ANIMATIONS
# ===========================================================
func _play_animation(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
	elif animation_player and animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

# ===========================================================
# SIGNALS
# ===========================================================
func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_body_exited(body):
	if body == player:
		player = null

func _on_attack_body_entered(body):
	pass

func _on_attack_body_exited(body):
	pass

# ===========================================================
# ATTAQUE QUAND LE JOUEUR TOUCHE LE HITBOXBODY
# ===========================================================
func _on_hit_box_body_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_dead:
		if body.has_method("_die_hit_and_reset"):
			body._die_hit_and_reset(global_position)
