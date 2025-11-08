extends CharacterBody2D

@export var walk_speed := 80.0
@export var chase_speed := 370.0
@export var jump_force := -420.0
@export var gravity := 1400.0
@export var max_hp := 10
@export var flee_duration := 2.0
@export var flee_speed := 700.0

# ===== NOUVELLES FONCTIONNALITÉS =====
@export var enrage_threshold := 0.3  # 30% de vie = mode rage
@export var dash_attack_speed := 900.0
@export var dash_attack_cooldown := 5.0
@export var dash_attack_duration := 0.5

var hp := max_hp
var state := "idle"   # idle, random_walk, chase, attack, hurt, fleeing, dead, dash_attack, charging
var player: CharacterBody2D = null
var hurt := false
var attacking := false
var dead := false
var fleeing_timer := 0.0  # temps restant pour la fuite

# ===== NOUVELLES VARIABLES =====
var is_enraged := false
var dash_attack_timer := 0.0
var dash_timer := 0.0
var combo_attack_count := 0  # Compteur de combo
var last_attack_time := 0.0
var is_charging := false  # Nouveau: indique si le boss charge son dash
var can_summon := true  # Peut invoquer des zombies
var summon_cooldown := 6.0  # Cooldown entre les invocations
var summon_timer := 0.0
var enemy_scene = preload("res://scenes/enemy.tscn")  # Charge la scène zombie
var summoning_active := false  # Le boss est en mode invocation

@onready var hearts := $"../CanvasLayer/HBoxContainer2".get_children()
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_head: Area2D = $HitHead
@onready var hit_player: Area2D = $HitPlayer
@onready var detection_area: Area2D = $Detection

var random_direction := 0
var random_timer := 0.0
@export var random_walk_time := 2.0

func _ready():
	hit_head.body_entered.connect(_on_head_hit)
	hit_player.body_entered.connect(_on_hit_player)
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_left)
	sprite.play("idle")
	update_hearts()
	print("🔥 Boss prêt - Vie: ", hp, "/", max_hp)

func update_hearts():
	for i in range(len(hearts)):
		if i < hp:
			hearts[i].texture = preload("res://medias/coeur.png")
		else:
			hearts[i].texture = preload("res://medias/coeur_vide.png")

func _physics_process(delta: float):
	if dead:
		return

	# Diminue les timers
	if fleeing_timer > 0:
		fleeing_timer -= delta
		if fleeing_timer <= 0:
			# Fin de la fuite
			if player != null and is_instance_valid(player):
				state = "chase"
			else:
				state = "random_walk"
	
	if dash_attack_timer > 0:
		dash_attack_timer -= delta
	
	if dash_timer > 0:
		dash_timer -= delta
	
	if summon_timer > 0:
		summon_timer -= delta

	velocity.y += gravity * delta

	# ===== BLOQUER LE MOUVEMENT PENDANT LA CHARGE =====
	if is_charging:
		velocity.x = 0
		move_and_slide()
		return

	# ===== NOUVELLE LOGIQUE: DASH ATTACK =====
	if state == "dash_attack":
		_do_dash_attack_state()
	elif state == "attack" or state == "hurt":
		velocity.x = 0
	elif state == "fleeing":
		_do_fleeing_state()
	elif state == "chase":
		_do_chase_state(delta)
	elif state == "random_walk":
		_do_random_walk(delta)

	move_and_slide()

func _do_chase_state(delta):
	if fleeing_timer > 0:
		return
	if hurt or attacking or player == null or not is_instance_valid(player):
		player = null
		state = "random_walk"
		return

	var distance = global_position.distance_to(player.global_position)
	
	# ===== INVOQUER DES ZOMBIES SI VIE FAIBLE =====
	# Continue d'invoquer même si des zombies sont déjà présents
	if hp <= 5 and summon_timer <= 0:
		_summon_zombies()
		return
	
	# ===== NOUVELLE FONCTIONNALITÉ: DASH ATTACK EN RAGE =====
	if is_enraged and dash_attack_timer <= 0 and distance < 400 and distance > 100:
		_initiate_dash_attack()
		return

	# ===== FIX: Zone morte pour éviter l'oscillation =====
	var horizontal_distance = player.global_position.x - global_position.x
	
	# Si le joueur est à moins de 20 pixels horizontalement, ne pas bouger
	if abs(horizontal_distance) < 20:
		velocity.x = 0
		if state != "attack":
			sprite.play("idle")
	else:
		var dir = sign(horizontal_distance)
		sprite.flip_h = dir < 0
		
		# ===== VITESSE AUGMENTÉE EN RAGE =====
		var current_speed = chase_speed * 1.3 if is_enraged else chase_speed
		velocity.x = dir * current_speed
		
		if state != "attack":
			sprite.play("walk")

	if player.global_position.y < global_position.y - 40 and is_on_floor():
		velocity.y = jump_force
		if state != "attack":
			sprite.play("jump")

