class_name MainStatue
extends Node2D

signal player_won

var active_statues = 0

func _ready() -> void:
	player_won.connect(UI.player_won)
	$YellowCrystal.statue_activated.connect(increment_active_statues)
	$CyanCrystal.statue_activated.connect(increment_active_statues)
	$PurpleCrystal.statue_activated.connect(increment_active_statues)

func increment_active_statues(_statue: Statue):
	active_statues += 1
	if active_statues == 3:
		player_won.emit()
