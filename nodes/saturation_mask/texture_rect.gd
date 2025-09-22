@tool
extends TextureRect

func _ready() -> void:
	texture = $"../MaskNode".get_mask_texture()
	
func _process(_delta: float) -> void:
	size = texture.get_size()
