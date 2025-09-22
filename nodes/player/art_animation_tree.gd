extends AnimationTree

@export var player: PlayerController

@export var accel_eps := 0.5     # units/s^2
@export var speed_eps := 0.5     # units/s
@export var vy_eps := 0.5        # units/s
@export var landing_freeze_time := 0.08  # brief post-landing debounce

# If the forward "flip" animation ends facing LEFT, leave this true.
# If yours ends facing RIGHT, set this to false in the inspector.
@export var flip_forward_faces_left := true

@onready var flip_animation: AnimationPlayer = $"../FlipAnimationPlayer"

var _prev_v := Vector2.ZERO
var _was_grounded := false
var _landing_freeze := false
var _landing_serial := 0  # prevents older awaits from unfreezing a newer landing
var _face_dir := 0        # -1 = left, 0 = idle/unknown, +1 = right

func _ready() -> void:
	active = true

func _physics_process(delta: float) -> void:
	assert(player, "Player reference should not be null")

	var v := player.linear_velocity
	var prev := _prev_v

	var grounded = player._on_ground
	var accel_state := 0

	# Start debounce when landing (air -> ground)
	if grounded and not _was_grounded:
		_start_landing_freeze()

	# --- ACCEL X (your spec) ---
	if grounded:
		if not _landing_freeze:
			# finite-difference on |vx| avoids sign-flip at zero crossing
			var d_abs_vx_dt := (absf(v.x) - absf(prev.x)) / delta
			if absf(v.x) < speed_eps:
				d_abs_vx_dt = 0.0
			if d_abs_vx_dt > accel_eps:
				accel_state = 1
			elif d_abs_vx_dt < -accel_eps:
				accel_state = -1
			else:
				accel_state = 0
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

	# feed BlendSpace2D: (x: accel_state, y: grounded as 0/1 per your mapping)
	var blend_state := Vector2(accel_state, 0.0 if grounded else 1.0)
	set("parameters/Movement/blend_position", blend_state)

	_prev_v = v
	_was_grounded = grounded

# --- landing freeze using SceneTree.create_timer on physics step ---
func _start_landing_freeze() -> void:
	_landing_freeze = true
	_landing_serial += 1
	var my_serial := _landing_serial
	await get_tree().create_timer(landing_freeze_time, true, true).timeout
	if my_serial == _landing_serial:
		_landing_freeze = false
