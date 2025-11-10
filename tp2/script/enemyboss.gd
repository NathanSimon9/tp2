extends CharacterBody2D

@export var walk_speed := 80.0
@export var chase_speed := 370.0
@export var jump_force := -420.0
@export var gravity := 1400.0
@export var max_hp := 10
@export var flee_duration := 2.0
@export var flee_speed := 700.0

# ===== FONCTIONNALITÉS DE BASE =====
@export var enrage_threshold := 3  # Mode rage à 3 HP
@export var dash_attack_speed := 900.0
@export var dash_attack_cooldown := 5.0
@export var dash_attack_duration := 0.5

# ===== ATTAQUE BOULES DE FEU 🔥 =====
@export var fireball_attack_cooldown := 8.0
@export var fireball_count := 6  # Nombre de boules de feu par salve
@export var fireball_delay := 0.3  # Délai entre chaque boule

var hp := max_hp
var state := "idle"
var player: CharacterBody2D = null
var hurt := false
var attacking := false
var dead := false
var fleeing_timer := 0.0

# ===== VARIABLES COMBAT =====
var is_enraged := false
var dash_attack_timer := 0.0
var dash_timer := 0.0
var combo_attack_count := 0
var last_attack_time := 0.0
var is_charging := false

# ===== INVOCATION ZOMBIES =====
var can_summon := true
var summon_cooldown := 15.0
var summon_timer := 0.0
var enemy_scene = preload("res://scenes/enemy.tscn")
var summoning_active := false

# ===== BOULES DE FEU 🔥 =====
var fireball_attack_timer := 0.0
var is_fireball_attacking := false
var fireball_scene = preload("res://script/BouleDeFeu.tscn")
var attack_pattern := 0  # Pour varier les attaques

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
	$CollisionShape2D.connect("body_entered", _on_body_entered)

	sprite.play("idle")
	update_hearts()
	
	print("🔥 BOSS READY - HP: ", hp, "/", max_hp)
	print("🎮 Nouvelles capacités : Dash, Boules de Feu, Invocation")

func update_hearts():
	for i in range(len(hearts)):
		if i < hp:
			hearts[i].texture = preload("res://medias/coeur.png")
		else:
			hearts[i].texture = preload("res://medias/coeur_vide.png")

func _physics_process(delta: float):
	if dead:
		return

	# Mise à jour des timers
	if fleeing_timer > 0:
		fleeing_timer -= delta
		if fleeing_timer <= 0:
			state = "chase" if player != null and is_instance_valid(player) else "random_walk"
	
	if dash_attack_timer > 0:
		dash_attack_timer -= delta
	
	if dash_timer > 0:
		dash_timer -= delta
	
	if summon_timer > 0:
		summon_timer -= delta
	
	if fireball_attack_timer > 0:
		fireball_attack_timer -= delta

	# Gravité
	velocity.y += gravity * delta

	# États spéciaux qui bloquent le mouvement horizontal
	if is_charging or is_fireball_attacking:
		velocity.x = 0
		move_and_slide()
		return

	# Machine à états
	match state:
		"fireball_attack":
			pass  # Géré par la coroutine
		"dash_attack":
			_do_dash_attack_state()
		"attack", "hurt":
			velocity.x = 0
		"fleeing":
			_do_fleeing_state()
		"chase":
			_do_chase_state(delta)
		"random_walk":
			_do_random_walk(delta)

	move_and_slide()

func _do_chase_state(delta):
	if fleeing_timer > 0 or hurt or attacking or player == null or not is_instance_valid(player):
		if player == null or not is_instance_valid(player):
			player = null
			state = "random_walk"
		return

	var distance = global_position.distance_to(player.global_position)
	var horizontal_distance = player.global_position.x - global_position.x

	# 🧟 INVOCATION (quand il reste 7 HP ou moins)
	if hp <= 7 and summon_timer <= 0:
		_summon_zombies()
		return
	
	# 🔥 ATTAQUE BOULES DE FEU (quand il reste 5 HP ou moins)
	if hp <= 5 and fireball_attack_timer <= 0 and distance < 500:
		attack_pattern = (attack_pattern + 1) % 3
		if attack_pattern == 0:  # 1 chance sur 3
			_initiate_fireball_attack()
			return
	
	# ⚡ DASH ATTACK (seulement en rage)
	if is_enraged and dash_attack_timer <= 0 and distance < 400 and distance > 100:
		_initiate_dash_attack()
		return

	# Mouvement normal de poursuite
	if abs(horizontal_distance) < 20:
		velocity.x = 0
		sprite.play("idle" if state != "attack" else sprite.animation)
	else:
		var dir = sign(horizontal_distance)
		sprite.flip_h = dir < 0
		var current_speed = chase_speed * 1.5 if is_enraged else chase_speed
		velocity.x = dir * current_speed
		
		if state != "attack":
			sprite.play("walk")

	# Saut vers le joueur
	if player.global_position.y < global_position.y - 40 and is_on_floor():
		velocity.y = jump_force
		if state != "attack" and state != "fireball_attack":
			sprite.play("jump")

