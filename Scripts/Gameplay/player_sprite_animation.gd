extends AnimatedSprite2D

enum STATES { # The animation states.
	IDLE,
	WALKING,
	RISING,
	FALLING,
	LANDING,
}

var current_state = STATES.IDLE

const LAND_TIME = 0.1 # How long the land animation lasts.
var land_timer = 0.0


func change_animation_state(new_state):
	# If you're still mid-landing animation, return.
	if land_timer > 0.0:
		land_timer -= get_process_delta_time()
		return
	
	if new_state == current_state:
		# Setting the current animation again is redundant, return.
		return
	
	current_state = new_state
	match current_state:
		STATES.IDLE:
			play("idle")
		STATES.WALKING:
			play("walk")
		STATES.RISING:
			play("rise")
		STATES.FALLING:
			play("fall")
		STATES.LANDING:
			play("land")
			# Set the landing timer.
			land_timer = LAND_TIME
