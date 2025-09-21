extends RigidBody2D

@export var LINEAR_FORCE = 500
@export var MAX_SPEED = 200
@export var JUMP_FORCE = 210
@export var WALL_JUMP_FORCE = 200
@export var WALL_JUMP_VERTICAL_MULTIPLIER = 1.0
@export var WALL_JUMP_HORIZONTAL_LIMIT = 120
@export var WALL_GRAB_GRAVITY_MULTIPLIER = 0.1
@export var JUMP_HOVER_COOLDOWN = 0.2
@export var DEBUG_MODE = false
@export var DRAW_SCALE = 1.0
@export var DAMPING_COEFFICIENT = 10
@export var HORIZONTAL_TO_VERTICAL_RATIO = 0.0
@export var AIR_CONTROL_MULTIPLIER = 1.0
@export var HOVER_RAY_LENGTH = 20.0
@export var HOVER_SPRING_CONSTANT = 1000
@export var HOVER_DAMPING = 50.0
@export var RIDE_HEIGHT = 15.0
@export var HOVER_FORCE_MULTIPLIER = 0.5
@export var COYOTE_TIME = 0.1
@export var WALL_JUMP_MIN_UP_SPEED := 220.0

@export var POWER := 1.0
@export var MOVE_POWER_SCALE := 1.0
@export var JUMP_POWER_SCALE := 1.0
@export var WALL_POWER_SCALE := 1.0
@export var SPEED_POWER_SCALE := 1.0
@export var POWER_EXP := 1.0

func _p(k: float, w: float = 1.0, exp: float = POWER_EXP) -> float:
	return k * pow(max(POWER * w, 0.0), exp)

func eff_linear_force() -> float: return _p(LINEAR_FORCE, MOVE_POWER_SCALE)
func eff_jump_force() -> float: return _p(JUMP_FORCE, JUMP_POWER_SCALE)
func eff_wall_jump_force() -> float: return _p(WALL_JUMP_FORCE, WALL_POWER_SCALE)
func eff_wall_jump_min_up() -> float: return _p(WALL_JUMP_MIN_UP_SPEED, WALL_POWER_SCALE)
func eff_max_speed() -> float: return _p(MAX_SPEED, SPEED_POWER_SCALE)

var _coyote_time_counter = 0.0
var _last_ground_normal = Vector2.ZERO
var _applied_force = Vector2.ZERO
var _gravity_force = Vector2.ZERO
var _velocity_last_frame = Vector2.ZERO
var _contact_points = []
var _contact_normals = []
var _normal = Vector2.ZERO
var _jump_requested = false
var _on_ground = false
var _is_near_wall = false
var _is_grabbing_wall = false
var _hover_disabled = false

func _ready() -> void:
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 10

# Process input to initiate jump
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") and (_on_ground or _coyote_time_counter > 0 or _is_near_wall):
		_jump_requested = true
	queue_redraw()

