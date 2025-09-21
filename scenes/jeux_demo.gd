extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var camera = find_child("Camera2D")
	var min_pos = $cameralimit_start.global_position
	var max_pos = $cameralimite_end.global_position
	camera.limit_left = min_pos.x
	camera.limit_top = min_pos.y
	camera.limit_right = max_pos.x
	camera.limit_bottom = max_pos.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
