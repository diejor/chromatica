extends Sprite2D

@onready var atlas_texture = texture

@export var save_path: String

func save_texture_to_disk(path: String):
	var image: Image = atlas_texture.get_image()

	var error = image.save_png(path)
	if error != OK:
		print("Error saving image: ", error)
	else:
		print("AtlasTexture region saved to: ", path)

func _ready():
	save_texture_to_disk(save_path)
