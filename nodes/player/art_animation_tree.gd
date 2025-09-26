extends AnimationTree

@onready var player: PlayerController = $"../../.."
@onready var motor: PlayerMotor = $"../../../Motor"

@export var accel_eps := 0.5
@export var speed_eps := 0.5
@export var vy_eps := 0.5

@export var flip_forward_faces_left := true
@export var stop_threshold := 10.0  # Velocity threshold for stop animation

@onready var player_animation: AnimationPlayer = $"../ArtAnimationPlayer"

var _prev_v := Vector2.ZERO
var _face_dir := 0
var _is_stopping := false  # Track if the player is in the stopping phase

# Timer to manage the cooldown between fall animations
var fall_timer: SceneTreeTimer = null
@export var fall_animation_cooldown := 0.5  # Time in seconds before the fall animation can play again

var is_falling := false  # Flag to track if the player is falling

func _ready() -> void:
	active = true

func _physics_process(delta: float) -> void:
	assert(player, "Player reference should not be null")

	var v := player.linear_velocity
	var prev := _prev_v

	var grounded = motor._on_ground
	var accel_state := 0

	# Handle movement when grounded
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
			if (input_dir == 0 or input_opposes) and (absf(v.x) > stop_threshold or _is_stopping):
				accel_state = -1
				_is_stopping = true
			else:
				accel_state = 1
		else:
			if input_dir == 0:
				accel_state = 0																																																																																																										
		
		if absf(v.x) < 25.0 and _is_stopping:
			_is_stopping = false

		# Player has landed, stop falling
		if is_falling and grounded and v.y < 0:
			is_falling = false
		
	else:
		if v.y > vy_eps and fall_timer == null:
			fall_timer = get_tree().create_timer(fall_animation_cooldown, false, false)
			fall_timer.timeout.connect(_on_fall_timer_timeout)
		
		if fall_timer != null and fall_timer.time_left < 0.001 and !grounded and v.y > vy_eps:
			is_falling = true

		elif v.y < -vy_eps:
			accel_state = 1

	var desired_dir := 0
	if v.x >  speed_eps: desired_dir =  1
	elif v.x < -speed_eps: desired_dir = -1

	if desired_dir != 0 and desired_dir != _face_dir:
		var want_forward := (desired_dir == -1) == flip_forward_faces_left
		if want_forward:
			$"../..".scale.x = -1.0
		else:
			$"../..".scale.x = 1.0
		_face_dir = desired_dir
	
	if absf(v.x) < 25.0:
		set("parameters/TimeScale/scale", 1.0)
	else:
		var speed_factor =v.x / 75.
		set("parameters/TimeScale/scale", speed_factor)
	
	if is_falling:
		accel_state = -1
		
	var blend_state := Vector2(accel_state, 0.0 if grounded else 1.0)
	set("parameters/AnimationNodeStateMachine/Movement/blend_position", blend_state)

	_prev_v = v

# Callback function for the fall cooldown timer
func _on_fall_timer_timeout() -> void:
	fall_timer = null  # Reset the timer after it completes

func _sgn_eps(x: float, eps: float) -> int:
	if x >  eps: return  1
	if x < -eps: return -1
	return 0
