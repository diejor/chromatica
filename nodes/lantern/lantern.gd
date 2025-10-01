@tool
extends Node2D

@onready var animator: AnimationPlayer = $LanternAnimations

signal on_lantern_changed(is_active: bool)

func emit_lantern_signal(is_active: bool):
	on_lantern_changed.emit(is_active)

func update_color(_color: Color):
	$LanternLight.update_color(_color)
