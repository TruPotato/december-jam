extends CharacterBody2D

const GRAVITY = 9.8
const H_SPEED = 200.0
const JUMP_VELOCITY = 500.0

# When first loaded.
func _ready():
	pass

# The main physics loop.
func _physics_process(_delta):
	# Get the player's main input.
	main_input_loop()
	# Apply gravity.
	passive_gravity()
	# Apply physics and move.
	move_and_slide()

# Fetch the player's directional input.
func get_directional_input():
	var result = Vector2.ZERO
	result = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return result

# The main input loop.
func main_input_loop():
	var input_result = get_directional_input()
	if input_result.x != 0.0:
		# If the player is moving horizontally.
		velocity.x = input_result.x * H_SPEED
	else:
		# If they player isn't moving.
		velocity.x = 0.0
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# Jump.
		velocity.y -= JUMP_VELOCITY

# Apply gravity.
func passive_gravity():
	if not is_on_floor(): # <- trupo doesn't like this.
		# Player is falling.
		# Downwards de-acceleration.
		velocity.y += GRAVITY
	else:
		# Player is on floor.
		# Set downwards velocity to zero if it is positive.
		if velocity.y > 0.0:
			velocity.y = 0.0
