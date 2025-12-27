extends CharacterBody2D

const SPEED = 90.0
# const JUMP_VELOCITY = -400.0 --- NO. dr houser shall not jump, his leg is fucked remember

var direction = -1 # the direction that dr houser wants to move in, will flip between left and right when he collides with a wall. 1=right -1=left

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

#	# Handle jump.   --- again, nuh-uh
#	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
#		velocity.y = JUMP_VELOCITY


	velocity.x = direction * SPEED

	move_and_slide()
	if is_on_wall():
		direction *= -1

# TODO: Give him a hurtbox (he needs vicodin it is in your bones
# TODO: Make him stick to slopes :(
