@tool
extends Node2D

@onready var flame_color: Color = $Flame.color
var is_active = true

func update_color(_color: Color):
	flame_color = _color
	if is_active:
		turn_on()

func turn_off():
	$Flame.color = Color.BLACK
	is_active = false

func turn_on():
	$Flame.color = flame_color
	is_active = true