# Integrate physics and apply forces
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	_contact_points.clear()
	_contact_normals.clear()
	_gravity_force = state.get_total_gravity()

	var _was_on_ground = _on_ground
	_on_ground = false
	_is_near_wall = false
	_is_grabbing_wall = false

	# Check for collisions and wall interactions
	for i in range(state.get_contact_count()):
		var _local_contact_point = self.to_local(state.get_contact_local_position(i))
		var _local_contact_normal = state.get_contact_local_normal(i).normalized()
		_contact_points.append(_local_contact_point)
		_contact_normals.append(_local_contact_normal)

		if _local_contact_normal.x != 0:
			_is_near_wall = true
			if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
				_is_grabbing_wall = true

	if _is_grabbing_wall:
		_gravity_force *= WALL_GRAB_GRAVITY_MULTIPLIER
	else:
		_gravity_force = state.get_total_gravity()

	# Check hover state and apply forces
	if _hover_disabled:
		pass
	else:
		var _from = transform.origin
		var _to = _from + Vector2.DOWN * HOVER_RAY_LENGTH
		var _space_state = get_world_2d().direct_space_state
		var _ray_params = PhysicsRayQueryParameters2D.create(_from, _to)
		var _result = _space_state.intersect_ray(_ray_params)

		if _result:
			_on_ground = true
			_contact_points.append(_result.position)
			_contact_normals.append(_result.normal)
			state.apply_central_force(-_gravity_force)
			var _hit_point = _result.position
			var _distance = (_hit_point - _from).length()
			var _displacement = _distance - RIDE_HEIGHT

			var _velocity = state.get_linear_velocity()
			var _ray_direction = Vector2.DOWN.normalized()
			var _velocity_along_ray = _velocity.dot(_ray_direction)

			var _spring_force = HOVER_SPRING_CONSTANT * _displacement
			var _damping_force = -HOVER_DAMPING * _velocity_along_ray
			var _total_hover_force = (_spring_force + _damping_force) * _ray_direction * HOVER_FORCE_MULTIPLIER
			state.apply_central_force(_total_hover_force)

	# Combine normal contact forces
	var _add = func (_acc, _a):
		if abs(_a.x) > 0.1:
			_a *= 0.01
		return _acc + _a
	_normal = _contact_normals.reduce(_add, Vector2.ZERO).normalized()

	if _on_ground:
		_last_ground_normal = _normal

	# Handle movement and input forces
	var _current_velocity = state.get_linear_velocity()
	var _current_speed = _current_velocity.length()
	var _factor = clamp(1.0 - (_current_speed / eff_max_speed()), 0.0, 1.0)

	var _move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var _move_len = _move_input.length_squared()
	var _desired_direction = _move_input.normalized()

	if _move_len > 0:
		_applied_force = _desired_direction * eff_linear_force() * _factor
	else:
		_applied_force = Vector2.ZERO

	if _on_ground:
		var _horizontal_velocity = Vector2(_current_velocity.x, 0)
		var _damping_factor = 0.1

		if _current_velocity.x * _desired_direction.x < 0:
			_damping_factor = 1.0
			_applied_force.x = _desired_direction.x * eff_linear_force() * _factor

		var _damping_force = -_horizontal_velocity.normalized() * DAMPING_COEFFICIENT * _current_speed * _damping_factor
		state.apply_central_force(_damping_force)

	# Apply normal sliding force
	if _normal.length_squared() > 0:
		_applied_force = _applied_force.slide(_normal)
	state.apply_central_force(_applied_force)

	# Damping when not moving
	if _current_speed > 0 and _move_len == 0:
		var _horizontal_velocity2 = Vector2(_current_velocity.x, 0)
		var _damping_force2 = -_horizontal_velocity2.normalized() * DAMPING_COEFFICIENT * _current_speed
		state.apply_central_force(_damping_force2)

	# Jump logic with coyote time and wall jump
	if _jump_requested:
		if _on_ground:
			state.apply_central_impulse(eff_jump_force() * _normal)
			var _velocity2 = state.get_linear_velocity()
			var _normal_velocity = _velocity2.project(_normal)
			var _tangent_velocity = _velocity2 - _normal_velocity
			var _transfer_velocity = _tangent_velocity * HORIZONTAL_TO_VERTICAL_RATIO
			_velocity2 -= _transfer_velocity
			_velocity2 += _normal_velocity.normalized() * _transfer_velocity.length() * 0.2
			state.set_linear_velocity(_velocity2)
			_hover_disabled = true
			get_tree().create_timer(JUMP_HOVER_COOLDOWN).timeout.connect(_enable_hover)
			_jump_requested = false
		elif _coyote_time_counter > 0:
			state.apply_central_impulse(eff_jump_force() * _last_ground_normal)
			_hover_disabled = true
			get_tree().create_timer(JUMP_HOVER_COOLDOWN).timeout.connect(_enable_hover)
			_jump_requested = false
		elif _is_near_wall:
			var _wall_n = _contact_normals[0]
			var _impulse_x = clamp(_wall_n.x * eff_wall_jump_force(), -WALL_JUMP_HORIZONTAL_LIMIT, WALL_JUMP_HORIZONTAL_LIMIT)
			var _impulse_y = -WALL_JUMP_VERTICAL_MULTIPLIER * eff_wall_jump_force()
			var _impulse = Vector2(_impulse_x, _impulse_y)
			print(_impulse)
			state.apply_central_impulse(_impulse)
			var _v = state.get_linear_velocity()
			if _v.y > -eff_wall_jump_min_up():
				_v.y = -eff_wall_jump_min_up()
			state.set_linear_velocity(_v)
			_hover_disabled = true
			get_tree().create_timer(JUMP_HOVER_COOLDOWN).timeout.connect(_enable_hover)
			_jump_requested = false

	# Update coyote time when not on ground
	if not _on_ground:
		_coyote_time_counter = max(0, _coyote_time_counter - state.get_step())

	if _on_ground:
		_coyote_time_counter = COYOTE_TIME

	_velocity_last_frame = state.get_linear_velocity()

# Timer callback to enable hover after cooldown
func _enable_hover() -> void:
	_hover_disabled = false

# Visual debugging for force vectors
func _draw() -> void:
	if not DEBUG_MODE:
		return
		
	draw_arrow(Vector2.ZERO, _applied_force * 0.3, Color(1, 0, 0))
	draw_arrow(Vector2.ZERO, _gravity_force * 0.3, Color(0, 0, 1))
	draw_arrow(Vector2.ZERO, _normal * 40, Color(0, 1, 0))
	
	var _damping_force = -Vector2(_velocity_last_frame.x, 0).normalized() * DAMPING_COEFFICIENT * _velocity_last_frame.length()
	draw_arrow(Vector2.ZERO, _damping_force * 0.2, Color(1, 0.5, 0))
	
	if not _hover_disabled:
		var _hover_force = (HOVER_SPRING_CONSTANT * (RIDE_HEIGHT - (_velocity_last_frame.y * HOVER_RAY_LENGTH))) + (-HOVER_DAMPING * _velocity_last_frame.y)
		draw_arrow(Vector2.ZERO, Vector2(0, _hover_force) * 0.5, Color(1, 1, 0))

	if _jump_requested and _on_ground:
		draw_arrow(Vector2.ZERO, Vector2(0, -JUMP_FORCE) * 0.1, Color(0.5, 0, 0.5))

	var _from = Vector2.ZERO
	var _to = Vector2.DOWN * HOVER_RAY_LENGTH
	draw_line(_from, _to, Color(1, 1, 0), DRAW_SCALE)

# Helper function to draw arrows
func draw_arrow(_from: Vector2, _to: Vector2, _color: Color) -> void:
	const ARROW_ANGLE_DEG = 90
	const ARROW_SIZE = 10
	draw_line(_from, _to, _color, DRAW_SCALE)

	if _to.length() == 0:
		return
	
	var _direction = (_to - _from).normalized()
	var _arrow_angle = deg_to_rad(ARROW_ANGLE_DEG)
	var _left = _direction.rotated(_arrow_angle) * ARROW_SIZE 
	var _right = _direction.rotated(-_arrow_angle) * ARROW_SIZE 

	draw_line(_to, _to - _direction * ARROW_SIZE + _left, _color, DRAW_SCALE)
	draw_line(_to, _to - _direction * ARROW_SIZE + _right, _color, DRAW_SCALE)
