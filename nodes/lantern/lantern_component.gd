extends Node2D

@onready var sfx_player: AnimationPlayer = $"../SFX/LanternPlayer"
@onready var lantern = $"../PlayerVisuals/InterpolateLantern/Lantern"
@onready var crystal_pouch = $"../PlayerVisuals/CrystalPouch"

@export var current_color: LanternColor.LanternColors

var is_lantern_active = false
var current_statue: Statue

func _ready() -> void:
	lantern.on_lantern_changed.connect(on_internal_lantern_changed)
	lantern.update_color(LanternColor.enum_to_color(current_color))

func expand_lantern():
	lantern.animator.play("expand_lantern")
	sfx_player.play("glass_ding")
	is_lantern_active = true
	
func shut_lantern():
	lantern.animator.play_backwards("expand_lantern")
	sfx_player.play("shovel")
	await lantern.animator.animation_finished
	is_lantern_active = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("lantern"):
		if not is_lantern_active:
			expand_lantern()
		else:
			shut_lantern()
		
	if Input.is_action_just_pressed("interact"):
		if current_statue and current_statue.is_active:
			var was_active = is_lantern_active
			await shut_lantern()
				
			lantern.update_color(current_statue.get_lantern_color())
			current_color = current_statue.lantern_color
			if was_active:
				expand_lantern()

func on_internal_lantern_changed(is_active: bool):
	$"..".on_lantern_changed.emit(is_active, current_color)

func _on_interact_area_body_entered(body: Node2D) -> void:
	current_statue = body as Statue
	for crystal in crystal_pouch.pouch.get_children():
		if crystal.initial_color == current_statue.lantern_color and not current_statue.is_active:
			crystal_pouch.pouch.remove_child(crystal)
			var interpolable = Interpolable.new()
			interpolable.global_position = crystal_pouch.global_position
			interpolable.add_child(crystal)
			current_statue.crystal.add_child(interpolable)
			sfx_player.play("crystal_released")
			current_statue.switch()

func _on_interact_area_body_exited(_body: Node2D) -> void:
	current_statue = null


func _on_pickup_area_body_entered(body: Node2D) -> void:
	var cb := body as CrystalBody
	if cb:
		cb.animator.stop()
		crystal_pouch.absorb_crystal(cb.crystal, cb)
		sfx_player.play("crystal_pickup")
