class_name Interpolable
extends Node2D

@export var lerp_speed: float = 5.0
@export var ignore_local = false

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
		
	var target := p.global_transform
	if not ignore_local:
		target *= _local_xform

	global_position = global_position.lerp(target.origin, lerp_speed * delta)
	rotation = lerp_angle(rotation, target.get_rotation(), lerp_speed * delta)

	var parent_flip = sign(p.scale.x)
	var target_scale = target.get_scale()
	
	scale.x = lerp(abs(scale.x), abs(target_scale.x), lerp_speed * delta) * parent_flip
	scale.y = lerp(abs(scale.y), abs(target_scale.y), lerp_speed * delta)
	
	_last_flip = parent_flip
