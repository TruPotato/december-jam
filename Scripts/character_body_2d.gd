extends CharacterBody2D

func _ready():
    pass

func _physics_process(delta):


    velocity = Vector2(400, 400);
    move_and_slide();