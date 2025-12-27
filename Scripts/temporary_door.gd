extends Area2D

@export var end_room = "test_map"

func _on_body_entered(body):
	if body.name == "PlayerNode":
		Globals.change_scene(end_room)
