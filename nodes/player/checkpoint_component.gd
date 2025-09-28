extends Node

@onready var player_animation: AnimationPlayer = $"../PlayerVisuals/PlayerArt/ArtAnimationPlayer"
@onready var animation_tree: AnimationTree = $"../PlayerVisuals/PlayerArt/ArtAnimationTree"
@onready var lantern_component = $"../LanternComponent"

var _teleporting := false

func _process(_delta: float) -> void:
	if not _teleporting and Input.is_action_just_pressed("checkpoint"):
		teleport_to_last_statue()

func teleport_to_last_statue() -> bool:
	if _teleporting:
		return false
	if not lantern_component.last_active_statue:
		return false
	var statue = lantern_component.last_active_statue
	_teleporting = true

	var root = $".."
	var prev_input_enabled: bool = root.input_enabled
	root.set_input_enabled(false)

	var prev_active := animation_tree and animation_tree.active
	if animation_tree:
		animation_tree.active = false
	if player_animation:
		player_animation.play("die")
		await player_animation.animation_finished
	var player := root as Node2D
	player.global_position = statue.global_position
	if player_animation:
		player_animation.play_backwards("die")
		await player_animation.animation_finished
	if animation_tree:
		animation_tree.active = prev_active

	root.set_input_enabled(prev_input_enabled)

	_teleporting = false
	return true
