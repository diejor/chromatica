extends Node2D

@onready var _mask_node: MaskNode = $"../MaskNode"

func _ready() -> void:
	_bind_uniforms()

	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_bind_uniforms)
	_mask_node._vp.size_changed.connect(_bind_uniforms)

func _bind_uniforms() -> void:
	var root := get_tree().root
	var vis := root.get_visible_rect()
	var tex := _mask_node.get_mask_texture()

	material.set_shader_parameter("mask_tex", tex)
	material.set_shader_parameter("visible_pos_px", vis.position)
	material.set_shader_parameter("visible_size_px", vis.size)
	material.set_shader_parameter("mask_size_px", tex.get_size())
