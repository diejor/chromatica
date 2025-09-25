extends RigidBody2D

@onready var player: PlayerController = %Player

func _ready() -> void:
	player.on_lantern_changed.connect(on_lantern_changed)
	mass = 10.

func on_lantern_changed(is_active: bool, color: LanternColor.LanternColors):
	if is_active and color == LanternColor.LanternColors.GREEN:
		mass = 1.
	else:
		mass = 10.
