extends CanvasLayer

@onready var ui_animations = $UIAnimations

func _ready() -> void:	
	$SongMixer.play("main_theme")
	$UIAnimations.play("main_menu")

func player_won():
	$UIAnimations.play("win")

func _on_button_pressed() -> void:
	ui_animations.play("start_game")

func _set_gameplay_input(on: bool) -> void:
	get_tree().call_group("gameplay_input", "set_input_enabled", on)
