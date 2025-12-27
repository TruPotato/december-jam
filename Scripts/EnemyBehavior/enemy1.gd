extends CharacterBody2D

const DAMAGE = 1 # how much damage can this enemy deal
const INITIAL_HP = 3
const SPEED = 12.0

var currentHP = 3 # gets set to INITIAL_HP later in ready, so it doesn't really matter what we set it to here

var direction = -1 # the direction that dr houser wants to move in, will flip between left and right when he collides with a wall. 1=right -1=left

func _ready():
	currentHP = INITIAL_HP

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	velocity.x = direction * SPEED
	
	move_and_slide()
	if is_on_wall():
		direction *= -1

# TODO: Give him a hurtbox (he needs vicodin it is in your bones
# TODO: Make him stick to slopes :(
