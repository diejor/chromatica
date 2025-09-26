extends Node2D

@export var lerp_speed: float = 10.0

var _local_xform := Transform2D.IDENTITY
var _last_flip := 1

func _ready():
	_local_xform = transform
	top_level = true
	_last_flip = sign(get_parent().scale.x)

func _process(delta):
	var p := get_parent() as Node2D
	if p == null:
		return

	var target := p.global_transform * _local_xform

	# Interpolate position and rotation normally
	global_position = global_position.lerp(target.origin, lerp_speed * delta)
	rotation = lerp_angle(rotation, target.get_rotation(), lerp_speed * delta)

	# Handle scale separately to avoid mirroring/flip issues
	var parent_flip = sign(p.scale.x)
	var target_scale := target.get_scale()
	
	# Keep scale magnitude interpolated
	scale.x = lerp(abs(scale.x), abs(target_scale.x), lerp_speed * delta) * parent_flip
	scale.y = lerp(abs(scale.y), abs(target_scale.y), lerp_speed * delta)
	
	_last_flip = parent_flip
