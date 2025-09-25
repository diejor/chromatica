@tool
class_name Statue
extends Maskable

@export var lantern_color: LanternColor.LanternColors
var is_active = true

func _ready() -> void:
	propagate_call("update_color", [get_lantern_color()])

func get_lantern_color() -> Color:
	return LanternColor.enum_to_color(lantern_color)

func off():
	propagate_call("turn_off")
	is_active = false
	
func on():
	propagate_call("turn_on")
	is_active = true

func switch():
	if is_active:
		off()
	else:
		on()
