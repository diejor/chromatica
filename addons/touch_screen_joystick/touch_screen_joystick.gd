## Responsive joystick control tool for your 
## Godot mobile games. It triggers input actions
## based on your touch and drag inputs.

@tool
@icon("res://addons/touch_screen_joystick/icon.png")
extends Control
class_name TouchScreenJoystick

@export var antialiased : bool = false : 
	set(b):
		antialiased = b
		queue_redraw()
		
@export var only_mobile: bool = true

@export_range(0, 9999, 0.1, "hide_slider")
var deadzone : float= 25.0 : 
	set(n):
		deadzone = n
		queue_redraw()

@export_range(0, 9999, 0.1, "hide_slider")
var base_radius : float = 120.0 :
	set(value):
		base_radius = value
		queue_redraw()

@export_range(0, 9999, 0.1, "hide_slider")
var knob_radius : float = 45.0 :
	set(value):
		knob_radius = value
		queue_redraw()

@export_group("Texture Joystick")
@export var use_textures : bool = false :
	set(value):
		use_textures = value
		queue_redraw()

@export_subgroup("Base")
@export var base_texture : Texture2D :
	set(value):
		base_texture = value
		queue_redraw()
@export var base_scale : Vector2 = Vector2.ONE :
	set(value):
		base_scale = value
		queue_redraw()

@export_subgroup("Knob")
@export var knob_texture : Texture2D :
	set(value):
		knob_texture = value
		queue_redraw()
@export var knob_scale : Vector2 = Vector2.ONE :
	set(value):
		knob_scale = value
		queue_redraw()

@export_group("Style")
@export var color : Color = Color.WHITE :
	set(value):
		color = value
		queue_redraw()
@export var back_color : Color = Color(Color.BLACK, 0.5):
	set(value):
		back_color = value
		queue_redraw()
@export_range(0, 999, 0.1, "hide_slider")
var thickness := 3.0 :
	set(value):
		thickness = value
		queue_redraw()

@export_group("Input Actions")
@export var use_input_actions : bool = true
@export var action_left : StringName = "move_left"
@export var action_right : StringName = "move_right"
@export var action_up : StringName = "move_up"
@export var action_down : StringName = "move_down"
@export var jump_action : StringName = "jump"
@export_range(0.0, 1.0) var jump_threshold := 0.55
@export var jump_pulse_hold_frames := 2

@export_group("Debug")
@export var show_debug : bool :
	set(value):
		show_debug = value
		queue_redraw()
@export var deadzone_debug_color : Color = Color.RED :
	set(value):
		deadzone_debug_color = value
		queue_redraw()
@export var base_debug_color : Color = Color.GREEN :
	set(value):
		base_debug_color = value
		queue_redraw()

signal on_press
signal on_release
signal on_drag(factor : float)
signal jumped

var knob_position : Vector2
var is_pressing : bool
var event_index : int = -1
var _prev_up_gate := false
var _jump_release_frames := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	reset_knob()

func _draw() -> void:
	if not is_pressing:
		reset_knob()
	if not use_textures:
		draw_default_joystick()
	else:
		draw_texture_joystick()
	if show_debug:
		draw_debug()

func draw_default_joystick() -> void:
	draw_circle(size / 2.0, base_radius, back_color)
	draw_circle(size / 2.0, base_radius, color, false, thickness, antialiased)
	draw_circle(knob_position, knob_radius, color, true, -1.0, antialiased)

func draw_texture_joystick() -> void:
	if base_texture:
		var base_size := base_texture.get_size() * base_scale
		draw_texture_rect(base_texture, Rect2(size / 2.0 - (base_size / 2.0), base_size), false)
	if knob_texture:
		var knob_size := knob_texture.get_size() * knob_scale
		draw_texture_rect(knob_texture, Rect2(knob_position - (knob_size / 2.0), knob_size), false)

func draw_debug() -> void:
	draw_circle(size / 2.0, deadzone, deadzone_debug_color, false, 5.0)
	draw_circle(size / 2.0, base_radius, base_debug_color, false, 5.0)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)

