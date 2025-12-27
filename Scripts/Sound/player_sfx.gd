extends Node

enum {
	JUMP
}

var is_walking = false

func walk_loop():
	if is_walking == true:
		return
	
	is_walking = true
	$StepLoopPlayer.play("StepLoop")
	return

func walk_stop():
	if is_walking == true:
		is_walking = false
		$StepLoopPlayer.stop()
	return

func step_noise():
	# We can implement logic here later for registering the type of surface the player is walking on.
	$Step.play()
	return

func play_sfx(key):
	match key:
		JUMP:
			$Jump.play()
	return