func _do_random_walk(delta: float):
	random_timer -= delta
	if random_timer <= 0:
		random_timer = random_walk_time
		random_direction = randi() % 3 - 1

	velocity.x = random_direction * walk_speed
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		if state != "attack":
			sprite.play("walk")
	else:
		if state != "attack":
			sprite.play("idle")

func _do_fleeing_state():
	if player == null or not is_instance_valid(player):
		state = "random_walk"
		return
	var dir = sign(global_position.x - player.global_position.x)
	sprite.flip_h = dir < 0
	velocity.x = dir * flee_speed
	sprite.play("walk")

# ===== NOUVELLE FONCTION: INVOQUER DES ZOMBIES =====
func _summon_zombies():
	state = "attack"  # Bloquer le mouvement
	velocity.x = 0
	summon_timer = summon_cooldown  # Reset le cooldown
	summoning_active = true
	
	print("🧟 INVOCATION DE ZOMBIES!")
	sprite.play("attaque")  # Animation d'invocation
	
	# Clignotement violet (effet magique)
	for i in range(4):
		sprite.modulate = Color(1, 0.5, 1)
		await get_tree().create_timer(0.15).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.15).timeout
	
	# Nombre aléatoire de zombies (entre 3 et 6)
	var zombie_count = randi_range(3, 6)
	print("🧟 Invocation de ", zombie_count, " zombies!")
	
	# Spawner les zombies à des positions aléatoires
	for i in range(zombie_count):
		# Position aléatoire autour du boss
		var random_x = randf_range(-250, 250)  # Entre -250 et +250 pixels
		var random_y = randf_range(-80, 20)    # Légèrement en hauteur ou au sol
		_spawn_zombie(Vector2(random_x, random_y))
		
		# Petit délai entre chaque spawn pour l'effet
		await get_tree().create_timer(0.15).timeout
	
	await get_tree().create_timer(0.3).timeout
	summoning_active = false
	
	# Reprendre la poursuite
	if player != null and is_instance_valid(player):
		state = "chase"
	else:
		state = "random_walk"

func _spawn_zombie(offset: Vector2):
	if not enemy_scene:
		print("❌ Erreur: enemy.tscn non trouvé!")
		return
	
	var zombie = enemy_scene.instantiate()
	
	# Position du zombie (à côté du boss)
	zombie.global_position = global_position + offset
	
	# Ajouter au même parent que le boss (la scène)
	get_parent().add_child(zombie)
	
	# Effet visuel de spawn
	zombie.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(zombie, "modulate", Color(1, 1, 1, 1), 0.5)
	
	print("🧟 Zombie spawné à ", zombie.global_position)
