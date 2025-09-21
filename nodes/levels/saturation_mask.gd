extends Node2D

@onready var _mask_node: MaskNode = $"../MaskNode" 

func _ready() -> void:
	var tex = _mask_node.get_mask_texture()
	material.set_shader_parameter("mask_tex", tex)
