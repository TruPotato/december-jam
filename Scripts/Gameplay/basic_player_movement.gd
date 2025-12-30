extends CharacterBody2D

#region Variables
const PIXEL_SCALE = 0.4 # Temporary, for scaling the physics down to pixel size.

const GRAVITY = 7.5; # Base gravity NOTE: (Casey) I temporarily changed this to be lower from 10.0, feel free to revert it later.
const GRAVITY_MULT = 3.5 * PIXEL_SCALE; # Multiplier to apply when falling
const H_SPEED = 200.0 * PIXEL_SCALE # Base horizontal speed
const CARRYING_MULT = 0.75; # Move speed multiplier for when the player is carrying a party member.
const AIR_FRICTION = 18 * PIXEL_SCALE; # Friction in the air (determines how much control you have while airborne)
const GROUND_FRICTION = 30 * PIXEL_SCALE; # Friction on the ground (same as AIR_FRICTION but for the ground)
const JUMP_VELOCITY = 500.0 * PIXEL_SCALE # Code says jump, this says how high
const IFRAMES = 0.3 # brief invincibility frames after you damage an enemy.
const DEFAULT_STOMP_BOUNCE = -120 # what will the player's velocity.v be set to when stomping an enemy without pressing jump? this.

# An "enum" or "Enumerator" is a list of variables that equate to integer values; for example, GROUNDED = 0, and AIRBORNE = 1.
enum { # These are possible gameplay states. It will probably become longer later!
	GROUNDED,
	AIRBORNE,
	DEAD,
	HURT,
	GROUNDPOUNDING
}

# escape timer gunk
const ESCAPE_TIMER_DEFAULT = 10.0;
var remaining_time = 0.0;
var escaping = false;

# skills. Do we have them? true or false
var ground_pound = true
var fire_dash    = true
var parry        = true
var thruster     = true

# violence :D
var base_atk    = 1 # variable in case we want there to be upgrades
var maximum_atk = 3 # variable in case we want there to be upgrades
var atk # this is the damage we will actually deal, may increase when doing a combo, using a skill, etc.
var damaged_enemy_this_frame = false # If an enemy was damaged on this frame, it is set to true. Does not seem very necessary but it's a nice safety measure.
var there_are_things_to_attack = false # Important for groundpunding TToTT
@onready var damage_indicator = preload("res://Scenes/Reusables/damage_indicator.tscn") # it's a variable but we won't vary it

# Control movement
var jumped = false; # Variable for determining if coyote time still applies and if downward velocity should be applied when releasing jump
var state = GROUNDED; # Sets the default state to GROUNDED or 0.

var max_health = 3.0; # Default health value. might change with levels?
var health = 3.0; # You die when this is 0.

var coyote_default = 10; # Default coyote time so we can reset to it after each fall.
var coyote_time; # Sets itself to the default when grounded; "coyote time" determines how long after leaving a ledge you can still jump.

# Animation related variables.
var moving_right = true # If velocity.x is positive.
var just_landed = false # Set to true if player has just landed.

# Pain related variables
var last_enemy # Helps us determine where we are getting hit from, relative position to enemy, so we can knockback in the correct direction
var current_iframes = 0.0 # take a wild guess what this is for
var invincible = false # think mark think
var just_got_hurt = false # for now hehehehehe

@export var death_screen = "death_screen"

@onready var player_sprite = $PlayerSprite # The sprite node.
@onready var sfx = $PlayerSFX; # The sounds.
@onready var UI = get_tree().get_nodes_in_group("UI")[0]; # Gets the UI node, which is attached to the camera.
@onready var escape_timer = UI.find_child("EscapeTimer");

# Observe player's hurtbox
@onready var ReceiveDamage = $ReceiveDamage

# Observe the player's... stompbox? I don't wanna call it a hitbox that is ambiguous as fuck.
@onready var JumpHit = $JumpHit
#endregion

# When first loaded:
func _ready():
	coyote_time = coyote_default; # Set coyote time to itself
	floor_snap_length = 3.5; # Set the floor snap length to 3.5. This allows built in godot functions to lock the player to slopes.
	floor_constant_speed = true; # Disables moving slowly when going up slopes. We can change this later.
	# Connect the area signals.
	ReceiveDamage.connect("area_entered", entered_player_is_hurt_area)
	JumpHit.connect("area_entered", entered_enemy_is_hurt_area)

