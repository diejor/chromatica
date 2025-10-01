extends Node

@onready var player: PlayerController = $".."
@onready var motor: PlayerMotor = $"../Motor"
@onready var player_animation: AnimationPlayer = $"../PlayerVisuals/PlayerArt/ArtAnimationPlayer"
@onready var animation_tree: AnimationTree = $"../PlayerVisuals/PlayerArt/ArtAnimationTree"
@onready var player_visuals = $"../PlayerVisuals"
@onready var jump_player = $"../SFX/JumpPlayer"

@export var accel_eps := 0.5
@export var speed_eps := 0.5
@export var vy_eps := 0.5
@export var flip_forward_faces_left := true
@export var stop_threshold := 50.0

@export var GROUNDED_ENTER_DELAY := 0.02 
@export var GROUNDED_EXIT_GRACE  := 0.10 
@export var FALL_ENTER_DELAY     := 0.08

var _prev_v := Vector2.ZERO
var _face_dir := 0
var _is_stopping := false

var _grounded_smoothed := false
var _ground_enter_accum := 0.0
var _ground_exit_accum := 0.0

var is_falling := false
var _fall_accum := 0.0

func _physics_process(delta: float) -> void:
	assert(player, "Player reference should not be null")

	var v := player.linear_velocity
	var prev := _prev_v

	# debounce grounded
	var grounded_raw := motor._on_ground
	if grounded_raw:
		_ground_enter_accum += delta
		_ground_exit_accum = 0.0
	else:
		_ground_exit_accum += delta
		_ground_enter_accum = 0.0

	if _grounded_smoothed:
		if _ground_exit_accum >= GROUNDED_EXIT_GRACE:
			_grounded_smoothed = false
	else:
		if _ground_enter_accum >= GROUNDED_ENTER_DELAY:
			_grounded_smoothed = true

	var grounded := _grounded_smoothed
	var accel_state := 0

	# common inputs / dirs
	var in_x := Input.get_vector("move_left", "move_right", "move_up", "move_down").x
	var input_dir := _sgn_eps(in_x, 0.2)
	var vel_dir := _sgn_eps(v.x, speed_eps)
	var has_input := input_dir != 0
	var input_matches_velocity := (has_input and vel_dir != 0 and input_dir == vel_dir)
	var at_speed_cap := false
	if motor and "eff_max_speed" in motor:
		at_speed_cap = absf(v.x) >= motor.eff_max_speed() - 1.0

	# movement when grounded
	if grounded:
		var d_abs_vx_dt := (absf(v.x) - absf(prev.x)) / delta
		if absf(v.x) < speed_eps:
			d_abs_vx_dt = 0.0

		if d_abs_vx_dt > accel_eps:
			accel_state = 1
		elif d_abs_vx_dt < -accel_eps:
			var input_opposes := (has_input and vel_dir != 0 and input_dir != vel_dir)
			if (not has_input or input_opposes) and (absf(v.x) > stop_threshold or _is_stopping):
				accel_state = -1
				_is_stopping = true
			else:
				accel_state = 1
		else:
			if input_matches_velocity and (at_speed_cap or absf(v.x) > speed_eps):
				accel_state = 1
			elif not has_input:
				accel_state = 0
			else:
				accel_state = 1

		if absf(v.x) < 25.0 and _is_stopping:
			_is_stopping = false

		# landed -> cancel falling immediately
		is_falling = false
		_fall_accum = 0.0

	else:
		# falling debounce
		if v.y > vy_eps:
			_fall_accum += delta
			if _fall_accum >= FALL_ENTER_DELAY:
				is_falling = true
		else:
			_fall_accum = 0.0
			if v.y < -vy_eps:
				is_falling = false
				accel_state = 1

	# face direction / flip
	var desired_dir := 0
	if v.x >  speed_eps: desired_dir =  1
	elif v.x < -speed_eps: desired_dir = -1

	if desired_dir != 0 and desired_dir != _face_dir:
		var want_forward := (desired_dir == -1) == flip_forward_faces_left
		player_visuals.scale.x = -1.0 if want_forward else 1.0
		_face_dir = desired_dir
	
	# run cycle speed scale
	if absf(v.x) < 25.0:
		animation_tree.set("parameters/TimeScale/scale", 1.0)
	else:
		var speed_factor := v.x / 75.0
		animation_tree.set("parameters/TimeScale/scale", speed_factor)
	
	if is_falling:
		accel_state = -1
	
	var blend_state := Vector2(accel_state, 0.0 if grounded else 1.0)
	animation_tree.set("parameters/AnimationNodeStateMachine/Movement/blend_position", blend_state)

	_prev_v = v

func _sgn_eps(x: float, eps: float) -> int:
	if x >  eps: return  1
	if x < -eps: return -1
	return 0

func _on_motor_jumped() -> void:
	jump_player.play("jump")
