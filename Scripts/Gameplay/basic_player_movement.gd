extends CharacterBody2D

const PIXEL_SCALE = 0.4 # Temporary, for scaling the physics down to pixel size.

const GRAVITY = 7.5; # Base gravity NOTE: (Casey) I temporarily changed this to be lower from 10.0, feel free to revert it later.
const GRAVITY_MULT = 3.5 * PIXEL_SCALE; # Multiplier to apply when falling
const H_SPEED = 200.0 * PIXEL_SCALE # Base horizontal speed
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

# skills
var ground_pound = true
var fire_dash    = true
var parry        = true
var thruster     = true

# violence :D
var base_atk    = 1 # variable in case we want there to be upgrades
var maximum_atk = 3 # variable in case we want there to be upgrades
var atk = 1 # this is the damage we will actually deal, may increase when doing a combo, using a skill, etc.
var damaged_enemy_this_frame = false # If an enemy was damaged on this frame, it is set to true.

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

# Observe player's hurtbox
@onready var ReceiveDamage = $ReceiveDamage

# Observe the player's... stompbox? I don't wanna call it a hitbox that is ambiguous as fuck.
@onready var JumpHit = $JumpHit

# When first loaded:
func _ready():
	coyote_time = coyote_default; # Set coyote time to itself
	floor_snap_length = 3.5; # Set the floor snap length to 3.5. This allows built in godot functions to lock the player to slopes.
	floor_constant_speed = true; # Disables moving slowly when going up slopes. We can change this later.
	# Connect the area signals.
	ReceiveDamage.connect("area_entered", entered_player_is_hurt_area)
	JumpHit.connect("area_entered", entered_enemy_is_hurt_area)
	

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
	
	# Decide what kind of action the player is doing
	state_machine(delta)

	# Apply physics and move.
	move_and_slide()
	
	# Update the player sprite.
	animation_update()

func get_directional_input(): # Get the player's directional input.
	var result = Vector2.ZERO
	result = Input.get_vector("move_left", "move_right", "move_up", "move_down") # Uses inputs to generate a Vector2.
	return result

func state_machine(_delta): # Change the way the player moves based on the current type of action
	match state: # Check the current state and run some code based on its value
		GROUNDED:
			grounded(_delta);
		AIRBORNE:
			airborne(_delta);
		HURT:
			hurt(_delta);
		DEAD:
			dead(_delta);
		GROUNDPOUNDING:
			groundpounding(_delta);

func grounded(_delta): # Grounded actions
	# Get player input and do movement
	movement(get_directional_input(), GROUND_FRICTION)
	
	atk = base_atk # kill the combo
	
	if Input.is_action_just_pressed("jump"): # If the player pressed the jump button...
		# ...jump.
		jump();

	if !is_on_floor(): # If we leave the ground for any reason, switch states to AIRBORNE.
		state = AIRBORNE;

func airborne(_delta): # Airboren actions
	# Get player input and do movement
	movement(get_directional_input(), AIR_FRICTION);
	
	# Check if we are stomping an enemy and act accordingly if so
	#stomp()
	
	# Use ground pound
	if Input.is_action_just_pressed("move_down"): # if we jump while holding down
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
		state = GROUNDED # if we're in the ground this will work well and if not it will turn us to airborne which also works YIPPIEEEE
		just_landed = true # Set for the sake of animation.

func dead(_delta):
	Globals.change_scene(death_screen) # gives you lupuse

func groundpounding(_delta): # GO DOWN FAST UNTIL LAND (will need more behaviors later, such as for breaking breakable tiles)
	velocity.x = 0
	velocity.y = 300
	# Check if we are stomping an enemy and act accordingly if so
	#stomp()
	# Down here same as in airborne
	if is_on_floor(): # If we hit the ground, switch states to GROUNDED and reset some variables.
		state = GROUNDED
		jumped = false;
		coyote_time = coyote_default;
		just_landed = true # Set for the sake of animation.

# Does the movement, applying friction as necessary.
func movement(direction, friction):
	# Check if direction is zero.
	# If it isn't, move velocity in the input direction, ramping up speed until a maximum.
	# If it is, move velocity back towards 0
	if direction != Vector2.ZERO:
		velocity.x = clampf(velocity.x + direction.x * friction, -H_SPEED, H_SPEED);
	else:
		if velocity.x != 0:
			velocity.x += clampf(0 - velocity.x, -friction, friction)

