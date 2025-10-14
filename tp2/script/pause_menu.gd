extends Control

func _ready() -> void:
	$CanvasLayer/CenterContainer/AnimationPlayer.play("RESET")

func _process(delta: float) -> void:
	testEsc()

func resume() -> void:
	get_tree().paused = false
	$CanvasLayer/CenterContainer/AnimationPlayer.play_backwards("blur")

func paused() -> void:
	get_tree().paused = true
	$CanvasLayer/CenterContainer/AnimationPlayer.play("blur")

func testEsc() -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			paused()

func _on_resume_pressed() -> void:
	resume()

func _on_recommencer_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quitter_pressed() -> void:
	get_tree().quit()

func _on_pause_pressed() -> void:
	get_tree().paused
