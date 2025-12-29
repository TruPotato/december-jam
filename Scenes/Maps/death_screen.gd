extends Node2D

const initial_wait = 0.5
var current_wait

# Called when the node enters the scene tree for the first time.
func _ready():
	current_wait = initial_wait


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	current_wait -= _delta
	if Input.is_action_just_pressed("accept") and current_wait <=0:
		Globals.change_scene("title_screen")
