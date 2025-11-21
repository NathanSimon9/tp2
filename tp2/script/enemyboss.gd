extends CharacterBody2D

@export var walk_speed := 80.0
@export var chase_speed := 370.0
@export var jump_force := -420.0
@export var gravity := 1400.0
@export var max_hp := 10
@export var flee_duration := 2.0
@export var flee_speed := 700.0

# ===== FONCTIONNALITÉS DE BASE =====
@export var enrage_threshold := 3
@export var dash_attack_speed := 900.0
@export var dash_attack_cooldown := 5.0
@export var dash_attack_duration := 0.5

# ===== ATTAQUE BOULES DE FEU 🔥 =====
@export var fireball_attack_cooldown := 8.0
@export var fireball_count := 6
@export var fireball_delay := 0.3

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
var fireball_scene = preload("res://scenes/BouleDeFeu.tscn")
var attack_pattern := 0

var hearts = []
var sprite: AnimatedSprite2D
var hit_head: Area2D
var hit_player: Area2D
var detection_area: Area2D

var random_direction := 0
var random_timer := 0.0
@export var random_walk_time := 2.0

# ===== VARIABLES VICTOIRE =====
var victory_triggered := false
var camera_original_pos := Vector2.ZERO
var camera_original_zoom := Vector2.ONE

func _ready():
	# Récupérer les nœuds
	sprite = get_node_or_null("AnimatedSprite2D")
	hit_head = get_node_or_null("HitHead")
	hit_player = get_node_or_null("HitPlayer")
	detection_area = get_node_or_null("Detection")
	
	# Récupérer les coeurs
	var canvas = get_node_or_null("../CanvasLayer/HBoxContainer2")
	if canvas:
		hearts = canvas.get_children()
	
	# Connexions sécurisées - vérifie que les nœuds existent
	if hit_head:
		hit_head.body_entered.connect(_on_head_hit)
		print("✅ HitHead connecté")
	else:
		print("⚠️ HitHead introuvable!")
	
	if hit_player:
		hit_player.body_entered.connect(_on_hit_player)
		print("✅ HitPlayer connecté")
	else:
		print("⚠️ HitPlayer introuvable!")
	
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_left)
		print("✅ Detection connecté")
	else:
		print("⚠️ Detection introuvable!")

	if sprite:
		sprite.play("idle")
	
	update_hearts()
	
	print("🔥 BOSS READY - HP: ", hp, "/", max_hp)

func update_hearts():
	for i in range(len(hearts)):
		if i < hp:
			hearts[i].texture = preload("res://medias/coeur.png")
		else:
			hearts[i].texture = preload("res://medias/coeur_vide.png")

func _physics_process(delta: float):
	if dead:
		return

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

	velocity.y += gravity * delta

	if is_charging or is_fireball_attacking:
		velocity.x = 0
		move_and_slide()
		return

	match state:
		"fireball_attack":
			pass
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

	if hp <= 7 and summon_timer <= 0:
		_summon_zombies()
		return
	
	if hp <= 5 and fireball_attack_timer <= 0 and distance < 500:
		attack_pattern = (attack_pattern + 1) % 3
		if attack_pattern == 0:
			_initiate_fireball_attack()
			return
	
	if is_enraged and dash_attack_timer <= 0 and distance < 400 and distance > 100:
		_initiate_dash_attack()
		return

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
	
	for i in range(4):
		$AudioStreamPlayer2D3.play()
		sprite.modulate = Color(2, 0.5, 0.1)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	
	for i in range(fireball_count):
		if state != "fireball_attack":  
			break
		
		sprite.play("attaque")
		_spawn_fireball()
		$AudioStreamPlayer2D12.play()
		
		sprite.modulate = Color(2, 0.7, 0.2)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		
		await get_tree().create_timer(fireball_delay).timeout
	
	is_fireball_attacking = false
	
	if player != null and is_instance_valid(player):
		state = "chase"
	else:
		state = "random_walk"

