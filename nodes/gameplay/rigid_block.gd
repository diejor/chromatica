extends RigidBody2D

@onready var player: PlayerController = %Player
@onready var default_mass = mass

func _ready() -> void:
	player.on_lantern_changed.connect(on_lantern_changed)
	mass = default_mass * 100.

func on_lantern_changed(is_active: bool, color: LanternColor.LanternColors):
	if is_active and LanternColor.enum_has_color(color, Color.GREEN):
		mass = default_mass
	else:
		mass = default_mass * 100.
