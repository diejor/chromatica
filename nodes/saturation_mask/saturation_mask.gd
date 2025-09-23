extends Maskable

@onready var _mask_node: MaskNode = $"../MaskNode"

func _ready() -> void:
	var propagate = propagate_call.bind("_bind_uniforms", [_mask_node])
	propagate.call()
	
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(propagate)
	_mask_node._vp.size_changed.connect(propagate)
