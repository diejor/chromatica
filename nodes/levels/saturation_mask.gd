extends Node2D

@export var shader: Shader

@onready var _mat := ShaderMaterial.new()
@onready var _mask_node: MaskNode = $"../MaskNode" 

func _ready() -> void:
	assert(shader, "Shader should bet for the mask to have an effect")
	_mat.shader = shader
	material = _mat

	_apply_mask_to_material()

	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_apply_mask_to_material)
	_mask_node._vp.size_changed.connect(_apply_mask_to_material)

func _apply_mask_to_material() -> void:
	var tex = _mask_node.get_mask_texture()
	var tex_size = _mask_node.get_mask_size()
	_mat.set_shader_parameter("mask_tex", tex)
	_mat.set_shader_parameter("mask_tex_size", tex_size)