func _initiate_dash_attack():
	state = "dash_attack"
	dash_attack_timer = dash_attack_cooldown
	is_charging = true  # Activer le mode charge
	
	# S'arrêter et s'orienter vers le joueur
	velocity.x = 0
	var dir = sign(player.global_position.x - global_position.x)
	sprite.flip_h = dir < 0
	sprite.play("idle")
	
	print("⚠️ DASH ATTACK EN PRÉPARATION...")
	
	# Clignotement rouge pendant 1 seconde (5 fois)
	for i in range(5):
		sprite.modulate = Color(1.5, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	
	# Fin de la charge
	is_charging = false
	
	# Vérifier que le joueur existe toujours
	if player == null or not is_instance_valid(player):
		state = "random_walk"
		return
	
	# DASH!
	dash_timer = dash_attack_duration
	print("💨 DASH ATTACK!")
	sprite.play("attaque")

func _do_dash_attack_state():
	if dash_timer <= 0:
		# Fin du dash
		if player != null and is_instance_valid(player):
			state = "chase"
		else:
			state = "random_walk"
		return
	
	# Dash vers le joueur
	var dir = 1 if not sprite.flip_h else -1
	velocity.x = dir * dash_attack_speed

func _on_hit_player(body):
	if dead or hurt:
		return
	
	# ===== DASH ATTACK PEUT AUSSI TOUCHER =====
	if state == "dash_attack":
		if body.name == "Personnages" and is_instance_valid(body):
			if body.has_method("_die_hit_and_reset"):
				body._die_hit_and_reset(global_position)
				print("💥 Dash attack réussi!")
		return
	
	if attacking:
		return
	
	if body.name == "Personnages" and is_instance_valid(body):
		attacking = true
		state = "attack"
		sprite.play("attaque")
		
		# ===== SYSTÈME DE COMBO =====
		var time_since_last = Time.get_ticks_msec() / 1000.0 - last_attack_time
		if time_since_last < 3.0:
			combo_attack_count += 1
			if combo_attack_count >= 3:
				print("🔥 COMBO x3!")
				# Attaque plus rapide
				sprite.speed_scale = 1.5
		else:
			combo_attack_count = 1
		
		last_attack_time = Time.get_ticks_msec() / 1000.0
		
		if body.has_method("_die_hit_and_reset"):
			body._die_hit_and_reset(global_position)

	var anim_length = _get_animation_length("attaque")
	await get_tree().create_timer(anim_length).timeout

	sprite.speed_scale = 1.0
	attacking = false
	if player != null and is_instance_valid(player):
		state = "chase"
	else:
		state = "random_walk"

func _get_animation_length(anim_name: String) -> float:
	var frames = sprite.get_sprite_frames()
	var frame_count = frames.get_frame_count(anim_name)
	if frame_count == 0:
		return 0.0
	var fps = frames.get_animation_speed(anim_name)
	if fps == 0:
		return 0.0
	return frame_count / fps

func _on_head_hit(body):
	if dead:
		return
	if body.name != "Personnages" or not is_instance_valid(body):
		return

	if body.global_position.y < global_position.y:
		_take_damage()
		update_hearts()

		# Propulsion horizontale du joueur
		var direction = sign(body.global_position.x - global_position.x)
		if direction == 0:
			direction = 1
		body.velocity.x = 800 * direction
		body.velocity.y = -200

		# Début de la fuite
		state = "fleeing"
		fleeing_timer = flee_duration

func _take_damage():
	if hurt or dead:
		return
	hp -= 1
	hurt = true
	state = "hurt"
	_flash_red()
	
	# ===== ENTRER EN MODE RAGE =====
	if not is_enraged and hp <= max_hp * enrage_threshold:
		_enter_rage_mode()
	
	if hp <= 0:
		_die()
		return
	
	sprite.play("hurt")
	await get_tree().create_timer(0.3).timeout
	hurt = false
	if player != null and is_instance_valid(player):
		state = "chase"
	else:
		state = "random_walk"

# ===== NOUVELLE FONCTION: MODE RAGE =====
func _enter_rage_mode():
	is_enraged = true
	print("😡 BOSS EN RAGE! Vie critique!")
	
	# Effet visuel de rage (pulsation rouge)
	for i in range(3):
		sprite.modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	
	# Le boss devient plus agressif
	chase_speed *= 1.2
	flee_speed *= 1.3

func _flash_red():
	var old = sprite.modulate
	sprite.modulate = Color(1,0.3,0.3)
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(sprite):
		sprite.modulate = old

func _die():
	dead = true
	state = "dead"
	velocity = Vector2.ZERO
	print("💀 Boss vaincu!")
	
	# ===== EFFET DE MORT AMÉLIORÉ =====
	sprite.play("meurt")
	
	# Faire clignoter avant de disparaître
	for i in range(5):
		sprite.modulate = Color(1, 1, 1, 0.3)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	
	queue_free()

func _on_player_detected(body):
	if dead:
		return
	if body.name == "Personnages" and is_instance_valid(body):
		player = body
		if fleeing_timer <= 0:
			state = "chase"
			print("🎯 Cible verrouillée!")

func _on_player_left(body):
	if body == player:
		player = null
		if fleeing_timer <= 0:
			state = "random_walk"
			print("❓ Cible perdue...")
