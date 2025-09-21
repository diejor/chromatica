@tool
class_name MaskNode
extends Node

@onready var _vp: SubViewport   = $MaskViewport
@onready var _mask_cam: Camera2D = $MaskViewport/MaskCamera

var _tracked_cam_id: int = 0

func _ready() -> void:
	_vp.disable_3d = true
	_vp.world_2d = get_viewport().world_2d

	_mask_cam.make_current()
	_sync_sizes()
	get_tree().root.size_changed.connect(_sync_sizes)
	
func get_mask_texture() -> ViewportTexture:
	return _vp.get_texture()

func _process(_dt: float) -> void:
	var main_cam := get_viewport().get_camera_2d()
	if main_cam == null:
		return

	# If the current main camera changed, copy “static” settings once.
	if main_cam.get_instance_id() != _tracked_cam_id:
		_copy_static_from(main_cam)
		_tracked_cam_id = main_cam.get_instance_id()

	# Always mirror the live state.
	_mask_cam.global_position = main_cam.global_position
	_mask_cam.rotation = main_cam.rotation
	_mask_cam.zoom = main_cam.zoom

func _copy_static_from(src: Camera2D) -> void:
	_mask_cam.limit_left   = src.limit_left
	_mask_cam.limit_right  = src.limit_right
	_mask_cam.limit_top    = src.limit_top
	_mask_cam.limit_bottom = src.limit_bottom
	_mask_cam.limit_smoothed = src.limit_smoothed
	_mask_cam.anchor_mode = src.anchor_mode
	_mask_cam.offset = src.offset
	_mask_cam.position_smoothing_enabled = src.position_smoothing_enabled
	_mask_cam.position_smoothing_speed = src.position_smoothing_speed

func _sync_sizes() -> void:
	_vp.size = get_viewport().size
