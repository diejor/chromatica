@tool
extends Node2D

@export var lerp_speed: float = 10.
@export var player: Node2D
@export var pos: Vector2

func _ready():
	top_level = true

func _process(delta):
	var target_global_position = player.global_position + pos

	position = position.lerp(target_global_position, lerp_speed * delta)
