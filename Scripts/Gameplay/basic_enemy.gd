extends CharacterBody2D

var alive = true

func _ready():
	$Hurtbox.connect("body_entered", body_entered_hurtbox)

func body_entered_hurtbox(body):
	if alive == false:
		return
	
	if body.name == "PlayerNode":
		# Stomped on.
		# Add a burst of energy for the player.
		body.velocity.y = -200.0
		$Hurt.play()
		# Health mechanics will be added later. For now, one stomp is enough.
		enemy_defeated()

func enemy_defeated():
	alive = false
	$EnemySprite.play("hurt")
	$EnemyPlayer.play("defeat_animation")
	await $EnemyPlayer.animation_finished
	# Release the star particles.
	for star in $StarParticles.get_children():
		star.show()
		star.position = position
		star.freeze = false
		var random_vel = Vector2.ZERO
		random_vel.x = randf_range(-100.0, 100.0)
		random_vel.y = randf_range(-160.0, -170.0)
		star.apply_impulse(random_vel)
		star.activate()
	await get_tree().create_timer(10.0).timeout
	hide()
	queue_free()
