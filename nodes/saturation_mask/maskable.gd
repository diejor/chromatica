class_name Maskable
extends Node2D

func _bind_uniforms(mask_node: MaskNode) -> void:
	assert(material, "A Maskable node must have a material set")
	var tex := mask_node.get_mask_texture()

	material.set_shader_parameter("mask_tex", tex)
