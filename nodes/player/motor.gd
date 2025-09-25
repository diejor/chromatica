class_name PlayerMotor
extends Node


signal jumped
signal landed
signal wall_jumped
signal on_ground_changed(on_ground: bool)

@export var LINEAR_FORCE := 500.0
@export var MAX_SPEED := 200.0
@export var JUMP_FORCE := 200.0
@export var WALL_JUMP_FORCE := 210.0
@export var WALL_JUMP_VERTICAL_MULTIPLIER := 1.1
@export var WALL_JUMP_HORIZONTAL_LIMIT := 125.0
@export var WALL_GRAB_GRAVITY_MULTIPLIER := 0.1
@export var JUMP_HOVER_COOLDOWN := 0.2
@export var DEBUG_MODE := false
@export var DRAW_SCALE := 1.0
@export var DAMPING_COEFFICIENT := 10.0
@export var HORIZONTAL_TO_VERTICAL_RATIO := 0.0
@export var AIR_CONTROL_MULTIPLIER := 1.0
@export var HOVER_RAY_LENGTH := 25.0
@export var HOVER_SPRING_CONSTANT := 1000.0
@export var HOVER_DAMPING := 50.0
@export var RIDE_HEIGHT := 15.0
@export var HOVER_FORCE_MULTIPLIER := 0.5
@export var COYOTE_TIME := 0.1
@export var WALL_JUMP_MIN_UP_SPEED := 220.0

@export var POWER := 1.0
@export var MOVE_POWER_SCALE := 1.0
@export var JUMP_POWER_SCALE := 1.0
@export var WALL_POWER_SCALE := 1.0
@export var SPEED_POWER_SCALE := 1.0
@export var POWER_EXP := 1.0

func _p(k: float, w: float = 1.0, e: float = POWER_EXP) -> float:
	return k * pow(max(POWER * w, 0.0), e)

func eff_linear_force() -> float: return _p(LINEAR_FORCE, MOVE_POWER_SCALE)
func eff_jump_force() -> float: return _p(JUMP_FORCE, JUMP_POWER_SCALE)
func eff_wall_jump_force() -> float: return _p(WALL_JUMP_FORCE, WALL_POWER_SCALE)
func eff_wall_jump_min_up() -> float: return _p(WALL_JUMP_MIN_UP_SPEED, WALL_POWER_SCALE)
func eff_max_speed() -> float: return _p(MAX_SPEED, SPEED_POWER_SCALE)

var _coyote_time_counter := 0.0
var _last_ground_normal := Vector2.ZERO
var _applied_force := Vector2.ZERO
var _gravity_force := Vector2.ZERO
var _velocity_last_frame := Vector2.ZERO
var _contact_points: Array[Vector2] = []
var _contact_normals: Array[Vector2] = []
var _normal := Vector2.ZERO
var _jump_requested := false
var _on_ground := false
var _was_on_ground := false
var _is_near_wall := false
var _is_grabbing_wall := false
var _hover_disabled := false

# --- external triggers ---
func request_jump() -> void:
	_jump_requested = true

