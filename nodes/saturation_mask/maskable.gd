class_name Maskable
extends Node2D

func _bind_uniforms(mask_node: MaskNode) -> void:
	var root := get_tree().root
	var vis := root.get_visible_rect()
	var tex := mask_node.get_mask_texture()

	material.set_shader_parameter("mask_tex", tex)
	material.set_shader_parameter("visible_pos_px", vis.position)
	material.set_shader_parameter("visible_size_px", vis.size)
	material.set_shader_parameter("mask_size_px", tex.get_size())
