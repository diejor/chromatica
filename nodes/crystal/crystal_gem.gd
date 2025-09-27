class_name CrystalGem
extends Sprite2D

@export var _color: LanternColor.LanternColors

@export var red_gem: AtlasTexture
@export var blue_gem: AtlasTexture
@export var green_gem: AtlasTexture
@export var purple_gem: AtlasTexture
@export var yellow_gem: AtlasTexture
@export var cyan_gem: AtlasTexture

func _ready() -> void:
	_apply_color()

func update_color(c: Color) -> void:
	_color = LanternColor.color_to_enum(c)
	_apply_color()

func _apply_color() -> void:
	match _color:
		LanternColor.LanternColors.RED:    texture = red_gem
		LanternColor.LanternColors.BLUE:   texture = blue_gem
		LanternColor.LanternColors.GREEN:  texture = green_gem
		LanternColor.LanternColors.PURPLE: texture = purple_gem
		LanternColor.LanternColors.YELLOW: texture = yellow_gem
		LanternColor.LanternColors.CYAN:   texture = cyan_gem
		_:                                  texture = null
