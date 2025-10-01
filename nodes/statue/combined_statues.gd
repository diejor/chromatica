class_name CombinedStatue
extends Node2D

signal player_won

var active_statues = 0

func _ready() -> void:
	player_won.connect(UI.player_won)
	$First.statue_activated.connect(increment_active_statues)
	$Second.statue_activated.connect(increment_active_statues)

func increment_active_statues(_statue: Statue):
	active_statues += 1
	if active_statues == 2:
		$Combined.switch()
