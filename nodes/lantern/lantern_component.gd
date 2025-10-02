extends Node2D

@onready var sfx_player: AnimationPlayer = $"../SFX/LanternPlayer"
@onready var lantern = $"../PlayerVisuals/InterpolateLantern/Lantern"
@onready var crystal_pouch = $"../PlayerVisuals/CrystalPouch"

@export var current_color: LanternColor.LanternColors

var is_lantern_active = false
var current_statue: Statue
var last_active_statue: Statue

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

func _unhandled_input(event: InputEvent) -> void:
	if not $"..".input_enabled:
		return
	if event.is_action_pressed("lantern"):
		if not is_lantern_active:
			expand_lantern()
		else:
			shut_lantern()

func on_internal_lantern_changed(is_active: bool):
	$"..".on_lantern_changed.emit(is_active, current_color)

func _on_interact_area_body_entered(body: Node2D) -> void:
	current_statue = body as Statue
	for crystal in crystal_pouch.pouch.get_children():
		if crystal.initial_color == current_statue.lantern_color and not current_statue.is_active:
			crystal_pouch.pouch.remove_child(crystal)
			var interpolable = Interpolable.new()
			interpolable.ignore_local = true
			interpolable.show_behind_parent = true
			interpolable.position = crystal_pouch.pouch.position
			interpolable.add_child(crystal)
			current_statue.add_crystal(interpolable)
			current_statue.switch()

	if current_statue and current_statue.is_active and current_statue.makes_lantern_change:
		last_active_statue = current_statue

	if current_statue and current_statue.is_active and current_color != current_statue.lantern_color and current_statue.makes_lantern_change:
		var was_active = is_lantern_active
		if is_lantern_active:
			await shut_lantern()
		lantern.update_color(current_statue.get_lantern_color())
		sfx_player.play("color_switched")
		current_color = current_statue.lantern_color
		if was_active:
			expand_lantern()
			
	if current_statue and current_statue.is_combined and not current_statue.statue_activated.is_connected(track_combined_statue_changed):
		current_statue.statue_activated.connect(track_combined_statue_changed)
		
func track_combined_statue_changed(statue: Statue):
	assert(statue.is_combined, "Tracking should be done in a combined statue")
	if statue.is_active and current_color != statue.lantern_color and statue.makes_lantern_change:
		var was_active = is_lantern_active
		if is_lantern_active:
			await shut_lantern()
		lantern.update_color(statue.get_lantern_color())
		sfx_player.play("color_switched")
		current_color = statue.lantern_color
		if was_active:
			expand_lantern()

func _on_interact_area_body_exited(_body: Node2D) -> void:
	current_statue = null

func _on_pickup_area_body_entered(body: Node2D) -> void:
	var cb := body as CrystalBody
	if cb:
		cb.animator.stop()
		crystal_pouch.absorb_crystal(cb.crystal, cb)
		sfx_player.play("crystal_pickup")
