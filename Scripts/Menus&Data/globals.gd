extends Node

# The library, assigning string keys to every scene you can load to for simplicity.
const SCENE_LIBRARY = {
	"title_screen" : "res://Scenes/Maps/title_screen_map.tscn",
	"test_map" : "res://Scenes/Maps/test_map.tscn",
	"map_dungeon_1" : "",
	"end_credits" : "res://Scenes/Maps/credits_map.tscn",
	"death_screen": "res://Scenes/Maps/death_screen.tscn"
}

# The current scene being run by the game.
var current_scene

# Upon launching the game.
func _ready():
	determine_current_scene()

func determine_current_scene():
	for node in get_parent().get_children():
		if node != self:
			current_scene = node
			return

func change_scene(new_scene_key):
	if SCENE_LIBRARY.has(new_scene_key) == false:
		# Scene isn't in the library, return.
		return
	var new_scene_node = load(SCENE_LIBRARY[new_scene_key])
	new_scene_node = new_scene_node.instantiate()
	# Prepare to end the current scene.
	current_scene.queue_free()
	# Add the new scene to the scene tree.
	get_parent().add_child(new_scene_node)
	current_scene = new_scene_node
