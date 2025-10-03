extends CanvasLayer

@onready var ui_animations = $UIAnimations
@onready var joystick: TouchScreenJoystick = $Joystick
@onready var lantern_button: TouchScreenButton = $LanternButton
@onready var jump_button: TouchScreenButton = $JumpButton


func _ready() -> void:	
	ui_animations.play("main_menu")

func player_won():
	ui_animations.play("win")

func _on_button_pressed() -> void:
	var music_bus := AudioServer.get_bus_index("Songs")
	AudioServer.set_bus_mute(music_bus, true)
	
	ui_animations.play("start_game")
	ui_animations.play("start_game")


func _is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios")

func _set_gameplay_input(on: bool) -> void:
	get_tree().call_group("gameplay_input", "set_input_enabled", on)

	if joystick.only_mobile and _is_mobile():
		joystick.visible = on
		lantern_button.visible = on
		jump_button.visible = on
