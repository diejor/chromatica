extends PointLight2D

func update_color(_color: Color):
	color = _color

func turn_on():
	visible = true
	
func turn_off():
	visible = false