#region Main Loop
func _physics_process(delta):
	damaged_enemy_this_frame = false # Reset this.
	just_got_hurt = false
	$Floored.text = "iof: " + str(is_on_floor()); # Display whether the "is_on_floor()" check returns true
	$FloorNormal.text = "vel: " + str(velocity); # Display velocity
	$State.text = "State: " + str(state); # Display the Epstein files
	
	if current_iframes > 0.0: # Decrease iframes.
		current_iframes -= delta
		if current_iframes < 0.0: current_iframes = 0.0
	
	if health <= 0:
		state = DEAD

	# Debug gunk
	# For now, this just starts the escape timer.
	# Any REAL function that starts the escape timer will have to toggle these same variables.
	if Input.is_action_just_pressed("debug_key"):
		escaping = !escaping; # Toggles escaping (i.e. if it's true, set it to false; if it's false, set it to true)
		escape_timer.visible = !escape_timer.visible; # Toggles the timer's visibility
		remaining_time = ESCAPE_TIMER_DEFAULT; # Sets remaining time to the default
	
	# Escaping
	if escaping:
		escape(delta);
	
	# Decide what kind of action the player is doing
	state_machine(delta)

	# Apply physics and move.
	move_and_slide()

	# Ground pound stuff. we hit it with a hammer
	if there_are_things_to_attack == true and state == GROUNDPOUNDING:
		groundpound_attack()
	there_are_things_to_attack = false
	
	# Update the player sprite.
	animation_update()
#endregion

#region State Machine
func state_machine(delta): # Change the way the player moves based on the current type of action
	match state: # Check the current state and run some code based on its value
		GROUNDED:
			grounded(delta);
		AIRBORNE:
			airborne(delta);
		HURT:
			hurt(delta);
		DEAD:
			dead(delta);
		GROUNDPOUNDING:
			groundpounding(delta);

func grounded(_delta): # Grounded actions
	# Get player input and do movement
	movement(get_directional_input(), GROUND_FRICTION, H_SPEED)
	
	atk = base_atk # kill the combo
	
	if Input.is_action_just_pressed("jump"): # If the player pressed the jump button...
		# ...jump.
		jump();

	if !is_on_floor(): # If we leave the ground for any reason, switch states to AIRBORNE.
		state = AIRBORNE;

func airborne(_delta): # Airboren actions
	# Get player input and do movement
	movement(get_directional_input(), AIR_FRICTION, H_SPEED);
	
	# Use ground pound
	if Input.is_action_just_pressed("move_down") and ground_pound: # if we press down while airborne AND we have unlocked the groundpound ability
		state = GROUNDPOUNDING
		groundpounding(_delta)
		return
	
	# Apply gravity. If velocity is lower than zero, just apply it normally; otherwise add a multiplier to make for a nicer jump arc.
	if velocity.y < 0:
		velocity.y += GRAVITY;
	else:
		velocity.y += GRAVITY * GRAVITY_MULT;
	
	if !jumped:
		# If we have already jumped, make releasing the button set velocity downward slightly so we can short hop.
		# this kind of makes the variable name confusing... i'll have to figure out a better name for it.
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y = -10.0;
			jumped = true;

		# If we have not already jumped and we have some coyote time remaining, let the player jump in the air.
		if Input.is_action_just_pressed("jump") and coyote_time > 0:
			jump();
	
	# Decrease coyote time if we have not run out
	if coyote_time > 0:
		coyote_time -= 1;

	if is_on_floor(): # If we hit the ground, switch states to GROUNDED and reset some variables.
		state = GROUNDED
		jumped = false;
		coyote_time = coyote_default;
		just_landed = true # Set for the sake of animation.

