extends TileMapLayer

@onready var player: PlayerController = %Player

func _ready() -> void:
	player.on_lantern_changed.connect(on_lantern_changed)
	collision_enabled = false
	
func on_lantern_changed(is_active: bool, color: LanternColor.LanternColors):
	if is_active and LanternColor.enum_has_color(color, Color.BLUE):
		collision_enabled = true
	else:
		collision_enabled = false
