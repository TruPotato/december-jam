extends Node2D

enum STATES {
	NORMAL, # Predefined by the behaviour script.
	HURT, # Stops normal functioning, staggers, still affected by physics.
	FROZEN, # Stops all code, including physics.
	DEFEATED, # Stops normal functioning and prepares to remove enemy from the world.
}
var current_state = STATES.NORMAL
var hurt_time_length = 0.25 # How long the enemy is hurt for.
var hurt_timer = 0.0 # The actual countdown.


@export var health = 6
@export var damage = 2
@export var damage_knockback = Vector2(50, -100) # The knockback after the player takes damage.
@export var dealt_i_frames = 0.4 # How many i_frames the player gets after taking damage.
@export var bounce_velocity = -80 # The burst of upward speed after bouncing off the enemy.
enum DIRECTIONS {
	LEFT = -1,
	RIGHT = 1
}
@export var start_direction: DIRECTIONS

var alive = true

@onready var movement_body = $EnemyMovementBody

@onready var damage_indicator = preload("res://Scenes/Reusables/damage_indicator.tscn") # it's a variable but we won't vary it

func _ready():
	movement_body.position = position
	movement_body.direction = start_direction

func _physics_process(delta):
	
	match current_state:
		STATES.NORMAL:
			movement_body.movement_logic_loop(delta)
			position = movement_body.position
		STATES.HURT:
			movement_body.movement_stopped(delta)
			position = movement_body.position
			hurt_timer -= delta
			if hurt_timer <= 0.0:
				current_state = STATES.NORMAL
				# reenable hitboxes when the enemy is done suffering
				$PlayerIsHurtArea.process_mode = Node.PROCESS_MODE_PAUSABLE
				$EnemyIsHurtArea.process_mode = Node.PROCESS_MODE_PAUSABLE
		STATES.DEFEATED:
			movement_body.movement_stopped(delta)
			position = movement_body.position

func player_took_damage():
	#spawn_damage_indicator(self)
	pass

func enemy_took_damage(player):
	health -= player.atk
	
	player.spawn_damage_indicator(self) 
	
	if health > 0:
		# Regular hurt.
		enemy_got_hurt()
		hurt_timer = hurt_time_length
		current_state = STATES.HURT
		# Disable hitboxes while the enemy suffers
		$PlayerIsHurtArea.process_mode = Node.PROCESS_MODE_DISABLED
		$EnemyIsHurtArea.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		#Defeat.
		current_state = STATES.DEFEATED
		defeat_enemy()

func enemy_got_hurt():
	#$Hurt.play() # sound TODO:
	#$EnemyPlayer.play("hurt_flash")
	#$EnemySprite.play("hurt")
	pass

func defeat_enemy():
	alive = false
	# Disable hitboxes.
	$PlayerIsHurtArea.process_mode = Node.PROCESS_MODE_DISABLED
	$EnemyIsHurtArea.process_mode = Node.PROCESS_MODE_DISABLED
	#$EnemyPlayer.play("defeat_animation") TODO:
	#$EnemySprite.play("hurt")
	await get_tree().create_timer(2.0).timeout
	queue_free()

func spawn_damage_indicator(origin): #for when the enemy hits the player
	var instance = damage_indicator.instantiate()
	instance.text = str(damage)
	instance.position.y -= 16
	instance.modulate = Color(1.0,0.3,0.5,1)
	origin.add_child(instance)
	pass
