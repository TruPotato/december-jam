extends CharacterBody2D

const GRAVITY = 10;
const GRAVITY_MULT = 3.5;
const H_SPEED = 200.0
const AIR_FRICTION = 18;
const GROUND_FRICTION = 30;
const JUMP_VELOCITY = 500.0

enum {
	GROUNDED,
	AIRBORNE
}

var jumped = false;
var state = AIRBORNE;

var coyote_default = 10;
var coyote_time;

# When first loaded.
func _ready():
	coyote_time = coyote_default;
	floor_snap_length = 3.5;
	floor_constant_speed = true;

# The main physics loop.
func _physics_process(_delta):
	$Floored.text = "iof: " + str(is_on_floor()); # Display whether the "is_on_floor()" check returns true
	$FloorNormal.text = "vel: " + str(velocity); # Display velocity

	# Decide what kind of action the player is doing
	state_machine(_delta)

	# Apply physics and move.
	move_and_slide()

# Fetch the player's directional input.
func get_directional_input():
	var result = Vector2.ZERO
	result = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return result

# Change the way the player moves based on the current type of action
func state_machine(_delta):
	match state:
		GROUNDED:
			grounded(_delta);
		AIRBORNE:
			airborne(_delta);

func grounded(_delta):
	# Get player input and do movement
	movement(get_directional_input(), GROUND_FRICTION)

	if Input.is_action_just_pressed("jump"):
		# Jump.
		jump();

	if !is_on_floor():
		state = AIRBORNE;

func airborne(_delta):
	# Get player input and do movement
	movement(get_directional_input(), AIR_FRICTION);

	# Apply gravity stronger if we are falling
	if velocity.y < 0:
		velocity.y += GRAVITY;
	else:
		velocity.y += GRAVITY * GRAVITY_MULT;
	
	# If we have already jumped, make releasing the button set velocity to something low
	# If we have not, give the player an airborne jump
	if !jumped:
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y = -10.0;
			jumped = true;
		if Input.is_action_just_pressed("jump") and coyote_time > 0:
			jump();
	
	# Decrease coyote time if we have not run out
	if coyote_time > 0:
		coyote_time -= 1;

	if is_on_floor():
		state = GROUNDED
		jumped = false;
		coyote_time = coyote_default;

# Does the movement, applying friction as necessary.
func movement(direction, friction):
	# Check if direction is zero. If it isn't, move velocity in the direction, ramping up speed. If it is, move velocity back towards 0
	if direction != Vector2.ZERO:
		velocity.x = clampf(velocity.x + direction.x * friction, -H_SPEED, H_SPEED);
	else:
		if velocity.x != 0:
			velocity.x += clampf(0 - velocity.x, -friction, friction)


func jump():
	# i doubt this will get more complex than this but just in case i am making it a function so i don't have repeat code
	velocity.y = -JUMP_VELOCITY;

# Apply gravity.
func passive_gravity():
	if not is_on_floor(): # <- seems like this has been fixed and works normally now! -trupo
		# Player is falling.
		# Downwards de-acceleration.
		velocity.y += GRAVITY
	else:
		# Player is on floor.
		# Set downwards velocity to zero if it is positive.
		if velocity.y > 0.0:
			velocity.y = 0.0;
		jumped = false;