func step_process(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") and (_on_ground or _coyote_time_counter > 0.0 or _is_near_wall):
		_jump_requested = true

func step_physics(state: PhysicsDirectBodyState2D, body: RigidBody2D) -> void:
	_contact_points.clear()
	_contact_normals.clear()
	_gravity_force = state.get_total_gravity()

	_was_on_ground = _on_ground
	_on_ground = false
	_is_near_wall = false
	_is_grabbing_wall = false

	for i in range(state.get_contact_count()):
		var local_p := body.to_local(state.get_contact_local_position(i))
		var local_n := state.get_contact_local_normal(i).normalized()
		_contact_points.append(local_p)
		_contact_normals.append(local_n)
		if local_n.x != 0.0:
			_is_near_wall = true
			if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
				_is_grabbing_wall = true

	if _is_grabbing_wall:
		_gravity_force *= WALL_GRAB_GRAVITY_MULTIPLIER
	else:
		_gravity_force = state.get_total_gravity()

	# Hover / ground check via ray
	if not _hover_disabled:
		var from := body.global_position
		var to := from + Vector2.DOWN * HOVER_RAY_LENGTH
		var space := body.get_world_2d().direct_space_state
		var q := PhysicsRayQueryParameters2D.create(from, to)
		var hit := space.intersect_ray(q)
		if hit:
			_on_ground = true
			_contact_points.append(hit.position)
			_contact_normals.append(hit.normal)
			_is_grabbing_wall = false
			_gravity_force = state.get_total_gravity()
			state.apply_central_force(-_gravity_force)

			var hit_point: Vector2 = hit.position
			var distance := (hit_point - from).length()
			var displacement := distance - RIDE_HEIGHT

			var v := state.get_linear_velocity()
			var ray_dir := Vector2.DOWN
			var v_along := v.dot(ray_dir)
			var f_spring := HOVER_SPRING_CONSTANT * displacement
			var f_damp := -HOVER_DAMPING * v_along
			var f_total := (f_spring + f_damp) * ray_dir * HOVER_FORCE_MULTIPLIER
			state.apply_central_force(f_total)

	# combine normals (downweight strong horizontals)
	_normal = Vector2.ZERO
	for n in _contact_normals:
		var w := 0.01 if abs(n.x) > 0.1 else 1.0
		_normal += n * w
	_normal = _normal.normalized()
	if _on_ground:
		_last_ground_normal = _normal

	# drive force
	var v_now := state.get_linear_velocity()
	var hspeed := absf(v_now.x)
	var factor = clamp(1.0 - (hspeed / eff_max_speed()), 0.0, 1.0)

	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_len2 := move.length_squared()
	var desired := move.normalized()

	_applied_force = desired * eff_linear_force() * factor if move_len2 > 0.0 else Vector2.ZERO

	if _on_ground:
		var damping_factor := 0.1
		if v_now.x * desired.x < 0.0:
			damping_factor = 1.0
			_applied_force.x = desired.x * eff_linear_force() * factor
		var h := Vector2(v_now.x, 0.0)
		var f_damp := -h * DAMPING_COEFFICIENT * damping_factor
		state.apply_central_force(f_damp)

	# slide along contact but keep intended magnitude
	if _normal.length_squared() > 0.0:
		var pre := _applied_force
		_applied_force = _applied_force.slide(_normal)
		if pre.length() > 0.001 and _applied_force.length() < pre.length():
			_applied_force = _applied_force.normalized() * pre.length()

	state.apply_central_force(_applied_force)

	if _on_ground and move_len2 == 0.0 and abs(v_now.x) > 0.01:
		var h2 := Vector2(v_now.x, 0.0)
		state.apply_central_force(-h2 * DAMPING_COEFFICIENT)

	if abs(v_now.x) < 0.001:
		v_now = state.get_linear_velocity()
		v_now.x = 0.0
		state.set_linear_velocity(v_now)

	# jumps
	if _jump_requested:
		if _on_ground:
			_do_ground_jump(state)
		elif _coyote_time_counter > 0.0:
			_do_coyote_jump(state)
		elif _is_near_wall and _contact_normals.size() > 0:
			_do_wall_jump(state)
		_jump_requested = false

	# coyote timer
	if not _on_ground:
		_coyote_time_counter = max(0.0, _coyote_time_counter - state.get_step())
	else:
		_coyote_time_counter = COYOTE_TIME

	_velocity_last_frame = state.get_linear_velocity()

	# land/takeoff signals
	if _on_ground != _was_on_ground:
		on_ground_changed.emit(_on_ground)
		if _on_ground:
			landed.emit()

# --- jump helpers ---
func _disable_hover_temporarily(body: RigidBody2D) -> void:
	_hover_disabled = true
	body.get_tree().create_timer(JUMP_HOVER_COOLDOWN).timeout.connect(func(): _hover_disabled = false)

func _do_ground_jump(state: PhysicsDirectBodyState2D) -> void:
	state.apply_central_impulse(Vector2.UP * eff_jump_force())
	var v := state.get_linear_velocity()
	var vN := v.project(Vector2.UP)
	var vT := v - vN
	var transfer := vT * HORIZONTAL_TO_VERTICAL_RATIO
	v -= transfer
	v += Vector2.UP * transfer.length() * 0.2
	state.set_linear_velocity(v)
	_disable_hover_temporarily(owner)
	jumped.emit()

func _do_coyote_jump(state: PhysicsDirectBodyState2D) -> void:
	state.apply_central_impulse(Vector2.UP * eff_jump_force())
	_disable_hover_temporarily(owner)
	jumped.emit()

func _do_wall_jump(state: PhysicsDirectBodyState2D) -> void:
	var wall_n := _contact_normals[0]
	var ix = clamp(wall_n.x * eff_wall_jump_force(), -WALL_JUMP_HORIZONTAL_LIMIT, WALL_JUMP_HORIZONTAL_LIMIT)
	var iy := -WALL_JUMP_VERTICAL_MULTIPLIER * eff_wall_jump_force()
	state.apply_central_impulse(Vector2(ix, iy))
	var v := state.get_linear_velocity()
	if v.y > -eff_wall_jump_min_up():
		v.y = -eff_wall_jump_min_up()
	state.set_linear_velocity(v)
	_disable_hover_temporarily(owner)
	wall_jumped.emit()

var _dbg_applied := Vector2.ZERO
var _dbg_gravity := Vector2.ZERO
var _dbg_normal := Vector2.ZERO

func debug_draw(drawer: CanvasItem) -> void:
	if not DEBUG_MODE:
		return
	_dbg_applied = _applied_force * 0.3
	_dbg_gravity = _gravity_force * 0.1
	_dbg_normal = _normal * 40.0

	_draw_arrow(drawer, Vector2.ZERO, _dbg_applied, Color(1,1,0))
	_draw_arrow(drawer, Vector2.ZERO, _dbg_gravity, Color(0,0,1))
	_draw_arrow(drawer, Vector2.ZERO, _dbg_normal, Color(0,1,0))

	var h_last := Vector2(_velocity_last_frame.x, 0.0)
	var f_damp_dbg := -h_last * DAMPING_COEFFICIENT * 0.1
	_draw_arrow(drawer, Vector2.ZERO, f_damp_dbg, Color(1,0.5,0))

	var from := Vector2.ZERO
	var to := Vector2.DOWN * HOVER_RAY_LENGTH
	drawer.draw_line(from, to, Color(1,1,0), DRAW_SCALE)

func _draw_arrow(d: CanvasItem, from: Vector2, to: Vector2, c: Color) -> void:
	const ARROW_ANGLE_DEG := 90.0
	const ARROW_SIZE := 10.0
	d.draw_line(from, to, c, DRAW_SCALE)
	if to.length() == 0.0:
		return
	var dir := (to - from).normalized()
	var a := deg_to_rad(ARROW_ANGLE_DEG)
	var left := dir.rotated(a) * ARROW_SIZE
	var right := dir.rotated(-a) * ARROW_SIZE
	d.draw_line(to, to - dir * ARROW_SIZE + left, c, DRAW_SCALE)
	d.draw_line(to, to - dir * ARROW_SIZE + right, c, DRAW_SCALE)