func _process(_dt: float) -> void:
	if _jump_release_frames > 0:
		_jump_release_frames -= 1
		if _jump_release_frames == 0:
			_emit_action_event(jump_action, false)

func _to_local_touch(global_pos: Vector2) -> Vector2:
	return (global_pos - global_position) / scale

func _inside_base(global_pos: Vector2) -> bool:
	var p := _to_local_touch(global_pos)
	return p.distance_to(size / 2.0) <= base_radius

func _inside_knob(global_pos: Vector2) -> bool:
	var p := _to_local_touch(global_pos)
	return p.distance_to(knob_position) <= knob_radius

func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and event_index == -1 and (_inside_base(event.position) or _inside_knob(event.position)):
		event_index = event.index
		is_pressing = true
		_move_knob(event.position)
		on_press.emit()
		get_viewport().set_input_as_handled()
	else:
		_release(event.index)

func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index == event_index and is_pressing:
		_move_knob(event.position)
		get_viewport().set_input_as_handled()
		on_drag.emit(get_factor())

func _move_knob(event_pos : Vector2) -> void:
	var center := size / 2.0
	var touch_pos := _to_local_touch(event_pos)
	var distance := touch_pos.distance_to(center)
	var angle := center.angle_to_point(touch_pos)
	if distance < base_radius:
		knob_position = touch_pos
	else:
		knob_position.x = center.x + cos(angle) * base_radius
		knob_position.y = center.y + sin(angle) * base_radius
	if distance > deadzone:
		_trigger_actions()
	else:
		_reset_actions()
	_check_jump_gate()
	queue_redraw()

func _release(index : int) -> void:
	if index == event_index:
		_reset_actions()
		reset_knob()
		event_index = -1
		is_pressing = false
		_prev_up_gate = false
		_jump_release_frames = 0
		_emit_action_event(jump_action, false)
		on_release.emit()
		get_viewport().set_input_as_handled()

func _trigger_actions() -> void:
	if not use_input_actions:
		return
	var direction := get_direction().normalized()
	if direction.x < 0.0:
		Input.action_release(action_right)
		Input.action_press(action_left, -direction.x)
	elif direction.x > 0.0:
		Input.action_release(action_left)
		Input.action_press(action_right, direction.x)
	if direction.y < 0.0:
		Input.action_release(action_down)
		Input.action_press(action_up, -direction.y)
	elif direction.y > 0.0:
		Input.action_release(action_up)
		Input.action_press(action_down, direction.y)

func _reset_actions() -> void:
	Input.action_release(action_left)
	Input.action_release(action_right)
	Input.action_release(action_up)
	Input.action_release(action_down)

func get_direction() -> Vector2:
	var center := size / 2.0
	return center.direction_to(knob_position)

func get_distance() -> float:
	var center := size / 2.0
	return center.distance_to(knob_position)

func get_angle() -> float:
	var center := size / 2.0
	return center.angle_to_point(knob_position)

func get_factor() -> float:
	var center := size / 2.0
	var distance := center.distance_to(knob_position)
	return distance / base_radius

func is_in_deadzone() -> bool:
	var center := size / 2.0
	var distance := center.distance_to(knob_position)
	return distance < deadzone

func reset_knob() -> void:
	knob_position = size / 2.0
	queue_redraw()

func _check_jump_gate() -> void:
	var center := size / 2.0
	var v := ((knob_position - center) / base_radius).limit_length(1.0)
	var up_gate := (-v.y) >= jump_threshold and is_pressing
	if up_gate and not _prev_up_gate and _jump_release_frames == 0:
		jumped.emit()
		_emit_action_event(jump_action, true)
		_jump_release_frames = jump_pulse_hold_frames
	_prev_up_gate = up_gate

func _emit_action_event(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _on_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lantern"):
		print("lantern!")
		accept_event()
		get_viewport().set_input_as_handled()
