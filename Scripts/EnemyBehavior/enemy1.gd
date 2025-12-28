extends CharacterBody2D

const DAMAGE = 1 # how much damage can this enemy deal
const INITIAL_HP = 3
const SPEED = 12.0
const MAX_IFRAMES = 3

var alive=true
var currentHP = 3 # gets set to INITIAL_HP later in ready, so it doesn't really matter what we set it to here

var current_iframes = 0

var direction = -1 # the direction that dr houser wants to move in, will flip between left and right when he collides with a wall. 1=right -1=left

func _ready():
	floor_snap_length = 3.5; # Stick to slopes
	floor_constant_speed = true; # Don't slow down on slopes
	currentHP = INITIAL_HP # reset HP
	$TakeDamageFromPlayer.connect("body_entered", body_entered_hurtbox) # When a body enters our damage-taking box, run the function body_enetered_hurtbox()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	velocity.x = direction * SPEED
	
	move_and_slide()
	if is_on_wall():
		direction *= -1
	
	current_iframes -= 10*delta

func body_entered_hurtbox(body):
	if alive == false or current_iframes > 0: # If we have died or we are invulnerable, don't run the function
		return
	
	if body.name=="PlayerNode": # If the entering body is the player
		body.velocity.y = -200 # Move them away
		$Hurt.play() # Play our hurt sound
		currentHP -= body.atk # Subtract the player's attack from our HP
		current_iframes = MAX_IFRAMES # Fill up our iframes
	
	if currentHP <= 0: # if dead then die
		enemy_defeated() # And with strange eons, even death may die...
	pass

func enemy_defeated():
	alive = false # KILL
	$EnemySprite.play("hurt") # Play our hurt animation (TODO: Make this happen when we take damage too)
	$EnemyPlayer.play("defeat_animation") # Play our death flickering
	await $EnemyPlayer.animation_finished # Wait until that's over
	# Release the star particles.
	for star in $StarParticles.get_children(): # Explode particles out by looping over them and activating them
		star.show()
		star.position = position
		star.freeze = false
		var random_vel = Vector2.ZERO
		random_vel.x = randf_range(-100.0, 100.0)
		random_vel.y = randf_range(-160.0, -170.0)
		star.apply_impulse(random_vel)
		star.activate()
	
	$DamageThePlayer.queue_free(); # Delete the hitboxes so they can't try anything funny
	$TakeDamageFromPlayer.queue_free();

	await get_tree().create_timer(2.0).timeout # Wait a couple seconds to delete the particles
	queue_free() # DIE
