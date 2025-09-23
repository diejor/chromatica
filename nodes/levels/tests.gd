extends Node2D

func _process(_delta: float) -> void:
	# show when jump is currently down (will be true for jump_pulse_hold_frames frames)
	if Input.is_action_pressed("jump"):
		print("jump: DOWN")

	# show the edge (if you also want to confirm just-pressed specifically)
	if Input.is_action_just_pressed("jump"):
		print("jump: JUST PRESSED")
