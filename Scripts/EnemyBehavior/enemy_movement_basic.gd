extends CharacterBody2D

# The basic enemy movement logic, used for enemies that wander side to side or stand still.

@export var wander_speed = 12.0

enum MODES {
	STILL,
	WANDERING,
}
@export var movement_mode: MODES
@export var sprite: Node

enum DIRECTIONS {
	LEFT = -1,
	RIGHT = 1
}
var direction: DIRECTIONS

func _ready():
	floor_snap_length = 3.5; # Stick to slopes
	floor_constant_speed = true; # Don't slow down on slopes
	if direction == DIRECTIONS.LEFT:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func movement_logic_loop(delta): # Default movement loop.
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	match movement_mode:
		MODES.WANDERING:
			sprite.play("walk")
			movement_wander(delta)
		MODES.STILL:
			sprite.play("idle")
			move_and_slide()

func movement_wander(_delta):
	velocity.x = direction * wander_speed
	move_and_slide()
	if is_on_wall(): # turn around after hitting a wall
		direction *= -1
	
	if direction == DIRECTIONS.LEFT:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func movement_stopped(delta): # Used for when the enemy is staggered ie. when hurt or defeated.
	velocity.x = 0.0
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
