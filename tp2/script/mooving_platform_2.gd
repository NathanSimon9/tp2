extends CharacterBody2D
@export var move_distance: float = 200.0
@export var speed: float = 100.0
var start_position: Vector2
var direction := 1
func _ready():
	start_position = global_position
func _physics_process(delta):
	var movement = Vector2.RIGHT * speed * direction * delta
	move_and_collide(movement)
	if abs(global_position.x - start_position.x) >= move_distance:
		direction *= -1
