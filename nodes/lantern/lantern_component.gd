extends Node2D

signal on_lantern_changed(is_active: bool)

@onready var lantern_animator: AnimationPlayer = $"../PlayerVisuals/LanternArt/LanternAnimations"

var is_lantern_active = false
var current_statue: Statue
var current_color: LanternColor.LanternColors

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("lantern"):
		lantern_animator.play("expand_lantern")
		is_lantern_active = true
	if Input.is_action_just_released("lantern") and is_lantern_active:
		lantern_animator.play_backwards("expand_lantern")
		is_lantern_active = false
		
	if Input.is_action_just_pressed("interact"):
		if current_statue:
			var was_active = is_lantern_active
			if is_lantern_active:
				lantern_animator.play_backwards("expand_lantern")
				await lantern_animator.animation_finished
				is_lantern_active = false
				
			$"../PlayerVisuals/LanternArt/LanternLight".color = current_statue.get_lantern_color()
			current_color = current_statue.lantern_color
			if was_active:
				lantern_animator.play("expand_lantern")
				is_lantern_active = true
			
			current_statue.switch()
	
func emit_lantern_signal(is_active: bool):
	on_lantern_changed.emit(is_active, current_color)

func _on_interact_area_body_entered(body: Node2D) -> void:
	current_statue = body as Statue

func _on_interact_area_body_exited(body: Node2D) -> void:
	current_statue = null