func _spawn_fireball():
	if not fireball_scene:
		print("❌ Erreur: BouleDeFeu.tscn non trouvé!")
		return
	
	var fireball = fireball_scene.instantiate()
	
	var spawn_offset = Vector2(60 if not sprite.flip_h else -60, -20)
	fireball.global_position = global_position + spawn_offset
	
	var direction = Vector2.ZERO
	if player != null and is_instance_valid(player):
		direction = (player.global_position - fireball.global_position).normalized()
		var angle_variation = randf_range(-0.3, 0.3)
		direction = direction.rotated(angle_variation)
	else:
		direction = Vector2(1 if not sprite.flip_h else -1, 0)
	
	if fireball.has_method("set_direction"):
		fireball.set_direction(direction)
	elif "direction" in fireball:
		fireball.direction = direction
	
	get_parent().add_child(fireball)

func _summon_zombies():
	state = "attack"
	velocity.x = 0
	summon_timer = summon_cooldown
	summoning_active = true
	
	print("🧟 INVOCATION DE LA HORDE!")
	sprite.play("attaque")
	
	for i in range(5):
		sprite.modulate = Color(0.8, 0.3, 1)
		$AudioStreamPlayer2D3.play()
		await get_tree().create_timer(0.12).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.12).timeout
	
	var zombie_count = randi_range(3, 5) if is_enraged else randi_range(2, 3)
	$AudioStreamPlayer2D2.play()
	
	for i in range(zombie_count):
		var offset = Vector2(randf_range(-250, 250), randf_range(-80, 20))
		var spawn_pos = _find_safe_spawn_position(offset)
		_spawn_zombie(spawn_pos)
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(0.5).timeout
	summoning_active = false
	
	state = "chase" if player != null and is_instance_valid(player) else "random_walk"

func _find_safe_spawn_position(offset: Vector2) -> Vector2:
	var test_pos = global_position + offset
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = test_pos
	query.collision_mask = 1
	query.exclude = [self]
	
	var result = space_state.intersect_point(query, 1)
	
	if result.is_empty():
		return test_pos
	
	var opposite_offset = Vector2(-offset.x, offset.y)
	test_pos = global_position + opposite_offset
	query.position = test_pos
	result = space_state.intersect_point(query, 1)
	
	if result.is_empty():
		return test_pos
	
	return global_position + Vector2(50 if randf() > 0.5 else -50, -20)

func _spawn_zombie(spawn_position: Vector2):
	if not enemy_scene:
		return
	
	var zombie = enemy_scene.instantiate()
	zombie.global_position = spawn_position
	zombie.add_to_group("zombie")
	
	get_parent().add_child(zombie)
	
	zombie.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.tween_property(zombie, "modulate", Color(1, 1, 1, 1), 0.5)

func _initiate_dash_attack():
	state = "dash_attack"
	dash_attack_timer = dash_attack_cooldown
	is_charging = true
	velocity.x = 0
	
	var dir = sign(player.global_position.x - global_position.x)
	sprite.flip_h = dir < 0
	sprite.play("idle")
	
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
	$AudioStreamPlayer2D4.play()
	sprite.play("attaque")

func _do_dash_attack_state():
	if dash_timer <= 0:
		state = "chase" if player != null and is_instance_valid(player) else "random_walk"
		return
	
	var dir = 1 if not sprite.flip_h else -1
	velocity.x = dir * dash_attack_speed

func _on_hit_player(body):
	if dead or hurt or victory_triggered:
		return
	
	if state == "dash_attack":
		if body.name == "Personnages" and is_instance_valid(body):
			if body.has_method("_die_hit_and_reset"):
				body._die_hit_and_reset(global_position)
				$AudioStreamPlayer2D5.play()
				$AudioStreamPlayer2D7.play()
		return
	
	if attacking:
		return
	
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
	
	if not is_enraged and hp <= enrage_threshold and hp > 0:
		_enter_rage_mode()
	
	if hp <= 0:
		print("💀 DERNIER COUP! Ralentissement...")
		Engine.time_scale = 0.3
		_die()
		return
	
	sprite.play("hurt")
	await get_tree().create_timer(0.3).timeout
	hurt = false
	state = "chase" if player != null and is_instance_valid(player) else "random_walk"

