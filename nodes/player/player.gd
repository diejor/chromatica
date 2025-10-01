extends RigidBody2D
class_name PlayerController

signal jumped
signal landed
signal wall_jumped
signal on_ground_changed(on_ground: bool)
signal on_lantern_changed(is_active: bool, color: LanternColor.LanternColors)

@onready var motor: PlayerMotor = $Motor
@onready var lantern = $LanternComponent

var input_enabled := true

func _ready() -> void:
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 10
	add_to_group("player")

	motor.jumped.connect(jumped.emit)
	motor.landed.connect(landed.emit)
	motor.wall_jumped.connect(wall_jumped.emit)
	motor.on_ground_changed.connect(on_ground_changed.emit)

func _process(delta: float) -> void:
	motor.step_process(delta)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	motor.step_physics(state, self)
	if motor.DEBUG_MODE:
		queue_redraw()

func _draw() -> void:
	motor.debug_draw(self)

func request_jump() -> void:
	motor.request_jump()

func set_power(p: float) -> void:
	motor.POWER = p

func set_input_enabled(v: bool) -> void:
	input_enabled = v
	set_process_input(v)
	set_process_unhandled_input(v)
