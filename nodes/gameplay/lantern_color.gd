class_name LanternColor
extends Node

enum LanternColors {
	BLACK,
	RED,
	ORANGE,
	YELLOW,
	GREEN,	
	BLUE,
	PURPLE,
	WHITE,
}

static func enum_to_color(enm: LanternColor.LanternColors) -> Color:
	match enm:
		LanternColors.BLACK:
			return Color.BLACK
		LanternColors.RED:
			return Color.RED
		LanternColors.ORANGE:
			return Color.ORANGE
		LanternColors.YELLOW:
			return Color.YELLOW
		LanternColors.GREEN:
			return Color.GREEN
		LanternColors.BLUE:
			return Color.BLUE
		LanternColors.PURPLE:
			return Color.PURPLE
		LanternColors.WHITE:
			return Color.WHITE
	return Color.BLACK

const _R := 1
const _G := 2
const _B := 4

static func _enum_mask(enm: LanternColor.LanternColors) -> int:
	match enm:
		LanternColors.BLACK:  return 0
		LanternColors.RED:    return _R
		LanternColors.GREEN:  return _G
		LanternColors.BLUE:   return _B
		LanternColors.YELLOW: return _R | _G
		LanternColors.PURPLE: return _R | _B
		LanternColors.ORANGE: return _R | _G
		LanternColors.WHITE:  return _R | _G | _B
	return 0

static func _color_mask(c: Color, tol := 0.01) -> int:
	var m := 0
	if c.r > tol: m |= _R
	if c.g > tol: m |= _G
	if c.b > tol: m |= _B
	return m

static func enum_has_color(enm: LanternColor.LanternColors, color: Color) -> bool:
	var want := _color_mask(color)
	var have := _enum_mask(enm)
	return (have & want) == want

static func color_to_enum(c: Color, tol := 0.01) -> LanternColor.LanternColors:
	var m := _color_mask(c, tol)
	match m:
		0:             return LanternColors.BLACK
		_R:            return LanternColors.RED
		_G:            return LanternColors.GREEN
		_B:            return LanternColors.BLUE
		_R | _G:       return LanternColors.ORANGE if c.g < c.r * 0.85 else LanternColors.YELLOW
		_R | _B:       return LanternColors.PURPLE
		_G | _B:       return LanternColors.BLUE if c.b >= c.g else LanternColors.GREEN
		_R | _G | _B:  return LanternColors.WHITE
	return LanternColors.BLACK
