@tool
class_name StatueArt
extends Sprite2D

@export var _color: LanternColor.LanternColors

@export var red_statue: AtlasTexture
@export var blue_statue: AtlasTexture
@export var green_statue: AtlasTexture
@export var purple_statue: AtlasTexture
@export var yellow_statue: AtlasTexture
@export var cyan_statue: AtlasTexture

func _ready() -> void:
	_apply_color()

func update_color(c: Color) -> void:
	_color = LanternColor.color_to_enum(c)
	_apply_color()

func _apply_color() -> void:
	match _color:
		LanternColor.LanternColors.RED:    texture = red_statue
		LanternColor.LanternColors.BLUE:   texture = blue_statue
		LanternColor.LanternColors.GREEN:  texture = green_statue
		LanternColor.LanternColors.PURPLE: texture = purple_statue
		LanternColor.LanternColors.YELLOW: texture = yellow_statue
		LanternColor.LanternColors.CYAN:   texture = cyan_statue
		_:                                  texture = null
