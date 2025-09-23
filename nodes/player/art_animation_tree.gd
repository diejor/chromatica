extends AnimationTree

@export var player: PlayerController

@export var accel_eps := 0.5     # units/s^2
@export var speed_eps := 0.5     # units/s
@export var vy_eps := 0.5        # units/s

# If the forward "flip" animation ends facing LEFT, leave this true.
# If yours ends facing RIGHT, set this to false in the inspector.
@export var flip_forward_faces_left := true

@onready var flip_animation: AnimationPlayer = $"../FlipAnimationPlayer"

var _prev_v := Vector2.ZERO
var _face_dir := 0        # -1 = left, 0 = idle/unknown, +1 = right

func _ready() -> void:
	active = true

func _physics_process(delta: float) -> void:
	assert(player, "Player reference should not be null")

	var v := player.linear_velocity
	var prev := _prev_v

	var grounded = player._on_ground
	var accel_state := 0

	# --- ACCEL X (grounded) ---
	if grounded:
		# player horizontal input (-1..1)
		var in_x := Input.get_vector("move_left", "move_right", "move_up", "move_down").x
		var input_dir := _sgn_eps(in_x, 0.2)         # small input deadzone
		var vel_dir := _sgn_eps(v.x, speed_eps)      # velocity direction with your deadzone

		# finite-difference on |vx| avoids sign-flip at zero crossing
		var d_abs_vx_dt := (absf(v.x) - absf(prev.x)) / delta
		if absf(v.x) < speed_eps:
			d_abs_vx_dt = 0.0

		if d_abs_vx_dt > accel_eps:
			accel_state = 1
		elif d_abs_vx_dt < -accel_eps:
			# Only allow STOP (deceleration) if no input **or** input opposes velocity
			var input_opposes := (input_dir != 0 and vel_dir != 0 and input_dir != vel_dir)
			if input_dir == 0 or input_opposes:
				accel_state = -1      # STOP
			else:
				accel_state = 1       # keep RUN since player is holding the direction
		else:
			accel_state = 0
	else:
		# Airborne: +1 going up, -1 falling, 0 near apex
		if v.y < -vy_eps:
			accel_state = 1
		elif v.y > vy_eps:
			accel_state = -1
		else:
			accel_state = 0

	# --- FLIP when horizontal direction changes past deadzone ---
	var desired_dir := 0
	if v.x >  speed_eps: desired_dir =  1
	elif v.x < -speed_eps: desired_dir = -1

	if flip_animation and desired_dir != 0 and desired_dir != _face_dir:
		# decide forward vs backward based on how your flip anim is authored
		var want_forward := (desired_dir == -1) == flip_forward_faces_left
		if want_forward:
			flip_animation.play("flip")
		else:
			flip_animation.play_backwards("flip")
		_face_dir = desired_dir

	var blend_state := Vector2(accel_state, 0.0 if grounded else 1.0)
	set("parameters/Movement/blend_position", blend_state)

	_prev_v = v

func _sgn_eps(x: float, eps: float) -> int:
	if x >  eps: return  1
	if x < -eps: return -1
	return 0
