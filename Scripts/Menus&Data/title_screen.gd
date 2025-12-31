extends Node2D

var select = 0; # What menu option we're on
var offset = 0; # Animation thing

var max_select = 1; # If we hit the bottom, go back to the top

var positions = [115, 143]; # Vertical positions of menu options

enum { # Pointless enum for options. there are two options. don't need an enum. enum's fun though
	START,
	QUIT
}

@onready var cursor = $Cursor; # Get the cursor object so we can move it around
@onready var timer = 25; # Make sure people don't accidenally select start after mashing through the opening cutscene

func _process(_delta):
	if timer > 0:
		timer -= 1
	if Input.is_action_pressed("accept"): # While we're holding down the accept button, move the cursor in a little
		offset = 4;
	else:
		offset = 0;
		if Input.is_action_just_pressed("move_down"): # Change the menu option and loop if we're past the max or below the min
			select += 1;
			if select > max_select:
				select = 0;
		if Input.is_action_just_pressed("move_up"):
			select -= 1;
			if select < 0:
				select = max_select;

	if Input.is_action_just_released("accept"): # Only choose an option after you RELEASE the accept button so you can see the earlier ui sauce i guess
		match select:
			START:
				start();
			QUIT:
				get_tree().quit();
	
	
	cursor.position = Vector2(13 + offset, positions[select]); # Set the cursor to the proper menu position

func start(): # again, this didn't need to be its own function. i don't care. i makea da function
	Globals.change_scene("entrance");
	