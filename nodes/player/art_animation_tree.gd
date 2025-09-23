extends AnimationTree

@onready var player: PlayerController = $"../../.."
@onready var motor: PlayerMotor = $"../../../Motor"

@export var accel_eps := 0.5
@export var speed_eps := 0.5
@export var vy_eps := 0.5

@export var flip_forward_faces_left := true

@onready var flip_animation: AnimationPlayer = $"../FlipAnimationPlayer"

var _prev_v := Vector2.ZERO
var _face_dir := 0

func _ready() -> void:
	active = true

func _physics_process(delta: float) -> void:
	assert(player, "Player reference should not be null")

	var v := player.linear_velocity
	var prev := _prev_v

	var grounded = motor._on_ground
	var accel_state := 0

	if grounded:
		var in_x := Input.get_vector("move_left", "move_right", "move_up", "move_down").x
		var input_dir := _sgn_eps(in_x, 0.2)
		var vel_dir := _sgn_eps(v.x, speed_eps)

		var d_abs_vx_dt := (absf(v.x) - absf(prev.x)) / delta
		if absf(v.x) < speed_eps:
			d_abs_vx_dt = 0.0

		if d_abs_vx_dt > accel_eps:
			accel_state = 1
		elif d_abs_vx_dt < -accel_eps:
			var input_opposes := (input_dir != 0 and vel_dir != 0 and input_dir != vel_dir)
			if input_dir == 0 or input_opposes:
				accel_state = -1
			else:
				accel_state = 1
		else:
			accel_state = 0
	else:
		if v.y < -vy_eps:
			accel_state = 1
		elif v.y > vy_eps:
			accel_state = -1
		else:
			accel_state = 0

	var desired_dir := 0
	if v.x >  speed_eps: desired_dir =  1
	elif v.x < -speed_eps: desired_dir = -1

	if flip_animation and desired_dir != 0 and desired_dir != _face_dir:
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
