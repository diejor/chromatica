extends Node

signal on_lantern_changed(is_active: bool)

@onready var lantern_animator: AnimationPlayer = $"../Visuals/LanternComponent/LanternAnimations"

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("lantern"):
		lantern_animator.play("expand_lantern")
	if Input.is_action_just_released("lantern"):
		lantern_animator.play_backwards("expand_lantern")
	
func emit_lantern_signal(is_active: bool):
	on_lantern_changed.emit(is_active)
