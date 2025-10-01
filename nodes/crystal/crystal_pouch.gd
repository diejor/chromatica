class_name CrystalPouch
extends Node2D

@onready var pouch := $InterpolatePouch

@export var spawn_radius: float = 16.0
@export var fly_time: float = 0.35

func absorb_crystal(n: Node2D, source: Node) -> void:
	n.reparent(pouch, true)
	var ang := randf() * TAU
	var target := Vector2(cos(ang), sin(ang)) * spawn_radius
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "position", target, fly_time)
	tw.tween_callback(func ():
		if is_instance_valid(source): source.queue_free()
	)
