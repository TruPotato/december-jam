extends RigidBody2D

var active = false

const SOUND_TIME_INTER = 0.2
var sound_cooldown = 0.0

func activate():
	$Blink.stream = $Blink.stream.duplicate() # Make the audio stream unique.
	process_mode = Node.PROCESS_MODE_INHERIT
	active = true
	await get_tree().create_timer(5.0).timeout
	for n in 3:
		hide()
		await get_tree().create_timer(0.1).timeout
		show()
		await get_tree().create_timer(0.1).timeout
	active = false
	hide()
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _physics_process(delta):
	if active != true:
		return
	
	if get_contact_count() > 0 and sound_cooldown == 0.0:
		sound_cooldown = SOUND_TIME_INTER
		$Blink.play()
		$Blink.volume_linear *= 0.9
	else:
		sound_cooldown -= delta
		if sound_cooldown < 0.0: sound_cooldown = 0.0