func hurt(_delta):
	velocity.y += GRAVITY * GRAVITY_MULT; # apply gravity
	if current_iframes <= 0.0 or is_on_floor(): # If we hit the ground, switch states to GROUNDED and reset some variables. Just got hurt check thing so we do not immediatly go to GROUNDED.
		state = GROUNDED # if we're on the ground this will work well and if not it will turn us to airborne which also works YIPPIEEEE
		just_landed = true # Set for the sake of animation.

func dead(_delta):
	velocity = Vector2.ZERO;
	$PlayerPlayer.play("die"); # use the animation player to play a quick death animation
	await $PlayerPlayer.animation_finished; # wait for that to be over
	Globals.change_scene(death_screen) # contract lupuse

func groundpounding(_delta): # GO DOWN FAST UNTIL LAND (will need more behaviors later, such as for breaking breakable tiles)
	velocity.x = 0
	velocity.y = 300
	atk = 1
	# Down here same as in airborne, exit groundpound state on floor collide.
	if is_on_floor(): # If we hit the ground, switch states to GROUNDED and reset some variables.
		state = GROUNDED
		jumped = false;
		coyote_time = coyote_default;
		just_landed = true # Set for the sake of animation.
#endregion

#region Animation
# Update the player's sprite.
func animation_update():
	# Set player facing direction.
	if velocity.x > 0.0 and moving_right == false:
		player_sprite.flip_h = false
		moving_right = true
	else:
		if velocity.x < 0.0 and moving_right == true:
			player_sprite.flip_h = true
			moving_right = false
	
	# Check if the player just landed.
	if just_landed == true:
		just_landed = false
		player_sprite.change_animation_state(player_sprite.STATES.LANDING)
	
	var player_walking = false
	# Check is player is airborne.
	match state:
		GROUNDED:
			# Player is on the ground.
			if abs(velocity.x) < 15.0:
				# Player is still.
				player_sprite.change_animation_state(player_sprite.STATES.IDLE)
			else:
				# Player is walking, or at least moving horizontally on the ground.
				player_sprite.change_animation_state(player_sprite.STATES.WALKING)
				player_walking = true
		AIRBORNE, GROUNDPOUNDING:
			# Player is in the air.
			if velocity.y < 0.0:
				# Player is rising.
				player_sprite.change_animation_state(player_sprite.STATES.RISING)
			else:
				# Player is falling.
				player_sprite.change_animation_state(player_sprite.STATES.FALLING)
		HURT, DEAD:
			# Player is hurt or dead.
			player_sprite.change_animation_state(player_sprite.STATES.HURT)
	
	
	# Set the player's walking sounds.
	if player_walking == true:
		sfx.walk_loop()
	else:
		sfx.walk_stop()
#endregion

#region Miscellaneous
func get_directional_input(): # Get the player's directional input.
	var result = Vector2.ZERO
	result = Input.get_vector("move_left", "move_right", "move_up", "move_down") # Uses inputs to generate a Vector2.
	return result

func movement(direction, friction, speed): # Does the movement, applying friction as necessary.
	# Check if direction is zero.
	# If it isn't, move velocity in the input direction, ramping up speed until a maximum.
	# If it is, move velocity back towards 0
	if direction != Vector2.ZERO:
		velocity.x = clampf(velocity.x + direction.x * friction, -speed, speed);
	else:
		if velocity.x != 0:
			velocity.x += clampf(0 - velocity.x, -friction, friction)

func jump():
	# i doubt this will get more complex than this but just in case i am making it a function so i don't have repeat code
	# future note: oh shit, we can use it for sound effects! nice
	velocity.y = -JUMP_VELOCITY;
	sfx.play_sfx(sfx.JUMP)

func entered_player_is_hurt_area(area): # Player will take damage from something.
	if current_iframes > 0.0 || damaged_enemy_this_frame:
		return # Player is invincible or we already did damage this frame, return.
	
	var enemy = area.get_parent() # Retrieve enemy node.
	if enemy.has_method("player_took_damage"): # Make sure the game doesn't crash by calling a nonexistent function
		enemy.player_took_damage()
		player_get_hit(enemy) # Take damage.
		player_knockback(enemy) # Take knockback.

