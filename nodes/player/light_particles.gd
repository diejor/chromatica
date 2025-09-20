extends Node2D

@export var light_scene : PackedScene  # The scene with the Light2D node.
@export var spawn_area : CollisionShape2D  # The collision shape defining the spawn area.
@export var pool_size : int = 10  # Number of lights in the pool.
@export var spawn_interval : float = 1.0  # Time interval between light spawns.

var light_pool = []
var active_lights = []
var spawn_timer : Timer
var rect_shape : RectangleShape2D  # To hold the RectangleShape2D reference

func _ready():
	# Assert the shape is a RectangleShape2D and get the shape
	assert(spawn_area.shape is RectangleShape2D, "Spawn area shape must be a RectangleShape2D!")
	rect_shape = spawn_area.shape as RectangleShape2D  # Cast to RectangleShape2D

	# Set up the spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false  # Set to false so it loops
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

	# Populate the pool with inactive light nodes
	for s in range(pool_size):
		var light = light_scene.instantiate()
		light.hide()  # Hide the light initially
		light.set_process(false)  # Disable processing to save resources
		light.set_physics_process(false)  # Disable physics processing (if applicable)
		light_pool.append(light)
		add_child(light)

# Timer callback to spawn new lights
func _on_spawn_timer_timeout():
	if len(light_pool) > 0:
		var light = light_pool.pop_back()
		spawn_light(light)

# Function to spawn the light within the CollisionShape2D area near the player
func spawn_light(light : Node2D):
	# Use the size of the RectangleShape2D to calculate spawn position
	var spawn_width = rect_shape.size.x
	var spawn_height = rect_shape.size.y

	# Calculate a random position near the player
	var spawn_pos = global_position + Vector2(randf_range(-spawn_width / 2, spawn_width / 2),
											   randf_range(-spawn_height / 2, spawn_height / 2))

	light.position = spawn_pos
	light.show()  # Show the light

	# Make the light top-level
	light.top_level = true

	light.set_process(true)  # Enable processing for the light
	light.set_physics_process(true)  # Enable physics processing (if applicable)

	# Start the light animation (fade in then fade out)
	start_light_animation(light)

# Function to start the light animation (fade in and then fade out)
func start_light_animation(light : Node2D):
	# Create a new tween for each light
	var tween = get_tree().create_tween()

	# Ensure light starts fully invisible (transparent)
	light.color = Color(1, 1, 1, 0)  # Start as fully transparent (dark)

	# First, fade in from completely dark (transparent) to fully visible (normal intensity)
	tween.tween_property(light, "color", Color(1, 1, 1, 1), 1.0)  # 1-second fade-in

	# Set transition and easing for fade-in
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	# After fading in, fade out to completely transparent just before "dying"
	tween.tween_property(light, "color", Color(1, 1, 1, 0), 2.0).set_delay(1.0)  # 2-second fade-out after 1s delay

	# Set transition and easing for fade-out
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Optionally, add a signal to disable light once animation is finished
	tween.finished.connect(_on_light_animation_finished.bind(light))

# Signal callback to disable light when the animation finishes
func _on_light_animation_finished(light : Node2D):
	light.hide()  # Hide the light
	light.set_process(false)  # Disable processing to save resources
	light.set_physics_process(false)  # Disable physics processing (if applicable)
	light_pool.append(light)  # Return it to the pool
