extends Node2D

func _process(delta):
    if $Visuals.frame >= 269 || Input.is_action_just_released("accept"):
        Globals.change_scene("title_screen");