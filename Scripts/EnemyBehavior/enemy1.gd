extends CharacterBody2D

const DAMAGE = 1 # how much damage can this enemy deal
const INITIAL_HP = 3
const SPEED = 12.0
const MAX_IFRAMES = 3

var alive=true
@export var currentHP = 3 # gets set to INITIAL_HP later in ready, so it doesn't really matter what we set it to here

@export var hurt_time = 0.4 # How long the enemy staggers for.
var hurt_timer_delta = 0.0

# pain related variables
var hurt_me = 0
var current_iframes = 0

enum MOVEMENT_STATE {
	IDLE,
	WANDERING,
	HURT, # After being damaged.
	DEFEATED,
	FROZEN, # Does not apply gravity.
}

var current_move_state = MOVEMENT_STATE.IDLE
@export var default_move_state: MOVEMENT_STATE # The movement state the enemy defaults to.


enum DIRECTIONS {
	LEFT = -1,
	RIGHT = 1
}
@export var direction: DIRECTIONS # the direction that dr houser wants to move in, will flip between left and right when he collides with a wall. 1=right -1=left
@onready var enemy_sprite = $EnemySprite

func _ready():
	floor_snap_length = 3.5; # Stick to slopes
	floor_constant_speed = true; # Don't slow down on slopes
	currentHP = INITIAL_HP # reset HP
	#$TakeDamageFromPlayer.connect("body_entered", body_entered_hurtbox) # When a body enters our damage-taking box, run the function body_enetered_hurtbox()
	if direction == DIRECTIONS.LEFT:
		enemy_sprite.flip_h = true
	else:
		enemy_sprite.flip_h = false
	current_move_state = default_move_state

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if hurt_me > 0:# The enemy has been damaged normally.
		currentHP -= hurt_me # Take in the damage
		if currentHP <= 0: # if dead then die
			enemy_defeated() # And with strange eons, even death may die...
		else: 
			current_iframes = MAX_IFRAMES
			hurt_me = 0 # Stop receiving additional damage
			$EnemySprite.play("hurt") # Play hurt animation.
			$EnemyPlayer.play("hurt_flash")
			hurt_timer_delta = hurt_time # Set the hurt timer.
			current_move_state = MOVEMENT_STATE.HURT
	
	
	match current_move_state:
		MOVEMENT_STATE.WANDERING:
			$EnemySprite.play("walk")
			movement_wander(delta)
		MOVEMENT_STATE.IDLE:
			$EnemySprite.play("idle")
			velocity.x = 0.0
			move_and_slide()
		MOVEMENT_STATE.DEFEATED:
			$EnemySprite.play("hurt")
			velocity.x = 0.0
			move_and_slide()
		MOVEMENT_STATE.HURT:
			$EnemySprite.play("hurt")
			velocity.x = 0.0
			move_and_slide()
			hurt_timer_delta -= delta
			if hurt_timer_delta <= 0.0: # Hurt time is over, return to default state.
				current_move_state = default_move_state
	
	
	current_iframes -= 10*delta

func movement_wander(_delta):
	velocity.x = direction * SPEED
	move_and_slide()
	if is_on_wall():
		direction *= -1
		
		if direction == DIRECTIONS.LEFT:
			enemy_sprite.flip_h = true
		else:
			enemy_sprite.flip_h = false

# be hurt by the player
# TODO: this will currently not trigger because of my new dogshit bounce-on-enemies logic. It should probably be deleted   -Paul
func body_entered_hurtbox(body):
	if alive == false or current_iframes > 0: # If we have died or we are invulnerable, don't run the function
		return
	
	if body.name=="PlayerNode" && body.velocity.y>0: # If the entering body is the player and the player is falling onto the enemy
		# TODO: spongeboy mebob, this will not work when we implement the fireball dash and I am soon going to die, aaaack ack ack ack ack
		#body.velocity.y = -120 # Make player bounce up
		$Hurt.play() # Play our hurt sound
		currentHP -= body.atk # Subtract the player's attack from our HP
		current_iframes = MAX_IFRAMES # Fill up our iframes
		
		if currentHP <= 0: # if dead then die
			enemy_defeated() # And with strange eons, even death may die...
		else: 
			# The enemy has been damaged normally.
			$EnemySprite.play("hurt") # Play hurt animation.
			$EnemyPlayer.play("hurt_flash")
			hurt_timer_delta = hurt_time # Set the hurt timer.
			current_move_state = MOVEMENT_STATE.HURT
		#pass

func enemy_defeated():
	
	$DamageThePlayer.process_mode = Node.PROCESS_MODE_DISABLED; # Disable the hitboxes.
	$TakeDamageFromPlayer.process_mode = Node.PROCESS_MODE_DISABLED; # ooooooo the debugger does not like this one
	
	
	current_move_state = MOVEMENT_STATE.DEFEATED # Put the enemy in the defeated state..
	alive = false # KILL
	$EnemySprite.play("hurt") # Play our hurt animation
	$EnemyPlayer.play("defeat_animation") # Play our death flickering
	await $EnemyPlayer.animation_finished # Wait until that's over
	$Burst.play() # sound effect :3
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

	while $StarParticles.get_child_count() > 0: # Wait for the particles to disappear.
		await get_tree().process_frame
	queue_free() # DIE
