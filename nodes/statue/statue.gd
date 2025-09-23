@tool
class_name Statue
extends Maskable

@export var lantern_color: LanternColor.LanternColors

func _ready() -> void:
	$LanternLight.color = get_lantern_color()

func get_lantern_color() -> Color:
	return LanternColor.enum_to_color(lantern_color)
