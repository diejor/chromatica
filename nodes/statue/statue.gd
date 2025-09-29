@tool
class_name Statue
extends Node2D

signal statue_activated

@onready var lantern = $Art/Lantern
@onready var crystal = $Art/Crystal
@onready var animatior = $StatuePlayer

@export var lantern_color: LanternColor.LanternColors
@export var is_active = true
@export var makes_lantern_change = true

func _ready() -> void:
	propagate_call("update_color", [get_lantern_color()])
	is_active = not is_active
	switch()

func get_lantern_color() -> Color:
	return LanternColor.enum_to_color(lantern_color)

func off():
	propagate_call("turn_off")
	$Art/Lantern.animator.play_backwards("expand_lantern")
	$Art/Lantern/LanternLight.energy = 0.25
	is_active = false
	
func on():
	statue_activated.emit()
	propagate_call("turn_on")
	$Art/Lantern.animator.play("expand_lantern")
	$Art/Lantern/LanternLight.energy = 0.5
	is_active = true

func switch():
	if is_active:
		off()
	else:
		on()
		
func add_crystal(node: Interpolable):
	animatior.play("crystal_received")
	crystal.add_child(node)