func _do_random_walk(delta: float):
	random_timer -= delta
	if random_timer <= 0:
		random_timer = random_walk_time
		random_direction = randi() % 3 - 1

	velocity.x = random_direction * walk_speed
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		sprite.play("walk" if state != "attack" else sprite.animation)
	else:
		sprite.play("idle" if state != "attack" else sprite.animation)

func _do_fleeing_state():
	if player == null or not is_instance_valid(player):
		state = "random_walk"
		return
	var dir = sign(global_position.x - player.global_position.x)
	sprite.flip_h = dir < 0
	velocity.x = dir * flee_speed
	
	sprite.play("walk")

# ===== 🔥 NOUVELLE ATTAQUE : BOULES DE FEU =====
func _initiate_fireball_attack():
	if player == null or not is_instance_valid(player):
		return
	
	state = "fireball_attack"
	fireball_attack_timer = fireball_attack_cooldown
	is_fireball_attacking = true
	velocity.x = 0
	
	var dir = sign(player.global_position.x - global_position.x)
	sprite.flip_h = dir < 0
	
	print("🔥 ATTAQUE BOULES DE FEU x", fireball_count, "!")
	
	# Animation de charge
	for i in range(4):
		$AudioStreamPlayer2D3.play()  # Son de lancement
		sprite.modulate = Color(2, 0.5, 0.1)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	
	# Lancer les boules de feu
	for i in range(fireball_count):
		if state != "fireball_attack":  
			break
		
		sprite.play("attaque")
		_spawn_fireball()
		$AudioStreamPlayer2D12.play()
		  # Son de lancement
		
		# Flash orange pour chaque tir
		sprite.modulate = Color(2, 0.7, 0.2)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		
		await get_tree().create_timer(fireball_delay).timeout
	
	# Fin de l'attaque
	is_fireball_attacking = false
	
	if player != null and is_instance_valid(player):
		state = "chase"
	else:
		state = "random_walk"

# ===== 🔥 CRÉER UNE BOULE DE FEU =====
func _spawn_fireball():
	if not fireball_scene:
		print("❌ Erreur: BouleDeFeu.tscn non trouvé!")
		return
	
	var fireball = fireball_scene.instantiate()
	
	# Position de spawn (devant le boss)
	var spawn_offset = Vector2(60 if not sprite.flip_h else -60, -20)
	fireball.global_position = global_position + spawn_offset
	
	# Direction vers le joueur (avec un peu de variation)
	var direction = Vector2.ZERO
	if player != null and is_instance_valid(player):
		direction = (player.global_position - fireball.global_position).normalized()
		# Ajouter une variation aléatoire pour rendre ça plus difficile à éviter
		var angle_variation = randf_range(-0.3, 0.3)
		direction = direction.rotated(angle_variation)
	else:
		# Si pas de joueur, tirer vers l'avant
		direction = Vector2(1 if not sprite.flip_h else -1, 0)
	
	# Appliquer la direction à la boule de feu (si elle a une propriété direction ou velocity)
	if fireball.has_method("set_direction"):
		fireball.set_direction(direction)
	elif "direction" in fireball:
		fireball.direction = direction
	
	get_parent().add_child(fireball)
	
	print("🔥 Boule de feu lancée!")