func entered_enemy_is_hurt_area(area): # Activated by signal, causes the player to deal damage
	
	there_are_things_to_attack = true # Needed to activate groundpound logic independently from signal activation because signals have ghosts in them (too long to detail here ask us)
	
	if state != GROUNDPOUNDING: # We only want to do regular stomp logic here.
		var hurt_enemy = area.get_parent() # Retrieve enemy node.
		if hurt_enemy.has_method("enemy_took_damage") and velocity.y>0:
			hurt_enemy.enemy_took_damage(self) # the enemy will take damage using us as the argument
			# Bounnce off enemy.
			if Input.is_action_pressed("jump"):
				jump()
			else: velocity.y = hurt_enemy.bounce_velocity
			increase_combo()

func groundpound_attack(): # Will only be activated if entered_enemy_is_hurt_area(area) is activated by the signal.
	
	damaged_enemy_this_frame = true
	
	var hurt_enemy # need this in a high scope

	# for some reason only detecting the overlap of 1 area instead of many... sometimes it detects 2 which is even more perplexing.
	for i in $JumpHit.get_overlapping_areas().size(): # groundpound can hurt multiple enemies at once, this will iterate over all enemies our hitbox is on when the triggering signal is sent
		
		hurt_enemy=$JumpHit.get_overlapping_areas()[i].get_parent() # Retrieve enemy node for current iteration.
		
		if hurt_enemy.has_method("enemy_took_damage"): # this conditional exists to ignore hitboxes corresponding to unhurtable nodes
			hurt_enemy.enemy_took_damage(self) # the enemy will take damage using us as the argument
		
			if hurt_enemy.health > 0: # apply bouncing behavior if one or more enemies survive
				state = AIRBORNE
				if hurt_enemy.bounce_velocity < velocity.y: # apply the highest bounce velocity from among all the surviving enemies we hit. Player does not (currently) have a say in how high they go
					velocity.y = hurt_enemy.bounce_velocity

	#else:
	#	hurt_enemy = area.get_parent() # Retrieve enemy node.
	#	if hurt_enemy.has_method("enemy_took_damage") and velocity.y>0:
	#		hurt_enemy.enemy_took_damage(self) # the enemy will take damage using us as the argument
	#		# Bounnce off enemy.
	#		if Input.is_action_pressed("jump"):
	#			jump()
	#		else: velocity.y = hurt_enemy.bounce_velocity
	#		increase_combo()

func player_get_hit(enemy): # Works with RECEIVEDAMAGE
	health -= enemy.damage
	UI.find_children("Health")[0].scale.y = clamp(health/max_health, 0, 1);
	print(health/max_health);
	current_iframes = enemy.dealt_i_frames # Retrieve i_frames from enemy. NOTE: Wouldn't it be better for player iframes to always be the same, and determined in this very file?
	state = HURT
	just_got_hurt = true
	last_enemy = enemy # important for determining knockback direction
	print(health)

func increase_combo():
	atk += 1
	if atk > maximum_atk:
		atk = maximum_atk

func player_knockback(enemy):
	var knockback_direction = 1 # right
	if position.x < enemy.position.x:
		knockback_direction = -1 # left
	velocity = Vector2(enemy.damage_knockback.x * knockback_direction,enemy.damage_knockback.y) #knock player up and away from the damage source
	move_and_slide()

func spawn_damage_indicator(origin):
	var instance = damage_indicator.instantiate()
	var yellowness = 1.0-(atk-base_atk/float(maximum_atk-base_atk)) # make better tomorrow
	instance.text = str(atk)
	instance.position.y -= 16
	instance.modulate = Color(1.0,yellowness,0.0,1)
	origin.add_child(instance)

func escape(delta):
	# this doesn't need to be its own line, but i wanted to explain it specifically
	# this makes a string out of the remaining time, using math to cut off the decimals past 10ths.
	var remaining_time_str = str(round(remaining_time * pow(10.0, 1)) / pow(10.0, 1));

	# Set's the escape timer's smaller text to the remaining time
	escape_timer.get_child(0).text = "TIME: " + remaining_time_str;

	# If we are not out of time, decrease the time in seconds
	if remaining_time > 0:
		remaining_time -= delta;
	else: # If we are, contract lupuse
		state = DEAD;
		remaining_time = 0;
#endregion
