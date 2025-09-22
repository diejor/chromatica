extends Node2D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("lantern"):
		$LanternAnimations.play("expand_lantern")
	if Input.is_action_just_released("lantern"):
		$LanternAnimations.play_backwards("expand_lantern")
