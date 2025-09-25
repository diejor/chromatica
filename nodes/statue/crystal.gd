extends Polygon2D

@onready var crystal_color = color
var is_active = true

func update_color(_color: Color):
	crystal_color = _color
	if is_active:
		turn_on()

func turn_off():
	color = Color.BLACK
	is_active = false
	
func turn_on():
	color = crystal_color
	is_active = true
