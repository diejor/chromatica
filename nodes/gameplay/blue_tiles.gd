extends TileMapLayer

@onready var player: PlayerController = %Player

func _ready() -> void:
	player.on_lantern_changed.connect(on_lantern_changed)
	collision_enabled = false
	
func on_lantern_changed(is_active: bool, color: LanternColor.LanternColors):
	if is_active and color == LanternColor.LanternColors.BLUE:
		collision_enabled = true
	else:
		collision_enabled = false

func _bind_uniforms(mask_node: MaskNode) -> void:
	var root := get_tree().root
	var vis := root.get_visible_rect()
	var tex := mask_node.get_mask_texture()

	material.set_shader_parameter("mask_tex", tex)
	material.set_shader_parameter("visible_pos_px", vis.position)
	material.set_shader_parameter("visible_size_px", vis.size)
	material.set_shader_parameter("mask_size_px", tex.get_size())
