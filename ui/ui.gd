extends CanvasLayer

@onready var ui_animations = $UIAnimations

func _ready() -> void:	
	ui_animations.play("main_menu")

func player_won():
	ui_animations.play("win")

func _on_button_pressed() -> void:
	var music_bus := AudioServer.get_bus_index("Songs")
	AudioServer.set_bus_mute(music_bus, true)
	
	ui_animations.play("start_game")
	ui_animations.play("start_game")

func _set_gameplay_input(on: bool) -> void:
	get_tree().call_group("gameplay_input", "set_input_enabled", on)