func jump():
	# i doubt this will get more complex than this but just in case i am making it a function so i don't have repeat code
	velocity.y = -JUMP_VELOCITY;
	sfx.play_sfx(sfx.JUMP)

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
		AIRBORNE:
			# Player is in the air.
			if velocity.y < 0.0:
				# Player is rising.
				player_sprite.change_animation_state(player_sprite.STATES.RISING)
			else:
				# Player is falling.
				player_sprite.change_animation_state(player_sprite.STATES.FALLING)
		HURT:
			# Player is hurt.
			player_sprite.change_animation_state(player_sprite.STATES.HURT)
	
	
	# Set the player's walking sounds.
	if player_walking == true:
		sfx.walk_loop()
	else:
		sfx.walk_stop()

func entered_player_is_hurt_area(area): # Player will take damage from something.
	if current_iframes > 0.0:
		return # Player is invincible, return.
	if damaged_enemy_this_frame == true:
		return # If an enemy has already been damaged this frame, ignore this.
	
	
	
	var enemy = area.get_parent() # Retrieve enemy node.
	if enemy.has_method("player_took_damage"):
		enemy.player_took_damage()
		player_get_hit(enemy) # Take damage.
		player_knockback(enemy) # Take knockback.

func entered_enemy_is_hurt_area(area): # Player is dealing damage, context dependent. JUMPHIT
	if damaged_enemy_this_frame == true:
		return # If an enemy has already been damaged this frame, ignore this.
	var hurt_enemy = area.get_parent() # Retrieve enemy node.
	if hurt_enemy.has_method("enemy_took_damage"):
		hurt_enemy.enemy_took_damage(self)
		damaged_enemy_this_frame = true
		# Bounnce off enemy.
		if Input.is_action_pressed("jump"):
			jump()
		else: velocity.y = hurt_enemy.bounce_velocity
		
		atk +=1
		if atk > maximum_atk:
			atk = maximum_atk

func player_get_hit(enemy): # Works with RECEIVEDAMAGE
	health -= enemy.damage
	UI.find_children("Health")[0].scale.y = health/max_health;
	print(health/max_health);
	current_iframes = enemy.dealt_i_frames # Retrieve i_frames from enemy.
	state = HURT
	just_got_hurt = true
	last_enemy = enemy
	print(health)

func player_knockback(enemy):
	var knockback_direction = 1 # right
	if position.x < enemy.position.x:
		knockback_direction = -1 # left
	velocity = Vector2(enemy.damage_knockback.x * knockback_direction,enemy.damage_knockback.y) #knock player up and away from the damage source
	move_and_slide()

func stomp(): # literally all calls for this are commented out after Casey's refactor, EPIC.
	if velocity.y >0: # We should not be able to stomp, say, on our way up.
		if JumpHit.get_overlapping_areas(): # are we even stomping anything
			var areas = JumpHit.get_overlapping_areas() # okay who are we stomping
			var victim = areas[0].get_parent() # let's only stomp 1 enemy at once mmmkay? whichever one godot says is [0]
			victim.hurt_me = atk # tell the enemy to SUFFER (when its their turn to run their code)
			# Hey, Paul, why do this whole hurt_me charade instead of just reducing the enemy's HP?
			# Because I want the enemy to be aware that they got hurt and hurt_me being > 0 is a nice way of doing that.
			# Alternatively we could give the enemies a just_got_hurt bool
			atk += 1 # reward combos with extra damage
			if atk > maximum_atk:
				atk = maximum_atk
			# Let the groundpound deal x2 damage, even if it exceeds the cap. The way I did it smells like it will brek if we stom through multiple enemies but oh well.
			if state == GROUNDPOUNDING:
				atk = 1
	
		# Allow the player to control how high they bounce off of enemies when attacking them (works like jumping as if off of ground)
		if Input.is_action_pressed("jump") && JumpHit.has_overlapping_areas(): # the player is actively trying to jump off of enemies. No "just_pressed", player can just hold, it's okayyyyy
			jump() # Yeah this works wonders right off the bat
			jumped = false # I think this is necessary but I honestly haven't even checked
		elif JumpHit.has_overlapping_areas(): # the player is not pressing jump, apply minimum bounce
			velocity.y = DEFAULT_STOMP_BOUNCE