func _enter_rage_mode():
	is_enraged = true
	print("😡 MODE RAGE ACTIVÉ!")
	
	for i in range(5):
		$AudioStreamPlayer2D8.play()
		sprite.modulate = Color(2, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	
	chase_speed *= 1.3
	flee_speed *= 1.4
	dash_attack_speed *= 1.2

func _flash_red():
	var old = sprite.modulate
	sprite.modulate = Color(1.5, 0.2, 0.2)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(sprite):
		sprite.modulate = old

# ===== 💀 MORT AVEC SÉQUENCE DE VICTOIRE ÉPIQUE =====
func _die():
	dead = true
	state = "dead"
	velocity = Vector2.ZERO
	print("💀 BOSS VAINCU!")
	
	if player and player.has_method("set_invincible"):
		player.set_invincible(true)
	
	$AudioStreamPlayer2D10.play()
	$AudioStreamPlayer2D9.play()
	sprite.play("meurt")
	sprite.speed_scale = 2.0
	
	for i in range(6):
		sprite.modulate = Color(1.5, 0.5, 0.5, 0.8)
		await get_tree().create_timer(0.05).timeout
		sprite.modulate = Color(1, 1, 1, 0.4)
		await get_tree().create_timer(0.05).timeout
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	sprite.speed_scale = 1.0
	_trigger_victory_sequence()

# ===== 🎉 SÉQUENCE DE VICTOIRE INSANE =====
func _trigger_victory_sequence():
	if victory_triggered:
		return
	victory_triggered = true
	
	print("🎉 DÉCLENCHEMENT SÉQUENCE VICTOIRE")
	
	if player and is_instance_valid(player):
		print("🧊 Tentative de figer le joueur...")
		if "can_move" in player:
			player.can_move = false
			print("✅ Joueur figé")
		else:
			print("⚠️ Le joueur n'a pas de propriété 'can_move'")
		
		player.velocity = Vector2.ZERO
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("repos")
	
	_victory_animation_insane()

func _victory_animation_insane():
	# PHASE 1: Freeze frame dramatique
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	# PHASE 2: EXPLOSION MASSIVE + SCREEN SHAKE
	await _epic_explosion()
	_screen_shake_extreme()
	
	if player and is_instance_valid(player):
		player.velocity = Vector2.ZERO
		if "can_move" in player:
			player.can_move = false
	
	Engine.time_scale = 1.0
	
	# PHASE 3: Animation RESET
	var anim_player = get_node_or_null("../AnimationPlayer")
	if anim_player and anim_player.has_animation("RESET"):
		anim_player.play("RESET")
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	if player and is_instance_valid(player):
		player.velocity = Vector2.ZERO
		if "can_move" in player:
			player.can_move = false
	
	# PHASE 4: Flash photographique ultra bright
	await _photo_flash()
	
	# PHASE 5: Texte VICTOIRE explosif
	await _show_epic_victory_text()
	
	# PHASE 6: CONFETTIS FESTIFS - Démarrage continu
	_spawn_continuous_confetti()
	
	await get_tree().create_timer(2.0).timeout
	
	# PHASE 7: GÉNÉRIQUE DE FIN
	await _show_end_credits()
	
	_transition_next_level()

# 💥 EXPLOSION MASSIVE
func _epic_explosion():
	var canvas = get_node_or_null("../CanvasLayer")
	if not canvas:
		return
	
	# Créer plusieurs cercles d'explosion
	for i in range(5):
		await get_tree().create_timer(0.1).timeout

# 📷 FLASH PHOTOGRAPHIQUE
func _photo_flash():
	var canvas = get_node_or_null("../CanvasLayer")
	if not canvas:
		return
	
	var flash = ColorRect.new()
	flash.color = Color(10, 10, 10, 1)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 150
	canvas.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	flash.queue_free()

# 🎬 TEXTE VICTOIRE SIMPLE ET CENTRÉ
func _show_epic_victory_text():
	var canvas = get_node_or_null("../CanvasLayer")
	if not canvas:
		return
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	canvas.add_child(overlay)
	
	var label = Label.new()
	label.text = "VICTOIRE!"
	label.add_theme_font_size_override("font_size", 80)
	label.modulate = Color(1, 1, 0, 0)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.pivot_offset = label.size / 2
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 101
	canvas.add_child(label)
	
	var tween1 = create_tween()
	tween1.tween_property(overlay, "color", Color(0, 0, 0, 0.7), 1.0)
	
	await get_tree().create_timer(0.5).timeout
	
	label.scale = Vector2(0.1, 0.1)
	label.rotation = -0.5
	
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(label, "modulate:a", 1.0, 0.5)
	tween2.tween_property(label, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween2.tween_property(label, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await tween2.finished
	
	var tween3 = create_tween()
	tween3.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

# 🎊 CONFETTIS CONTINUS PENDANT TOUTE LA SÉQUENCE
var confetti_active := false

func _spawn_continuous_confetti():
	confetti_active = true
	_confetti_loop()

func _confetti_loop():
	while confetti_active:
		var viewport_size = get_viewport().get_visible_rect().size
		
		# Spawner 5 confettis à la fois
		for i in range(5):
			var confetti = ColorRect.new()
			
			# Palette de couleurs festives
			var colors = [
				Color(1, 0, 0),      # Rouge
				Color(1, 0.5, 0),    # Orange
				Color(1, 1, 0),      # Jaune
				Color(0, 1, 0),      # Vert
				Color(0, 0.5, 1),    # Bleu
				Color(1, 0, 1),      # Magenta
				Color(1, 0.75, 0.8), # Rose
				Color(1, 1, 1)       # Blanc
			]
			confetti.color = colors[randi() % colors.size()]
			
			# Tailles variées
			var size = Vector2(randf_range(10, 25), randf_range(10, 25))
			confetti.custom_minimum_size = size
			
			# Spawn en haut sur toute la largeur
			confetti.position = Vector2(randf_range(0, viewport_size.x), randf_range(-300, -100))
			confetti.z_index = 105
			
			var canvas = get_node_or_null("../CanvasLayer")
			if canvas:
				canvas.add_child(confetti)
				
				var tween = create_tween()
				tween.set_parallel(true)
				# Tomber vers le bas
				tween.tween_property(confetti, "position:y", viewport_size.y + 100, randf_range(3, 6))
				# Léger mouvement horizontal (balancement)
				tween.tween_property(confetti, "position:x", confetti.position.x + randf_range(-150, 150), randf_range(3, 6))
				# Rotation pendant la chute
				tween.tween_property(confetti, "rotation", randf_range(-PI * 6, PI * 6), randf_range(3, 6))
				
				tween.finished.connect(confetti.queue_free)
		
		await get_tree().create_timer(0.3).timeout
	
	print("🎊 Confettis arrêtés")

# 📜 GÉNÉRIQUE DE FIN IMPACTANT
func _show_end_credits():
	var canvas = get_node_or_null("../CanvasLayer")
	if not canvas:
		return
	
	# Fond noir complet
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	canvas.add_child(overlay)
	
	var tween_bg = create_tween()
	tween_bg.tween_property(overlay, "color", Color(0, 0, 0, 1), 1.5)
	await tween_bg.finished
	
	# Texte du générique - plus court et impactant
	var credits_lines = [
		{ "text": "Après un combat épique...", "size": 42 },
		{ "text": "", "size": 20 },
		{ "text": "Tu as vaincu le terrible Boss", "size": 48, "gold": true },
		{ "text": "et libéré le royaume !", "size": 44 },
		{ "text": "", "size": 20 },
		{ "text": "La Princesse est sauvée", "size": 50, "gold": true },
		{ "text": "", "size": 20 },
		{ "text": "Les villageois te proclament", "size": 42 },
		{ "text": "HÉROS DU ROYAUME !", "size": 60, "gold": true, "special": true },
		{ "text": "", "size": 20 },
		{ "text": "✨ FÉLICITATIONS ✨", "size": 70, "gold": true, "special": true }
	]
	
	var container = VBoxContainer.new()
	container.anchor_left = 0.5
	container.anchor_top = 0.5
	container.anchor_right = 0.5
	container.anchor_bottom = 0.5
	container.pivot_offset = Vector2(400, 0)
	container.position = Vector2(-400, -250)
	container.custom_minimum_size = Vector2(800, 0)
	container.add_theme_constant_override("separation", 20)
	container.z_index = 201
	canvas.add_child(container)
	
	# Afficher chaque ligne progressivement
	for line_data in credits_lines:
		var label = Label.new()
		label.text = line_data["text"]
		label.add_theme_font_size_override("font_size", line_data["size"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate = Color(1, 1, 1, 0)
		
		# Couleur dorée pour les lignes importantes
		if line_data.get("gold", false):
			label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		
		container.add_child(label)
		
		# IMPORTANT: Calculer le pivot_offset APRÈS l'ajout au conteneur
		await get_tree().process_frame
		label.pivot_offset = label.size / 2
		
		# Animation d'apparition plus dramatique pour les lignes spéciales
		if line_data.get("special", false):
			label.scale = Vector2(0.5, 0.5)
			var label_tween = create_tween()
			label_tween.set_parallel(true)
			label_tween.tween_property(label, "modulate:a", 1.0, 0.6)
			label_tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			
			# Effet de pulse continu
			await label_tween.finished
			var pulse = create_tween()
			pulse.set_loops()
			pulse.tween_property(label, "scale", Vector2(1.15, 1.15), 0.8)
			pulse.tween_property(label, "scale", Vector2(1.1, 1.1), 0.8)
		else:
			# Animation normale
			var label_tween = create_tween()
			label_tween.tween_property(label, "modulate:a", 1.0, 0.7)
		
		await get_tree().create_timer(0.5).timeout
	
	# Attendre avant de continuer
	await get_tree().create_timer(3.5).timeout
	
	# Arrêter les confettis
	confetti_active = false
	
	# Faire disparaître le générique
	var fade_out = create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(overlay, "modulate:a", 0.0, 2.0)
	fade_out.tween_property(container, "modulate:a", 0.0, 2.0)
	await fade_out.finished
	
	overlay.queue_free()
	container.queue_free()

# 📳 SCREEN SHAKE EXTRÊME
func _screen_shake_extreme():
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	camera_original_pos = camera.offset
	
	for i in range(20):
		camera.offset = camera_original_pos + Vector2(
			randf_range(-30, 30),
			randf_range(-30, 30)
		)
		await get_tree().create_timer(0.05).timeout
	
	# Retour progressif
	var tween = create_tween()
	tween.tween_property(camera, "offset", camera_original_pos, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _transition_next_level():
	print("🎬 Début transition...")
	
	Engine.time_scale = 1.0
	
	var canvas = get_node_or_null("../CanvasLayer")
	if canvas:
		var overlay = ColorRect.new()
		overlay.color = Color(0, 0, 0, 0)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.z_index = 150
		canvas.add_child(overlay)
		
		var tween = create_tween()
		tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 1.0)
		await tween.finished
		print("⬛ Fade to black terminé")
	else:
		await get_tree().create_timer(1.0).timeout
	
	if player and is_instance_valid(player):
		print("🔓 Déverrouillage du joueur...")
		player.can_move = true
		player.velocity = Vector2.ZERO
		if player.has_method("set_invincible"):
			player.set_invincible(false)
	
	print("🌍 Changement de scène vers niveau_1...")
	get_tree().change_scene_to_file("res://scenes/niveau_1.tscn")

func _on_player_detected(body):
	if dead:
		return
	if body.name == "Personnages" and is_instance_valid(body):
		player = body
		if fleeing_timer <= 0:
			state = "chase"
			$AudioStreamPlayer2D11.play()

func _on_player_left(body):
	if body == player:
		player = null
		if fleeing_timer <= 0:
			state = "random_walk"

func _on_body_entered(body):
	if dead or is_fireball_attacking:
		return
	if body.is_in_group("zombie") and is_on_floor():
		velocity.y = jump_force * 0.7
		sprite.play("jump")
