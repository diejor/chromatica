extends SubViewport

func _ready() -> void:
	await RenderingServer.frame_post_draw
	var cone_img: Image = $Cone.texture.get_image()
	get_texture().get_image().save_png("res://cone.png")
