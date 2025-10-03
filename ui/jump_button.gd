extends TouchScreenButton
class_name UpJumpTouchButton

@export var action_up: StringName = "move_up"
@export var jump_action: StringName = "jump"
@export var jump_pulse_hold_frames := 2

var _jump_frames := 0

func _ready() -> void:
	pressed.connect(_on_pressed)
	released.connect(_on_released)

func _process(_dt: float) -> void:
	if _jump_frames > 0:
		_jump_frames -= 1
		if _jump_frames == 0:
			_emit_action(jump_action, false)

func _on_pressed() -> void:
	Input.action_press(action_up, 1.0)
	if _jump_frames == 0:
		_emit_action(jump_action, true)
		_jump_frames = jump_pulse_hold_frames

func _on_released() -> void:
	Input.action_release(action_up)
	_jump_frames = 0
	_emit_action(jump_action, false)

func _emit_action(_action: StringName, _pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = _action
	ev.pressed = _pressed
	Input.parse_input_event(ev)
