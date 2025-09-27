class_name CrystalBody
extends StaticBody2D

@export var _color: LanternColor.LanternColors

@onready var animator = $AnimationPlayer
@onready var crystal = $Crystal

func _ready() -> void:
	propagate_call("update_color", [LanternColor.enum_to_color(_color)])
	animator.play("hover")
