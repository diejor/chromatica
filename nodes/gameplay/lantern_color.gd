class_name LanternColor
extends Node

enum LanternColors {
	RED,
	GREEN,
	BLUE
}

static func enum_to_color(enm: LanternColor.LanternColors) -> Color:
	match enm:
		LanternColors.RED:
			return Color.RED
		LanternColors.GREEN:
			return Color.GREEN
		LanternColors.BLUE:
			return Color.BLUE
	return Color.BLACK