# ===== 🧟 INVOCATION AMÉLIORÉE (spawn sécurisé) =====
func _summon_zombies():
	state = "attack"
	velocity.x = 0
	summon_timer = summon_cooldown
	summoning_active = true
	
	print("🧟 INVOCATION DE LA HORDE!")
	sprite.play("attaque")
	
	# Effet visuel d'invocation
	for i in range(5):
		sprite.modulate = Color(0.8, 0.3, 1)
		$AudioStreamPlayer2D3.play()
		await get_tree().create_timer(0.12).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.12).timeout
	
	var zombie_count = randi_range(3, 5) if is_enraged else randi_range(2, 3)
	$AudioStreamPlayer2D2.play()
	print("🧟 Invocation de ", zombie_count, " zombies!")
	
	for i in range(zombie_count):
		var offset = Vector2(randf_range(-250, 250), randf_range(-80, 20))
		var spawn_pos = _find_safe_spawn_position(offset)
		_spawn_zombie(spawn_pos)
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(0.5).timeout
	summoning_active = false
	
	state = "chase" if player != null and is_instance_valid(player) else "random_walk"

# ===== 🎯 SPAWN SÉCURISÉ (évite les murs) =====
func _find_safe_spawn_position(offset: Vector2) -> Vector2:
	var test_pos = global_position + offset
	var space_state = get_world_2d().direct_space_state
	
	# Vérifier s'il y a un mur à cette position
	var query = PhysicsPointQueryParameters2D.new()
	query.position = test_pos
	query.collision_mask = 1  # Layer des murs/sols
	query.exclude = [self]
	
	var result = space_state.intersect_point(query, 1)
	
	# Si pas de collision avec un mur, position OK
	if result.is_empty():
		return test_pos
	
	# Sinon, essayer de l'autre côté du boss
	var opposite_offset = Vector2(-offset.x, offset.y)
	test_pos = global_position + opposite_offset
	query.position = test_pos
	result = space_state.intersect_point(query, 1)
	
	if result.is_empty():
		return test_pos
	
	# En dernier recours, spawn juste à côté du boss
	return global_position + Vector2(50 if randf() > 0.5 else -50, -20)

func _spawn_zombie(spawn_position: Vector2):
	if not enemy_scene:
		print("❌ Erreur: enemy.tscn non trouvé!")
		return
	
	var zombie = enemy_scene.instantiate()
	zombie.global_position = spawn_position
	zombie.add_to_group("zombie")
	
	get_parent().add_child(zombie)
	
	# Effet d'apparition (fade uniquement, pas de scale)
	zombie.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.tween_property(zombie, "modulate", Color(1, 1, 1, 1), 0.5)
	
	print("🧟 Zombie spawné à ", zombie.global_position)

# ===== ⚡ DASH ATTACK =====
func _initiate_dash_attack():
	state = "dash_attack"
	dash_attack_timer = dash_attack_cooldown
	is_charging = true
	velocity.x = 0
	
	var dir = sign(player.global_position.x - global_position.x)
	sprite.flip_h = dir < 0
	sprite.play("idle")
	
	print("⚠️ DASH ATTACK EN CHARGE...")
	
	# Effet de charge intense (sans scale)
	for i in range(6):
		$AudioStreamPlayer2D8.play()
		sprite.modulate = Color(2, 0.2, 0.2)
		await get_tree().create_timer(0.08).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.08).timeout
	
	is_charging = false
	
	if player == null or not is_instance_valid(player):
		state = "random_walk"
		return
	
	dash_timer = dash_attack_duration
	print("💨 DASH!")
	$AudioStreamPlayer2D4.play()
	sprite.play("attaque")

func _do_dash_attack_state():
	if dash_timer <= 0:
		state = "chase" if player != null and is_instance_valid(player) else "random_walk"
		return
	
	var dir = 1 if not sprite.flip_h else -1
	velocity.x = dir * dash_attack_speed

