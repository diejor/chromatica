@tool
extends Polygon2D

@export var initial_color: LanternColor.LanternColors

func _ready() -> void:
	color = LanternColor.enum_to_color(initial_color)

func update_color(new_color: Color):
	color = new_color
	initial_color = LanternColor.color_to_enum(new_color)
