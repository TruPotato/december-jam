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
	floor_snap_length = 3.5;
	floor_constant_speed = true;
	currentHP = INITIAL_HP
	$TakeDamageFromPlayer.connect("body_entered", body_entered_hurtbox)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	velocity.x = direction * SPEED
	
	move_and_slide()
	if is_on_wall():
		direction *= -1
	
	current_iframes -= 10*delta
	
	if currentHP <= 0:
		enemy_defeated()

func body_entered_hurtbox(body):
	if alive == false or current_iframes > 0:
		return
	
	if body.name=="PlayerNode":
		body.velocity.y = -200
		$Hurt.play()
		currentHP -= body.atk
		current_iframes = MAX_IFRAMES
	pass

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

# TODO: Let him die