# ===== 🎯 DÉTECTION COLLISION JOUEUR =====
func _on_hit_player(body):
	if dead or hurt:
		return
	
	if state == "dash_attack":
		if body.name == "Personnages" and is_instance_valid(body):
			if body.has_method("_die_hit_and_reset"):
				body._die_hit_and_reset(global_position)
				$AudioStreamPlayer2D5.play()
				$AudioStreamPlayer2D7.play()
				print("💥 Dash attack réussi!")
		return
	
	if attacking:
		return
	
	# Attaque normale avec combo
	if body.name == "Personnages" and is_instance_valid(body):
		attacking = true
		state = "attack"
		$AudioStreamPlayer2D7.play()
		$AudioStreamPlayer2D4.play()
		sprite.play("attaque")
		
		var time_since_last = Time.get_ticks_msec() / 1000.0 - last_attack_time
		if time_since_last < 3.0:
			combo_attack_count += 1
			if combo_attack_count >= 3:
				print("🔥 COMBO x", combo_attack_count, "!")
				sprite.speed_scale = 1.8
		else:
			combo_attack_count = 1
		
		last_attack_time = Time.get_ticks_msec() / 1000.0
		
		if body.has_method("_die_hit_and_reset"):
			$AudioStreamPlayer2D5.play()
			body._die_hit_and_reset(global_position)

	var anim_length = _get_animation_length("attaque")
	await get_tree().create_timer(anim_length).timeout

	sprite.speed_scale = 1.0
	attacking = false
	state = "chase" if player != null and is_instance_valid(player) else "random_walk"

func _get_animation_length(anim_name: String) -> float:
	var frames = sprite.get_sprite_frames()
	var frame_count = frames.get_frame_count(anim_name)
	if frame_count == 0:
		return 0.0
	var fps = frames.get_animation_speed(anim_name)
	if fps == 0:
		return 0.0
	return frame_count / fps

# ===== 💔 PRISE DE DÉGÂTS =====
func _on_head_hit(body):
	if dead:
		return
	if body.name != "Personnages" or not is_instance_valid(body):
		return

	if body.global_position.y < global_position.y:
		_take_damage()
		update_hearts()

		var direction = sign(body.global_position.x - global_position.x)
		if direction == 0:
			direction = 1
		body.velocity.x = 800 * direction
		body.velocity.y = -200

		state = "fleeing"
		fleeing_timer = flee_duration

func _take_damage():
	if hurt or dead:
		return
	
	hp -= 1
	hurt = true
	state = "hurt"
	$AudioStreamPlayer2D6.play()
	$AudioStreamPlayer2D.play()
	_flash_red()
	
	print("💢 Boss blessé! HP: ", hp, "/", max_hp)
	
	# Mode rage à 3 HP exactement
	if not is_enraged and hp <= enrage_threshold:
		_enter_rage_mode()
	
	if hp <= 0:
		_die()
		return
	
	sprite.play("hurt")
	await get_tree().create_timer(0.3).timeout
	hurt = false
	state = "chase" if player != null and is_instance_valid(player) else "random_walk"

func _enter_rage_mode():
	is_enraged = true
	print("😡 MODE RAGE ACTIVÉ!")
	
	# Effet visuel intense (sans changer la taille)
	for i in range(5):
		$AudioStreamPlayer2D8.play()
		sprite.modulate = Color(2, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	
	# Boost permanent
	chase_speed *= 1.3
	flee_speed *= 1.4
	dash_attack_speed *= 1.2

func _flash_red():
	var old = sprite.modulate
	sprite.modulate = Color(1.5, 0.2, 0.2)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(sprite):
		sprite.modulate = old

# ===== 💀 MORT ÉPIQUE =====
func _die():
	dead = true
	state = "dead"
	velocity = Vector2.ZERO
	print("💀 BOSS VAINCU!")
	$AudioStreamPlayer2D10.play()
	$AudioStreamPlayer2D9.play()
	sprite.play("meurt")
	
	# Effet de mort dramatique (sans rotation ni scale)
	for i in range(8):
		sprite.modulate = Color(1.5, 0.5, 0.5, 0.8)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1, 0.4)
		await get_tree().create_timer(0.1).timeout
	
	# Disparition finale
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	queue_free()

# ===== 🎯 DÉTECTION JOUEUR =====
func _on_player_detected(body):
	if dead:
		return
	if body.name == "Personnages" and is_instance_valid(body):
		player = body
		if fleeing_timer <= 0:
			state = "chase"
			$AudioStreamPlayer2D11.play()
			print("🎯 CIBLE VERROUILLÉE!")

func _on_player_left(body):
	if body == player:
		player = null
		if fleeing_timer <= 0:
			state = "random_walk"
			print("❓ Cible perdue...")

# ===== 🦘 ÉVITE LES ZOMBIES =====
func _on_body_entered(body):
	if dead or is_fireball_attacking:  # Ne pas sauter pendant l'attaque de feu
		return
	if body.is_in_group("zombie") and is_on_floor():
		velocity.y = jump_force * 0.7
		sprite.play("jump")
